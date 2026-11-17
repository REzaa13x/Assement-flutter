// Smoke test untuk halaman login: memastikan form login tampil dan
// validasi bekerja sebelum request dikirim ke server.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/pages/login_page.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/': (context) => const Scaffold(body: Text('HOME')),
          '/register': (context) => const Scaffold(body: Text('REGISTER')),
        },
      ),
    );
  }

  testWidgets('halaman login menampilkan form email dan password',
      (WidgetTester tester) async {
    await pumpLogin(tester);

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('login tanpa mengisi form menampilkan error validasi',
      (WidgetTester tester) async {
    await pumpLogin(tester);

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets(
      'password pendek tetap diterima form login (validasi >=8 hanya di register)',
      (WidgetTester tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'user@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'abc');
    // Check the form locally; no real API request is needed for validation.
    expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
    await tester.pump();

    // Tidak boleh ada pesan "Password minimal 8 karakter" di halaman login
    expect(find.text('Password minimal 8 karakter'), findsNothing);
    expect(find.text('Password wajib diisi'), findsNothing);
  });
}
