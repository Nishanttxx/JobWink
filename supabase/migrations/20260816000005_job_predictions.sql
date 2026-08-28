-- Migration: 20260816000005_job_predictions.sql
-- Description: Create job_predictions table for ML job match model predictions, staleness tracking, and user feature overrides

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

-- Trigger for updating updated_at timestamp
DROP TRIGGER IF EXISTS set_job_predictions_updated_at ON public.job_predictions;
CREATE TRIGGER set_job_predictions_updated_at
    BEFORE UPDATE ON public.job_predictions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_job_predictions_user ON public.job_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_job_predictions_resume ON public.job_predictions(resume_id);
CREATE INDEX IF NOT EXISTS idx_job_predictions_stale ON public.job_predictions(resume_id, is_stale);

-- Row Level Security (RLS)
ALTER TABLE public.job_predictions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own job predictions" ON public.job_predictions;
CREATE POLICY "Users can manage own job predictions" ON public.job_predictions
    FOR ALL USING (auth.uid() = user_id OR user_id IS NULL);

