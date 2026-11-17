# Perbaikan pendaftaran relawan

Tambahan alur sesi: formulir membuka login jika token belum tersedia. Jika API membalas 401, token lama dibersihkan dan login dibuka kembali. Isian dan CV tetap tersimpan selama halaman formulir terbuka. Setelah login ulang karena 401, pengguna menekan Kirim Pendaftaran kembali. Login/registrasi dari alur ini kembali ke formulir. Server Laravel harus aktif di alamat `API_BASE_URL`; tanpa server, login maupun submit tidak dapat berjalan.

Penyebab: endpoint POST `/api/v1/volunteer-applications` masih mencoba menulis `motivation` dan `skills`, sedangkan migrasi website menggunakan `alamat`, `posisi_dilamar`, `alasan_bergabung`, serta `cv_path` yang wajib terisi. File CV dari mobile sebelumnya tidak disimpan oleh API.

Controller dalam folder ini sudah dipasang pada backend lokal `C:\Users\Lenovo\Downloads\DONGIV\TUBES-PABW-new - Salin`. Untuk hosting, gabungkan perubahan controller ini dengan versi backend tujuan. Tidak ada perubahan database, endpoint, token autentikasi, atau mekanisme persetujuan admin.

API kini memvalidasi alamat minimal 10 karakter, alasan minimal 20 karakter, posisi wajib, dan CV PDF maksimal 2048 KB. CV disimpan pada disk public dalam `cv-uploads`, mengikuti website. File dibersihkan jika penyimpanan database gagal. ID pengguna ditentukan dari login dan status awal tetap pending. Pendaftaran ganda dan kuota penuh ditolak sebelum file disimpan. Endpoint update lama tetap menerima motivation/skills tetapi memetakannya ke kolom website yang benar.

Flutter tetap menggunakan halaman pendaftaran yang ada. Multipart CV kini menyertakan MIME application/pdf; tombol dilindungi sejak sebelum pembacaan token, serta tetap nonaktif setelah berhasil. Error API tetap ditampilkan dan isian dipertahankan. Dialog sukses disesuaikan agar teks tidak meluber pada layar kecil.

Pengujian backend: `VolunteerRegistrationApiTest` lulus 4 tes/30 assertion dengan SQLite in-memory dan disk foto/file palsu. Cakupan: upload PDF tersimpan, field website, autentikasi, ownership/status, riwayat, duplikasi, validasi PDF/ukuran, serta kuota penuh. Tidak ada pendaftaran dibuat pada akun pengguna nyata.

Untuk menjalankan tes di backend:

```powershell
$env:CACHE_STORE='array'
$env:SESSION_DRIVER='array'
php vendor/bin/phpunit --filter VolunteerRegistrationApiTest
```

Alamat API perangkat tetap mengikuti API_BASE_URL. Browser komputer memakai 127.0.0.1, emulator Android memakai 10.0.2.2, dan perangkat fisik memakai IP LAN/HTTPS server. PHP harus mengizinkan request multipart di atas ukuran PDF 2 MB. Kamera/GPS tidak terkait alur pendaftaran ini; file dipilih melalui pemilih dokumen perangkat.
