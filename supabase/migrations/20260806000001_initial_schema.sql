-- Migration: 20260806000001_initial_schema.sql
-- Description: Create JobWink database architecture (10 tables), RLS policies, triggers, and performance indexes

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- -----------------------------------------------------------------------------
-- Helper Functions & Triggers
-- -----------------------------------------------------------------------------

-- Trigger function to automatically update `updated_at` timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 1. PROFILES TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    location TEXT,
    linkedin_url TEXT,
    github_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to create profile record on auth user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 2. RESUMES TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Master Resume',
    template_type TEXT NOT NULL DEFAULT 'NATIONAL_ATS' CHECK (template_type IN ('NATIONAL_ATS', 'INTERNATIONAL_GLOBAL')),
    raw_file_path TEXT,
    current_version_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS set_resumes_updated_at ON public.resumes;
CREATE TRIGGER set_resumes_updated_at
    BEFORE UPDATE ON public.resumes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3. RESUME VERSIONS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.resume_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resume_id UUID NOT NULL REFERENCES public.resumes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    version_number INT NOT NULL DEFAULT 1,
    parsed_content JSONB NOT NULL DEFAULT '{}'::jsonb,
    optimized_content JSONB DEFAULT '{}'::jsonb,
    change_summary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_resume_version UNIQUE (resume_id, version_number)
);

-- Add deferrable foreign key constraint for resumes.current_version_id
ALTER TABLE public.resumes
    DROP CONSTRAINT IF EXISTS fk_resumes_current_version;

ALTER TABLE public.resumes
    ADD CONSTRAINT fk_resumes_current_version
    FOREIGN KEY (current_version_id) REFERENCES public.resume_versions(id)
    ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

DROP TRIGGER IF EXISTS set_resume_versions_updated_at ON public.resume_versions;
CREATE TRIGGER set_resume_versions_updated_at
    BEFORE UPDATE ON public.resume_versions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 4. REFERENCE RESUMES TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reference_resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    target_role TEXT,
    parsed_content JSONB DEFAULT '{}'::jsonb,
    file_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS set_reference_resumes_updated_at ON public.reference_resumes;
CREATE TRIGGER set_reference_resumes_updated_at
    BEFORE UPDATE ON public.reference_resumes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 5. ATS ANALYSIS TABLE
-- -----------------------------------------------------------------------------
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

DROP TRIGGER IF EXISTS set_ats_analysis_updated_at ON public.ats_analysis;
CREATE TRIGGER set_ats_analysis_updated_at
    BEFORE UPDATE ON public.ats_analysis
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 6. KEYWORD ANALYSIS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.keyword_analysis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_version_id UUID REFERENCES public.resume_versions(id) ON DELETE CASCADE,
    job_id UUID,
    extracted_skills TEXT[] DEFAULT '{}',
    matching_keywords TEXT[] DEFAULT '{}',
    missing_keywords TEXT[] DEFAULT '{}',
    keyword_density JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS set_keyword_analysis_updated_at ON public.keyword_analysis;
CREATE TRIGGER set_keyword_analysis_updated_at
    BEFORE UPDATE ON public.keyword_analysis
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 7. JOBS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_job_id TEXT UNIQUE,
    job_title TEXT NOT NULL,
    company_name TEXT NOT NULL,
    company_logo_url TEXT,
    location TEXT DEFAULT 'Remote',
    salary_range TEXT DEFAULT 'Competitive',
    platform_source TEXT NOT NULL,
    job_url TEXT,
    description TEXT NOT NULL,
    required_skills TEXT[] DEFAULT '{}',
    embedding VECTOR(768),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS set_jobs_updated_at ON public.jobs;
CREATE TRIGGER set_jobs_updated_at
    BEFORE UPDATE ON public.jobs
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Add FK constraints for ats_analysis and keyword_analysis after jobs creation
ALTER TABLE public.ats_analysis
    DROP CONSTRAINT IF EXISTS fk_ats_analysis_job;
ALTER TABLE public.ats_analysis
    ADD CONSTRAINT fk_ats_analysis_job
    FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE SET NULL;

ALTER TABLE public.keyword_analysis
    DROP CONSTRAINT IF EXISTS fk_keyword_analysis_job;
