# API Endpoints Documentation

Berdasarkan konfigurasi Laravel kamu, berikut adalah endpoint-endpoint API yang tersedia:

## Public Endpoints (Tidak Memerlukan Autentikasi)

### Campaign Endpoints
- `GET /api/v1/campaigns` - Mendapatkan daftar kampanye
  - Query params: `page`, `status`, `kategori`, `search`
  - Contoh: `/api/v1/campaigns?page=1&status=Active&kategori=Lingkungan`

- `GET /api/v1/campaigns/{id}` - Mendapatkan detail kampanye berdasarkan ID atau slug
  - Contoh: `/api/v1/campaigns/1` atau `/api/v1/campaigns/slug-kampanye`

- `GET /api/v1/campaigns/urgent` - Mendapatkan kampanye mendesak
  - Query params: `page`
  - Kampanye mendesak: kurang dari 3 hari tersisa dan minimal 50% terkumpul

### Image Proxy Endpoint
- `GET /api/images/{folder}/{filename}` - Endpoint proxy untuk menampilkan gambar dari storage
  - Contoh: `/api/images/campaigns/filename.jpg`

### Volunteer Campaigns Endpoints
- `GET /api/v1/volunteer-campaigns` - Mendapatkan daftar kampanye sukarelawan
- `GET /api/v1/volunteer-campaigns/{id}` - Mendapatkan detail kampanye sukarelawan

### Authentication Endpoints
- `POST /api/v1/register` - Registrasi pengguna baru
- `POST /api/v1/login` - Login pengguna

## Protected Endpoints (Memerlukan Autentikasi)

### User Authentication
- `GET /api/v1/me` - Mendapatkan informasi pengguna yang sedang login
- `POST /api/v1/logout` - Logout pengguna
- `POST /api/v1/refresh` - Refresh token autentikasi

### Campaign Management (Memerlukan Autentikasi)
- `POST /api/v1/campaigns` - Membuat kampanye baru
- `PUT /api/v1/campaigns/{id}` - Mengupdate kampanye
- `DELETE /api/v1/campaigns/{id}` - Menghapus kampanye

### Donation Endpoints (Memerlukan Autentikasi)
- `POST /api/v1/donations/process/midtrans` - Proses donasi dengan Midtrans
- `GET /api/v1/donations` - Mendapatkan daftar donasi (untuk admin)
- `GET /api/v1/donations/{order_id}` - Mendapatkan detail donasi
- `GET /api/v1/my-donations` - Mendapatkan daftar donasi pengguna
- `PUT /api/v1/donations/{order_id}/status` - Mengupdate status donasi

### Profile Endpoints (Memerlukan Autentikasi)
- `GET /api/v1/profile` - Mendapatkan profil pengguna
- `PUT /api/v1/profile` - Mengupdate profil pengguna
- `GET /api/v1/profile/donations` - Mendapatkan riwayat donasi
- `GET /api/v1/profile/volunteer` - Mendapatkan riwayat sukarelawan
- `GET /api/v1/profile/history` - Mendapatkan riwayat lengkap
- `GET /api/v1/profile/stats` - Mendapatkan statistik profil

### Campaign Donation with Midtrans (Memerlukan Autentikasi)
- `POST /api/v1/campaigns/{id}/midtrans-payment` - Membuat pembayaran Midtrans untuk kampanye

## Admin Endpoints (Memerlukan Autentikasi Admin)
- `GET /api/v1/admin/dashboard/stats` - Statistik dashboard admin
- `GET /api/v1/admin/campaigns/stats` - Statistik kampanye
- `GET /api/v1/admin/donations/stats` - Statistik donasi
- Dan banyak endpoint admin lainnya...

## Format Response API

### Campaign Response Format
```json
{
  "id": 1,
  "slug": "judul-kampanye",
  "title": "Judul Kampanye",
  "description": "Deskripsi lengkap kampanye",
  "target_amount": 10000000,
  "current_amount": 5000000,
  "image": "campaigns/nama_file.jpg",
  "end_date": "2025-12-31",
  "formatted_end_date": "31 Dec 2025",
  "status": "Active",
  "kategori": "Lingkungan",
  "yayasan": "Nama Yayasan",
  "user": {
    "id": 1,
    "name": "Nama Pengguna",
    "email": "email@example.com"
  },
  "created_at": "2024-12-27 10:00:00",
  "updated_at": "2024-12-27 10:00:00"
}
```

### Error Response Format
```json
{
  "message": "Error message",
  "errors": {
    "field_name": ["Error details"]
  }
}
```

## Penggunaan di Flutter

Di Flutter, endpoint diakses relatif terhadap base URL. Misalnya:
- Jika base URL: `https://dongiv.kolab.top/api`
- Maka endpoint `/api/v1/campaigns` diakses sebagai `v1/campaigns`

Contoh penggunaan:
```dart
// Mendapatkan daftar kampanye
final response = await CampaignRepository.getCampaigns(page: 1, status: 'Active');

// Mendapatkan kampanye mendesak
final urgentResponse = await CampaignRepository.getUrgentCampaigns(page: 1);

// Mendapatkan detail kampanye
final campaign = await CampaignRepository.getCampaign('1');
```

## Catatan Penting

1. **CORS**: Pastikan CORS telah diatur di Laravel agar aplikasi Flutter Web (Chrome) dapat mengakses API
2. **Token Autentikasi**: Endpoint yang dilindungi memerlukan token Bearer dalam header
3. **Pagination**: Sebagian besar endpoint menggunakan pagination dengan 10 item per halaman secara default
4. **Image Proxy**: Gunakan endpoint `/api/images/{folder}/{filename}` untuk menampilkan gambar dari storage Laravel