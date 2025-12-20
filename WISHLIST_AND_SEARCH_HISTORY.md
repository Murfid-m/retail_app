# Fitur Wishlist dan Riwayat Pencarian

## Wishlist / Favorit

### Deskripsi
Fitur wishlist memungkinkan pengguna untuk menyimpan produk favorit mereka. Pengguna dapat menambah/menghapus produk dari wishlist dengan menekan ikon hati.

### Fitur:
1. **Tombol Wishlist di Product Card** - Icon hati di pojok kiri atas setiap card produk
2. **Tombol Wishlist di Product Detail** - Icon hati di app bar halaman detail produk
3. **Halaman Wishlist** - Daftar semua produk yang disimpan
4. **Badge Counter** - Menampilkan jumlah item di wishlist pada icon
5. **Swipe to Delete** - Geser ke kiri untuk menghapus item dari wishlist
6. **Add to Cart dari Wishlist** - Langsung tambahkan ke keranjang dari halaman wishlist

### Lokasi Akses:
- Icon hati di app bar home screen
- Menu "Wishlist" di drawer/navigation

### Database:
Tabel `wishlists` di Supabase dengan kolom:
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key ke auth.users)
- `product_id` (UUID, foreign key ke products)
- `created_at` (TIMESTAMPTZ)

### File Terkait:
- `lib/models/wishlist_model.dart` - Model data
- `lib/services/wishlist_service.dart` - Service untuk CRUD
- `lib/providers/wishlist_provider.dart` - State management
- `lib/screens/user/wishlist_screen.dart` - Halaman wishlist
- `lib/widgets/wishlist_button.dart` - Komponen tombol wishlist
- `supabase/migrations/004_wishlist.sql` - SQL migration

---

## Riwayat Pencarian

### Deskripsi
Fitur riwayat pencarian menyimpan kata kunci pencarian terakhir pengguna secara lokal (SharedPreferences). Pengguna dapat dengan cepat mengulangi pencarian sebelumnya.

### Fitur:
1. **Auto-save** - Pencarian disimpan otomatis saat user submit
2. **Dropdown History** - Muncul saat tap pada search bar (jika kosong)
3. **Max 10 Item** - Hanya menyimpan 10 pencarian terakhir
4. **Delete Individual** - Hapus item riwayat satu per satu
5. **Clear All** - Hapus semua riwayat pencarian
6. **Tap to Search** - Klik item riwayat untuk langsung mencari

### Cara Kerja:
1. Tap pada search bar → dropdown riwayat muncul
2. Ketik dan tekan Enter → pencarian disimpan ke riwayat
3. Klik item riwayat → otomatis mencari dengan kata kunci tersebut
4. Klik X pada item → hapus dari riwayat
5. Klik "Hapus Semua" → bersihkan semua riwayat

### Penyimpanan:
Data disimpan di `SharedPreferences` dengan key `search_history`

### File Terkait:
- `lib/models/search_history_model.dart` - Model data
- `lib/services/search_history_service.dart` - Service untuk local storage
- `lib/providers/search_history_provider.dart` - State management
- `lib/widgets/search_history_widget.dart` - Widget untuk search bar dengan history

---

## Setup Database

Jalankan SQL migration untuk membuat tabel wishlists:

```sql
-- Buka Supabase SQL Editor dan jalankan file:
-- supabase/migrations/004_wishlist.sql
```

Atau jalankan manual:
```sql
CREATE TABLE IF NOT EXISTS wishlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product_id ON wishlists(product_id);

ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own wishlist"
ON wishlists FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add to their own wishlist"
ON wishlists FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove from their own wishlist"
ON wishlists FOR DELETE USING (auth.uid() = user_id);
```

---

## Catatan Dark Mode

Dark mode sudah tersedia di aplikasi ini! Toggle ada di:
- **Home Screen** → Drawer → "Mode Gelap" switch
- **Admin Dashboard** → Drawer → "Mode Gelap" switch

Pengaturan dark mode disimpan di SharedPreferences dan akan diingat saat app restart.
