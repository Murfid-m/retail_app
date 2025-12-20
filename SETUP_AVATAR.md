# Setup Avatar Profile - Panduan Lengkap

## Masalah yang Ditemukan
Foto profil hilang setelah logout dan login lagi karena:
1. ❌ Kolom `avatar_url` belum ada di database Supabase
2. ❌ Storage bucket `user-avatars` belum dibuat
3. ❌ Storage policies belum di-setup

## Solusi yang Sudah Diimplementasikan
✅ Update `auth_service.dart` - menambahkan `avatar_url` ke method `updateUserProfile`
✅ Migration SQL sudah tersedia di `supabase/migrations/005_user_avatar.sql`

## Langkah-langkah Setup (WAJIB DILAKUKAN)

### 1. Jalankan Migration SQL di Supabase Dashboard

1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project Anda
3. Klik menu **SQL Editor** di sidebar kiri
4. Klik tombol **New Query**
5. Copy-paste kode SQL berikut ke editor:

```sql
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
```

6. Klik tombol **Run** atau tekan `Ctrl+Enter`
7. Pastikan muncul pesan sukses

### 2. Verifikasi Setup

#### A. Cek Kolom avatar_url
1. Di Supabase Dashboard, klik **Table Editor**
2. Pilih tabel `users`
3. Pastikan ada kolom baru bernama `avatar_url` (type: text)

#### B. Cek Storage Bucket
1. Di Supabase Dashboard, klik **Storage**
2. Pastikan ada bucket bernama `user-avatars` dengan status Public

#### C. Cek Storage Policies
1. Di halaman Storage, klik bucket `user-avatars`
2. Klik tab **Policies**
3. Pastikan ada 4 policies:
   - ✅ Users can upload their own avatar (INSERT)
   - ✅ Users can update their own avatar (UPDATE)
   - ✅ Users can delete their own avatar (DELETE)
   - ✅ Anyone can view avatars (SELECT)

### 3. Test di Aplikasi

1. Restart aplikasi Flutter (tekan `r` di terminal atau `flutter run`)
2. Login ke akun Anda
3. Upload foto profil baru
4. **Logout** dari aplikasi
5. **Login** lagi
6. ✅ Foto profil seharusnya masih ada!

## Troubleshooting

### Foto profil masih hilang setelah setup?

**Cek 1: Migration berhasil?**
```sql
-- Jalankan query ini di SQL Editor
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'avatar_url';
```
Harusnya return: `avatar_url`

**Cek 2: Bucket ada?**
```sql
-- Jalankan query ini di SQL Editor
SELECT * FROM storage.buckets WHERE id = 'user-avatars';
```
Harusnya return 1 row dengan name = 'user-avatars'

**Cek 3: Data avatar tersimpan?**
```sql
-- Ganti YOUR_USER_ID dengan ID user Anda
SELECT id, email, name, avatar_url FROM users WHERE id = 'YOUR_USER_ID';
```
Harusnya `avatar_url` berisi URL seperti: `https://xxx.supabase.co/storage/v1/object/public/user-avatars/avatars/xxx.jpg`

### Error "Bucket not found" saat upload?

Berarti bucket belum dibuat. Jalankan lagi:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-avatars', 'user-avatars', true)
ON CONFLICT (id) DO NOTHING;
```

### Error "Policy violation" saat upload?

Berarti policies belum di-setup. Copy-paste dan jalankan semua CREATE POLICY dari migration SQL di atas.

## Kode yang Sudah Diperbaiki

### File: `lib/services/auth_service.dart`

**SEBELUM:**
```dart
Future<void> updateUserProfile(UserModel user) async {
  await _supabase.from('users').update({
    'name': user.name,
    'phone': user.phone,
    'address': user.address,
  }).eq('id', user.id);
}
```

**SESUDAH:**
```dart
Future<void> updateUserProfile(UserModel user) async {
  await _supabase.from('users').update({
    'name': user.name,
    'phone': user.phone,
    'address': user.address,
    'avatar_url': user.avatarUrl,  // ← DITAMBAHKAN
  }).eq('id', user.id);
}
```

Sekarang ketika Anda upload foto profil, `avatar_url` akan disimpan ke database, sehingga foto tidak hilang setelah logout/login.

## Status

- ✅ Kode aplikasi sudah diperbaiki
- ⚠️ **WAJIB: Jalankan migration SQL di Supabase Dashboard** (lihat Langkah 1)
- ⚠️ Restart aplikasi setelah migration selesai

---

**Catatan:** Setelah menjalankan migration SQL dan restart aplikasi, foto profil yang Anda upload akan tersimpan permanen dan tidak hilang lagi setelah logout/login.
