-- ============================================================================
-- SUPABASE MIGRATION: Replace hardcoded admin email with dynamic app_config table
-- Migration File: supabase/migrations/20260827000001_dynamic_admin_config.sql
-- ============================================================================

-- 1. Create app_config table for runtime configuration
CREATE TABLE IF NOT EXISTS public.app_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Lock down: only service role can write; no direct client reads
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "No direct client reads on app_config" ON public.app_config;
CREATE POLICY "No direct client reads on app_config"
  ON public.app_config FOR ALL
  TO authenticated
  USING (false);


-- 2. Helper to read admin email from config table (SECURITY DEFINER = reads as postgres)
CREATE OR REPLACE FUNCTION public.get_admin_email()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_email TEXT;
BEGIN
  SELECT value INTO v_email
  FROM public.app_config
  WHERE key = 'admin_email';
  RETURN COALESCE(v_email, '');
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_email() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_email() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_email() TO service_role;


-- 3. Update is_admin_caller() to use config table instead of hardcoded email
CREATE OR REPLACE FUNCTION public.is_admin_caller()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_admin_email TEXT;
BEGIN
  v_admin_email := public.get_admin_email();
  IF v_admin_email = '' OR v_admin_email IS NULL THEN
    RETURN false;
  END IF;
  RETURN auth.email() = v_admin_email;
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO service_role;


-- 4. Update RLS policy on user_resume_limits (remove hardcoded email literal)
DROP POLICY IF EXISTS "Users can view their own resume limit" ON public.user_resume_limits;
CREATE POLICY "Users can view their own resume limit"
  ON public.user_resume_limits FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin_caller());


-- 5. Update RLS policy on bug_reports (remove hardcoded email literal)
DROP POLICY IF EXISTS "Admins can view all bug reports" ON public.bug_reports;
CREATE POLICY "Admins can view all bug reports"
  ON public.bug_reports FOR SELECT
  TO authenticated
  USING (public.is_admin_caller());


-- ============================================================================
-- IMPORTANT: After applying this migration, set the admin email:
--
--   INSERT INTO public.app_config (key, value)
--   VALUES ('admin_email', 'your-admin@email.com')
--   ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
--
-- Run this in the Supabase SQL Editor or Table Editor.
-- Without this step, is_admin_caller() will return false for everyone.
-- ============================================================================
