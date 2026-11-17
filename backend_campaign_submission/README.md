# Pengajuan kampanye mobile DonGiv

Formulir yang digunakan tetap `lib/pages/start_campaign_page.dart`; endpoint pengajuan tetap `POST /api/v1/campaigns` dengan token Sanctum dan multipart. Implementasi sudah dipasang pada backend lokal `C:\Users\Lenovo\Downloads\DONGIV\TUBES-PABW-new - Salin`. Folder ini menyimpan salinan perubahan backend agar dapat ditinjau dan dipindahkan ke hosting.

## Kontrak data

| Formulir | Field API |
| --- | --- |
| Judul, cerita, kategori | title, description, category |
| Target Rupiah, tanggal akhir | target_amount (angka tanpa pemisah), end_date (YYYY-MM-DD) |
| Nama penerima, jenis penerima | yayasan, jenis_penerima |
| Informasi penerima, kontak, cara penyaluran | recipient_description, whatsapp, penyaluran |
| Foto JPEG/PNG maksimal 2 MiB | image (multipart) |
| Alamat dan wilayah | lokasi, alamat_lengkap, kecamatan, kabupaten, provinsi, kode_pos |
| Titik yang dikonfirmasi pengguna | latitude, longitude (7 desimal) |

Target minimal Rp10.000. Jenis penerima: Individu/Yayasan/Komunitas. Penyaluran: Langsung/Yayasan/Platform. ID pemilik selalu berasal dari autentikasi; status pengajuan selalu pending dan saldo awal nol. Klien tidak menentukan pemilik atau menyetujui kampanyenya sendiri. Riwayat menggunakan `GET /api/v1/campaigns?my=1`. Kampanye pending/rejected hanya terlihat oleh pemilik/admin; daftar publik menampilkan verified. Verifikasi admin tetap memakai alur yang sudah ada. Detail admin kini menampilkan informasi penerima dan koordinat.

## Perubahan database dan instalasi

Database lama belum mempunyai koordinat maupun cerita penerima yang terpisah. Migrasi baru hanya menambahkan tiga kolom nullable: latitude, longitude, recipient_description; catatan lama tetap valid. Migrasi ini sudah diterapkan pada backend lokal.

Untuk backend lain, tinjau dan gabungkan file dalam folder ini dengan versi backend tujuan. `install.ps1` menunjuk folder lokal di atas dan menyalin file secara utuh; jangan menjalankannya ke proyek berbeda tanpa menyesuaikan serta meninjau perubahan. Script juga menambahkan dua route lokasi dan include detail admin secara idempoten. Setelah file digabungkan, jalankan hanya migrasi baru:

```sh
php artisan migrate --path=database/migrations/2026_11_17_000002_add_campaign_submission_location.php --force
php artisan optimize:clear
```

Tidak perlu menjalankan ulang migrasi lama atau menghapus database. Pastikan disk public/storage link dan URL penyajian gambar backend tetap berfungsi. Batas PHP `upload_max_filesize` minimal 2M dan `post_max_size` lebih besar dari total request multipart.

## Peta dan hosting

Peta menggunakan flutter_map dengan tile OpenStreetMap; pencarian/reverse melalui Laravel ke Nominatim. Tidak memerlukan Google Maps API key. Endpoint baru, keduanya memerlukan login:

- `GET /api/v1/locations/search?q=alamat` (pencarian manual, minimal 3 karakter).
- `GET /api/v1/locations/reverse?latitude=...&longitude=...`.

Koordinat reverse selalu mempertahankan titik pilihan pengguna, bukan menggantinya dengan pusat alamat dari penyedia. Tampilan awal Indonesia hanyalah viewport; formulir tidak memiliki lokasi sampai pengguna memilih dan mengonfirmasinya. Gangguan penyedia/izin tidak menghasilkan lokasi dummy.

Konfigurasi Laravel opsional (lihat config/maps.php):

