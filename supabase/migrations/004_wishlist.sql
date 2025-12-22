
-- ============================================
-- Migration: Wishlist Feature
-- Description: Add wishlists table for user favorites
-- ============================================

-- Create wishlists table
CREATE TABLE IF NOT EXISTS wishlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Each user can only add a product once
    UNIQUE(user_id, product_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product_id ON wishlists(product_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_created_at ON wishlists(created_at);

-- Enable Row Level Security
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view only their own wishlist
CREATE POLICY "Users can view their own wishlist"
ON wishlists FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can add to their own wishlist
CREATE POLICY "Users can add to their own wishlist"
ON wishlists FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can remove from their own wishlist
CREATE POLICY "Users can remove from their own wishlist"
ON wishlists FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- Optional: Add wishlist count to products (denormalized for performance)
-- Uncomment if you want to track wishlist count on products
-- ============================================

-- ALTER TABLE products ADD COLUMN IF NOT EXISTS wishlist_count INTEGER DEFAULT 0;

-- CREATE OR REPLACE FUNCTION update_product_wishlist_count()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     IF TG_OP = 'INSERT' THEN
--         UPDATE products 
--         SET wishlist_count = wishlist_count + 1 
--         WHERE id = NEW.product_id;
--         RETURN NEW;
--     ELSIF TG_OP = 'DELETE' THEN
--         UPDATE products 
--         SET wishlist_count = wishlist_count - 1 
--         WHERE id = OLD.product_id;
--         RETURN OLD;
--     END IF;
--     RETURN NULL;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER trigger_update_wishlist_count
-- AFTER INSERT OR DELETE ON wishlists
-- FOR EACH ROW EXECUTE FUNCTION update_product_wishlist_count();
