-- =============================================
-- FIX RLS POLICIES - JALANKAN INI DI SQL EDITOR
-- =============================================

-- 1. DROP semua policy yang bermasalah
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Anyone can view products" ON public.products;
DROP POLICY IF EXISTS "Admins can insert products" ON public.products;
DROP POLICY IF EXISTS "Admins can update products" ON public.products;
DROP POLICY IF EXISTS "Admins can delete products" ON public.products;

-- 2. USERS POLICIES - Fix
-- Allow service role and users to insert their profile
CREATE POLICY "Enable insert for users" ON public.users
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own profile
CREATE POLICY "Enable select for users" ON public.users
    FOR SELECT USING (true);

-- Allow users to update their own profile
CREATE POLICY "Enable update for users" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- 3. PRODUCTS POLICIES - Fix (semua bisa lihat, termasuk anonymous)
CREATE POLICY "Products are viewable by everyone" ON public.products
    FOR SELECT USING (true);

CREATE POLICY "Admins can insert products" ON public.products
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
    );

CREATE POLICY "Admins can update products" ON public.products
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
    );

CREATE POLICY "Admins can delete products" ON public.products
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
    );

-- 4. Masukkan user yang sudah terdaftar ke tabel users
-- Ganti 'YOUR_USER_ID' dengan ID dari auth.users
-- Bisa cek di Authentication -> Users -> klik user -> copy ID

-- Cek apakah ada user di auth.users yang belum ada di public.users
INSERT INTO public.users (id, email, name, phone, address, is_admin, created_at)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'name', split_part(au.email, '@', 1)),
    COALESCE(au.raw_user_meta_data->>'phone', ''),
    COALESCE(au.raw_user_meta_data->>'address', ''),
    false,
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.users pu WHERE pu.id = au.id);

-- 5. Set admin untuk email tertentu
UPDATE public.users SET is_admin = true WHERE email = 'uaziz3890@gmail.com';

-- 6. Verifikasi data
SELECT * FROM public.users;
SELECT * FROM public.products;
