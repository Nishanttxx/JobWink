-- ============================================================================
-- SUPABASE MIGRATION: Production-grade Per-User Daily Resume Limit & Admin System
-- Migration File: supabase/migrations/20260820000001_user_resume_limits.sql
-- ============================================================================

-- 1. USER RESUME LIMITS TABLE
CREATE TABLE IF NOT EXISTS public.user_resume_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_limit INTEGER NOT NULL DEFAULT 4 CHECK (daily_limit >= 0),
  resumes_generated_today INTEGER NOT NULL DEFAULT 0 CHECK (resumes_generated_today >= 0),
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Rapid lookup index
CREATE INDEX IF NOT EXISTS idx_user_resume_limits_user_date ON public.user_resume_limits (user_id, usage_date);

-- Enable Row Level Security
ALTER TABLE public.user_resume_limits ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Authenticated users can view ONLY their own rate limit state
DROP POLICY IF EXISTS "Users can view their own resume limit" ON public.user_resume_limits;
CREATE POLICY "Users can view their own resume limit"
  ON public.user_resume_limits FOR SELECT
  USING (auth.uid() = user_id);

-- Note: Direct client INSERT/UPDATE/DELETE are blocked by default RLS (no policy created).
-- All quota mutations must go through SECURITY DEFINER stored procedures or Service Role.


-- 2. AUTOMATIC USER INITIALIZATION TRIGGER & BACKFILL
CREATE OR REPLACE FUNCTION public.handle_new_user_resume_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'user_resume_limits' AND column_name = 'usage_count'
  ) THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
    VALUES (NEW.id, 4, 0, CURRENT_DATE)
    ON CONFLICT (user_id) DO NOTHING;
  ELSE
    INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
    VALUES (NEW.id, 4, 0, CURRENT_DATE)
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger on auth.users (runs whenever a new user registers)
DROP TRIGGER IF EXISTS on_auth_user_created_resume_limit ON auth.users;
CREATE TRIGGER on_auth_user_created_resume_limit
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_resume_limit();

-- Backfill existing users who do not have a limit record yet
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'user_resume_limits' AND column_name = 'usage_count'
    ) THEN
      INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
      SELECT id, 4, 0, CURRENT_DATE
      FROM auth.users
      ON CONFLICT (user_id) DO NOTHING;
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'user_resume_limits' AND column_name = 'resumes_generated_today'
    ) THEN
      INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
      SELECT id, 4, 0, CURRENT_DATE
      FROM auth.users
      ON CONFLICT (user_id) DO NOTHING;
    END IF;
  END IF;
END $$;



-- 3. ATOMIC RPC FUNCTION: CHECK AND RESERVE RESUME GENERATION (RACE-CONDITION PROOF)
CREATE OR REPLACE FUNCTION public.check_and_reserve_resume_limit(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit_record public.user_resume_limits%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
  v_daily_limit INT := 4;
BEGIN
  -- Lock row for update to prevent concurrent race conditions across tabs/requests
  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Create missing record if user has no row yet
  IF NOT FOUND THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
    VALUES (p_user_id, 4, 0, v_today)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_limit_record
    FROM public.user_resume_limits
    WHERE user_id = p_user_id
    FOR UPDATE;
  END IF;

  v_daily_limit := v_limit_record.daily_limit;

  -- Daily reset logic: if usage_date is prior to server current date, reset count
  IF v_limit_record.usage_date < v_today THEN
    v_used := 0;
  ELSE
    v_used := v_limit_record.resumes_generated_today;
  END IF;

  -- Check limit
  IF v_used >= v_daily_limit THEN
    -- Limit reached: update usage_date to current server date without incrementing count
    UPDATE public.user_resume_limits
    SET resumes_generated_today = v_used,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
      'allowed', false,
      'error', 'DAILY_LIMIT_REACHED',
      'message', 'Daily resume generation limit reached.',
      'limit', v_daily_limit,
      'used', v_used,
      'remaining', 0,
      'usage_date', v_today
    );
  ELSE
    -- Increment count atomically
    v_used := v_used + 1;

    UPDATE public.user_resume_limits
    SET resumes_generated_today = v_used,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
      'allowed', true,
      'limit', v_daily_limit,
      'used', v_used,
      'remaining', GREATEST(0, v_daily_limit - v_used),
      'usage_date', v_today
    );
  END IF;
END;
$$;


