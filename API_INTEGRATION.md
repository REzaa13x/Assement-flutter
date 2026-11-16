# Laravel API Integration Guide

This document explains how to connect your Flutter app to your Laravel API running on localhost on the same laptop.

## Setup Instructions

### 1. Configure API URL

Update the API URL in `lib/config/app_config.dart` to match your Laravel server:

```dart
class AppConfig {
  // For production server
  static const String apiUrl = 'https://dongiv.kolab.top/api';

  // For Android emulator (most common case)
  // static const String apiUrl = 'http://10.0.2.2:8000/api';

  // For iOS simulator
  // static const String apiUrl = 'http://localhost:8000/api';

  // For real device connected to same WiFi network
  // static const String apiUrl = 'http://YOUR_COMPUTER_IP:8000/api';
}
```

### 2. Find Your IP Address

To connect from a real device on the same network:

**Windows:**
- Open Command Prompt
- Type `ipconfig`
- Look for "IPv4 Address" under your active network connection (usually starts with 192.168.x.x)

**Mac/Linux:**
- Open Terminal
- Type `ifconfig` or `ip addr`
- Look for inet address under your active network interface

### 3. Start Your Laravel Server

From your Laravel project directory:

```bash
php artisan serve
```

This will start your Laravel server, typically on http://127.0.0.1:8000

### 4. Update Network Security (Android)

The network security configuration has been added to allow HTTP connections to localhost. If you encounter issues, make sure the `network_security_config.xml` file includes your IP address.

## Available API Endpoints

### Campaigns
- `GET /campaigns` - Get all campaigns with pagination, filtering by status, kategori, and search
- `GET /campaigns/{id}` - Get a specific campaign by ID or slug
- `POST /campaigns` - Create a new campaign
- `PUT /campaigns/{id}` - Update a campaign by ID or slug
- `DELETE /campaigns/{id}` - Delete a campaign by ID or slug
- `GET /campaigns/urgent` - Get urgent campaigns

### Example Usage

```dart
// Get all campaigns
final response = await CampaignRepository.getCampaigns();
print('Found ${response.data.length} campaigns');

// Get campaigns with filters
final filteredResponse = await CampaignRepository.getCampaigns(
  status: 'Active',
  kategori: 'Lingkungan',
  search: 'bencana'
);

// Get a single campaign
final campaign = await CampaignRepository.getCampaign('1');

// Create a new campaign
final newCampaign = await CampaignRepository.createCampaign(
  title: 'New Campaign',
  description: 'Campaign description',
  targetAmount: 1000000,
  endDate: '2023-12-31',
  kategori: 'Lingkungan'
);
```

## Testing the Connection

1. Make sure your Laravel server is running (`php artisan serve`)
2. Update the API URL in `app_config.dart` to match your setup
3. Run your Flutter app
4. Navigate to the Campaigns page (route: `/api_campaigns`)

## Troubleshooting

### Common Issues:

1. **Connection refused:** Make sure Laravel server is running with `php artisan serve`
2. **Network security error:** Ensure the network_security_config.xml includes your IP address
3. **CORS issues:** Make sure your Laravel app has CORS enabled (install `barryvdh/laravel-cors` if needed) - **This is especially critical for Chrome**
4. **IP address not working:** Try different IP addresses (10.0.2.2, 127.0.0.1, your actual IP)

### For CORS in Laravel (especially important for Chrome):
```bash
composer require barryvdh/laravel-cors
php artisan vendor:publish --provider="Barryvdh\Cors\ServiceProvider"
```

Then update your `config/cors.php`:
```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],  // For development only, specify exact domains in production
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

For development purposes, you can also temporarily disable CORS in Laravel by adding this middleware to your `app/Http/Kernel.php` in the `$middleware` array:
```php
\Barryvdh\Cors\HandleCors::class,
```

### For Flutter Web (Chrome) specific issues:
If you're still having issues with Chrome, you can run Chrome with disabled security (only for development):
```bash
# On Windows:
chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security

# On Mac:
open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_session" --disable-web-security

# On Linux:
google-chrome --disable-web-security --user-data-dir="/tmp/chrome_dev_session"
```

### Debugging Steps:
1. Use the debug screen in the app (access via `/debug` route) to check connection
2. Verify your Laravel API is accessible in browser at `http://127.0.0.1:8000/api/campaigns`
3. Check the Troubleshooting guide in TROUBLESHOOTING.md for detailed steps
4. Make sure to restart both Laravel server and Flutter app after making configuration changes

## Security Note

For production, make sure to:
1. Use HTTPS instead of HTTP
2. Implement proper authentication
3. Validate and sanitize all inputs
4. Use environment variables for API URLs