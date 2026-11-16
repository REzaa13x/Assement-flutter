import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/chatbot_message.dart';

class ChatbotRepository {
  /// Mengirim pesan ke endpoint chatbot Laravel
  static Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    final token = await AuthService.getToken();
    final bodyData = {'message': userMessage};

    dynamic response;
    try {
      // 1. Coba endpoint standar v1/chatbot/message
      response = await ApiService.post('v1/chatbot/message', bodyData, token: token);
      if (response.statusCode == 404) {
        // Fallback ke /chatbot/message jika dipanggil tanpa v1 prefix
        response = await ApiService.post('chatbot/message', bodyData, token: token);
      }
    } catch (e) {
      debugPrint('[ChatbotRepository] Network error: $e');
      rethrow;
    }

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final replyText = decoded['reply']?.toString() ?? 'Tidak ada jawaban.';
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
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}
