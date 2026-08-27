-- ============================================================================
-- SUPABASE MIGRATION: Fix is_admin_caller() — use role-based check, no app_config
-- Migration File: supabase/migrations/20260827000001_dynamic_admin_config.sql
-- ============================================================================
-- Replaces the hardcoded email literal in is_admin_caller() with a
-- raw_app_meta_data role check. Admin access is controlled by setting:
--
--   UPDATE auth.users
--   SET raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb
--   WHERE email = 'your-admin@email.com';
--
-- Run that once via Supabase SQL Editor (requires service role).
-- No hardcoded email is stored in migration files or DB schema.
-- ============================================================================

-- Update is_admin_caller() to use metadata role instead of email literal
CREATE OR REPLACE FUNCTION public.is_admin_caller()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check JWT app_metadata for role = 'admin'
  -- This is set server-side via service role and never exposed to the client.
  RETURN (
    auth.uid() IS NOT NULL AND
    (
      SELECT (raw_app_meta_data->>'role') = 'admin'
      FROM auth.users
      WHERE id = auth.uid()
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin_caller() TO service_role;

-- Fix RLS policy on user_resume_limits to use updated is_admin_caller()
DROP POLICY IF EXISTS "Users can view their own resume limit" ON public.user_resume_limits;
CREATE POLICY "Users can view their own resume limit"
  ON public.user_resume_limits FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR public.is_admin_caller());

