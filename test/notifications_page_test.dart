// Test halaman riwayat notifikasi DonGiv.
//
// Jalankan dengan: flutter test test/notifications_page_test.dart
// (server Laravel lokal harus berjalan di http://127.0.0.1:8000)
//
// Catatan: request HTTP nyata dijalankan lewat tester.runAsync() karena
// testWidgets berjalan di zone async buatan yang membuat socket menggantung.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/pages/notifications_page.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // flutter_test memasang HttpOverrides yang membalas 400 untuk semua
    // request; nonaktifkan agar test bisa memanggil Laravel lokal.
    HttpOverrides.global = null;
  });

  testWidgets(
      'tanpa sesi login, halaman menampilkan status error dan aksi coba lagi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget, reason: 'Judul halaman');
    expect(find.text('Gagal memuat notifikasi'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('dengan sesi login, halaman menampilkan daftar atau keadaan kosong',
      (WidgetTester tester) async {
    // 1. Login sungguhan (di luar zone async buatan)
    final dynamic loginResult = await tester.runAsync(() async {
      final response = await AuthRepository.login(
        email: 'saski@gmail.com',
        password: '12345678',
      );
      if (response.success) {
        await AuthService.saveToken(response.token!);
      }
      return response.success;
    });

    expect(loginResult, isTrue,
        reason: 'Login ke server lokal harus berhasil. Pastikan `php artisan serve` berjalan.');

    // 2. Tampilkan halaman + beri waktu nyata agar request riwayat
    //    notifikasi selesai (semuanya di dalam zone async nyata)
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));
      await Future<void>.delayed(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(
      find.text('Gagal memuat notifikasi'),
      findsNothing,
      reason: 'Dengan sesi valid, halaman tidak boleh gagal memuat',
    );

    final emptyState = find.text('Belum ada notifikasi');
    final tileIcons = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          (widget.icon == Icons.volunteer_activism_rounded ||
              widget.icon == Icons.event_available_rounded ||
              widget.icon == Icons.notifications_rounded),
    );

    expect(
      emptyState.evaluate().isNotEmpty || tileIcons.evaluate().isNotEmpty,
      isTrue,
      reason: 'Halaman harus menampilkan daftar notifikasi atau keadaan kosong',
    );
  }, timeout: const Timeout(Duration(seconds: 60)));
}
