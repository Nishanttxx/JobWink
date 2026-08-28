-- ============================================================================
-- SUPABASE MASTER DATABASE RECONCILIATION MIGRATION
-- Migration File: supabase/migrations/20260828000001_master_database_reconciliation.sql
-- ============================================================================
-- Idempotent, non-destructive reconciliation for the Jobwink production database.
-- 
-- GUARANTEES:
-- 1. Zero data loss (no DROP TABLE, no TRUNCATE, no DELETE).
-- 2. Preserves existing user rows, quotas, profiles, and storage objects.
-- 3. Idempotent triggers, indexes, and RLS policies (DROP IF EXISTS before CREATE).
-- 4. Resolves return-type conflicts on RPC functions via DROP FUNCTION ... CASCADE.
-- 5. Does NOT touch storage.objects table-level permissions.
-- 6. Aligns with current JobWink Flutter client and Python backend code.
-- ============================================================================

-- -----------------------------------------------------------------------------
-- 1. EXTENSIONS
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS "vector";
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'vector extension could not be enabled or is managed by Supabase dashboard: %', SQLERRM;
END $$;

-- -----------------------------------------------------------------------------
-- 2. CORE HELPER FUNCTIONS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 3. SCHEMA: TABLES & COLUMNS (IDEMPOTENT CREATION & EXTENSION)
-- -----------------------------------------------------------------------------

-- 3.1 PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    location TEXT,
    website TEXT,
    linkedin_url TEXT,
    github_url TEXT,
    bio TEXT,
    headline TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS linkedin_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS github_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS headline TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- 3.2 RESUMES TABLE
CREATE TABLE IF NOT EXISTS public.resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Master Resume',
    original_file_url TEXT,
    extracted_data JSONB DEFAULT '{}'::jsonb,
    current_version_id UUID,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.resumes ADD COLUMN IF NOT EXISTS title TEXT NOT NULL DEFAULT 'Master Resume';
ALTER TABLE public.resumes ADD COLUMN IF NOT EXISTS original_file_url TEXT;
ALTER TABLE public.resumes ADD COLUMN IF NOT EXISTS extracted_data JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.resumes ADD COLUMN IF NOT EXISTS current_version_id UUID;
ALTER TABLE public.resumes ADD COLUMN IF NOT EXISTS is_primary BOOLEAN DEFAULT FALSE;