ALTER TABLE public.keyword_analysis
    ADD CONSTRAINT fk_keyword_analysis_job
    FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 8. JOB MATCHES TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.job_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_version_id UUID REFERENCES public.resume_versions(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    match_percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (match_percentage BETWEEN 0.00 AND 100.00),
    status TEXT NOT NULL DEFAULT 'DISCOVERED' CHECK (status IN ('DISCOVERED', 'SAVED', 'PASSED', 'APPLIED', 'INTERVIEWING', 'OFFER', 'REJECTED')),
    matching_skills TEXT[] DEFAULT '{}',
    missing_skills TEXT[] DEFAULT '{}',
    notes TEXT,
    scanned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_job_match UNIQUE (user_id, job_id)
);

DROP TRIGGER IF EXISTS set_job_matches_updated_at ON public.job_matches;
CREATE TRIGGER set_job_matches_updated_at
    BEFORE UPDATE ON public.job_matches
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 9. COVER LETTERS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cover_letters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    resume_version_id UUID REFERENCES public.resume_versions(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tone TEXT NOT NULL DEFAULT 'Professional',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS set_cover_letters_updated_at ON public.cover_letters;
CREATE TRIGGER set_cover_letters_updated_at
    BEFORE UPDATE ON public.cover_letters
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- -----------------------------------------------------------------------------
-- 10. USER ACTIVITY TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- PERFORMANCE INDEXES
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_resumes_user ON public.resumes(user_id);
CREATE INDEX IF NOT EXISTS idx_resume_versions_resume ON public.resume_versions(resume_id);
CREATE INDEX IF NOT EXISTS idx_resume_versions_user ON public.resume_versions(user_id);
CREATE INDEX IF NOT EXISTS idx_reference_resumes_user ON public.reference_resumes(user_id);

CREATE INDEX IF NOT EXISTS idx_ats_analysis_user ON public.ats_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_ats_analysis_version ON public.ats_analysis(resume_version_id);
CREATE INDEX IF NOT EXISTS idx_keyword_analysis_user ON public.keyword_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_keyword_analysis_version ON public.keyword_analysis(resume_version_id);

CREATE INDEX IF NOT EXISTS idx_jobs_external_id ON public.jobs(external_job_id);
CREATE INDEX IF NOT EXISTS idx_jobs_is_active ON public.jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_jobs_trgm_title ON public.jobs USING gin (job_title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_jobs_embedding ON public.jobs USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_job_matches_user_status ON public.job_matches(user_id, status);
CREATE INDEX IF NOT EXISTS idx_job_matches_job ON public.job_matches(job_id);
CREATE INDEX IF NOT EXISTS idx_cover_letters_user ON public.cover_letters(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_type ON public.user_activity(user_id, activity_type);

-- -----------------------------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) & POLICIES
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

-- 1. Profiles Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Resumes Policies
CREATE POLICY "Users can manage own resumes" ON public.resumes FOR ALL USING (auth.uid() = user_id);

-- 3. Resume Versions Policies
CREATE POLICY "Users can manage own resume versions" ON public.resume_versions FOR ALL USING (auth.uid() = user_id);

-- 4. Reference Resumes Policies
CREATE POLICY "Users can manage own reference resumes" ON public.reference_resumes FOR ALL USING (auth.uid() = user_id);

-- 5. ATS Analysis Policies
CREATE POLICY "Users can manage own ATS analysis" ON public.ats_analysis FOR ALL USING (auth.uid() = user_id);

-- 6. Keyword Analysis Policies
CREATE POLICY "Users can manage own keyword analysis" ON public.keyword_analysis FOR ALL USING (auth.uid() = user_id);

-- 7. Jobs Policies
CREATE POLICY "Authenticated users can view active jobs" ON public.jobs FOR SELECT USING (auth.role() = 'authenticated' AND is_active = TRUE);

-- 8. Job Matches Policies
CREATE POLICY "Users can manage own job matches" ON public.job_matches FOR ALL USING (auth.uid() = user_id);

-- 9. Cover Letters Policies
CREATE POLICY "Users can manage own cover letters" ON public.cover_letters FOR ALL USING (auth.uid() = user_id);

-- 10. User Activity Policies
CREATE POLICY "Users can view own activity logs" ON public.user_activity FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activity logs" ON public.user_activity FOR INSERT WITH CHECK (auth.uid() = user_id);
