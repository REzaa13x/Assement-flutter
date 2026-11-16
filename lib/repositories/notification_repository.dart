import 'dart:convert';
import '../models/app_notification.dart';
import '../services/api_service.dart';

/// Akses endpoint notifikasi & device token DonGiv.
///
/// Semua request selalu memakai token autentikasi milik user yang login,
/// sehingga tidak mungkin mengambil notifikasi milik user lain.
class NotificationRepository {
  /// Daftar riwayat notifikasi (berpagination dan filter kategori).
  static Future<List<AppNotification>> getNotifications({
    String? authToken,
    int page = 1,
    int perPage = 15,
    String? categoryFilter, // all | donasi | relawan | kampanye | sistem
  }) async {
    String endpoint = 'v1/notifications?page=$page&per_page=$perPage';
    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
      endpoint += '&filter=$categoryFilter';
    }

    final response = await ApiService.get(
      endpoint,
      token: authToken,
    );

    final body = _decode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> items = body['data'] is List ? body['data'] : [];
      return items
          .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw Exception(_messageOf(body) ?? 'Gagal memuat notifikasi');
  }

  /// Jumlah notifikasi yang belum dibaca.
  static Future<int> getUnreadCount({String? authToken}) async {
    final response = await ApiService.get(
      'v1/notifications/unread-count',
      token: authToken,
    );

    final body = _decode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];
      if (data is Map && data['unread_count'] is int) {
        return data['unread_count'] as int;
      }
      return 0;
    }

    throw Exception(_messageOf(body) ?? 'Gagal memuat jumlah notifikasi');
  }

  /// Tandai satu notifikasi sebagai sudah dibaca.
  static Future<bool> markAsRead({
    required String id,
    String? authToken,
  }) async {
    final response = await ApiService.put(
      'v1/notifications/$id/read',
      const {},
      token: authToken,
    );

    return response.statusCode == 200;
  }

  /// Tandai semua notifikasi sebagai sudah dibaca.
  static Future<bool> markAllAsRead({String? authToken}) async {
    final response = await ApiService.put(
      'v1/notifications/read-all',
      const {},
      token: authToken,
    );

    return response.statusCode == 200;
  }

  /// Simpan / perbarui token FCM perangkat untuk user yang login.
  static Future<bool> registerDeviceToken({
    required String authToken,
    required String fcmToken,
    required String platform,
    String? appVersion,
  }) async {
    final response = await ApiService.post(
      'v1/device-tokens',
      {
        'token': fcmToken,
        'platform': platform,
        if (appVersion != null) 'app_version': appVersion,
      },
      token: authToken,
    );

    return response.statusCode == 200;
  }

  /// Hapus token perangkat (dipanggil saat logout).
  static Future<bool> removeDeviceToken({
    required String authToken,
    required String fcmToken,
  }) async {
    final response = await ApiService.delete(
      'v1/device-tokens',
      token: authToken,
      data: {'token': fcmToken},
    );

    return response.statusCode == 200;
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String? _messageOf(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty && message != 'Validation failed') {
      return message;
    }
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      return errors.values.first.toString();
    }
    return null;
  }
}
