-- Tambah kolom verifikasi ke tabel users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS verification_code VARCHAR(6),
ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;

-- Update user yang sudah ada menjadi verified
UPDATE users SET is_verified = true WHERE is_verified IS NULL;