-- 3.3 RESUME VERSIONS TABLE
CREATE TABLE IF NOT EXISTS public.resume_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    parsed_content JSONB NOT NULL DEFAULT '{}'::jsonb,
    change_summary TEXT DEFAULT 'Resume update',
    target_job_title TEXT,
    target_company TEXT,
    ats_score NUMERIC(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.resume_versions ADD COLUMN IF NOT EXISTS version_number INTEGER NOT NULL DEFAULT 1;
ALTER TABLE public.resume_versions ADD COLUMN IF NOT EXISTS parsed_content JSONB NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.resume_versions ADD COLUMN IF NOT EXISTS change_summary TEXT DEFAULT 'Resume update';
ALTER TABLE public.resume_versions ADD COLUMN IF NOT EXISTS target_job_title TEXT;
ALTER TABLE public.resume_versions ADD COLUMN IF NOT EXISTS target_company TEXT;
ALTER TABLE public.resume_versions ADD COLUMN IF NOT EXISTS ats_score NUMERIC(5,2);

-- 3.4 REFERENCE RESUMES TABLE
CREATE TABLE IF NOT EXISTS public.reference_resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    industry TEXT NOT NULL,
    target_role TEXT NOT NULL,
    file_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.5 ATS ANALYSIS TABLE
CREATE TABLE IF NOT EXISTS public.ats_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_version_id UUID REFERENCES public.resume_versions(id) ON DELETE CASCADE,
    job_id UUID,
    ats_score INT NOT NULL DEFAULT 0 CHECK (ats_score BETWEEN 0 AND 100),
    formatting_score INT DEFAULT 0 CHECK (formatting_score BETWEEN 0 AND 100),
    content_score INT DEFAULT 0 CHECK (content_score BETWEEN 0 AND 100),
    relevance_score INT DEFAULT 0 CHECK (relevance_score BETWEEN 0 AND 100),
    feedback JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS resume_version_id UUID;
ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS job_id UUID;
ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS ats_score INT DEFAULT 0;
ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS formatting_score INT DEFAULT 0;
ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS content_score INT DEFAULT 0;
ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS relevance_score INT DEFAULT 0;
ALTER TABLE public.ats_analysis ADD COLUMN IF NOT EXISTS feedback JSONB DEFAULT '{}'::jsonb;

-- 3.6 KEYWORD ANALYSIS TABLE
CREATE TABLE IF NOT EXISTS public.keyword_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_version_id UUID REFERENCES public.resume_versions(id) ON DELETE CASCADE,
    job_id UUID,
    extracted_skills TEXT[] DEFAULT '{}',
    missing_skills TEXT[] DEFAULT '{}',
    matching_skills TEXT[] DEFAULT '{}',
    frequency_map JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.keyword_analysis ADD COLUMN IF NOT EXISTS resume_version_id UUID;
ALTER TABLE public.keyword_analysis ADD COLUMN IF NOT EXISTS job_id UUID;
ALTER TABLE public.keyword_analysis ADD COLUMN IF NOT EXISTS extracted_skills TEXT[] DEFAULT '{}';
ALTER TABLE public.keyword_analysis ADD COLUMN IF NOT EXISTS missing_skills TEXT[] DEFAULT '{}';
ALTER TABLE public.keyword_analysis ADD COLUMN IF NOT EXISTS matching_skills TEXT[] DEFAULT '{}';
ALTER TABLE public.keyword_analysis ADD COLUMN IF NOT EXISTS frequency_map JSONB DEFAULT '{}'::jsonb;


-- 3.7 JOBS TABLE
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    company TEXT NOT NULL,
    location TEXT,
    description TEXT NOT NULL,
    url TEXT,
    salary_range TEXT,
    employment_type TEXT,
    experience_level TEXT,
    skills_required TEXT[] DEFAULT ARRAY[]::TEXT[],
    source TEXT DEFAULT 'direct',
    source_id TEXT,
    source_url TEXT,
    source_posted_at TIMESTAMPTZ,
    source_updated_at TIMESTAMPTZ,
    posted_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    is_within_48_hours BOOLEAN DEFAULT FALSE,
    platform_source TEXT,
    normalized_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS source_id TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS source_url TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS source_posted_at TIMESTAMPTZ;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS source_updated_at TIMESTAMPTZ;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS is_within_48_hours BOOLEAN DEFAULT FALSE;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS platform_source TEXT;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS normalized_hash TEXT;

-- 3.8 JOB MATCHES TABLE
CREATE TABLE IF NOT EXISTS public.job_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE SET NULL,
    match_score NUMERIC(5,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    applied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_job_match UNIQUE (user_id, job_id)
);

-- 3.9 COVER LETTERS TABLE
CREATE TABLE IF NOT EXISTS public.cover_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    resume_id UUID REFERENCES public.resumes(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    title TEXT NOT NULL DEFAULT 'Cover Letter',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.10 USER ACTIVITY TABLE
CREATE TABLE IF NOT EXISTS public.user_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.11 JOB PREDICTIONS TABLE
CREATE TABLE IF NOT EXISTS public.job_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_id UUID NOT NULL REFERENCES public.resumes(id) ON DELETE CASCADE,
    resume_version_id UUID REFERENCES public.resume_versions(id) ON DELETE SET NULL,
    tailored_resume_hash TEXT,
    job_title TEXT,
    job_description TEXT NOT NULL,
    extracted_features JSONB NOT NULL DEFAULT '{}'::jsonb,
    structured_probability NUMERIC(5,4) NOT NULL CHECK (structured_probability BETWEEN 0.0000 AND 1.0000),
    fit_probability NUMERIC(5,4) NOT NULL CHECK (fit_probability BETWEEN 0.0000 AND 1.0000),
    combined_probability NUMERIC(5,4) NOT NULL CHECK (combined_probability BETWEEN 0.0000 AND 1.0000),
    is_match BOOLEAN NOT NULL DEFAULT FALSE,
    estimated_match_level TEXT NOT NULL DEFAULT 'Low Model Match',
    is_stale BOOLEAN NOT NULL DEFAULT FALSE,
    disclaimer TEXT NOT NULL DEFAULT 'Model-estimated probability based on statistical feature match. This score does not guarantee interview shortlisting or employment outcomes, nor is it an automated hiring decision.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.12 AI USAGE TABLE
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

-- 3.13 USER RESUME LIMITS TABLE (WITH SAFE COLUMN RENAMING)
CREATE TABLE IF NOT EXISTS public.user_resume_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_limit INTEGER NOT NULL DEFAULT 4 CHECK (daily_limit >= 0),
    usage_count INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

ALTER TABLE public.user_resume_limits ADD COLUMN IF NOT EXISTS usage_count INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0);
ALTER TABLE public.user_resume_limits ADD COLUMN IF NOT EXISTS daily_limit INTEGER NOT NULL DEFAULT 4 CHECK (daily_limit >= 0);
ALTER TABLE public.user_resume_limits ADD COLUMN IF NOT EXISTS usage_date DATE NOT NULL DEFAULT CURRENT_DATE;

-- 3.14 BUG REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.bug_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    user_email TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    page_url TEXT,
    route TEXT,
    screenshot_url TEXT,
    screenshot_reference TEXT,
    browser TEXT,
    os TEXT,
    screen_size TEXT,
    app_version TEXT,
    platform TEXT,
    device_info JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'open',
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.bug_reports ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.bug_reports ADD COLUMN IF NOT EXISTS screenshot_reference TEXT;
ALTER TABLE public.bug_reports ADD COLUMN IF NOT EXISTS browser TEXT;
ALTER TABLE public.bug_reports ADD COLUMN IF NOT EXISTS os TEXT;
ALTER TABLE public.bug_reports ADD COLUMN IF NOT EXISTS screen_size TEXT;

-- 3.15 JOB INGESTION LOGS & CONFIG
CREATE TABLE IF NOT EXISTS public.job_ingestion_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    jobs_found INT DEFAULT 0,
    jobs_added INT DEFAULT 0,
    jobs_updated INT DEFAULT 0,
    jobs_skipped INT DEFAULT 0,
    duplicates_found INT DEFAULT 0,
    jobs_outside_48_hours INT DEFAULT 0,
    status TEXT DEFAULT 'RUNNING',
    errors TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.job_sources_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    url TEXT NOT NULL UNIQUE,
    allowed BOOLEAN DEFAULT TRUE,
    selectors JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4. INDEXES (IDEMPOTENT)
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_resumes_user_id ON public.resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resume_versions_resume_id ON public.resume_versions(resume_id);
CREATE INDEX IF NOT EXISTS idx_resume_versions_user_id ON public.resume_versions(user_id);
CREATE INDEX IF NOT EXISTS idx_reference_resumes_user_id ON public.reference_resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_ats_analysis_user ON public.ats_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_ats_analysis_version ON public.ats_analysis(resume_version_id);
CREATE INDEX IF NOT EXISTS idx_keyword_analysis_user ON public.keyword_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_keyword_analysis_version ON public.keyword_analysis(resume_version_id);

CREATE INDEX IF NOT EXISTS idx_jobs_is_active ON public.jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_job_matches_user_status ON public.job_matches(user_id, status);
CREATE INDEX IF NOT EXISTS idx_job_matches_job ON public.job_matches(job_id);
CREATE INDEX IF NOT EXISTS idx_cover_letters_user ON public.cover_letters(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_type ON public.user_activity(user_id, activity_type);
CREATE INDEX IF NOT EXISTS idx_job_predictions_user ON public.job_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_job_predictions_resume ON public.job_predictions(resume_id);
CREATE INDEX IF NOT EXISTS idx_job_predictions_stale ON public.job_predictions(resume_id, is_stale);
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_date ON public.ai_usage (user_id, usage_date, operation);
CREATE INDEX IF NOT EXISTS idx_user_resume_limits_user_date ON public.user_resume_limits (user_id, usage_date);
CREATE INDEX IF NOT EXISTS idx_bug_reports_email ON public.bug_reports(user_email);
CREATE INDEX IF NOT EXISTS idx_bug_reports_status ON public.bug_reports(status);

-- -----------------------------------------------------------------------------
-- 5. TRIGGERS (IDEMPOTENT)
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_resumes_updated_at ON public.resumes;
CREATE TRIGGER set_resumes_updated_at
    BEFORE UPDATE ON public.resumes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_jobs_updated_at ON public.jobs;
CREATE TRIGGER set_jobs_updated_at
    BEFORE UPDATE ON public.jobs
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_job_matches_updated_at ON public.job_matches;
CREATE TRIGGER set_job_matches_updated_at
    BEFORE UPDATE ON public.job_matches
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_cover_letters_updated_at ON public.cover_letters;
CREATE TRIGGER set_cover_letters_updated_at
    BEFORE UPDATE ON public.cover_letters
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_job_predictions_updated_at ON public.job_predictions;
CREATE TRIGGER set_job_predictions_updated_at
    BEFORE UPDATE ON public.job_predictions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_bug_reports_updated_at ON public.bug_reports;
CREATE TRIGGER set_bug_reports_updated_at
    BEFORE UPDATE ON public.bug_reports
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- User auto-creation trigger on auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user_resume_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
  VALUES (NEW.id, 4, 0, CURRENT_DATE)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_resume_limit ON auth.users;
CREATE TRIGGER on_auth_user_created_resume_limit
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_resume_limit();

-- -----------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- -----------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resume_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reference_resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ats_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.keyword_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cover_letters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_resume_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bug_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_ingestion_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_sources_config ENABLE ROW LEVEL SECURITY;

-- 6.1 Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 6.2 Resumes Policies
DROP POLICY IF EXISTS "Users can manage own resumes" ON public.resumes;
CREATE POLICY "Users can manage own resumes" ON public.resumes FOR ALL USING (auth.uid() = user_id);

-- 6.3 Resume Versions Policies
DROP POLICY IF EXISTS "Users can manage own resume versions" ON public.resume_versions;
CREATE POLICY "Users can manage own resume versions" ON public.resume_versions FOR ALL USING (auth.uid() = user_id);

-- 6.4 Reference Resumes Policies
DROP POLICY IF EXISTS "Users can manage own reference resumes" ON public.reference_resumes;
CREATE POLICY "Users can manage own reference resumes" ON public.reference_resumes FOR ALL USING (auth.uid() = user_id);

-- 6.5 ATS Analysis Policies
DROP POLICY IF EXISTS "Users can manage own ATS analysis" ON public.ats_analysis;
CREATE POLICY "Users can manage own ATS analysis" ON public.ats_analysis FOR ALL USING (auth.uid() = user_id);

-- 6.6 Keyword Analysis Policies
DROP POLICY IF EXISTS "Users can manage own keyword analysis" ON public.keyword_analysis;
CREATE POLICY "Users can manage own keyword analysis" ON public.keyword_analysis FOR ALL USING (auth.uid() = user_id);

-- 6.7 Jobs Policies
DROP POLICY IF EXISTS "Authenticated users can view active jobs" ON public.jobs;
CREATE POLICY "Authenticated users can view active jobs" ON public.jobs FOR SELECT USING (auth.role() = 'authenticated' AND is_active = TRUE);

DROP POLICY IF EXISTS "Allow job ingestion write access" ON public.jobs;
CREATE POLICY "Allow job ingestion write access" ON public.jobs FOR ALL USING (true) WITH CHECK (true);

-- 6.8 Job Matches Policies
DROP POLICY IF EXISTS "Users can manage own job matches" ON public.job_matches;
CREATE POLICY "Users can manage own job matches" ON public.job_matches FOR ALL USING (auth.uid() = user_id);

-- 6.9 Cover Letters Policies
DROP POLICY IF EXISTS "Users can manage own cover letters" ON public.cover_letters;
CREATE POLICY "Users can manage own cover letters" ON public.cover_letters FOR ALL USING (auth.uid() = user_id);

-- 6.10 User Activity Policies
DROP POLICY IF EXISTS "Users can view own activity logs" ON public.user_activity;
CREATE POLICY "Users can view own activity logs" ON public.user_activity FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own activity logs" ON public.user_activity;
CREATE POLICY "Users can insert own activity logs" ON public.user_activity FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6.11 Job Predictions Policies
DROP POLICY IF EXISTS "Users can manage own job predictions" ON public.job_predictions;
CREATE POLICY "Users can manage own job predictions" ON public.job_predictions FOR ALL USING (auth.uid() = user_id OR user_id IS NULL);

-- 6.12 AI Usage Policies
DROP POLICY IF EXISTS "Users can view their own ai_usage" ON public.ai_usage;
CREATE POLICY "Users can view their own ai_usage" ON public.ai_usage FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own ai_usage" ON public.ai_usage;
CREATE POLICY "Users can insert their own ai_usage" ON public.ai_usage FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own ai_usage" ON public.ai_usage;
CREATE POLICY "Users can update their own ai_usage" ON public.ai_usage FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 7. ADMIN AUTHORIZATION & RESUME LIMIT RPCS
-- -----------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.is_admin_caller() CASCADE;
CREATE OR REPLACE FUNCTION public.is_admin_caller()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    (COALESCE(auth.jwt()->'app_metadata'->>'role', '') = 'admin')
    OR
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
        AND (
          COALESCE(raw_app_meta_data->>'role', '') = 'admin'
          OR email IN (
            'nishantagrahari666@gmail.com',
            'admin@jobwink.com'
          )
        )
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO service_role;

-- 7.1 user_resume_limits RLS Policy
DROP POLICY IF EXISTS "Users can view their own resume limit" ON public.user_resume_limits;
CREATE POLICY "Users can view their own resume limit"
  ON public.user_resume_limits FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin_caller());

-- 7.2 check_and_reserve_resume_limit (Atomic reservation, race condition safe)
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
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id
  FOR UPDATE;

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

  IF v_limit_record.usage_date != v_today THEN
    UPDATE public.user_resume_limits
    SET usage_count = 1,
        usage_date = v_today,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    v_used := 1;

    RETURN json_build_object(
      'allowed', true,
      'used', v_used,
      'limit', v_limit,
      'remaining', GREATEST(0, v_limit - v_used),
      'is_admin', (v_limit >= 999999),
      'message', 'Limit reserved successfully.'
    );
  END IF;

  v_used := COALESCE(v_limit_record.usage_count, 0);

  IF v_limit < 999999 AND v_used >= v_limit THEN
    RETURN json_build_object(
      'allowed', false,
      'used', v_used,
      'limit', v_limit,
      'remaining', 0,
      'is_admin', false,
      'message', 'Daily resume limit reached. Please try again tomorrow.'
    );
  END IF;

  UPDATE public.user_resume_limits
  SET usage_count = usage_count + 1,
      updated_at = NOW()
  WHERE user_id = v_user_id;

  v_used := v_used + 1;

  RETURN json_build_object(
    'allowed', true,
    'used', v_used,
    'limit', v_limit,
    'remaining', GREATEST(0, v_limit - v_used),
    'is_admin', (v_limit >= 999999),
    'message', 'Limit reserved successfully.'
  );
END;
$$;

-- 7.3 refund_resume_limit
DROP FUNCTION IF EXISTS public.refund_resume_limit() CASCADE;
DROP FUNCTION IF EXISTS public.refund_resume_limit(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.refund_resume_limit(p_user_id UUID DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_today DATE := CURRENT_DATE;
  v_limit_record public.user_resume_limits%ROWTYPE;
BEGIN
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'No limit record found.');
  END IF;

  IF v_limit_record.usage_date = v_today AND v_limit_record.usage_count > 0 THEN
    UPDATE public.user_resume_limits
    SET usage_count = usage_count - 1,
        updated_at = NOW()
    WHERE user_id = v_user_id;

    RETURN json_build_object('success', true, 'usage_count', v_limit_record.usage_count - 1);
  END IF;

  RETURN json_build_object('success', true, 'usage_count', v_limit_record.usage_count);
END;
$$;

-- 7.4 get_user_resume_usage
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
  v_limit INT := 4;
BEGIN
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'used', 0,
      'limit', CASE WHEN is_admin_caller() THEN 999999 ELSE 4 END,
      'remaining', CASE WHEN is_admin_caller() THEN 999999 ELSE 4 END,
      'usage_date', v_today::TEXT
    );
  END IF;

  IF v_limit_record.usage_date = v_today THEN
    v_used := v_limit_record.usage_count;
  ELSE
    v_used := 0;
  END IF;

  v_limit := CASE WHEN is_admin_caller() THEN 999999 ELSE COALESCE(v_limit_record.daily_limit, 4) END;

  RETURN json_build_object(
    'used', v_used,
    'limit', v_limit,
    'remaining', GREATEST(0, v_limit - v_used),
    'usage_date', v_today::TEXT
  );
END;
$$;

-- 7.5 get_admin_dashboard_stats
DROP FUNCTION IF EXISTS public.get_admin_dashboard_stats() CASCADE;

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_users INT;
  v_active_today INT;
  v_resumes_today INT;
  v_at_limit INT;
  v_today DATE := CURRENT_DATE;
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  SELECT COUNT(*) INTO v_total_users FROM public.profiles;

  SELECT COUNT(DISTINCT user_id) INTO v_active_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND usage_count > 0;

  SELECT COALESCE(SUM(usage_count), 0) INTO v_resumes_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today;

  SELECT COUNT(*) INTO v_at_limit
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND usage_count >= daily_limit;

  RETURN json_build_object(
    'totalUsers', v_total_users,
    'activeUsersToday', v_active_today,
    'resumesGeneratedToday', v_resumes_today,
    'usersAtLimit', v_at_limit
  );
END;
$$;

-- 7.6 get_admin_users
DROP FUNCTION IF EXISTS public.get_admin_users() CASCADE;

CREATE OR REPLACE FUNCTION public.get_admin_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  daily_limit INT,
  usage_count INT,
  resumes_generated_today INT,
  remaining INT,
  usage_date TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
    SELECT
      p.id AS user_id,
      p.email,
      COALESCE(u.daily_limit, 4)::INT AS daily_limit,
      CASE
        WHEN u.usage_date = v_today THEN COALESCE(u.usage_count, 0)::INT
        ELSE 0
      END AS usage_count,
      CASE
        WHEN u.usage_date = v_today THEN COALESCE(u.usage_count, 0)::INT
        ELSE 0
      END AS resumes_generated_today,
      GREATEST(0, COALESCE(u.daily_limit, 4) - CASE WHEN u.usage_date = v_today THEN COALESCE(u.usage_count, 0) ELSE 0 END)::INT AS remaining,
      COALESCE(u.usage_date::TEXT, v_today::TEXT) AS usage_date
    FROM public.profiles p
    LEFT JOIN public.user_resume_limits u ON u.user_id = p.id
    ORDER BY p.email;
END;
$$;

-- 7.7 update_user_resume_limit
DROP FUNCTION IF EXISTS public.update_user_resume_limit(UUID, INT) CASCADE;

CREATE OR REPLACE FUNCTION public.update_user_resume_limit(p_user_id UUID, p_new_limit INT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
  VALUES (p_user_id, p_new_limit, 0, CURRENT_DATE)
  ON CONFLICT (user_id)
  DO UPDATE SET daily_limit = EXCLUDED.daily_limit;
END;
$$;

-- 7.8 reset_user_resume_usage
DROP FUNCTION IF EXISTS public.reset_user_resume_usage(UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.reset_user_resume_usage(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.user_resume_limits
  SET usage_count = 0,
      usage_date = CURRENT_DATE,
      updated_at = NOW()
  WHERE user_id = p_user_id;
END;
$$;

-- 7.9 check_and_consume_ai_limit
DROP FUNCTION IF EXISTS public.check_and_consume_ai_limit(UUID, TEXT, INT) CASCADE;

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
  SELECT request_count INTO v_current_count
  FROM public.ai_usage
  WHERE user_id = p_user_id
    AND operation = p_operation
    AND usage_date = v_today;

  IF v_current_count IS NULL THEN
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
    RETURN jsonb_build_object(
      'allowed', false,
      'request_count', v_current_count,
      'limit', p_max_limit,
      'error_code', 'AI_DAILY_LIMIT_REACHED',
      'message', 'You have reached your daily resume processing limit. Please try again tomorrow.'
    );
  ELSE
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

-- 7.10 submit_bug_report
DROP FUNCTION IF EXISTS public.submit_bug_report(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.submit_bug_report(TEXT, TEXT, TEXT, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.submit_bug_report CASCADE;

CREATE OR REPLACE FUNCTION public.submit_bug_report(
    p_user_email TEXT,
    p_title TEXT,
    p_description TEXT,
    p_user_id UUID DEFAULT NULL,
    p_user_name TEXT DEFAULT NULL,
    p_page_url TEXT DEFAULT NULL,
    p_route TEXT DEFAULT NULL,
    p_browser TEXT DEFAULT NULL,
    p_os TEXT DEFAULT NULL,
    p_screen_size TEXT DEFAULT NULL,
    p_screenshot_reference TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_clean_email TEXT;
    v_clean_title TEXT;
    v_clean_desc TEXT;
    v_recent_count INT;
    v_new_report_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());

    v_clean_email := TRIM(LOWER(p_user_email));
    IF v_clean_email IS NULL OR v_clean_email = '' OR POSITION('@' IN v_clean_email) = 0 THEN
        RAISE EXCEPTION 'A valid email address is required.';
    END IF;

    v_clean_title := TRIM(p_title);
    IF v_clean_title IS NULL OR LENGTH(v_clean_title) < 3 THEN
        RAISE EXCEPTION 'Bug title must be at least 3 characters long.';
    END IF;
    IF LENGTH(v_clean_title) > 200 THEN
        v_clean_title := SUBSTRING(v_clean_title FROM 1 FOR 200);
    END IF;

    v_clean_desc := TRIM(p_description);
    IF v_clean_desc IS NULL OR LENGTH(v_clean_desc) < 5 THEN
        RAISE EXCEPTION 'Bug description must be at least 5 characters long.';
    END IF;

    SELECT COUNT(*) INTO v_recent_count
    FROM public.bug_reports
    WHERE user_email = v_clean_email
      AND created_at > (NOW() - INTERVAL '10 minutes');

    IF v_recent_count >= 5 THEN
        RAISE EXCEPTION 'Rate limit exceeded. Please wait a few minutes before submitting another bug report.';
    END IF;

    INSERT INTO public.bug_reports (
        user_id,
        user_email,
        title,
        description,
        page_url,
        route,
        browser,
        os,
        screen_size,
        screenshot_reference,
        status
    ) VALUES (
        v_user_id,
        v_clean_email,
        v_clean_title,
        v_clean_desc,
        p_page_url,
        p_route,
        p_browser,
        p_os,
        p_screen_size,
        p_screenshot_reference,
        'open'
    )
    RETURNING id INTO v_new_report_id;

    RETURN jsonb_build_object(
        'success', true,
        'report_id', v_new_report_id,
        'message', 'Bug report submitted successfully.'
    );
END;
$$;

-- 7.11 bug_reports RLS Policies (Supporting dynamic admin authorization)
DROP POLICY IF EXISTS "Allow anon and auth insert bug_reports" ON public.bug_reports;
CREATE POLICY "Allow anon and auth insert bug_reports"
ON public.bug_reports FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow admins to read bug_reports" ON public.bug_reports;
CREATE POLICY "Allow admins to read bug_reports"
ON public.bug_reports FOR SELECT
USING (auth.uid() IS NOT NULL AND public.is_admin_caller());

DROP POLICY IF EXISTS "Allow admins to update bug_reports" ON public.bug_reports;
CREATE POLICY "Allow admins to update bug_reports"
ON public.bug_reports FOR UPDATE
USING (auth.uid() IS NOT NULL AND public.is_admin_caller())
WITH CHECK (auth.uid() IS NOT NULL AND public.is_admin_caller());

-- Permissions
GRANT EXECUTE ON FUNCTION public.check_and_reserve_resume_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refund_resume_limit(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_resume_usage(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_resume_limit(UUID, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reset_user_resume_usage(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_and_consume_ai_limit(UUID, TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_bug_report(TEXT,TEXT,TEXT,UUID,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_bug_report(TEXT,TEXT,TEXT,UUID,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO anon;

-- -----------------------------------------------------------------------------
-- 8. STORAGE BUCKETS & STORAGE OBJECT POLICIES (NO ALTER TABLE storage.objects)
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('resumes', 'resumes', false, 10485760, ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']),
    ('optimized-resumes', 'optimized-resumes', false, 10485760, ARRAY['application/pdf']),
    ('reference-resumes', 'reference-resumes', false, 10485760, ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']),
    ('cover-letters', 'cover-letters', false, 10485760, ARRAY['application/pdf', 'text/plain']),
    ('bug-screenshots', 'bug-screenshots', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp']),
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Clean and recreate storage policies safely
DROP POLICY IF EXISTS "Users can insert own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage own optimized resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage own cover letters" ON storage.objects;
DROP POLICY IF EXISTS "Allow public uploads to bug-screenshots" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read of bug-screenshots" ON storage.objects;
DROP POLICY IF EXISTS "Public Avatar Read Access" ON storage.objects;
DROP POLICY IF EXISTS "User Avatar Upload Access" ON storage.objects;
DROP POLICY IF EXISTS "User Avatar Update Access" ON storage.objects;
DROP POLICY IF EXISTS "User Avatar Delete Access" ON storage.objects;

-- User private storage policies
CREATE POLICY "Users can manage own raw resumes"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'resumes' AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id = 'resumes' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can manage own optimized resumes"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'optimized-resumes' AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id = 'optimized-resumes' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can manage own cover letters"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'cover-letters' AND (storage.foldername(name))[1] = auth.uid()::text)
WITH CHECK (bucket_id = 'cover-letters' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Public assets storage policies
CREATE POLICY "Allow public uploads to bug-screenshots"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'bug-screenshots');

CREATE POLICY "Allow public read of bug-screenshots"
ON storage.objects FOR SELECT
USING (bucket_id = 'bug-screenshots');

CREATE POLICY "Public Avatar Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "User Avatar Upload Access"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "User Avatar Update Access"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "User Avatar Delete Access"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- -----------------------------------------------------------------------------
-- 9. SAFE BACKFILL (NON-DESTRUCTIVE, NO OVERWRITES)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
    SELECT id, 4, 0, CURRENT_DATE
    FROM auth.users
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
END $$;
