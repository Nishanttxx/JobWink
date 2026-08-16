-- Migration: 20260808000003_job_ingestion_system.sql
-- Description: Add normalized job fields, ingestion logging, RLS policies, and 48-hour filtering view.

-- 1. Extend public.jobs table with normalized columns
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS source_job_id TEXT,
  ADD COLUMN IF NOT EXISTS country TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS state TEXT,
  ADD COLUMN IF NOT EXISTS remote BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS workplace_type TEXT DEFAULT 'On-site',
  ADD COLUMN IF NOT EXISTS employment_type TEXT DEFAULT 'Full-time',
  ADD COLUMN IF NOT EXISTS experience_level TEXT,
  ADD COLUMN IF NOT EXISTS salary_min NUMERIC,
  ADD COLUMN IF NOT EXISTS salary_max NUMERIC,
  ADD COLUMN IF NOT EXISTS salary_currency TEXT DEFAULT 'USD',
  ADD COLUMN IF NOT EXISTS responsibilities TEXT,
  ADD COLUMN IF NOT EXISTS requirements TEXT,
  ADD COLUMN IF NOT EXISTS source_posted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS source_updated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS first_seen_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS apply_url TEXT,
  ADD COLUMN IF NOT EXISTS company_url TEXT,
  ADD COLUMN IF NOT EXISTS is_within_48_hours BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS normalized_hash TEXT;

-- Add unique constraint for normalized_hash if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'jobs_normalized_hash_key'
    ) THEN
        ALTER TABLE public.jobs ADD CONSTRAINT jobs_normalized_hash_key UNIQUE (normalized_hash);
    END IF;
END $$;

-- RLS Policy for public.jobs writes
DROP POLICY IF EXISTS "Allow job ingestion write access" ON public.jobs;
CREATE POLICY "Allow job ingestion write access"
    ON public.jobs FOR ALL
    USING (true)
    WITH CHECK (true);

-- 2. Indexes for performance and quick querying
CREATE INDEX IF NOT EXISTS idx_jobs_source_updated_at ON public.jobs(source_updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_source_posted_at ON public.jobs(source_posted_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_is_within_48h ON public.jobs(is_within_48_hours) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_jobs_platform_source ON public.jobs(platform_source);
CREATE INDEX IF NOT EXISTS idx_jobs_normalized_hash ON public.jobs(normalized_hash);

-- 3. Job Ingestion Logs Table
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

-- Enable RLS on job_ingestion_logs
ALTER TABLE public.job_ingestion_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read of ingestion logs" ON public.job_ingestion_logs;
CREATE POLICY "Allow public read of ingestion logs"
    ON public.job_ingestion_logs FOR ALL
    USING (true)
    WITH CHECK (true);

-- 4. Job Sources Configuration Table (for Crawl4AI dynamic websites)
CREATE TABLE IF NOT EXISTS public.job_sources_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    url TEXT NOT NULL UNIQUE,
    allowed BOOLEAN DEFAULT TRUE,
    selectors JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on job_sources_config
ALTER TABLE public.job_sources_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read of job sources config" ON public.job_sources_config;
CREATE POLICY "Allow public read of job sources config"
    ON public.job_sources_config FOR ALL
    USING (true)
    WITH CHECK (true);

-- 5. View for 48-Hour Filtered Active Jobs
CREATE OR REPLACE VIEW public.latest_48h_jobs AS
SELECT 
    j.*,
    COALESCE(j.source_updated_at, j.source_posted_at, j.posted_at) AS effective_timestamp,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(j.source_updated_at, j.source_posted_at, j.posted_at))) / 3600 AS hours_ago
FROM public.jobs j
WHERE j.is_active = TRUE
  AND COALESCE(j.source_updated_at, j.source_posted_at, j.posted_at) >= (NOW() - INTERVAL '48 hours')
ORDER BY COALESCE(j.source_updated_at, j.source_posted_at, j.posted_at) DESC;
