-- ============================================================================
-- SUPABASE MIGRATION: Fix bug_reports RLS — remove hardcoded admin email
-- Migration File: supabase/migrations/20260827000002_fix_bug_reports_rls.sql
-- ============================================================================

-- Replace the old admin-email-based SELECT policy with a role-based check only.
-- Admin access is determined by the app_metadata 'role' = 'admin' field,
-- which is set by the service role and never exposed to the frontend.

DROP POLICY IF EXISTS "Allow admins to read bug_reports" ON public.bug_reports;
DROP POLICY IF EXISTS "Admins can view all bug reports" ON public.bug_reports;

CREATE POLICY "Allow admins to read bug_reports"
ON public.bug_reports
FOR SELECT
USING (
    auth.uid() IS NOT NULL AND
    (SELECT (raw_app_meta_data->>'role') FROM auth.users WHERE id = auth.uid()) = 'admin'
);

-- Note: To grant admin access to a user, run via Service Role:
--   UPDATE auth.users
--   SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
--   WHERE email = 'your-admin@email.com';
