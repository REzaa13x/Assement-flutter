import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/chatbot_message.dart';

class ChatbotException implements Exception {
  final String message;
  const ChatbotException(this.message);
  @override
  String toString() => message;
}

class ChatbotRepository {
  /// Mengirim pesan ke endpoint chatbot Laravel
  static Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    final message = userMessage.trim();
    if (message.isEmpty || message.runes.length > 1000) {
      throw const ChatbotException(
          'Pesan wajib diisi dan maksimal 1000 karakter.');
    }
    final token = await AuthService.getToken();
    final bodyData = {'message': message};

    dynamic response;
    try {
      // 1. Coba endpoint standar v1/chatbot/message
      response =
          await ApiService.post('v1/chatbot/message', bodyData, token: token);
      if (response.statusCode == 404) {
        // Fallback ke /chatbot/message jika dipanggil tanpa v1 prefix
        response =
            await ApiService.post('chatbot/message', bodyData, token: token);
      }
    } catch (e) {
      debugPrint('[ChatbotRepository] Network error: $e');
      throw const ChatbotException(
          'Assistant belum dapat dihubungi. Periksa koneksi, lalu kirim ulang pesan Anda.');
    }

    if (response.statusCode == 200) {
      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (_) {
        throw const ChatbotException(
            'Balasan Assistant tidak valid. Silakan kirim ulang pesan Anda.');
      }
      if (decoded is! Map ||
          decoded['reply'] is! String ||
          (decoded['reply'] as String).trim().isEmpty) {
        throw const ChatbotException(
            'Assistant belum memberikan jawaban. Silakan coba lagi.');
      }
      final replyText = (decoded['reply'] as String).trim();
      final bool usedAi = decoded['used_ai'] == true;

      final List<ChatbotRecommendation> recommendations = [];
      if (decoded['data'] is Map) {
        final dataMap = decoded['data'] as Map;
        // Donasi
        if (dataMap['donations'] is List) {
          for (var item in dataMap['donations']) {
            if (item is Map<String, dynamic>) {
              recommendations.add(ChatbotRecommendation.fromJson(item));
            }
          }
        }
        // Relawan
        if (dataMap['volunteers'] is List) {
          for (var item in dataMap['volunteers']) {
            if (item is Map<String, dynamic>) {
              recommendations.add(ChatbotRecommendation.fromJson(item));
            }
          }
        }
      }

      return {
        'reply': replyText,
        'used_ai': usedAi,
        'recommendations': recommendations,
      };
    } else {
      if (response.statusCode == 404) {
        throw const ChatbotException(
            'Layanan Assistant belum tersedia pada server. Silakan coba lagi nanti.');
      }
      if (response.statusCode == 401) {
        throw const ChatbotException(
            'Sesi login berakhir. Silakan login kembali.');
      }
      if (response.statusCode == 429) {
        throw const ChatbotException(
            'Pesan terlalu sering dikirim. Tunggu sebentar lalu coba lagi.');
      }
      if (response.statusCode == 422) {
        throw const ChatbotException(
            'Pesan tidak dapat diproses. Isi pesan maksimal 1000 karakter.');
      }
      throw const ChatbotException(
          'Assistant sedang mengalami gangguan. Silakan coba lagi.');
    }
  }
}
