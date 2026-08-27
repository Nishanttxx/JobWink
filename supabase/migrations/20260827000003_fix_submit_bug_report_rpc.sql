-- ============================================================================
-- SUPABASE MIGRATION: Fix submit_bug_report() — accept p_user_id parameter
-- Migration File: supabase/migrations/20260827000003_fix_submit_bug_report_rpc.sql
-- ============================================================================
-- The Flutter client (fallback path) and Python backend both pass p_user_id
-- to the submit_bug_report RPC. The original function did not accept it,
-- causing the call to fail. This migration adds p_user_id as an optional param.
-- ============================================================================

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
    -- Use explicitly passed user_id, otherwise fall back to authenticated JWT uid
    v_user_id := COALESCE(p_user_id, auth.uid());

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
    -- bug_reports.user_email stores the REPORTER's email (not the admin email)
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

-- Grant to authenticated and anon (anon can submit bug reports too)
REVOKE ALL ON FUNCTION public.submit_bug_report(TEXT,TEXT,TEXT,UUID,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_bug_report(TEXT,TEXT,TEXT,UUID,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_bug_report(TEXT,TEXT,TEXT,UUID,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT,TEXT) TO anon;

