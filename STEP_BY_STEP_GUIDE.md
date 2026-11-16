# Panduan Lengkap: Menghubungkan Flutter ke Laravel API

## Langkah 1: Pastikan Laravel Server Berjalan
Buka terminal/command prompt di folder Laravel kamu dan jalankan:
```bash
php artisan serve
```

Harus muncul:
```
Starting Laravel development server: http://127.0.0.1:8000
```

## Langkah 2: Cek API Bisa Diakses
Buka browser dan kunjungi:
```
http://127.0.0.1:8000/api/campaigns
```

Jika muncul data JSON, berarti API kamu berjalan dengan baik.

## Langkah 3: Install dan Setup CORS di Laravel (PENTING UNTUK CHROME)
Ini adalah langkah yang PALING PENTING untuk Flutter Web di Chrome:

### A. Install package CORS:
```bash
composer require barryvdh/laravel-cors
```

### B. Publish konfigurasi:
```bash
php artisan vendor:publish --provider="Barryvdh\Cors\ServiceProvider"
```

### C. Update file `config/cors.php`:
Ganti SELURUH isi file `config/cors.php` dengan:

```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],  // Untuk development
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

### D. Tambahkan middleware di `app/Http/Kernel.php`:
Di bagian `$middleware`, tambahkan:
```php
\Barryvdh\Cors\HandleCors::class,
```

Contoh lengkap bagian `$middleware`:
```php
protected $middleware = [
    // ... middleware lainnya
    \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
    \App\Http\Middleware\TrimStrings::class,
    \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    \Barryvdh\Cors\HandleCors::class,  // Tambahkan ini
];
```

### E. Restart Laravel server:
```bash
php artisan serve
```

## Langkah 4: Jalankan Flutter App
Dari folder Flutter kamu:
```bash
flutter pub get
flutter run -d chrome
```

## Langkah 5: Akses Halaman Campaign dari API
Setelah Flutter app berjalan di Chrome, akses URL:
```
/api_campaigns
```

## Jika Masih Bermasalah: Gunakan Debug Screen
Akses di browser kamu:
```
/debug
```

Lalu klik tombol "Mulai Debug Koneksi" untuk pengecekan otomatis.

## Alternatif: Test Manual
Jika ingin test manual, akses:
```
/manual_test
```

Lalu masukkan URL: `http://127.0.0.1:8000/api/campaigns`

## Penting!
- Restart Laravel server setelah mengubah konfigurasi CORS
- Restart Flutter app setelah mengubah konfigurasi API
- Pastikan tidak ada aplikasi lain yang menggunakan port 8000

## Solusi Cepat (Jika Semua Langkah di Atas Gagal)
Jalankan Chrome tanpa keamanan CORS (HANYA UNTUK DEVELOPMENT):
```bash
# Windows
chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security

# Mac
open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_session" --disable-web-security

# Linux
google-chrome --disable-web-security --user-data-dir="/tmp/chrome_dev_session"
```

Ikuti langkah 1-3 terlebih dahulu sebelum menggunakan solusi alternatif.