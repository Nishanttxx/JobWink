-- Migration: 20260806000002_storage_buckets.sql
-- Description: Create private Supabase Storage buckets and RLS storage policies for user files and backend-only reference resumes

-- -----------------------------------------------------------------------------
-- 1. CREATE PRIVATE STORAGE BUCKETS
-- -----------------------------------------------------------------------------

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    (
        'resumes', 
        'resumes', 
        false, 
        10485760, -- 10 MB limit
        ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
    ),
    (
        'optimized-resumes', 
        'optimized-resumes', 
        false, 
        10485760, -- 10 MB limit
        ARRAY['application/pdf']
    ),
    (
        'reference-resumes', 
        'reference-resumes', 
        false, 
        10485760, -- 10 MB limit
        ARRAY['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword']
    ),
    (
        'cover-letters', 
        'cover-letters', 
        false, 
        10485760, -- 10 MB limit
        ARRAY['application/pdf', 'text/plain']
    )
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- -----------------------------------------------------------------------------
-- 2. ENABLE ROW LEVEL SECURITY ON STORAGE.OBJECTS
-- -----------------------------------------------------------------------------
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Clean up any prior existing storage policies for these buckets
DROP POLICY IF EXISTS "Users can insert own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own raw resumes" ON storage.objects;

DROP POLICY IF EXISTS "Users can manage own raw resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage own optimized resumes" ON storage.objects;
DROP POLICY IF EXISTS "Users can manage own cover letters" ON storage.objects;

-- -----------------------------------------------------------------------------
-- 3. STORAGE RLS POLICIES
-- -----------------------------------------------------------------------------

-- Policy A: Resumes Bucket (Authenticated users can only read/write files under their user_id folder)
CREATE POLICY "Users can manage own raw resumes"
ON storage.objects FOR ALL
TO authenticated
USING (
    bucket_id = 'resumes' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'resumes' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy B: Optimized Resumes Bucket (Authenticated users can read/write files under their user_id folder)
CREATE POLICY "Users can manage own optimized resumes"
ON storage.objects FOR ALL
TO authenticated
USING (
    bucket_id = 'optimized-resumes' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'optimized-resumes' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy C: Cover Letters Bucket (Authenticated users can read/write files under their user_id folder)
CREATE POLICY "Users can manage own cover letters"
ON storage.objects FOR ALL
TO authenticated
USING (
    bucket_id = 'cover-letters' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'cover-letters' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy D: Backend-Only Reference Resumes Bucket
-- NOTE: No RLS policy is created for 'reference-resumes' for authenticated users.
-- By default in Supabase PostgreSQL RLS, lack of an explicit policy denies access to all standard authenticated requests.
-- Access to 'reference-resumes' is strictly restricted to backend Edge Functions using the service_role key.
