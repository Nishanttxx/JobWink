-- ==============================================================================
-- Migration: 20260830000001_fix_resume_limits_rpc_aliases.sql
-- Description: Fixes resume limit RPC return values by including comprehensive
-- canonical aliases ('allowed', 'daily_limit', 'limit', 'usage_count', 'used',
-- 'resumes_generated_today', 'remaining', 'usage_date', 'is_admin').
-- Guarantees that brand-new users with no existing limit record receive allowed = true,
-- usage_count = 0, remaining = 4, daily_limit = 4.
-- ==============================================================================

-- 1. check_and_reserve_resume_limit
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
  v_is_admin BOOLEAN := false;
BEGIN
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  v_is_admin := is_admin_caller() AND (p_user_id IS NULL OR p_user_id = auth.uid());

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.user_resume_limits (user_id, daily_limit, usage_count, usage_date)
    VALUES (v_user_id, CASE WHEN v_is_admin THEN 999999 ELSE 4 END, 0, v_today)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT * INTO v_limit_record
    FROM public.user_resume_limits
    WHERE user_id = v_user_id
    FOR UPDATE;
  END IF;

  IF v_is_admin THEN
    v_limit := 999999;
  ELSE
    v_limit := COALESCE(v_limit_record.daily_limit, 4);
  END IF;

  -- Daily reset if record is from a previous day
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
      'usage_count', v_used,
      'resumes_generated_today', v_used,
      'limit', v_limit,
      'daily_limit', v_limit,
      'remaining', GREATEST(0, v_limit - v_used),
      'usage_date', v_today::TEXT,
      'is_admin', (v_limit >= 999999),
      'message', 'Limit reserved successfully.'
    );
  END IF;

  v_used := COALESCE(v_limit_record.usage_count, 0);

  IF v_limit < 999999 AND v_used >= v_limit THEN
    RETURN json_build_object(
      'allowed', false,
      'used', v_used,
      'usage_count', v_used,
      'resumes_generated_today', v_used,
      'limit', v_limit,
      'daily_limit', v_limit,
      'remaining', 0,
      'usage_date', v_today::TEXT,
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
    'usage_count', v_used,
    'resumes_generated_today', v_used,
    'limit', v_limit,
    'daily_limit', v_limit,
    'remaining', GREATEST(0, v_limit - v_used),
    'usage_date', v_today::TEXT,
    'is_admin', (v_limit >= 999999),
    'message', 'Limit reserved successfully.'
  );
END;
$$;

-- 2. refund_resume_limit
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

    RETURN json_build_object(
      'success', true,
      'used', v_limit_record.usage_count - 1,
      'usage_count', v_limit_record.usage_count - 1,
      'resumes_generated_today', v_limit_record.usage_count - 1
    );
  END IF;

  RETURN json_build_object(
    'success', true,
    'used', v_limit_record.usage_count,
    'usage_count', v_limit_record.usage_count,
    'resumes_generated_today', v_limit_record.usage_count
  );
END;
$$;

-- 3. get_user_resume_usage
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
  v_is_admin BOOLEAN := false;
BEGIN
  IF p_user_id IS NOT NULL AND is_admin_caller() THEN
    v_user_id := p_user_id;
  ELSE
    v_user_id := auth.uid();
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  v_is_admin := is_admin_caller() AND (p_user_id IS NULL OR p_user_id = auth.uid());

  SELECT * INTO v_limit_record
  FROM public.user_resume_limits
  WHERE user_id = v_user_id;

  IF NOT FOUND THEN
    v_limit := CASE WHEN v_is_admin THEN 999999 ELSE 4 END;
    RETURN json_build_object(
      'allowed', true,
      'used', 0,
      'usage_count', 0,
      'resumes_generated_today', 0,
      'limit', v_limit,
      'daily_limit', v_limit,
      'remaining', v_limit,
      'usage_date', v_today::TEXT,
      'is_admin', v_is_admin
    );
  END IF;

  IF v_limit_record.usage_date = v_today THEN
    v_used := COALESCE(v_limit_record.usage_count, 0);
  ELSE
    v_used := 0;
  END IF;

  v_limit := CASE WHEN v_is_admin THEN 999999 ELSE COALESCE(v_limit_record.daily_limit, 4) END;

  RETURN json_build_object(
    'allowed', (v_is_admin OR v_used < v_limit),
    'used', v_used,
    'usage_count', v_used,
    'resumes_generated_today', v_used,
    'limit', v_limit,
    'daily_limit', v_limit,
    'remaining', GREATEST(0, v_limit - v_used),
    'usage_date', v_today::TEXT,
    'is_admin', v_is_admin
  );
END;
$$;

-- 4. Permissions
REVOKE ALL ON FUNCTION public.check_and_reserve_resume_limit(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_and_reserve_resume_limit(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.refund_resume_limit(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refund_resume_limit(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_user_resume_usage(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_resume_usage(UUID) TO authenticated;
