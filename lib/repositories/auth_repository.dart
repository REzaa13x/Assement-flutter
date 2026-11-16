import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

class AuthRepository {
  // Register user
  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? birthDate,
  }) async {
    try {
      final response = await ApiService.post('v1/register', {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null) 'phone': phone,
        if (birthDate != null) 'birth_date': birthDate,
      });

      print('Register response status: ${response.statusCode}');
      print('Register response body length: ${response.body.length}');
      print('Register response body preview: ${response.body.substring(0, min(response.body.length, 500))}...');

      if (response.statusCode == 201) {
        // Ambil respons dan bersihkan karakter tambahan
        String responseBody = response.body;

        // Cari objek JSON utama di dalam respons
        int startIndex = responseBody.indexOf('{');
        int endIndex = responseBody.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
          String jsonString = responseBody.substring(startIndex, endIndex + 1);

          try {
            final jsonData = json.decode(jsonString);
            return AuthResponse.fromJson(jsonData);
          } catch (jsonError) {
            print('JSON parsing error: $jsonError');
            print('Attempted to parse: $jsonString');
            throw Exception('Invalid JSON format after extraction');
          }
        } else {
          throw Exception('No valid JSON object found in response');
        }
      } else {
        // Ambil respons dan bersihkan karakter tambahan untuk error response
        String responseBody = response.body;

        // Cari objek JSON utama di dalam respons
        int startIndex = responseBody.indexOf('{');
        int endIndex = responseBody.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
          String jsonString = responseBody.substring(startIndex, endIndex + 1);

          try {
            final jsonData = json.decode(jsonString);
            return AuthResponse(
              success: false,
              message: jsonData['message'],
              errors: jsonData['errors'] as Map<String, dynamic>?,
            );
          } catch (jsonError) {
            print('JSON parsing error for error response: $jsonError');
            print('Attempted to parse: $jsonString');
            throw Exception('Invalid JSON format after extraction');
          }
        } else {
          throw Exception('No valid JSON object found in error response');
        }
      }
    } catch (e) {
      print('Error in register: $e');
      return AuthResponse(
        success: false,
        message: 'Error registering user: $e',
      );
    }
  }

  // Login user
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      // Gunakan endpoint yang tidak memiliki masalah middleware
      final response = await ApiService.post('v1/login', {
        'email': email,
        'password': password,
      });

      print('Login response status: ${response.statusCode}');
      print('Login response body length: ${response.body.length}');
      print('Login response body preview: ${response.body.substring(0, min(response.body.length, 500))}...');

      if (response.statusCode == 200) {
        // Coba parsing langsung karena sekarang menggunakan endpoint yang benar
        try {
          final jsonData = json.decode(response.body);
          final authResponse = AuthResponse.fromJson(jsonData);

          // Simpan informasi pengguna ke local storage jika login berhasil
          if (authResponse.success && authResponse.user != null) {
            await ProfileService.saveUserProfile(authResponse.user!);
          }

          return authResponse;
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      } else {
        // Untuk error response juga parsing langsung
        try {
          final jsonData = json.decode(response.body);
          return AuthResponse(
            success: false,
            message: jsonData['message'],
            errors: jsonData['errors'] as Map<String, dynamic>?,
          );
        } catch (jsonError) {
          print('JSON parsing error for error response: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      }
    } catch (e) {
      print('Error in login: $e');
      return AuthResponse(
        success: false,
        message: 'Error logging in: $e',
      );
    }
  }

  // Logout user
  static Future<bool> logout({required String? token}) async {
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await ApiService.post('v1/logout', {}, token: token);

      return response.statusCode == 200;
    } catch (e) {
      print('Error in logout: $e');
      return false;
    }
  }

  // Get current user profile
  static Future<AuthResponse> getCurrentUser({required String? token}) async {
    if (token == null || token.isEmpty) {
      return AuthResponse(
        success: false,
        message: 'Authentication token is required',
      );
    }

    try {
      final response = await ApiService.get('v1/me', token: token);

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return AuthResponse.fromJson(jsonData);
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      } else if (response.statusCode == 401) {
        return AuthResponse(
          success: false,
          message: 'Unauthorized: Invalid or expired token',
        );
      } else {
        try {
          final jsonData = json.decode(response.body);
          return AuthResponse(
            success: false,
            message: jsonData['message'] ?? 'Error getting user profile',
          );
        } catch (jsonError) {
          print('JSON parsing error for error response: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      return AuthResponse(
        success: false,
        message: 'Error getting user profile: $e',
      );
    }
  }

  // Refresh token
  static Future<AuthResponse> refreshToken({required String? token}) async {
    if (token == null || token.isEmpty) {
      return AuthResponse(
        success: false,
        message: 'Authentication token is required',
      );
    }

    try {
      final response = await ApiService.post('v1/refresh', {}, token: token);

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return AuthResponse.fromJson(jsonData);
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      } else {
        try {
          final jsonData = json.decode(response.body);
          return AuthResponse(
            success: false,
            message: jsonData['message'],
          );
        } catch (jsonError) {
          print('JSON parsing error for error response: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      }
    } catch (e) {
      print('Error in refreshToken: $e');
      return AuthResponse(
        success: false,
        message: 'Error refreshing token: $e',
      );
    }
  }
}

class ProfileRepository {
  // Get user profile
  static Future<ProfileResponse> getProfile({required String? token}) async {
    if (token == null || token.isEmpty) {
      return ProfileResponse(
        message: 'Authentication token is required',
      );
    }

    try {
      // Coba endpoint utama dulu
      print('Making request to: v1/profile with token: ${token.substring(0, 10)}...');
      final response = await ApiService.get('v1/profile', token: token);

      print('Profile response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Profile response body: ${response.body}');
        final jsonData = json.decode(response.body);
        return ProfileResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        return ProfileResponse(
          message: 'Unauthorized: Invalid or expired token',
        );
      } else {
        // Coba parsing error response
        try {
          final jsonData = json.decode(response.body);
          return ProfileResponse(
            message: jsonData['message'] ?? 'Error getting profile',
          );
        } catch (jsonError) {
          print('JSON parsing error for error response: $jsonError');
          print('Full response body: ${response.body}');
          throw Exception('Invalid JSON response format');
        }
      }
    } catch (e) {
      print('Error in getProfile: $e');
      // Jika endpoint utama gagal, coba endpoint alternatif
      try {
        // Coba endpoint me sebagai alternatif
        final response = await ApiService.get('v1/me', token: token);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          // Konversi dari response /me ke format profile
          return ProfileResponse(
            message: 'User profile retrieved successfully',
            data: UserProfile(
              id: jsonData['user']['id'],
              name: jsonData['user']['name'],
              email: jsonData['user']['email'],
              role: jsonData['user']['role'],
              coins: jsonData['user']['coins'],
              photo: jsonData['user']['photo'],
              phone: jsonData['user']['phone'],
              birthDate: jsonData['user']['birth_date'],
            ),
          );
        } else {
          throw Exception('Failed to load profile from alternative endpoint');
        }
      } catch (altError) {
        print('Alternative endpoint also failed: $altError');
        // Jika semua endpoint gagal, kembalikan dari local storage
        final localProfile = await ProfileService.getUserProfile();
        if (localProfile != null) {
          return ProfileResponse(
            message: 'User profile retrieved from local storage due to server issues',
            data: localProfile,
          );
        } else {
          return ProfileResponse(
            message: 'Could not retrieve profile: $e',
          );
        }
      }
    }
  }

  // Update user profile
  static Future<ProfileResponse> updateProfile({
    required String? token,
    String? name,
    String? email,
    String? phone,
    String? birthDate,
    String? address,  // Menambahkan parameter address
    String? password,
    String? currentPassword,
  }) async {
    if (token == null || token.isEmpty) {
      return ProfileResponse(
        message: 'Authentication token is required',
      );
    }

    try {
      // Coba update ke server dulu
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (birthDate != null) updateData['birth_date'] = birthDate;
      if (address != null) updateData['address'] = address;  // Menambahkan parameter address
      if (password != null) {
        updateData['password'] = password;
        if (currentPassword != null) updateData['current_password'] = currentPassword;
      }

      print('Making request to update profile on server...');
      final response = await ApiService.put('v1/profile', updateData, token: token);

      print('Update profile response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Update profile response body: ${response.body}');
        final jsonData = json.decode(response.body);
        final updatedUser = UserProfile.fromJson(jsonData['data']);

        // Simpan juga ke local storage - buat User dari UserProfile
        await ProfileService.saveUserProfile(User(
          id: updatedUser.id,
          name: updatedUser.name,
          email: updatedUser.email,
          role: updatedUser.role,
          coins: updatedUser.coins,
          photo: updatedUser.photo,
          phone: updatedUser.phone,
          birthDate: updatedUser.birthDate,
          createdAt: updatedUser.createdAt,
          updatedAt: updatedUser.updatedAt,
        ));

        return ProfileResponse(
          message: 'Profile updated successfully',
          data: updatedUser,
        );
      } else {
        // Jika server gagal (mungkin karena CORS), update lokal saja
        print('Server update failed: ${response.statusCode}, updating locally...');

        final currentUser = await ProfileService.getUserProfile();
        if (currentUser != null) {
          final updatedUser = UserProfile(
            id: currentUser.id,
            name: name ?? currentUser.name,
            email: email ?? currentUser.email,
            role: currentUser.role,
            coins: currentUser.coins,
            photo: currentUser.photo,
            phone: phone ?? currentUser.phone ?? '',
            birthDate: birthDate ?? currentUser.birthDate,
          );

          await _updateLocalProfile(updatedUser);

          return ProfileResponse(
            message: 'Profile updated locally. Server update failed.',
            data: updatedUser,
          );
        } else {
          throw Exception('No existing user profile found to update');
        }
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      // Jika server error, coba update lokal saja
      try {
        final currentUser = await ProfileService.getUserProfile();
        if (currentUser != null) {
          final updatedUser = UserProfile(
            id: currentUser.id,
            name: name ?? currentUser.name,
            email: email ?? currentUser.email,
            role: currentUser.role,
            coins: currentUser.coins,
            photo: currentUser.photo,
            phone: phone ?? currentUser.phone ?? '',
            birthDate: birthDate ?? currentUser.birthDate,
            address: address ?? currentUser.address,  // Menambahkan parameter address
          );

          await ProfileService.saveUserProfile(User(
            id: updatedUser.id,
            name: updatedUser.name,
            email: updatedUser.email,
            role: updatedUser.role,
            coins: updatedUser.coins,
            photo: updatedUser.photo,
            phone: updatedUser.phone,
            birthDate: updatedUser.birthDate,
            address: updatedUser.address,  // Menambahkan parameter address ke User
            createdAt: updatedUser.createdAt,
            updatedAt: updatedUser.updatedAt,
          ));

          return ProfileResponse(
            message: 'Profile updated locally due to server error.',
            data: updatedUser,
          );
        } else {
          throw Exception('No existing user profile found to update');
        }
      } catch (localError) {
        print('Local update also failed: $localError');
        throw Exception('Error updating profile: $e');
      }
    }
  }

  // Fungsi bantu untuk memperbarui profile di local storage
  static Future<void> _updateLocalProfile(UserProfile updatedUser) async {
    // Kita simpan informasi yang diperbarui ke dalam local storage
    // Dalam implementasi sebenarnya, kamu bisa menyimpan ke shared preferences sebagai map
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': updatedUser.id,
      'name': updatedUser.name,
      'email': updatedUser.email,
      'role': updatedUser.role,
      'coins': updatedUser.coins,
      'photo': updatedUser.photo,
      'phone': updatedUser.phone,
      'birth_date': updatedUser.birthDate,
      'address': updatedUser.address,  // Menambahkan field address ke local storage
    };
    await prefs.setString('user_profile', json.encode(userData));
  }

  // Get donation history
  static Future<http.Response> getDonationHistory({required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required');
    }

    try {
      return await ApiService.get('v1/donations', token: token);
    } catch (e) {
      print('Error in getDonationHistory: $e');
      rethrow;
    }
  }

  // Get volunteer history
  static Future<http.Response> getVolunteerHistory({required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required');
    }

    try {
      return await ApiService.get('v1/profile/volunteer', token: token);
    } catch (e) {
      print('Error in getVolunteerHistory: $e');
      rethrow;
    }
  }

  // Get complete history
  static Future<http.Response> getCompleteHistory({required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required');
    }

    try {
      return await ApiService.get('v1/profile/history', token: token);
    } catch (e) {
      print('Error in getCompleteHistory: $e');
      rethrow;
    }
  }

  // Get user stats
  static Future<http.Response> getStats({required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required');
    }

    try {
      return await ApiService.get('v1/profile/stats', token: token);
    } catch (e) {
      print('Error in getStats: $e');
      rethrow;
    }
  }
}