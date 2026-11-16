# Integrasi ulasan DonGiv

Sumber backend fitur ulasan untuk Laravel di:
`C:/Users/Lenovo/Downloads/DONGIV/TUBES-PABW-new - Salin`.

Fitur sudah dipasang. `install.ps1` menyimpan daftar file dan penambahan rute yang diterapkan ke proyek tersebut. Jangan menimpa perubahan lanjutan di backend tanpa membandingkan file terlebih dahulu.

Kategori: Semua Ulasan (`all`), Donasi (`donation`), Relawan (`volunteer`).

API publik:

- `GET /api/v1/reviews?activity_type=donation&page=1&per_page=20`
- Filter `activity_id` opsional; ringkasan rating mencakup semua hasil yang cocok, bukan hanya halaman saat ini.

API dengan Bearer token:

- `GET /api/v1/reviews/eligibility`
- `POST /api/v1/reviews`: `activity_type`, `activity_id` (ID kampanye), `reference_id` (ID transaksi donasi atau lamaran relawan), `rating`, `comment`, `is_anonymous`.
- `PUT /api/v1/reviews/{id}`: `rating`, `comment`, `is_anonymous` opsional.
- `DELETE /api/v1/reviews/{id}`.

Halaman website: `/ulasan`; endpoint web menggunakan autentikasi sesi dan perlindungan CSRF. Beranda menampilkan tiga ulasan terbaru untuk kategori terpilih dan tautan ke halaman lengkap.

Pengujian backend menggunakan SQLite `:memory:` dan skema minimal tersendiri. Tidak menjalankan migrasi lama yang dapat mengubah data pengguna.

```powershell
php vendor/bin/phpunit --filter ReviewApiTest
```

Pengujian aplikasi dari folder Flutter:

```powershell
flutter test --no-pub test/review_integration_test.dart
```
