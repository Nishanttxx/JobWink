-- Migration: 20260820000003_avatars_storage.sql
-- Description: Create avatars storage bucket and Row Level Security policies for profile photos

-- 1. Insert avatars bucket into storage.buckets if it does not exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

-- 2. Storage RLS Policies for avatars bucket

-- Allow public read access to avatars
DROP POLICY IF EXISTS "Public Avatar Read Access" ON storage.objects;
CREATE POLICY "Public Avatar Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload their own avatar into avatars/{auth.uid()}/*
DROP POLICY IF EXISTS "User Avatar Upload Access" ON storage.objects;
CREATE POLICY "User Avatar Upload Access"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to update their own avatar into avatars/{auth.uid()}/*
DROP POLICY IF EXISTS "User Avatar Update Access" ON storage.objects;
CREATE POLICY "User Avatar Update Access"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own avatar from avatars/{auth.uid()}/*
DROP POLICY IF EXISTS "User Avatar Delete Access" ON storage.objects;
CREATE POLICY "User Avatar Delete Access"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
);
