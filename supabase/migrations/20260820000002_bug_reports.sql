-- Migration: 20260820000002_bug_reports.sql
-- Description: Create bug_reports table, bug-screenshots storage bucket, RLS policies, and submit_bug_report RPC function

-- 1. Create bug_reports table
CREATE TABLE IF NOT EXISTS public.bug_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_email TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    page_url TEXT,
    route TEXT,
    browser TEXT,
    os TEXT,
    screen_size TEXT,
    screenshot_reference TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for querying by user or created_at
CREATE INDEX IF NOT EXISTS idx_bug_reports_user_id ON public.bug_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_bug_reports_created_at ON public.bug_reports(created_at DESC);

-- Enable RLS
ALTER TABLE public.bug_reports ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if re-run
DROP POLICY IF EXISTS "Allow anon and auth insert bug_reports" ON public.bug_reports;
DROP POLICY IF EXISTS "Allow admins to read bug_reports" ON public.bug_reports;

-- Policy: Anyone (auth or anon) can insert bug reports
CREATE POLICY "Allow anon and auth insert bug_reports"
ON public.bug_reports
FOR INSERT
WITH CHECK (true);

-- Policy: Only admin email or role can read bug reports
CREATE POLICY "Allow admins to read bug_reports"
ON public.bug_reports
FOR SELECT
USING (
    auth.uid() IS NOT NULL AND (
        (SELECT email FROM auth.users WHERE id = auth.uid()) = 'na6236786@gmail.com'
        OR (SELECT (raw_app_meta_data->>'role') FROM auth.users WHERE id = auth.uid()) = 'admin'
    )
);

-- 2. Create Storage Bucket for bug screenshots if storage schema exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'bug-screenshots',
    'bug-screenshots',
    true,
    5242880, -- 5 MB
    ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp'];

-- Storage RLS Policy for bug-screenshots bucket
DROP POLICY IF EXISTS "Allow public uploads to bug-screenshots" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read of bug-screenshots" ON storage.objects;

CREATE POLICY "Allow public uploads to bug-screenshots"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'bug-screenshots');

CREATE POLICY "Allow public read of bug-screenshots"
ON storage.objects
FOR SELECT
USING (bucket_id = 'bug-screenshots');

-- 3. Create Secure RPC function submit_bug_report with rate-limiting and validation
CREATE OR REPLACE FUNCTION public.submit_bug_report(
    p_user_email TEXT,
    p_title TEXT,
    p_description TEXT,
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
    v_user_id UUID := auth.uid();
    v_clean_email TEXT;
    v_clean_title TEXT;
    v_clean_desc TEXT;
    v_recent_count INT;
    v_new_report_id UUID;
BEGIN
    -- Sanitize & Validate Email
    v_clean_email := TRIM(LOWER(p_user_email));
    IF v_clean_email IS NULL OR v_clean_email = '' OR POSITION('@' IN v_clean_email) = 0 THEN
        RAISE EXCEPTION 'A valid email address is required.';
    END IF;

    -- Sanitize & Validate Title
    v_clean_title := TRIM(p_title);
    IF v_clean_title IS NULL OR LENGTH(v_clean_title) < 3 THEN
        RAISE EXCEPTION 'Bug title must be at least 3 characters long.';
    END IF;
    IF LENGTH(v_clean_title) > 200 THEN
        v_clean_title := SUBSTRING(v_clean_title FROM 1 FOR 200);
    END IF;

    -- Sanitize & Validate Description
    v_clean_desc := TRIM(p_description);
    IF v_clean_desc IS NULL OR LENGTH(v_clean_desc) < 5 THEN
        RAISE EXCEPTION 'Bug description must be at least 5 characters long.';
    END IF;

    -- Basic Rate Limiting: Max 5 bug reports per email per 10 minutes
    SELECT COUNT(*) INTO v_recent_count
    FROM public.bug_reports
    WHERE user_email = v_clean_email
      AND created_at > (NOW() - INTERVAL '10 minutes');

    IF v_recent_count >= 5 THEN
        RAISE EXCEPTION 'Rate limit exceeded. Please wait a few minutes before submitting another bug report.';
    END IF;

    -- Insert into bug_reports table
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
