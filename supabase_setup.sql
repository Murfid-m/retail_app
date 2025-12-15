-- =============================================
-- SUPABASE DATABASE SETUP FOR RETAIL APP
-- =============================================
-- Jalankan SQL ini di Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. USERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy untuk users
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

-- =============================================
-- 2. PRODUCTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL,
    category TEXT NOT NULL,
    image_url TEXT,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Policy untuk products (semua bisa read, admin bisa CRUD)
CREATE POLICY "Anyone can view products" ON public.products
    FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "Admins can insert products" ON public.products
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

CREATE POLICY "Admins can update products" ON public.products
    FOR UPDATE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

CREATE POLICY "Admins can delete products" ON public.products
    FOR DELETE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

-- =============================================
-- 3. ORDERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    user_phone TEXT NOT NULL,
    user_email TEXT NOT NULL,
    shipping_address TEXT NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Policy untuk orders
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all orders" ON public.orders
    FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

CREATE POLICY "Admins can update orders" ON public.orders
    FOR UPDATE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

-- =============================================
-- 4. ORDER ITEMS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    price DECIMAL(12, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Policy untuk order items
CREATE POLICY "Users can view own order items" ON public.order_items
    FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_id AND orders.user_id = auth.uid())
    );

CREATE POLICY "Users can insert own order items" ON public.order_items
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_id AND orders.user_id = auth.uid())
    );

CREATE POLICY "Admins can view all order items" ON public.order_items
    FOR SELECT TO authenticated USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

-- =============================================
-- 5. FUNCTION TO DECREMENT STOCK
-- =============================================
CREATE OR REPLACE FUNCTION decrement_stock(product_id UUID, quantity INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE public.products
    SET stock = stock - quantity
    WHERE id = product_id AND stock >= quantity;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 6. CREATE STORAGE BUCKET FOR PRODUCT IMAGES
-- =============================================
-- Storage bucket untuk menyimpan gambar produk
-- Cara manual via Dashboard:
-- 1. Buka Supabase Dashboard -> Storage
-- 2. Klik "New Bucket"
-- 3. Name: products
-- 4. Public bucket: ON (centang)
-- 5. Klik "Create bucket"

-- Atau jalankan SQL ini:
INSERT INTO storage.buckets (id, name, public) 
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Policy: Semua orang bisa melihat gambar
CREATE POLICY "Public Access" ON storage.objects
    FOR SELECT USING (bucket_id = 'products');

-- Policy: User authenticated bisa upload gambar
CREATE POLICY "Authenticated users can upload" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'products');

-- Policy: Admin bisa update gambar
CREATE POLICY "Admin can update images" ON storage.objects
    FOR UPDATE TO authenticated USING (
        bucket_id = 'products' AND
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

-- Policy: Admin bisa delete gambar
CREATE POLICY "Admin can delete images" ON storage.objects
    FOR DELETE TO authenticated USING (
        bucket_id = 'products' AND
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE)
    );

-- =============================================
-- 7. INSERT SAMPLE ADMIN USER
-- =============================================
-- First, create an admin account via your app's register screen
-- Then run this SQL to make them admin:
-- UPDATE public.users SET is_admin = TRUE WHERE email = 'admin@example.com';

-- =============================================
-- 8. INSERT SAMPLE PRODUCTS (OPTIONAL)
-- =============================================
INSERT INTO public.products (name, description, price, category, image_url, stock) VALUES
('Kaos Polos Hitam', 'Kaos polos bahan cotton combed 30s, nyaman dipakai sehari-hari', 89000, 'Kaos', 'https://via.placeholder.com/300x300?text=Kaos+Hitam', 50),
('Kaos Polos Putih', 'Kaos polos bahan cotton combed 30s, cocok untuk casual', 89000, 'Kaos', 'https://via.placeholder.com/300x300?text=Kaos+Putih', 45),
('Kemeja Flanel Merah', 'Kemeja flanel kotak-kotak, bahan tebal dan hangat', 175000, 'Kemeja', 'https://via.placeholder.com/300x300?text=Kemeja+Flanel', 30),
('Kemeja Polos Navy', 'Kemeja formal bahan katun premium', 150000, 'Kemeja', 'https://via.placeholder.com/300x300?text=Kemeja+Navy', 25),
('Celana Jeans Slim Fit', 'Celana jeans stretch, nyaman dan stylish', 250000, 'Celana', 'https://via.placeholder.com/300x300?text=Celana+Jeans', 40),
('Celana Chino Cream', 'Celana chino bahan katun twill', 189000, 'Celana', 'https://via.placeholder.com/300x300?text=Celana+Chino', 35),
('Jaket Bomber Hitam', 'Jaket bomber dengan bahan parasut premium', 299000, 'Jaket', 'https://via.placeholder.com/300x300?text=Jaket+Bomber', 20),
('Hoodie Oversize Grey', 'Hoodie oversize bahan fleece tebal', 225000, 'Jaket', 'https://via.placeholder.com/300x300?text=Hoodie+Grey', 30),
('Sepatu Sneakers Putih', 'Sepatu sneakers casual, sol empuk dan ringan', 350000, 'Sepatu', 'https://via.placeholder.com/300x300?text=Sepatu+Putih', 25),
('Sepatu Loafers Coklat', 'Sepatu loafers kulit sintetis premium', 299000, 'Sepatu', 'https://via.placeholder.com/300x300?text=Sepatu+Loafers', 20),
('Topi Baseball Hitam', 'Topi baseball dengan bordir premium', 75000, 'Aksesoris', 'https://via.placeholder.com/300x300?text=Topi+Baseball', 50),
('Tas Sling Bag Canvas', 'Tas sling bag bahan canvas tebal', 125000, 'Aksesoris', 'https://via.placeholder.com/300x300?text=Sling+Bag', 40);

-- =============================================
-- DONE! 
-- =============================================
-- Catatan:
-- 1. Copy SUPABASE_URL dan SUPABASE_ANON_KEY dari Supabase Dashboard
-- 2. Paste di file lib/config/supabase_config.dart
-- 3. Untuk membuat admin, register user biasa lalu jalankan:
--    UPDATE public.users SET is_admin = TRUE WHERE email = 'email_admin@example.com';
