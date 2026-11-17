# Peta, sertifikat, dan PDF relawan

## Menjalankan aplikasi lokal yang sudah terhubung

Alamat Flutter `http://localhost:58236` adalah server tampilan; endpoint lokasi berada pada Laravel `http://127.0.0.1:8000/api`. Jalankan aplikasi dengan API yang eksplisit:

```powershell
flutter run -d web-server --web-hostname=localhost --web-port=58236 --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Atau pilih konfigurasi VS Code **DonGiv Web - API localhost** dalam `.vscode/launch.json`. Gunakan satu proses Flutter pada port 58236. Setelah mengganti konfigurasi `API_BASE_URL`, hentikan sesi Flutter lama dan jalankan ulang; hot reload saja tidak mengganti compile-time define. Jika browser masih menampilkan halaman lama, lakukan hard refresh (Ctrl+Shift+R).

Pemeriksaan langsung dari origin `http://localhost:58236` pada koordinat `-6.9731680,107.6326450` berhasil mengembalikan alamat melalui endpoint reverse berautentikasi. CORS preflight mengizinkan Authorization. Tidak ada kampanye baru yang dibuat dalam pemeriksaan ini.

Perubahan pada komputer localhost belum otomatis memperbarui hosting atau APK yang sudah terpasang.

## Peta

Pastikan server tujuan memiliki `CampaignLocationController`, `CampaignGeocodingService`, dan `config/maps.php` dari folder ini. Gabungkan `routes/locations.php` ke `routes/api.php`, lalu jalankan `php artisan route:clear`. Jangan menambahkan prefix `api` lagi pada file route: Laravel sudah memasangnya.

Untuk backend lokal Windows yang sudah memiliki controller tersebut:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File backend_campaign_submission/repair_locations.ps1 -BackendPath "C:/path/laravel"
```

Script menambahkan hanya route yang belum ada, termasuk alias `revese` untuk aplikasi lama. Endpoint utama tetap `GET /api/v1/locations/reverse?latitude=...&longitude=...`, dengan Bearer token. Tanpa token, respons yang benar adalah 401, bukan 404. Endpoint pencarian dan reverse memerlukan koneksi HTTPS keluar ke penyedia geocoding.

## Sertifikat kegiatan dari database

Script berikut memakai relasi kampanye dan pengguna dari pendaftaran yang berstatus `approved`. Sertifikat yang sudah ada tetap dipertahankan. Status sertifikat baru mengikuti aturan model backend yang dipakai admin.

```sh
php backend_certificates/backfill_certificates.php /path/laravel
php backend_certificates/backfill_certificates.php /path/laravel --apply
```

Baris pertama hanya menampilkan jumlah. Jalankan pada database server tujuan agar kegiatan tersedia melalui `GET /api/v1/certificates` milik pengguna yang login. Tidak ada sertifikat untuk pendaftaran pending/rejected.

## PDF pendaftaran relawan

Gabungkan controller `backend_volunteer_registration/app/Http/Controllers/Api/VolunteerApplicationController.php` ke backend tujuan. Endpoint harus menerima multipart `cv` (PDF maksimal 2 MiB), `volunteer_campaign_id`, `posisi_dilamar`, `alamat`, dan `alasan_bergabung`. Disk public harus dapat ditulis. Batas PHP/web server untuk request harus lebih besar dari 2 MiB karena multipart juga memuat field lain.

Flutter kini membaca byte/stream/path dari pemilih dokumen, memeriksa isi PDF, dan menyimpan byte tersebut sampai submit selesai. Perubahan ini memerlukan rebuild aplikasi atau web Flutter.

## Alamat API untuk HP

`127.0.0.1` atau `localhost` pada HP menunjuk HP itu sendiri. Untuk backend di komputer, gunakan IP LAN komputer dan jaringan yang sama. Untuk backend hosting, gunakan URL HTTPS hosting yang benar melalui `--dart-define=API_BASE_URL=https://domain-anda/api`. Website yang sudah dihosting tidak otomatis membuat backend localhost dapat diakses dari HP.
