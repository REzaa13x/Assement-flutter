import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Menyimpan token autentikasi
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Mendapatkan token autentikasi
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Menghapus token (saat logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await ProfileService.clearUserProfile();
  }

  // Menyimpan data pengguna (dalam format JSON agar bisa dibaca kembali)
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Mendapatkan data pengguna
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);

    if (userDataString != null && userDataString.isNotEmpty) {
      try {
        final decoded = jsonDecode(userDataString);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        // Data lama tersimpan sebagai Map.toString(), bukan JSON
        print('Gagal parse data pengguna: $e');
      }
      return null;
    }
    return null;
  }

  // Mengecek apakah pengguna sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
