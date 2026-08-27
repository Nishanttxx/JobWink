-- ============================================================================
-- SUPABASE MIGRATION: Admin Dashboard & Atomic Resume Creation Limit Enforcement
-- Migration File: supabase/migrations/20260824000001_admin_resume_limits.sql
-- ============================================================================

-- 1. Ensure Table Structure for `user_resume_limits`
CREATE TABLE IF NOT EXISTS public.user_resume_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_limit INTEGER NOT NULL DEFAULT 4 CHECK (daily_limit >= 0),
  usage_count INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Migration safety: Rename `resumes_generated_today` to `usage_count` if table was created in an older migration
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_resume_limits' AND column_name = 'resumes_generated_today'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_resume_limits' AND column_name = 'usage_count'
  ) THEN
    ALTER TABLE public.user_resume_limits RENAME COLUMN resumes_generated_today TO usage_count;
  END IF;
END $$;

-- Fast index on user and usage date
CREATE INDEX IF NOT EXISTS idx_user_resume_limits_user_date ON public.user_resume_limits (user_id, usage_date);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_resume_limits ENABLE ROW LEVEL SECURITY;

-- 2. Row Level Security Policies
-- Authenticated users can view ONLY their own limit record.
-- The admin (role = 'admin' in app_metadata) can view all rows.
DROP POLICY IF EXISTS "Users can view their own resume limit" ON public.user_resume_limits;
CREATE POLICY "Users can view their own resume limit"
  ON public.user_resume_limits FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin_caller());

-- All mutations (INSERT/UPDATE/DELETE) must execute via SECURITY DEFINER functions or Service Role.
-- Normal users cannot directly insert, update, or delete from this table.


