import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/repositories/chatbot_repository.dart';
import 'package:flutter_application_1/pages/assistant_chat_page.dart';
import 'package:flutter_application_1/models/chatbot_message.dart';

void main() {
  setUp(() =>
      SharedPreferences.setMockInitialValues({'auth_token': 'test-token'}));
  final reply = jsonEncode({
    'reply': 'Silakan unggah CV PDF maksimal 2 MB.',
    'used_ai': false,
    'data': {'donations': [], 'volunteers': []}
  });

  test('repository sends trimmed message and parses database recommendations',
      () async {
    await http.runWithClient(() async {
      final result = await ChatbotRepository.sendMessage('  Relawan Bandung  ');
      expect(result['reply'], 'Kegiatan tersedia');
      expect(
          (result['recommendations'] as List<ChatbotRecommendation>)
              .single
              .isVolunteer,
          isTrue);
    },
        () => MockClient((request) async {
              expect(request.url.path, '/api/v1/chatbot/message');
              expect(request.headers['Authorization'], 'Bearer test-token');
              expect(jsonDecode(request.body)['message'], 'Relawan Bandung');
              return http.Response(
                  jsonEncode({
                    'reply': 'Kegiatan tersedia',
                    'used_ai': false,
                    'data': {
                      'volunteers': [
                        {
                          'id': 1,
                          'type': 'volunteer',
                          'title': 'Bersih Sungai',
                          'category': 'Lingkungan',
                          'progress': 20
                        }
                      ],
                    }
                  }),
                  200);
            }));
  });
  test('invalid response and rate limit surface useful errors', () async {
    for (final code in [200, 429, 503]) {
      await http.runWithClient(() async {
        await expectLater(ChatbotRepository.sendMessage('Halo'),
            throwsA(isA<ChatbotException>()));
      },
          () => MockClient(
              (_) async => http.Response('<html>Error</html>', code)));
    }
  });
  test('legacy endpoint is only tried after a missing route', () async {
    var count = 0;
    await http.runWithClient(() async {
      expect((await ChatbotRepository.sendMessage('Halo'))['reply'],
          contains('PDF'));
      expect(count, 2);
    },
        () => MockClient((request) async {
              count++;
              if (count == 1) return http.Response('{}', 404);
              expect(request.url.path, '/api/chatbot/message');
              return http.Response(reply, 200);
            }));
  });
  test('empty message is rejected without a request', () async {
    await http.runWithClient(() async {
      await expectLater(ChatbotRepository.sendMessage('  '),
          throwsA(isA<ChatbotException>()));
    }, () => MockClient((_) async => throw StateError('Unexpected request')));
  });
  testWidgets('typed request receives reply and blocks duplicate sends',
      (tester) async {
    final response = Completer<http.Response>();
    var count = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AssistantChatPage()));
      await tester.enterText(find.byType(TextField), 'Cara daftar relawan');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.testTextInput.receiveAction(TextInputAction.send);
      expect(count, 1);
      response.complete(http.Response(reply, 200));
      await tester.pumpAndSettle();
      expect(find.text('Silakan unggah CV PDF maksimal 2 MB.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((_) async {
              count++;
              return response.future;
            }));
  });
  testWidgets('failed request preserves input for retry and shows actual error',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: AssistantChatPage()));
      await tester.enterText(find.byType(TextField), 'Cari relawan');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(find.textContaining('Pesan terlalu sering'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Cari relawan');
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response('{}', 429)));
  });
}
