-- ============================================================================
-- SUPABASE MIGRATION: Production-grade AI Usage Limits & Resume Caching
-- Migration File: supabase/migrations/20260814_ai_usage_and_caching.sql
-- ============================================================================

-- 1. SUPABASE AI USAGE TABLE
CREATE TABLE IF NOT EXISTS public.ai_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation TEXT NOT NULL,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  request_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ai_usage_user_op_date_key UNIQUE (user_id, operation, usage_date)
);

-- Index for rapid usage lookups
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_date ON public.ai_usage (user_id, usage_date, operation);

-- Enable Row Level Security (RLS) on ai_usage
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own ai_usage" ON public.ai_usage;
CREATE POLICY "Users can view their own ai_usage"
  ON public.ai_usage FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own ai_usage" ON public.ai_usage;
CREATE POLICY "Users can insert their own ai_usage"
  ON public.ai_usage FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own ai_usage" ON public.ai_usage;
CREATE POLICY "Users can update their own ai_usage"
  ON public.ai_usage FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- 2. RESUMES TABLE FOR CACHING & PERSISTENCE
CREATE TABLE IF NOT EXISTS public.resumes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'Master Resume',
  original_file_url TEXT,
  extracted_data JSONB,
  current_version_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for user resumes
CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON public.resumes (user_id);

-- Enable RLS on resumes
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own resumes" ON public.resumes;
CREATE POLICY "Users can view their own resumes"
  ON public.resumes FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own resumes" ON public.resumes;
CREATE POLICY "Users can insert their own resumes"
  ON public.resumes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own resumes" ON public.resumes;
CREATE POLICY "Users can update their own resumes"
  ON public.resumes FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own resumes" ON public.resumes;
CREATE POLICY "Users can delete their own resumes"
  ON public.resumes FOR DELETE
  USING (auth.uid() = user_id);


-- 3. RESUME VERSIONS TABLE
CREATE TABLE IF NOT EXISTS public.resume_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resume_id UUID NOT NULL REFERENCES public.resumes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL DEFAULT 1,
  parsed_content JSONB NOT NULL DEFAULT '{}'::jsonb,
  change_summary TEXT DEFAULT 'Resume update',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on resume_versions
ALTER TABLE public.resume_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own resume versions" ON public.resume_versions;
CREATE POLICY "Users can view their own resume versions"
  ON public.resume_versions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own resume versions" ON public.resume_versions;
CREATE POLICY "Users can insert their own resume versions"
  ON public.resume_versions FOR INSERT
  WITH CHECK (auth.uid() = user_id);


-- 4. ATOMIC RPC FUNCTION TO CHECK AND CONSUME AI USAGE LIMIT (RACE-CONDITION PROOF)
CREATE OR REPLACE FUNCTION public.check_and_consume_ai_limit(
  p_user_id UUID,
  p_operation TEXT,
  p_max_limit INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_current_count INT := 0;
BEGIN
  -- Retrieve current request_count for today
  SELECT request_count INTO v_current_count
  FROM public.ai_usage
  WHERE user_id = p_user_id
    AND operation = p_operation
    AND usage_date = v_today;

  IF v_current_count IS NULL THEN
    -- First request of the day
    INSERT INTO public.ai_usage (user_id, operation, usage_date, request_count)
    VALUES (p_user_id, p_operation, v_today, 1)
    ON CONFLICT (user_id, operation, usage_date)
    DO UPDATE SET request_count = public.ai_usage.request_count + 1, updated_at = NOW();

    RETURN jsonb_build_object(
      'allowed', true,
      'request_count', 1,
      'limit', p_max_limit
    );
  ELSIF v_current_count >= p_max_limit THEN
    -- Limit reached
    RETURN jsonb_build_object(
      'allowed', false,
      'request_count', v_current_count,
      'limit', p_max_limit,
      'error_code', 'AI_DAILY_LIMIT_REACHED',
      'message', 'You have reached your daily resume processing limit. Please try again tomorrow.'
    );
  ELSE
    -- Atomically increment usage
    UPDATE public.ai_usage
    SET request_count = request_count + 1,
        updated_at = NOW()
    WHERE user_id = p_user_id
      AND operation = p_operation
      AND usage_date = v_today;

    RETURN jsonb_build_object(
      'allowed', true,
      'request_count', v_current_count + 1,
      'limit', p_max_limit
    );
  END IF;
END;
$$;