-- 3. Automatic User Record Creation Trigger & Backfill
CREATE OR REPLACE FUNCTION public.handle_new_user_resume_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_resume_limits (
    user_id,
    daily_limit,
    usage_count,
    usage_date
  )
  VALUES (
    NEW.id,
    4,
    0,
    CURRENT_DATE
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_resume_limit ON auth.users;
CREATE TRIGGER on_auth_user_created_resume_limit
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_resume_limit();

-- Backfill all existing auth.users who do not yet have a record
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
    SELECT id, 4, 0, CURRENT_DATE
    FROM auth.users
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
END $$;


-- 4. Server-Side Admin Authorization Helper
-- NOTE: Overridden by migration 20260827000001 (role-based check, no hardcoded email)
DROP FUNCTION IF EXISTS public.is_admin_caller() CASCADE;
CREATE OR REPLACE FUNCTION public.is_admin_caller()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Placeholder: overridden by later migration 20260827000001_dynamic_admin_config.sql
  RETURN false;
END;
$$;


-- 5. ATOMIC RPC FUNCTION: Check & Reserve Resume Creation Quota
-- Race-condition-proof using row-level locking (FOR UPDATE)
-- Automatically performs daily reset if usage_date < CURRENT_DATE
DROP FUNCTION IF EXISTS public.check_and_reserve_resume_limit() CASCADE;
DROP FUNCTION IF EXISTS public.check_and_reserve_resume_limit(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.check_and_reserve_resume_limit(p_user_id UUID DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_limit_record public.user_resume_limits%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
  v_limit INT := 4;
BEGIN
  -- Always derive user from authenticated JWT session; allow override only for verified admin caller
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  -- Lock row for update to eliminate race conditions
  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id
  FOR UPDATE;

  -- Auto-create record with default limit (999999 for admin, 4 for normal users) if missing
  IF NOT FOUND THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
    VALUES (v_user_id, CASE WHEN is_admin_caller() AND (p_user_id IS NULL OR p_user_id = auth.uid()) THEN 999999 ELSE 4 END, 0, v_today)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_limit_record
    FROM public.user_resume_limits
    WHERE user_id = v_user_id
    FOR UPDATE;
  END IF;

  IF is_admin_caller() AND (p_user_id IS NULL OR p_user_id = auth.uid()) THEN
    v_limit := 999999;
  ELSE
    v_limit := COALESCE(v_limit_record.daily_limit, 4);
  END IF;

  -- Daily Reset Logic: if recorded date is not current date, reset usage count to 0
  IF v_limit_record.usage_date != v_today THEN
    v_used := 0;
  ELSE
    v_used := COALESCE(v_limit_record.usage_count, 0);
  END IF;

  -- Quota Limit Check (Admin is exempt from daily limit blocking)
  IF v_limit < 999999 AND v_used >= v_limit THEN
    UPDATE public.user_resume_limits
    SET usage_count = v_used,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    RETURN json_build_object(
      'allowed', false,
      'error', 'DAILY_LIMIT_REACHED',
      'message', 'Daily resume limit reached. Please try again tomorrow.',
      'daily_limit', v_limit,
      'usage_count', v_used,
      'remaining', 0,
      'usage_date', v_today
    );
  ELSE
    -- Atomically increment usage
    v_used := v_used + 1;

    UPDATE public.user_resume_limits
    SET usage_count = v_used,
        daily_limit = CASE WHEN is_admin_caller() AND (p_user_id IS NULL OR p_user_id = auth.uid()) THEN 999999 ELSE v_limit_record.daily_limit END,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    RETURN json_build_object(
      'allowed', true,
      'daily_limit', v_limit,
      'usage_count', v_used,
      'remaining', GREATEST(0, v_limit - v_used),
      'usage_date', v_today,
      'is_admin', (v_limit >= 999999)
    );
  END IF;
END;
$$;


-- 6. ATOMIC RPC FUNCTION: Refund Resume Creation (On Pipeline / Parser Failure)
DROP FUNCTION IF EXISTS public.refund_resume_limit() CASCADE;
DROP FUNCTION IF EXISTS public.refund_resume_limit(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.refund_resume_limit(p_user_id UUID DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_limit_record public.user_resume_limits%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
BEGIN
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RETURN json_build_object('refunded', false);
  END IF;

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_limit_record.usage_date = v_today AND v_limit_record.usage_count > 0 THEN
      v_used := v_limit_record.usage_count - 1;
      UPDATE public.user_resume_limits
      SET usage_count = v_used,
          updated_at = NOW()
      WHERE user_id = v_user_id;
    ELSE
      v_used := 0;
    END IF;

    RETURN json_build_object(
      'refunded', true,
      'daily_limit', v_limit_record.daily_limit,
      'usage_count', v_used,
      'remaining', GREATEST(0, v_limit_record.daily_limit - v_used)
    );
  END IF;

  RETURN json_build_object('refunded', false, 'usage_count', 0);
END;
$$;


-- 7. RPC FUNCTION: Get Current User's Resume Usage
DROP FUNCTION IF EXISTS public.get_user_resume_usage() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_resume_usage(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.get_user_resume_usage(p_user_id UUID DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_limit_record public.user_resume_limits%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
  v_is_admin BOOLEAN := false;
BEGIN
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  v_is_admin := is_admin_caller() AND (p_user_id IS NULL OR p_user_id = auth.uid());

  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'daily_limit', 4,
      'usage_count', 0,
      'remaining', 4,
      'allowed', true
    );
  END IF;

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
    VALUES (v_user_id, CASE WHEN v_is_admin THEN 999999 ELSE 4 END, 0, v_today)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_limit_record
    FROM public.user_resume_limits
    WHERE user_id = v_user_id;
  END IF;

  IF v_limit_record.usage_date != v_today THEN
    v_used := 0;
    UPDATE public.user_resume_limits
    SET usage_count = 0,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = v_user_id;
  ELSE
    v_used := COALESCE(v_limit_record.usage_count, 0);
  END IF;

  RETURN json_build_object(
    'user_id', v_user_id,
    'daily_limit', CASE WHEN v_is_admin THEN 999999 ELSE COALESCE(v_limit_record.daily_limit, 4) END,
    'usage_count', v_used,
    'resumes_generated_today', v_used,
    'remaining', CASE WHEN v_is_admin THEN 999999 ELSE GREATEST(0, COALESCE(v_limit_record.daily_limit, 4) - v_used) END,
    'allowed', (v_is_admin OR v_used < COALESCE(v_limit_record.daily_limit, 4)),
    'is_unlimited', v_is_admin,
    'usage_date', v_today
  );
END;
$$;


-- 8. ADMIN RPC FUNCTION: Get Admin Dashboard Stats
DROP FUNCTION IF EXISTS public.get_admin_dashboard_stats() CASCADE;

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_users INT := 0;
  v_active_today INT := 0;
  v_resumes_today INT := 0;
  v_at_limit INT := 0;
  v_today DATE := CURRENT_DATE;
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  -- 1. Total registered users
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    SELECT COUNT(*) INTO v_total_users FROM public.profiles;
  ELSE
    SELECT COUNT(*) INTO v_total_users FROM public.user_resume_limits;
  END IF;

  -- 2. Active users who created >= 1 resume today
  SELECT COUNT(DISTINCT user_id) INTO v_active_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND usage_count > 0;

  -- 3. Total resumes created today
  SELECT COALESCE(SUM(usage_count), 0) INTO v_resumes_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today;

  -- 4. Users at or above limit today (excluding admin with 999999 limit)
  SELECT COUNT(*) INTO v_at_limit
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND usage_count >= daily_limit AND daily_limit < 999999;

  RETURN json_build_object(
    'totalUsers', v_total_users,
    'activeUsersToday', v_active_today,
    'resumesGeneratedToday', v_resumes_today,
    'usersAtLimit', v_at_limit
  );
END;
$$;


-- 9. ADMIN RPC FUNCTION: Get Admin Users List
DROP FUNCTION IF EXISTS public.get_admin_users() CASCADE;

CREATE OR REPLACE FUNCTION public.get_admin_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  full_name TEXT,
  daily_limit INT,
  usage_count INT,
  resumes_generated_today INT,
  remaining INT,
  usage_date TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
    SELECT
      p.id AS user_id,
      p.email,
      p.full_name,
      COALESCE(u.daily_limit, 4)::INT AS daily_limit,
      CASE
        WHEN u.usage_date = CURRENT_DATE THEN COALESCE(u.usage_count, 0)::INT
        ELSE 0
      END AS usage_count,
      CASE
        WHEN u.usage_date = CURRENT_DATE THEN COALESCE(u.usage_count, 0)::INT
        ELSE 0
      END AS resumes_generated_today,
      GREATEST(0, COALESCE(u.daily_limit, 4) - (
        CASE
          WHEN u.usage_date = CURRENT_DATE THEN COALESCE(u.usage_count, 0)::INT
          ELSE 0
        END
      ))::INT AS remaining,
      COALESCE(u.usage_date::TEXT, CURRENT_DATE::TEXT) AS usage_date,
      p.created_at
    FROM public.profiles p
    LEFT JOIN public.user_resume_limits u ON u.user_id = p.id
    ORDER BY p.created_at DESC;
END;
$$;


-- 10. ADMIN RPC FUNCTION: Update User Daily Limit
DROP FUNCTION IF EXISTS public.update_user_resume_limit(UUID, INT) CASCADE;

CREATE OR REPLACE FUNCTION public.update_user_resume_limit(p_user_id UUID, p_new_limit INT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_used INT := 0;
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  IF p_new_limit < 0 THEN
    RAISE EXCEPTION 'Daily limit must be greater than or equal to 0' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
  VALUES (p_user_id, p_new_limit, 0, v_today)
  ON CONFLICT (user_id)
  DO UPDATE SET
    daily_limit = p_new_limit,
    updated_at = NOW();

  SELECT
    CASE
      WHEN usage_date = v_today THEN COALESCE(usage_count, 0)
      ELSE 0
    END INTO v_used
  FROM public.user_resume_limits
  WHERE user_id = p_user_id;

  IF v_used IS NULL THEN
    v_used := 0;
  END IF;

  RETURN json_build_object(
    'user_id', p_user_id,
    'daily_limit', p_new_limit,
    'usage_count', v_used,
    'remaining', GREATEST(0, p_new_limit - v_used),
    'usage_date', v_today
  );
END;
$$;


-- 11. ADMIN RPC FUNCTION: Reset User Usage
DROP FUNCTION IF EXISTS public.reset_user_resume_usage(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.reset_user_resume_usage(p_user_id UUID)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_limit INT := 4;
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.user_resume_limits
  SET usage_count = 0,
      usage_date = v_today,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  SELECT COALESCE(daily_limit, 4) INTO v_limit
  FROM public.user_resume_limits
  WHERE user_id = p_user_id;

  RETURN json_build_object(
    'user_id', p_user_id,
    'daily_limit', v_limit,
    'usage_count', 0,
    'remaining', v_limit,
    'usage_date', v_today
  );
END;
$$;


-- 12. Security Grants: Grant execute permissions exclusively to authenticated users
REVOKE ALL ON FUNCTION public.is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO authenticated;

REVOKE ALL ON FUNCTION public.check_and_reserve_resume_limit(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_and_reserve_resume_limit(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.refund_resume_limit(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refund_resume_limit(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_user_resume_usage(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_resume_usage(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_admin_dashboard_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_stats() TO authenticated;

REVOKE ALL ON FUNCTION public.get_admin_users() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_users() TO authenticated;

REVOKE ALL ON FUNCTION public.update_user_resume_limit(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_user_resume_limit(UUID, INT) TO authenticated;

REVOKE ALL ON FUNCTION public.reset_user_resume_usage(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reset_user_resume_usage(UUID) TO authenticated;