```dotenv
MAP_GEOCODING_URL=https://nominatim.openstreetmap.org
MAP_GEOCODING_CONTACT=alamat-email-pengelola@example.com
```

Isi kontak pengelola sebenarnya. Cache hasil 1 hari, global lock dan pembatas 1 permintaan penyedia/detik diterapkan; pencarian tanpa autocomplete. Request bersamaan dapat menerima pesan sibuk untuk dicoba lagi. Gunakan cache bersama jika backend memiliki beberapa instance. Layanan publik tidak menjamin kapasitas untuk trafik produksi; sediakan penyedia yang sesuai dengan beban dan ketentuannya. URL geocoder dapat diganti dengan penyedia yang kompatibel dengan respons Nominatim.

Tile dapat diganti melalui `--dart-define=MAP_TILE_URL=https://penyedia/{z}/{x}/{y}.png`. Penyedia lain mungkin memerlukan kunci dan penyesuaian atribusi; jangan menganggap konfigurasi itu sudah tersedia. Atribusi OpenStreetMap ditampilkan pada pemilih peta.

Alamat API Flutter dikonfigurasi dengan `--dart-define=API_BASE_URL=.../api`. Browser lokal menggunakan http://127.0.0.1:8000/api; emulator Android menggunakan http://10.0.2.2:8000/api; perangkat fisik menggunakan IP LAN komputer (Laravel perlu mendengarkan pada 0.0.0.0 dan port diizinkan firewall). Pada hosting, gunakan domain HTTPS yang sebenarnya, APP_URL yang sesuai, dan konfigurasi CORS aplikasi. Domain hosting belum diberikan. GPS browser membutuhkan secure context; localhost biasanya diizinkan browser, akses HTTP melalui IP LAN dapat diblokir.

Android sudah memiliki izin lokasi foreground; iOS sudah memiliki keterangan izin lokasi, kamera, dan galeri. Geolocator memerlukan Android compileSdk setidaknya 35. Aplikasi meminta izin lokasi saat tombol Lokasi Saya ditekan, bukan saat halaman dibuka. Kamera/galeri memakai image_picker yang sudah ada.

## Validasi

Tes Flutter mencakup form lengkap multipart, validasi, kategori/tanggal, foto kamera/ukuran/hapus, persistensi lokasi setelah edit/batal, pencegahan pengiriman ganda, Rupiah, peta pencarian/geser/konfirmasi, GPS dan izin ditolak. API diuji dengan SQLite dan disk foto terisolasi, bukan membuat kampanye pada akun pengguna nyata. Tes API mencakup ownership, pending, privasi, admin approval, file tersimpan, koordinat, geocoder cache/rate limit/error. Pencarian/reverse serta tile publik juga diperiksa langsung.

Android SDK dan perangkat Android belum tersedia di lingkungan ini. Build APK serta pengujian kamera/GPS pada perangkat fisik masih perlu dilakukan; tes platform menggunakan simulasi izin/posisi. Jangan mengartikan kelulusan tes simulasi sebagai pengujian perangkat nyata.

Hasil pemeriksaan: build Web berhasil; 42 tes regresi Flutter lulus dan seluruh 6 tes formulir versi akhir lulus (termasuk satu tes persistensi lokasi tambahan). Analisis statis tujuh file baru/formulir dan tes bersih. Repository lama masih memiliki lint informasional sebelumnya. Regresi Laravel gabungan lulus 27 tes/165 assertion. Jalankan PHPUnit dengan `CACHE_STORE=array` dan `SESSION_DRIVER=array`; bersihkan config cache Laravel terlebih dahulu agar tes tidak menggunakan konfigurasi sesi/database lokal yang tersimpan.

Referensi penyedia: [kebijakan Nominatim](https://operations.osmfoundation.org/policies/nominatim/), [kebijakan tile OpenStreetMap](https://operations.osmfoundation.org/policies/tiles/), [persyaratan geolocator](https://pub.dev/packages/geolocator).
