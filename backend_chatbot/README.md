# DonGiv Assistant

Penyebab chatbot tidak merespons: klien memanggil `POST /api/v1/chatbot/message`, tetapi backend lokal belum memiliki route/controller chatbot.

Endpoint baru sudah dipasang di Laravel lokal `C:/Users/Lenovo/Downloads/DONGIV/TUBES-PABW-new - Salin`. Request memakai `{"message":"Kegiatan relawan lingkungan di Bandung"}`. Respons memuat `reply`, `used_ai: false`, dan `data.donations`/`data.volunteers`, sesuai model rekomendasi Flutter.

Layanan menggunakan panduan DonGiv dan pencarian kata kunci di database, tanpa API AI eksternal/API key. Panduan meliputi donasi, pembayaran, pendaftaran relawan/CV, pengajuan kampanye, dan sertifikat. Chatbot tidak memproses pembayaran atau mengubah status pendaftaran.

Rekomendasi donasi harus verified, belum berakhir, dan belum mencapai target. Kegiatan relawan harus Aktif, belum berakhir, dan memiliki kuota. Pencarian mendukung kategori dan lokasi. Data private, kampanye pending/rejected, dan detail transaksi pengguna tidak disajikan. Mengirim chat tidak mengubah data database.

Input maksimal 1000 karakter; pembatasan 20 request/menit per klien. Endpoint publik karena hanya menyajikan informasi publik. Flutter mempertahankan input ketika gagal, menampilkan error sesuai kondisi, dan mencegah pengiriman ganda selama menunggu balasan.

## Pemasangan

Tinjau dan gabungkan controller pada backend tujuan. Untuk Windows:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File backend_chatbot/install.ps1 -BackendPath "C:/path/laravel"
```

Installer menyalin controller/tes, membuat backup file target yang sudah ada, menambahkan route, dan membersihkan cache route. Untuk hosting non-Windows, salin controller lalu gabungkan berikut pada `routes/api.php`:

```php
Route::post('v1/chatbot/message', [\App\Http\Controllers\Api\ChatbotController::class, 'message'])
    ->middleware(['cors', 'throttle:20,1']);
```

Jalankan `php artisan route:clear`. Tidak ada migrasi, dependency, atau perubahan kredensial. Pastikan CORS mengizinkan origin aplikasi. Hosting/APK lama memerlukan deployment/build ulang terpisah.

## Validasi

- Backend: `php vendor/bin/phpunit --filter ChatbotApiTest` (SQLite in-memory), 5 tes/46 assertion.
- Flutter: `flutter test --no-pub test/chatbot_test.dart`, 6 tes.
- Analyzer pada halaman, repository, dan tes chatbot bersih.
- Request HTTP nyata dari origin `http://localhost:58236` berhasil mengembalikan panduan pendaftaran relawan. CORS preflight mengizinkan POST.
