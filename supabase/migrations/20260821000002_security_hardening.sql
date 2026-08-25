-- Migration: 20260821000002_security_hardening.sql
-- Description: Server-side admin authorization for all admin RPCs.
--              Rate-limit RPC updated to derive user from auth.uid() instead of trusting client-supplied p_user_id.
--
-- NOTE: DROP ... CASCADE is used before each CREATE so PostgreSQL can recreate
--       functions whose return type has changed. CASCADE drops any dependent
--       objects (e.g. views) that reference the old function signature.

-- ============================================================
-- 1. Admin Authorization Helper
--    Returns true only if the calling Supabase user is the admin.
-- ============================================================
DROP FUNCTION IF EXISTS is_admin_caller() CASCADE;

CREATE FUNCTION is_admin_caller()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN auth.email() = 'na6236786@gmail.com';
END;
$$;


-- ============================================================
-- 2. Harden get_admin_dashboard_stats
--    Raises exception if caller is not the admin.
-- ============================================================
DROP FUNCTION IF EXISTS get_admin_dashboard_stats() CASCADE;

CREATE FUNCTION get_admin_dashboard_stats()
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
  WHERE usage_date = v_today AND resumes_generated_today > 0;

  SELECT COALESCE(SUM(resumes_generated_today), 0) INTO v_resumes_today
  FROM public.user_resume_limits
  WHERE usage_date = v_today;

  SELECT COUNT(*) INTO v_at_limit
  FROM public.user_resume_limits
  WHERE usage_date = v_today AND resumes_generated_today >= daily_limit;

  RETURN json_build_object(
    'totalUsers', v_total_users,
    'activeUsersToday', v_active_today,
    'resumesGeneratedToday', v_resumes_today,
    'usersAtLimit', v_at_limit
  );
END;
$$;


-- ============================================================
-- 3. Harden get_admin_users
--    Raises exception if caller is not the admin.
-- ============================================================
DROP FUNCTION IF EXISTS get_admin_users() CASCADE;

CREATE FUNCTION get_admin_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  daily_limit INT,
  resumes_generated_today INT,
  remaining INT,
  usage_date TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
    SELECT
      p.id AS user_id,
      p.email,
      COALESCE(u.daily_limit, 4)::INT AS daily_limit,
      COALESCE(u.resumes_generated_today, 0)::INT AS resumes_generated_today,
      GREATEST(0, COALESCE(u.daily_limit, 4) - COALESCE(u.resumes_generated_today, 0))::INT AS remaining,
      COALESCE(u.usage_date::TEXT, '') AS usage_date
    FROM public.profiles p
    LEFT JOIN public.user_resume_limits u ON u.user_id = p.id
    ORDER BY p.email;
END;
$$;


-- ============================================================
-- 4. Harden update_user_resume_limit
--    Raises exception if caller is not the admin.
-- ============================================================
DROP FUNCTION IF EXISTS update_user_resume_limit(UUID, INT) CASCADE;

CREATE FUNCTION update_user_resume_limit(p_user_id UUID, p_new_limit INT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
  VALUES (p_user_id, p_new_limit, 0, CURRENT_DATE)
  ON CONFLICT (user_id)
  DO UPDATE SET daily_limit = EXCLUDED.daily_limit;
END;
$$;


-- ============================================================
-- 5. Harden reset_user_resume_usage
--    Raises exception if caller is not the admin.
-- ============================================================
DROP FUNCTION IF EXISTS reset_user_resume_usage(UUID) CASCADE;

CREATE FUNCTION reset_user_resume_usage(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin_caller() THEN
    RAISE EXCEPTION 'Access denied: admin privileges required.' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.user_resume_limits
  SET resumes_generated_today = 0
  WHERE user_id = p_user_id;
END;
$$;


-- ============================================================
-- 6. Harden check_and_reserve_resume_limit
--    Derives user from auth.uid() — ignores client-supplied p_user_id entirely.
--    Drop both the no-arg and UUID-arg variants in case either exists.
-- ============================================================
DROP FUNCTION IF EXISTS check_and_reserve_resume_limit() CASCADE;
DROP FUNCTION IF EXISTS check_and_reserve_resume_limit(UUID) CASCADE;

CREATE FUNCTION check_and_reserve_resume_limit(p_user_id UUID DEFAULT NULL)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_today DATE := CURRENT_DATE;
  v_limit INT;
  v_used INT;
BEGIN
  -- Always derive user from JWT — never trust the client-supplied p_user_id
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required.' USING ERRCODE = 'P0001';
  END IF;

  -- Admin account (na6236786@gmail.com) has unlimited creations
  IF is_admin_caller() THEN
    RETURN json_build_object('allowed', true, 'used', 0, 'limit', 999999, 'remaining', 999999, 'is_admin', true);
  END IF;

  -- Upsert the row for today, resetting count if the date changed
  INSERT INTO public.user_resume_limits (user_id, daily_limit, resumes_generated_today, usage_date)
  VALUES (v_user_id, 4, 0, v_today)
  ON CONFLICT (user_id)
  DO UPDATE SET
    resumes_generated_today = CASE
      WHEN user_resume_limits.usage_date < v_today THEN 0
      ELSE user_resume_limits.resumes_generated_today
    END,
    usage_date = v_today;

  -- Read current state
  SELECT daily_limit, resumes_generated_today
  INTO v_limit, v_used
  FROM public.user_resume_limits
  WHERE user_id = v_user_id;

  IF v_used >= v_limit THEN
    RETURN json_build_object('allowed', false, 'used', v_used, 'limit', v_limit, 'remaining', 0);
  END IF;

  -- Atomically increment
  UPDATE public.user_resume_limits
  SET resumes_generated_today = resumes_generated_today + 1
  WHERE user_id = v_user_id;

  v_used := v_used + 1;

  RETURN json_build_object(
    'allowed', true,
    'used', v_used,
    'limit', v_limit,
    'remaining', v_limit - v_used
  );
END;
$$;


-- ============================================================
-- 7. Grant execute only to authenticated role
-- ============================================================
REVOKE ALL ON FUNCTION is_admin_caller() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_admin_caller() TO authenticated;

REVOKE ALL ON FUNCTION get_admin_dashboard_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_admin_dashboard_stats() TO authenticated;

REVOKE ALL ON FUNCTION get_admin_users() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_admin_users() TO authenticated;

REVOKE ALL ON FUNCTION update_user_resume_limit(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION update_user_resume_limit(UUID, INT) TO authenticated;

REVOKE ALL ON FUNCTION reset_user_resume_usage(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reset_user_resume_usage(UUID) TO authenticated;

REVOKE ALL ON FUNCTION check_and_reserve_resume_limit(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION check_and_reserve_resume_limit(UUID) TO authenticated;
