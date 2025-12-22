-- Reviews & Multi-Image Migration
-- Run this SQL in Supabase SQL Editor

-- ========================================
-- 1. Add multi-image support to products
-- ========================================

-- Add image_urls array column to products
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- Add rating columns to products
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0;

ALTER TABLE products 
ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;

-- ========================================
-- 2. Create reviews table
-- ========================================

CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Each user can only review a product once
    UNIQUE(product_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at);

-- ========================================
-- 3. Enable Row Level Security
-- ========================================

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view reviews
CREATE POLICY "Anyone can view reviews" ON reviews
    FOR SELECT
    USING (true);

-- Policy: Authenticated users can insert their own reviews
CREATE POLICY "Users can insert own reviews" ON reviews
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text OR EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid()
    ));

-- Policy: Users can update their own reviews
CREATE POLICY "Users can update own reviews" ON reviews
    FOR UPDATE
    USING (auth.uid()::text = user_id::text OR EXISTS (
        SELECT 1 FROM users WHERE id = user_id
    ));

-- Policy: Users can delete their own reviews
CREATE POLICY "Users can delete own reviews" ON reviews
    FOR DELETE
    USING (auth.uid()::text = user_id::text OR EXISTS (
        SELECT 1 FROM users WHERE id = user_id
    ));

-- ========================================
-- 4. Function to update product rating
-- ========================================

CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the product's average rating and total reviews
    UPDATE products
    SET 
        average_rating = COALESCE(
            (SELECT AVG(rating)::DECIMAL(3,2) FROM reviews WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)),
            0
        ),
        total_reviews = COALESCE(
            (SELECT COUNT(*) FROM reviews WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)),
            0
        )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- 5. Triggers to auto-update rating
-- ========================================

-- Drop existing triggers if any
DROP TRIGGER IF EXISTS trigger_update_rating_on_insert ON reviews;
DROP TRIGGER IF EXISTS trigger_update_rating_on_update ON reviews;
DROP TRIGGER IF EXISTS trigger_update_rating_on_delete ON reviews;

-- Create triggers
CREATE TRIGGER trigger_update_rating_on_insert
    AFTER INSERT ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_rating();

CREATE TRIGGER trigger_update_rating_on_update
    AFTER UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_rating();

CREATE TRIGGER trigger_update_rating_on_delete
    AFTER DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_product_rating();

-- ========================================
-- 6. Sample Data (Optional)
-- ========================================

-- You can uncomment and run this to add sample reviews
-- Make sure to replace the UUIDs with actual product and user IDs from your database

/*
-- Get some product and user IDs first:
-- SELECT id, name FROM products LIMIT 5;
-- SELECT id, name FROM users LIMIT 5;

-- Insert sample reviews
INSERT INTO reviews (product_id, user_id, rating, comment) VALUES
    ('product-uuid-1', 'user-uuid-1', 5, 'Produk sangat bagus! Kualitas premium.'),
    ('product-uuid-1', 'user-uuid-2', 4, 'Bagus, sesuai deskripsi. Pengiriman cepat.'),
    ('product-uuid-2', 'user-uuid-1', 5, 'Recommended! Pasti beli lagi.'),
    ('product-uuid-2', 'user-uuid-3', 3, 'Lumayan, bisa lebih baik.'),
    ('product-uuid-3', 'user-uuid-2', 4, 'Keren, worth the price.');
*/

-- ========================================
-- 7. Verify Setup
-- ========================================

-- Check if columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name IN ('image_urls', 'average_rating', 'total_reviews');

-- Check if reviews table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'reviews'
);

-- ========================================
-- Migration Complete!
-- ========================================
