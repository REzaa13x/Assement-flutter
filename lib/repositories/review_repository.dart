import 'dart:convert';
import '../models/review_model.dart';
import 'package:http/http.dart' as http;
import '../models/testimonial_review.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ReviewRepository {
  static Future<http.Response> _safeSend(
      Future<http.Response> Function() send) async {
    try {
      final response = await send();
      if (json.decode(response.body) is! Map) {
        throw const FormatException('Respons ulasan tidak valid');
      }
      return response;
    } catch (_) {
      return http.Response(
          json.encode({
            'message':
                'Tidak dapat memastikan perubahan ulasan. Muat ulang daftar sebelum mencoba lagi.',
          }),
          503);
    }
  }

  /// Mengambil daftar ulasan dari API Laravel beserta rating summary.
  /// Menjamin ulasan yang ditampilkan adalah data nyata dari database.
  static Future<ReviewListResponse> getReviewListResponse({
    String? activityType,
    int? activityId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      String endpoint = 'v1/reviews?page=$page&per_page=$perPage';
      if (activityType != null &&
          activityType.isNotEmpty &&
          activityType != 'all') {
        endpoint += '&activity_type=${Uri.encodeQueryComponent(activityType)}';
      }
      if (activityId != null && activityId > 0) {
        endpoint += '&activity_id=$activityId';
      }

      final response =
          await ApiService.get(endpoint, token: await AuthService.getToken());

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final summaryJson = decoded['summary'] is Map<String, dynamic>
              ? decoded['summary'] as Map<String, dynamic>
              : <String, dynamic>{};
          final summary = ReviewSummary.fromJson(summaryJson);

          final rawList =
              decoded['data'] is List ? decoded['data'] as List : [];
          final reviews = rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => ReviewItem.fromJson(item))
              .toList();

          return ReviewListResponse(
            reviews: reviews,
            summary: summary,
          );
        }
      }
    } catch (e) {
      rethrow;
    }

    throw Exception('Gagal memuat ulasan dari server');
  }

  /// Backward-compatible method untuk home_page:
  /// Mengambil daftar ulasan nyata dari database jika tersedia.
  static Future<List<TestimonialReview>> getReviews({
    String? activityType,
    int? activityId,
  }) async {
    try {
      final res = await getReviewListResponse(
        activityType: activityType,
        activityId: activityId,
        perPage: 10,
      );

      if (res.reviews.isNotEmpty) {
        return res.reviews
            .map((r) => TestimonialReview(
                  id: r.id,
                  name: r.userName,
                  role: r.activityType == 'volunteer'
                      ? 'Relawan Terverifikasi'
                      : 'Donatur Terverifikasi',
                  content: r.comment,
                  avatarUrl: r.userAvatar,
                  rating: r.rating.toDouble(),
                  isSample: false,
                  campaignTitle: r.campaignTitle,
                  activityType: r.activityType,
                  isVerified: r.isVerified,
                  createdAtFormatted: r.createdAtFormatted,
                ))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// Memeriksa kelayakan pengguna untuk memberikan ulasan (Protected).
  /// Mengembalikan daftar aktivitas donasi (VERIFIED) dan relawan (approved) yang telah selesai.
  static Future<ReviewEligibilityResult> getEligibility({
    required String token,
  }) async {
    try {
      final response = await ApiService.get(
        'v1/reviews/eligibility',
        token: token,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ReviewEligibilityResult.fromJson(decoded);
        }
      }
    } catch (e) {
      rethrow;
    }

    throw Exception('Gagal memeriksa aktivitas untuk ulasan');
  }

  /// Mengirimkan ulasan dan rating baru (Protected).
  /// Divalidasi secara ketat oleh backend Laravel berdasarkan status aktivitas.
  static Future<Map<String, dynamic>> submitReview({
    required String token,
    required String activityType,
    required int activityId,
    required int referenceId,
    required int rating,
    required String comment,
    bool isAnonymous = false,
  }) async {
    final payload = {
      'activity_type': activityType,
      'activity_id': activityId,
      'reference_id': referenceId,
      'rating': rating,
      'comment': comment.trim(),
      'is_anonymous': isAnonymous,
    };

    final response = await _safeSend(() => ApiService.post(
          'v1/reviews',
          payload,
          token: token,
        ));

    final decoded = json.decode(response.body);
    final String message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : (response.statusCode == 201
            ? 'Ulasan berhasil dikirim.'
            : 'Gagal mengirim ulasan.');

    return {
      'success': response.statusCode == 201,
      'statusCode': response.statusCode,
      'message': message,
      'data': decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : null,
    };
  }

  /// Memperbarui ulasan yang sudah pernah dibuat oleh pengguna (Protected).
  static Future<Map<String, dynamic>> updateReview({
    required String token,
    required int reviewId,
    required int rating,
    required String comment,
    bool? isAnonymous,
  }) async {
    final payload = {
      'rating': rating,
      'comment': comment.trim(),
      if (isAnonymous != null) 'is_anonymous': isAnonymous,
    };

    final response = await _safeSend(() => ApiService.put(
          'v1/reviews/$reviewId',
          payload,
          token: token,
        ));

    final decoded = json.decode(response.body);
    final String message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : (response.statusCode == 200
            ? 'Ulasan berhasil diperbarui.'
            : 'Gagal memperbarui ulasan.');

    return {
      'success': response.statusCode == 200,
      'statusCode': response.statusCode,
      'message': message,
      'data': decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : null,
    };
  }

  /// Menghapus ulasan milik pengguna (Protected).
  static Future<Map<String, dynamic>> deleteReview({
    required String token,
    required int reviewId,
  }) async {
    final response = await _safeSend(() => ApiService.delete(
          'v1/reviews/$reviewId',
          token: token,
        ));

    final decoded = json.decode(response.body);
    final String message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : (response.statusCode == 200
            ? 'Ulasan berhasil dihapus.'
            : 'Gagal menghapus ulasan.');

    return {
      'success': response.statusCode == 200,
      'statusCode': response.statusCode,
      'message': message,
    };
  }
}
