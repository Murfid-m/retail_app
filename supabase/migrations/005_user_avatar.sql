-- Add avatar_url column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Create storage bucket for user avatars (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-avatars', 'user-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for user-avatars bucket
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = 'avatars'
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = 'avatars'
);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = 'avatars'
);

CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-avatars');
