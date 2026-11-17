# Sertifikat relawan: kesesuaian website, mobile, dan hosting

Perbaikan data: `backfill_certificates.php` menambahkan sertifikat yang belum ada dari pendaftaran `approved`, menggunakan data kegiatan asli dan aturan model admin. Pada backend localhost, dua sertifikat yang hilang sudah dibuat; pemeriksaan ulang menunjukkan nol pendaftaran approved tanpa sertifikat. Tujuh sertifikat sekarang berstatus pending. Status sertifikat lama tetap dipertahankan. Untuk hosting, jalankan dry run pada direktori Laravel tujuan sebelum memakai `--apply`.

Perubahan sudah dipasang pada Laravel lokal:
`C:/Users/Lenovo/Downloads/DONGIV/TUBES-PABW-new - Salin`.

`http://127.0.0.1:8000` adalah alamat lokal yang diberikan pengguna. Hosting publik belum dikonfigurasi karena domain publik belum tersedia. Tidak ada perubahan pada kredensial database atau APP_KEY.

## Perilaku yang disamakan

- Website dan aplikasi membaca tabel `volunteer_certificates` yang sama.
- Status `active` dapat diunduh; `pending` dan `revoked` tidak dapat diunduh. Status ditetapkan melalui alur admin yang sudah ada pada website; tanggal selesai saja tidak menimpa keputusan admin.
- Ringkasan: total sertifikat, sertifikat aktif, jumlah kampanye unik, total jam dari sertifikat aktif, dan tingkat relawan.
- Flutter memuat ulang detail sertifikat dari API, memverifikasi melalui endpoint publik, dan mendukung berbagi tautan verifikasi lewat WhatsApp/LinkedIn.
- PDF website, PDF Bearer API, dan PDF signed link menggunakan satu `CertificatePdfService` dan template `pdf.certificate` yang sama (A4 landscape).
- QR PNG dibuat di server menggunakan BaconQrCode, dengan tautan verifikasi pada domain yang sedang dikonfigurasi. PDF menyematkan QR sebagai data URI, tanpa memanggil layanan Google Chart atau layanan gambar eksternal.
- Flutter tidak lagi memakai fallback ke URL sesi website ketika API menolak unduhan. Signed link hanya diminta setelah pengguna terautentikasi dan memiliki sertifikat; tautan berlaku 10 menit. Status dicabut diperiksa kembali ketika tautan digunakan.

## Endpoint API

Dengan Bearer token:

- `GET /api/v1/certificates`
- `GET /api/v1/certificates/{id}`
- `GET /api/v1/certificates/{id}/download-url` → `download_url`, `expires_at`.
- `GET /api/v1/certificates/{id}/download` → PDF langsung, bukan redirect login HTML.

Publik:

- `GET /api/v1/certificate/verify/{certificateNumber}`
- `GET /api/v1/certificate/qr/{certificateNumber}` → PNG.
- `GET /api/v1/certificates/{id}/download-signed?expires=...&signature=...` → hanya dapat dipakai dengan tanda tangan valid dan belum kedaluwarsa; ditolak jika sertifikat pending/dicabut.

Tanda tangan bersifat relatif terhadap path/query sehingga pemetaan localhost ke Android emulator tidak membatalkannya. Jangan mengubah path atau query URL unduhan di proxy.

## Menjalankan lokal

Browser/Windows pada komputer yang sama:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Perangkat fisik harus memakai alamat LAN komputer yang menjalankan Laravel, bukan 127.0.0.1. Contohnya `http://192.168.1.10:8000/api`; server harus mendengarkan alamat LAN dan firewall mengizinkan port pengujian.

## Hosting

1. Deploy perubahan Laravel beserta **composer.json dan composer.lock yang sudah diperbarui**. Sumber pada direktori ini menyimpan file yang diubah; `install.ps1` dipakai untuk pemasangan lokal, bukan untuk dijalankan pada hosting dengan path berbeda.
2. Aktifkan ekstensi PHP GD, mbstring, DOM/XML, dan ekstensi yang disyaratkan Composer. PHP 8.2+ mengikuti proyek Laravel. Jalankan `composer install --no-dev --optimize-autoloader` agar `bacon/bacon-qr-code` dan dependency-nya tersedia.
3. Gabungkan `.env.hosting.example` ke konfigurasi hosting, isi **domain HTTPS yang sebenarnya**, dan pertahankan APP_KEY/database yang sudah ada. APP_URL harus URL publik Laravel, tanpa `/api`. Arahkan document root ke direktori Laravel `public` dan pastikan `storage` serta `bootstrap/cache` writable.
4. Isi `CORS_ALLOWED_ORIGINS` dengan domain website Flutter yang tepat. Middleware custom tidak lagi menimpa konfigurasi origin menjadi `*`. Preflight menggunakan HandleCors bawaan Laravel. Autentikasi API tetap Bearer; tidak perlu cookie lintas domain.
5. Jika menggunakan reverse proxy/CDN, konfigurasikan trusted proxies sesuai topologi hosting. URL produksi memakai APP_URL dan HTTPS yang dikonfigurasi; jangan memakai localhost pada APP_URL produksi.
6. Jalankan `php artisan optimize:clear`, `php artisan config:cache`, dan `php artisan route:cache` pada hosting setelah deployment sesuai dukungan server. Tidak ada migrasi database baru untuk perbaikan sertifikat ini.
7. Build aplikasi dengan alamat API publik:

```powershell
flutter build web --dart-define=API_BASE_URL=https://donasi.example.com/api
flutter build apk --release --dart-define=API_BASE_URL=https://donasi.example.com/api
```

Ganti domain contoh di atas; jangan mengunggah build yang masih menggunakan localhost. Tidak ada proses deploy publik yang dijalankan dalam tugas ini.

## Validasi

- Laravel: `php vendor/bin/phpunit --filter CertificateApiTest` — database SQLite in-memory; tidak menambah atau mengubah sertifikat pengguna.
- Flutter: `flutter test --no-pub test/certificate_integration_test.dart`.
- Tes mencakup kepemilikan, status pending/dicabut, statistik, PDF nyata, URL kedaluwarsa/tampered, hosting HTTPS, QR PNG, CORS, URL emulator, penolakan HTML yang menyamar sebagai PDF, serta tampilan mobile.

Referensi implementasi: [Laravel URL signing](https://api.laravel.com/docs/12.x/Illuminate/Support/Facades/URL.html), [Laravel trusted proxies](https://laravel.com/framework/docs/12.x/requests#configuring-trusted-proxies), [BaconQrCode GD renderer](https://github.com/Bacon/BaconQrCode#gdlib-renderer).
