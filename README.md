# Retail App - Clothing Brand Application

Aplikasi retail untuk brand clothing dengan fitur lengkap untuk user dan admin.

## Fitur

### User
- ✅ Register & Login dengan email
- ✅ Input data: nama, no HP, email, alamat
- ✅ Browse produk pakaian
- ✅ Search produk
- ✅ Filter berdasarkan kategori (Kaos, Kemeja, Celana, Jaket, Sepatu, Aksesoris)
- ✅ Keranjang belanja
- ✅ Checkout dengan konfirmasi identitas dan alamat pengiriman
- ✅ Riwayat pesanan
- ✅ Edit profil

### Admin
- ✅ CRUD produk (Create, Read, Update, Delete)
- ✅ Manajemen pesanan dengan update status
- ✅ Statistik penjualan:
  - Harian
  - Mingguan
  - Bulanan
  - Total keseluruhan
- ✅ Chart penjualan 7 hari terakhir

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase
  - Authentication
  - Database (PostgreSQL)
  - Storage (untuk gambar produk)
- **State Management**: Provider

## Setup

### 1. Setup Supabase

1. Buat project baru di [Supabase](https://supabase.com)
2. Buka SQL Editor dan jalankan `supabase_setup.sql`
3. Buat Storage Bucket:
   - Nama: `products`
   - Public: Yes

### 2. Konfigurasi Flutter

1. Buka file `lib/config/supabase_config.dart`
2. Ganti dengan credentials Supabase Anda:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run Aplikasi

```bash
flutter run
```

## Membuat Admin

1. Register user biasa melalui aplikasi
2. Jalankan SQL di Supabase:

```sql
UPDATE public.users SET is_admin = TRUE WHERE email = 'email_admin@example.com';
```

## Struktur Folder

```
lib/
├── config/
│   └── supabase_config.dart
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_model.dart
│   └── order_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   ├── cart_provider.dart
│   └── order_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── product_service.dart
│   └── order_service.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── user/
│   │   ├── home_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── order_success_screen.dart
│   │   ├── order_history_screen.dart
│   │   └── profile_screen.dart
│   └── admin/
│       ├── admin_dashboard_screen.dart
│       ├── product_management_screen.dart
│       ├── add_edit_product_screen.dart
│       ├── order_management_screen.dart
│       └── statistics_screen.dart
└── main.dart
```

## Database Schema

### users
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary Key (dari Auth) |
| email | TEXT | Email user |
| name | TEXT | Nama lengkap |
| phone | TEXT | Nomor HP |
| address | TEXT | Alamat |
| is_admin | BOOLEAN | Status admin |
| created_at | TIMESTAMP | Waktu dibuat |

### products
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary Key |
| name | TEXT | Nama produk |
| description | TEXT | Deskripsi |
| price | DECIMAL | Harga |
| category | TEXT | Kategori |
| image_url | TEXT | URL gambar |
| stock | INTEGER | Stok |
| created_at | TIMESTAMP | Waktu dibuat |

### orders
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary Key |
| user_id | UUID | Foreign Key ke users |
| user_name | TEXT | Nama pemesan |
| user_phone | TEXT | No HP pemesan |
| user_email | TEXT | Email pemesan |
| shipping_address | TEXT | Alamat pengiriman |
| total_amount | DECIMAL | Total harga |
| status | TEXT | Status pesanan |
| created_at | TIMESTAMP | Waktu dibuat |

### order_items
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary Key |
| order_id | UUID | Foreign Key ke orders |
| product_id | UUID | Foreign Key ke products |
| product_name | TEXT | Nama produk |
| price | DECIMAL | Harga satuan |
| quantity | INTEGER | Jumlah |
| image_url | TEXT | URL gambar |
| created_at | TIMESTAMP | Waktu dibuat |

## Status Pesanan

- `pending` - Menunggu konfirmasi
- `processing` - Diproses
- `shipped` - Dikirim
- `delivered` - Selesai
- `cancelled` - Dibatalkan

## Screenshots

(Tambahkan screenshots aplikasi di sini)

## License

This project is licensed under the MIT License.

