// Test halaman detail transaksi donasi (tujuan notifikasi status donasi).
//
// Jalankan dengan: flutter test test/donation_transaction_detail_test.dart
// (server Laravel lokal harus berjalan di http://127.0.0.1:8000)

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/pages/donation_transaction_detail_page.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // flutter_test memasang HttpOverrides yang membalas 400 untuk semua
    // request; nonaktifkan agar test bisa memanggil Laravel lokal.
    HttpOverrides.global = null;
  });

  testWidgets('tanpa sesi login, halaman menampilkan status error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DonationTransactionDetailPage(orderId: 'ORD-X')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Donasi'), findsOneWidget);
    expect(find.text('Gagal memuat detail donasi'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });

  testWidgets('dengan sesi login, halaman menampilkan rincian transaksi',
      (WidgetTester tester) async {
    String? orderId;

    // Login + ambil order id sungguhan (di luar zone async buatan)
    final dynamic loggedIn = await tester.runAsync(() async {
      final response = await AuthRepository.login(
        email: 'saski@gmail.com',
        password: '12345678',
      );
      if (!response.success) return false;

      await AuthService.saveToken(response.token!);
      try {
        // Ambil order id langsung dari API (parsing sederhana)
        final res = await ApiService.get('v1/my-donations', token: response.token);
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final items = body is Map ? (body['data']?['data'] ?? []) : [];
          if (items is List && items.isNotEmpty) {
            orderId = items.first['order_id']?.toString();
          }
        }
      } catch (_) {
        // riwayat kosong -> biarkan null
      }
      return true;
    });

    expect(loggedIn, isTrue,
        reason: 'Login ke server lokal harus berhasil. Pastikan `php artisan serve` berjalan.');

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: DonationTransactionDetailPage(
            orderId: orderId ?? 'ORD-TIDAK-ADA',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    expect(find.text('Detail Donasi'), findsOneWidget);

    if (orderId != null) {
      expect(
        find.text('Gagal memuat detail donasi'),
        findsNothing,
        reason: 'Transaksi yang ada harus berhasil dimuat',
      );
      expect(find.text(orderId!), findsOneWidget, reason: 'Kode transaksi');
      // Label status Bahasa Indonesia (muncul di chip status dan baris rincian)
      expect(
        find.text('Menunggu Transfer'),
        findsWidgets,
        reason: 'Status transaksi harus ditampilkan',
      );
      expect(find.textContaining('Rp'), findsWidgets,
          reason: 'Nominal donasi harus ditampilkan');
    } else {
      expect(find.text('Gagal memuat detail donasi'), findsOneWidget);
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}
