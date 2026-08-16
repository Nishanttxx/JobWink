-- Migration: 20260821000001_profiles_rls_fix.sql
-- Description: Fix RLS policies on public.profiles to allow authenticated users to INSERT, UPDATE, and SELECT their own profile.

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive or conflicting policies if present
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;

-- 1. SELECT Policy: Authenticated users can view their own profile row
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- 2. INSERT Policy: Authenticated users can insert their own profile row (required for Supabase upsert)
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 3. UPDATE Policy: Authenticated users can update their own profile row
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Grants
GRANT ALL ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;
GRANT ALL ON public.profiles TO service_role;