-- 4. ATOMIC RPC FUNCTION: REFUND RESUME GENERATION (ON AI API FAILURE)
CREATE OR REPLACE FUNCTION public.refund_resume_limit(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit_record public.user_resume_limits%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
BEGIN
  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_limit_record.usage_date = v_today AND v_limit_record.resumes_generated_today > 0 THEN
      v_used := v_limit_record.resumes_generated_today - 1;
      UPDATE public.user_resume_limits
      SET resumes_generated_today = v_used,
          updated_at = NOW()
      WHERE user_id = p_user_id;
    ELSE
      v_used := 0;
    END IF;

    RETURN jsonb_build_object(
      'refunded', true,
      'limit', v_limit_record.daily_limit,
      'used', v_used,
      'remaining', GREATEST(0, v_limit_record.daily_limit - v_used)
    );
  END IF;

  RETURN jsonb_build_object('refunded', false, 'used', 0);
END;
$$;


-- 5. RPC FUNCTION: GET USER RESUME USAGE (WITH DAY RESET)
CREATE OR REPLACE FUNCTION public.get_user_resume_usage(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_limit_record public.user_resume_limits%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
BEGIN
  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
    VALUES (p_user_id, 4, 0, v_today)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_limit_record
    FROM public.user_resume_limits
    WHERE user_id = p_user_id;
  END IF;

  IF v_limit_record.usage_date < v_today THEN
    v_used := 0;
    -- Optionally update usage_date & count in background
    UPDATE public.user_resume_limits
    SET resumes_generated_today = 0,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = p_user_id;
  ELSE
    v_used := v_limit_record.resumes_generated_today;
  END IF;

  RETURN jsonb_build_object(
    'user_id', p_user_id,
    'daily_limit', v_limit_record.daily_limit,
    'resumes_generated_today', v_used,
    'remaining', GREATEST(0, v_limit_record.daily_limit - v_used),
    'allowed', (v_used < v_limit_record.daily_limit),
    'usage_date', v_today
  );
END;
$$;


-- 6. ADMIN RPC FUNCTION: UPDATE USER DAILY LIMIT
CREATE OR REPLACE FUNCTION public.update_user_resume_limit(p_user_id UUID, p_new_limit INT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
BEGIN
  IF p_new_limit < 0 THEN
    RAISE EXCEPTION 'Daily limit must be greater than or equal to 0';
  END IF;

  INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
  VALUES (p_user_id, p_new_limit, 0, v_today)
  ON CONFLICT (user_id)
  DO UPDATE SET daily_limit = p_new_limit, updated_at = NOW();

  SELECT resumes_generated_today INTO v_used
  FROM public.user_resume_limits
  WHERE user_id = p_user_id AND usage_date = v_today;

  IF v_used IS NULL THEN
    v_used := 0;
  END IF;

  RETURN jsonb_build_object(
    'user_id', p_user_id,
    'daily_limit', p_new_limit,
    'resumes_generated_today', v_used,
    'remaining', GREATEST(0, p_new_limit - v_used),
    'usage_date', v_today
  );
END;
$$;


-- 7. ADMIN RPC FUNCTION: RESET TODAY'S USER USAGE
CREATE OR REPLACE FUNCTION public.reset_user_resume_usage(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_limit INT := 4;
BEGIN
  UPDATE public.user_resume_limits
  SET resumes_generated_today = 0,
      usage_date = v_today,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  SELECT daily_limit INTO v_limit
  FROM public.user_resume_limits
  WHERE user_id = p_user_id;

  IF v_limit IS NULL THEN
    v_limit := 4;
  END IF;

  RETURN jsonb_build_object(
    'user_id', p_user_id,
    'daily_limit', v_limit,
    'resumes_generated_today', 0,
    'remaining', v_limit,
    'usage_date', v_today
  );
END;
$$;


-- 8. ADMIN RPC FUNCTION: GET DASHBOARD STATS
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_total_users INT := 0;
  v_active_users_today INT := 0;
  v_resumes_today INT := 0;
  v_users_at_limit INT := 0;
BEGIN
  -- Total registered users
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    SELECT COUNT(*) INTO v_total_users FROM public.profiles;
  ELSE
    SELECT COUNT(*) INTO v_total_users FROM public.user_resume_limits;
  END IF;

  -- Active users today (users who generated >= 1 resume today)
  SELECT COUNT(*) INTO v_active_users_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND resumes_generated_today > 0;

  -- Total resumes generated today
  SELECT COALESCE(SUM(resumes_generated_today), 0) INTO v_resumes_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today;

  -- Users at daily limit today
  SELECT COUNT(*) INTO v_users_at_limit
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND resumes_generated_today >= daily_limit;

  RETURN jsonb_build_object(
    'totalUsers', v_total_users,
    'activeUsersToday', v_active_users_today,
    'resumesGeneratedToday', v_resumes_today,
    'usersAtLimit', v_users_at_limit
  );
END;
$$;
