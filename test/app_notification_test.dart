import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/app_notification.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('membaca field notifikasi donasi dengan benar', () {
      final notification = AppNotification.fromJson({
        'id': 'abc-123',
        'type': 'App\\Notifications\\DonationStatusChanged',
        'category': 'donation',
        'title': 'Donasi: Wakaf Air Bersih',
        'message': 'Terverifikasi. Pembayaran terverifikasi.',
        'data': {
          'order_id': 'ORD-ABC123',
          'campaign_id': 7,
          'status': 'VERIFIED',
        },
        'is_read': false,
        'read_at': null,
        'created_at': '2026-10-09T17:57:04+00:00',
      });

      expect(notification.id, 'abc-123');
      expect(notification.category, 'donation');
      expect(notification.title, 'Donasi: Wakaf Air Bersih');
      expect(notification.isRead, isFalse);
      expect(notification.orderId, 'ORD-ABC123');
      expect(notification.createdAt.isUtc, isTrue);
      // campaignId hanya dipakai untuk navigasi kategori relawan
      expect(notification.campaignId, isNull);
    });

    test('notifikasi relawan menghasilkan campaignId untuk navigasi', () {
      final notification = AppNotification.fromJson({
        'id': 'notif-2',
        'type': 'App\\Notifications\\VolunteerActivityReminder',
        'category': 'volunteer',
        'title': 'Pengingat Kegiatan Besok',
        'message': 'Kegiatan besok di Bandung.',
        'data': {
          'campaign_id': '9',
          'kind': '1day',
          'jadwal': '2026-10-11',
        },
        'is_read': false,
        'created_at': '2026-10-09T17:57:04Z',
      });

      expect(notification.category, 'volunteer');
      expect(notification.campaignId, 9);
      expect(notification.orderId, isNull);
    });

    test('read_at terisi dianggap sudah dibaca', () {
      final notification = AppNotification.fromJson({
        'id': 'notif-3',
        'category': 'donation',
        'title': 'Judul',
        'message': 'Pesan',
        'data': <String, dynamic>{},
        'read_at': '2026-10-09T18:00:00+00:00',
        'created_at': '2026-10-09T17:57:04+00:00',
      });

      expect(notification.isRead, isTrue);
      expect(notification.readAt, isNotNull);
    });

    test('data tidak lengkap tidak membuat crash', () {
      final notification = AppNotification.fromJson({
        'id': 'notif-4',
        'data': null,
      });

      expect(notification.category, 'general');
      expect(notification.title, 'Notifikasi');
      expect(notification.message, '');
      expect(notification.isRead, isFalse);
      expect(notification.orderId, isNull);
      expect(notification.campaignId, isNull);
    });
  });
}
