# Seed Data untuk Statistik

Fitur seeding data ini membantu Anda mengisi database dengan data order dummy untuk testing statistik admin.

## 📊 Sumber Data

Data diambil dari `data/dashboard_summary.json` yang berisi:
- Total sales: Rp 2,261,536.78
- 48 bulan data (2015-2018)
- Breakdown per kategori dan produk top

## 🚀 Cara Menggunakan

### Opsi 1: Melalui UI Admin (Recommended)

1. Login sebagai admin
2. Buka halaman **Statistik**
3. Jika belum ada data, akan muncul banner "Belum ada data statistik"
4. Klik tombol **"Seed Data Testing"**
5. Tunggu proses seeding selesai (±30 detik)
6. Statistik akan otomatis ter-refresh

### Opsi 2: SQL Script (Manual)

1. Buka Supabase Dashboard → SQL Editor
2. Copy paste isi file `supabase/seed_orders.sql`
3. Jalankan query
4. Refresh halaman statistik admin

### Opsi 3: Dart Script (Command Line)

```bash
dart run lib/scripts/seed_orders.dart
```

## 📈 Data yang Dibuat

Script akan membuat:

1. **Data Historis** (12 bulan terakhir)
   - 3-5 orders per bulan
   - Total berdasarkan monthly_sales_trend dari JSON
   - Random distribution sepanjang bulan

2. **Data Bulan Ini** (20 orders)
   - Distributed 20 hari terakhir
   - Nilai: Rp 50,000 - 240,000

3. **Data Hari Ini** (5 orders)
   - Waktu acak hari ini
   - Nilai: Rp 75,000 - 175,000

## ⚠️ Catatan Penting

- Semua order memiliki status `completed` agar masuk ke statistik
- User yang digunakan: admin pertama yang ditemukan di database
- Data bersifat dummy dan hanya untuk testing
- Untuk production, hapus atau disable fitur seeding

## 🔄 Reset Data

Untuk menghapus data seeding:

```sql
-- Hapus semua order dengan email customer testing
DELETE FROM orders 
WHERE user_email LIKE 'customer%@example.com' 
   OR user_email LIKE 'recent%@example.com'
   OR user_email LIKE 'today%@example.com';
```

## 📝 Struktur JSON

`data/dashboard_summary.json`:
```json
{
  "total_sales": 2261536.78,
  "monthly_sales_trend": [
    {
      "month": "2015-01",
      "sales": 14205.71
    },
    ...
  ]
}
```

## 🎯 KPI yang Akan Terisi

Setelah seeding, halaman statistik akan menampilkan:

- **Hari Ini**: Sales dari order hari ini
- **Minggu Ini**: Sales 7 hari terakhir
- **Bulan Ini**: Sales bulan berjalan
- **Total**: Semua sales dengan status completed
- **Chart**: Bar chart sales 7 hari terakhir

## 🛠️ Troubleshooting

**Q: Statistik masih 0 setelah seeding?**
- A: Check console log, pastikan tidak ada error
- Pastikan StatisticsService query status = 'completed'
- Refresh halaman atau restart app

**Q: Error "No admin user found"?**
- A: Buat user admin terlebih dahulu di database
- Set `is_admin = true` untuk user tersebut

**Q: Proses seeding lama?**
- A: Normal, karena insert ratusan orders
- UI script lebih cepat karena hanya seed 12 bulan terakhir
- SQL script seed semua data (48 bulan)
