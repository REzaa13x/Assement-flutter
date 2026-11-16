class AppConfig {
  // Update this URL to match your Laravel API address
  // For same laptop:
  // - Android emulator: http://10.0.2.2:8000
  // - iOS simulator: http://localhost:8000
  // - Chrome browser: http://127.0.0.1:8000
  // - Real device: http://YOUR_COMPUTER_IP:8000

  static const String apiUrl = 'http://127.0.0.1:8000/api'; // For Chrome browser (Laravel: php artisan serve)
  // static const String apiUrl = 'http://10.0.2.2:8000/api'; // For Android emulator
  // static const String apiUrl = 'http://localhost:8000/api'; // For iOS simulator
  // static const String apiUrl = 'http://192.168.1.100:8000/api'; // Replace with your actual IP
  // static const String apiUrl = 'https://dongiv.kolab.top/api'; // Production server (domain sudah tidak aktif / DNS tidak ditemukan)

  // How to find your IP address:
  // Windows: Open Command Prompt and type 'ipconfig', look for IPv4 address
  // Mac/Linux: Open Terminal and type 'ifconfig' or 'ip addr', look for inet address
}