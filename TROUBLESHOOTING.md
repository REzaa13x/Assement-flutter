# Panduan Troubleshooting Koneksi API Laravel-Flutter

## Masalah Umum dan Solusi

### 1. Cek Laravel Server Berjalan
Pastikan server Laravel kamu benar-benar berjalan:
```bash
php artisan serve
```

Harus muncul output seperti:
```
Starting Laravel development server: http://127.0.0.1:8000
```

### 2. Cek Akses API dari Browser
Buka browser dan kunjungi:
- http://127.0.0.1:8000/api/campaigns
- http://127.0.0.1:8000/api/campaigns/1

Jika muncul JSON response, berarti API kamu berjalan dengan baik.

### 3. Cek CORS (Cross-Origin Resource Sharing)
Ini adalah masalah utama saat menggunakan Flutter Web dengan Chrome.

**Langkah-langkah mengatasi CORS:**

#### A. Install package CORS di Laravel:
```bash
composer require barryvdh/laravel-cors
```

#### B. Publish konfigurasi CORS:
```bash
php artisan vendor:publish --provider="Barryvdh\Cors\ServiceProvider"
```

#### C. Update file `config/cors.php`:
```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],  // Untuk development, nanti di production harus spesifik
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

#### D. Tambahkan middleware di `app/Http/Kernel.php`:
Tambahkan di bagian `$middleware`:
```php
protected $middleware = [
    // ... middleware lainnya
    \Barryvdh\Cors\HandleCors::class,
];
```

#### E. Restart Laravel server:
```bash
php artisan serve
```

### 4. Cek Alamat IP
Kadang-kadang `127.0.0.1` tidak bekerja di semua sistem. Coba:

#### Di command prompt/terminal, jalankan:
```bash
ipconfig  # Windows
# atau
ifconfig  # Mac/Linux
```

Cari alamat IP kamu (biasanya dimulai dengan 192.168.x.x) dan ganti di file `lib/config/app_config.dart`:
```dart
static const String apiUrl = 'http://192.168.x.x:8000/api'; // Ganti x.x dengan IP kamu
```

### 5. Jalankan Debug Screen
Flutter app ini memiliki debug screen khusus. Akses dengan route:
```
/debug
```

Ini akan:
- Mengecek apakah server Laravel berjalan
- Mencoba berbagai kemungkinan URL
- Memberikan instruksi untuk mengatasi CORS

### 6. Solusi Alternatif untuk Chrome
Jika CORS tetap bermasalah, kamu bisa jalankan Chrome tanpa keamanan (HANYA UNTUK DEVELOPMENT):
```bash
# Windows
chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security

# Mac
open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_session" --disable-web-security

# Linux
google-chrome --disable-web-security --user-data-dir="/tmp/chrome_dev_session"
```

### 7. Pastikan Semua Package Terinstall
Di Flutter project kamu, pastikan semua dependencies terinstall:
```bash
flutter pub get
```

## Urutan Troubleshooting yang Disarankan

1. Jalankan `php artisan serve` di Laravel
2. Cek API bisa diakses di browser
3. Install dan setup CORS di Laravel
4. Gunakan debug screen di Flutter: `/debug`
5. Jika masih gagal, coba jalankan Chrome tanpa keamanan
6. Cek kembali file `lib/config/app_config.dart`

## Route yang Tersedia di Flutter

- `/api_campaigns` - Menampilkan campaign dari Laravel API
- `/api_test` - Test koneksi API
- `/debug` - Debug screen untuk troubleshoot koneksi

## Contoh Error Umum dan Artinya

- `Failed to fetch` - Biasanya masalah CORS
- `Connection refused` - Server Laravel tidak berjalan
- `Network request failed` - URL salah atau server tidak bisa diakses
- `Access to XMLHttpRequest at ... has been blocked by CORS policy` - Harus setup CORS di Laravel

Lakukan langkah-langkah di atas secara berurutan, dan koneksi API kamu seharusnya berhasil.