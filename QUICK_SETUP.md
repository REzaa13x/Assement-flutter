# QUICK SETUP GUIDE

## 1. LARAVEL SETUP (PENTING!)
Di folder Laravel kamu, jalankan perintah berikut:

```bash
composer require barryvdh/laravel-cors
php artisan vendor:publish --provider="Barryvdh\Cors\ServiceProvider"
```

Edit file `config/cors.php`:
```php
<?php
return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

Tambahkan ke `app/Http/Kernel.php` di bagian `$middleware`:
```php
\Barryvdh\Cors\HandleCors::class,
```

Restart Laravel:
```bash
php artisan serve
```

## 2. FLUTTER SETUP
Di folder Flutter, jalankan:
```bash
flutter pub get
flutter run -d chrome
```

## 3. TEST CONNECTION
Akses di Chrome: `/debug` dan klik "Mulai Debug Koneksi"

## 4. LIHAT CAMPAIGNS
Akses di Chrome: `/api_campaigns`

## JIKA MASIH GAGAL
Coba URL alternatif di `/manual_test`:
- http://localhost:8000/api/campaigns
- http://10.0.2.2:8000/api/campaigns
- Ganti 127.0.0.1 dengan IP kamu sebenarnya

Pastikan Laravel server tetap berjalan di http://127.0.0.1:8000