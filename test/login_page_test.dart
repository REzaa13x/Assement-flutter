import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app() => MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginPage(),
          '/register': (_) => const Scaffold(body: Text('REGISTRATION')),
          '/': (_) => const Scaffold(body: Text('HOME')),
        },
      );

  Future<void> enterCredentials(WidgetTester tester) async {
    await tester.enterText(
        find.byType(TextFormField).first, 'sahabat@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pump();
  }

  for (final width in [280.0, 320.0, 412.0, 768.0]) {
    testWidgets(
        'login fits width $width with keyboard and scrolls to registration',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(app());
      expect(find.text('Selamat Datang Kembali'), findsOneWidget);
      expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.showKeyboard(find.byType(TextFormField).last);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Daftar sekarang'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar sekarang').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text remains scrollable without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: const LoginPage(),
    ));
    await tester.ensureVisible(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation, password visibility and registration still work',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak valid'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Tampilkan password'));
    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        false);
    await tester.tap(find.byTooltip('Sembunyikan password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText,
        true);
    await tester.ensureVisible(find.text('Daftar sekarang'));
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('REGISTRATION'), findsOneWidget);
  });

  testWidgets(
      'loading prevents repeat requests and successful login saves the token',
      (tester) async {
    final response = Completer<http.Response>();
    var requests = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await enterCredentials(tester);
      await tester.tap(find.text('Masuk'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(requests, 1);
      response.complete(http.Response(
          jsonEncode({
            'token': 'test-login-token',
            'user': {
              'id': 42,
              'name': 'Sahabat',
              'email': 'sahabat@example.com'
            },
          }),
          200));
      await tester.pumpAndSettle();
      expect(await AuthService.getToken(), 'test-login-token');
      expect((await AuthService.getUserData())?['id'], 42);
      expect(find.text('HOME'), findsOneWidget);
    },
        () => MockClient((request) {
              requests++;
              expect(request.url.path, '/api/v1/login');
              expect(request.method, 'POST');
              expect(jsonDecode(request.body),
                  {'email': 'sahabat@example.com', 'password': 'password123'});
              return response.future;
            }));
  });

  testWidgets('failed login shows the API error and allows retry',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(app());
      await enterCredentials(tester);
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Email atau password salah.'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
      expect(await AuthService.getToken(), isNull);
    },
        () => MockClient((_) async => http.Response(
              '{"message":"Invalid credentials","errors":{"email":["Email atau password salah."]}}',
              422,
            )));
  });
}
