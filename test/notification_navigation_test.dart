// Test navigasi ketika notifikasi ditekan (foreground/background/riwayat).
//
// Test ini sengaja TIDAK memanggil server sungguhan: flutter_test memasang
// HttpOverrides yang membalas 400 untuk semua request, sehingga kegagalan
// jaringan ditangani dan navigasi tetap berjalan (sesuai desain aplikasi).
//
// Jalankan dengan: flutter test test/notification_navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models.dart' show VolunteerCampaign;
import 'package:flutter_application_1/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final opened = <String, Object?>{};

  setUp(() {
    opened.clear();
    SharedPreferences.setMockInitialValues({'auth_token': 'token-uji'});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const Scaffold(body: Text('HOME')),
          '/donation_transaction_detail': (context) {
            opened['route'] = '/donation_transaction_detail';
            opened['arguments'] = ModalRoute.of(context)?.settings.arguments;
            return const Scaffold(body: Text('DETAIL_DONASI'));
          },
          '/volunteer_campaign_detail': (context) {
            opened['route'] = '/volunteer_campaign_detail';
            opened['arguments'] = ModalRoute.of(context)?.settings.arguments;
            return const Scaffold(body: Text('DETAIL_RELAWAN'));
          },
          '/volunteer_campaigns': (context) {
            opened['route'] = '/volunteer_campaigns';
            return const Scaffold(body: Text('DAFTAR_RELAWAN'));
          },
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('notifikasi donasi membuka detail transaksi yang sesuai',
      (tester) async {
    await pumpApp(tester);

    await NotificationService.handleNotificationData({
      'category': 'donation',
      'order_id': 'ORD-TEST-1',
    });
    await tester.pumpAndSettle();

    expect(opened['route'], '/donation_transaction_detail');
    final arguments = opened['arguments'] as Map;
    expect(arguments['order_id'], 'ORD-TEST-1');
    expect(find.text('DETAIL_DONASI'), findsOneWidget);
  });

  testWidgets(
      'penandaan sudah dibaca yang gagal tidak menghalangi navigasi detail',
      (tester) async {
    await pumpApp(tester);

    // notification_id tidak valid -> request mark-read gagal (400/404),
    // navigasi tetap harus terjadi.
    await NotificationService.handleNotificationData({
      'category': 'donation',
      'order_id': 'ORD-TEST-2',
      'notification_id': 'id-tidak-ada',
    });
    await tester.pumpAndSettle();

    expect(opened['route'], '/donation_transaction_detail');
    expect(find.text('DETAIL_DONASI'), findsOneWidget);
  });

  testWidgets('notifikasi relawan membuka halaman kegiatan relawan',
      (tester) async {
    await pumpApp(tester);

    await NotificationService.handleNotificationData({
      'category': 'volunteer',
      'campaign_id': '9',
    });
    await tester.pumpAndSettle();

    expect(
      ['/volunteer_campaign_detail', '/volunteer_campaigns'],
      contains(opened['route']),
      reason: 'Notifikasi relawan harus membuka halaman kegiatan relawan',
    );

    // Jika data kegiatan berhasil dimuat, harus membawa objek kampanye yang benar
    if (opened['route'] == '/volunteer_campaign_detail') {
      final campaign = opened['arguments'] as VolunteerCampaign;
      expect(campaign.id, 9);
      expect(find.text('DETAIL_RELAWAN'), findsOneWidget);
    } else {
      expect(find.text('DAFTAR_RELAWAN'), findsOneWidget);
    }
  });

  testWidgets('tanpa sesi login, notifikasi tidak membuka halaman mana pun',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // tidak ada token
    await pumpApp(tester);

    await NotificationService.handleNotificationData({
      'category': 'donation',
      'order_id': 'ORD-TANPA-LOGIN',
    });
    await tester.pumpAndSettle();

    expect(opened.containsKey('route'), isFalse);
    expect(find.text('DETAIL_DONASI'), findsNothing);
  });
}
