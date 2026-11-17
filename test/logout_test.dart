import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/pages/profile_page.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({
        'auth_token': 'old-token',
        'user_data': '{"id":1,"name":"Old user"}',
        'user_profile': '{"id":1,"name":"Old user","email":"old@example.test"}',
        'unrelated_preference': 'keep',
      }));

  Future<void> expectCleared() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['auth_token', 'user_data', 'user_profile']) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(await AuthService.isLoggedIn(), isFalse);
    expect(prefs.getString('unrelated_preference'), 'keep');
  }

  for (final code in [200, 204, 401, 500]) {
    test('logout clears all local session data on HTTP $code', () async {
      await http.runWithClient(() async {
        expect(await AuthRepository.logout(token: 'old-token'), code != 500);
        await expectCleared();
      },
          () => MockClient((request) async {
                expect(request.method, 'POST');
                expect(request.url.path, '/api/v1/logout');
                expect(request.headers['Authorization'], 'Bearer old-token');
                return http.Response('', code);
              }));
    });
  }
  test('logout clears session when network fails', () async {
    await http.runWithClient(() async {
      expect(await AuthRepository.logout(token: 'old-token'), isFalse);
      await expectCleared();
    }, () => MockClient((_) async => throw http.ClientException('offline')));
  });
  test('logout without token still clears stale profile without a request',
      () async {
    await http.runWithClient(() async {
      expect(await AuthRepository.logout(token: null), isTrue);
      await expectCleared();
    }, () => MockClient((_) async => throw StateError('Unexpected request')));
  });

  testWidgets('logout works from profile error and removes navigation history',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
    final response = Completer<http.Response>();
    var count = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(initialRoute: '/profile', routes: {
        '/': (_) => const Scaffold(body: Text('HOME')),
        '/profile': (_) => const ProfilePage(),
        '/login': (_) => const Scaffold(body: Text('LOGIN')),
      }));
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat profil'), findsOneWidget);
      await tester.tap(find.text('Keluar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sedang keluar...'), findsOneWidget);
      await tester.tap(find.text('Sedang keluar...'));
      await tester.pump();
      expect(count, 1);
      response.complete(http.Response('', 401));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
      expect(
          Navigator.of(tester.element(find.text('LOGIN'))).canPop(), isFalse);
      await expectCleared();
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/logout')) {
                count++;
                return response.future;
              }
              return http.Response('{"message":"Unavailable"}', 500);
            }));
  });

  testWidgets('unresponsive logout request has a bounded wait', (tester) async {
    await http.runWithClient(() async {
      final result = AuthRepository.logout(token: 'old-token');
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(await result, isFalse);
      await expectCleared();
    }, () => MockClient((_) => Completer<http.Response>().future));
  });
}
