import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth.dart';
import 'dart:convert';

class ProfileService {
  static const String _userKey = 'user_profile';

  // Simpan informasi pengguna setelah login
  static Future<void> saveUserProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'coins': user.coins,
      'photo': user.photo,
      'phone': user.phone,
      'birth_date': user.birthDate,
    };
    await prefs.setString(_userKey, json.encode(userData));
  }

  // Ambil informasi pengguna yang tersimpan
  static Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    
    if (userDataString != null) {
      final userData = json.decode(userDataString) as Map<String, dynamic>;
      
      return UserProfile(
        id: userData['id'],
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'],
        coins: userData['coins'],
        photo: userData['photo'],
        phone: userData['phone'],
        birthDate: userData['birth_date'],
      );
    }
    return null;
  }

  // Hapus informasi pengguna (saat logout)
  static Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}