-- Fix RLS policy untuk mengizinkan user membuat profile mereka sendiri

-- Drop existing policies on users table
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Allow all for users" ON users;
DROP POLICY IF EXISTS "Enable read for all users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON users;

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: User dapat melihat semua user (untuk tampilan)
CREATE POLICY "Anyone can view users"
ON users FOR SELECT
USING (true);

-- Policy: User baru dapat insert profile mereka sendiri
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy: User dapat update profile mereka sendiri
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy: Admin dapat delete users
CREATE POLICY "Admins can delete users"
ON users FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true
  )
);
