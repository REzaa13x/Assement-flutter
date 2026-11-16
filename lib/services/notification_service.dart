// ===========================================================================
// notification_service.dart  –  STUB untuk Windows Desktop
// ===========================================================================
// Firebase Messaging dan flutter_local_notifications TIDAK tersedia di Windows.
// Semua method tetap ada agar kode di main.dart, login_page, register_page,
// profile_page, dan notifications_page dapat dikompilasi tanpa error.
// Fitur notifikasi push (FCM) hanya aktif di Android / iOS.
// ===========================================================================

import 'package:flutter/widgets.dart';

import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import 'auth_service.dart';

class NotificationService {
  // ---------------------------------------------------------------------------
  // Navigator key – dipakai MaterialApp.navigatorKey
  // ---------------------------------------------------------------------------
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _initialized = false;
  static bool _appReady = false;

  // ---------------------------------------------------------------------------
  // initialize() – dipanggil di main() sebelum runApp
  // ---------------------------------------------------------------------------
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // No-op pada Windows – Firebase dan local notifications tidak didukung.
  }

  // ---------------------------------------------------------------------------
  // markAppReady() – dipanggil setelah runApp selesai mount
  // ---------------------------------------------------------------------------
  static void markAppReady() {
    _appReady = true;
  }

  // ---------------------------------------------------------------------------
  // registerTokenForCurrentUser() – dipanggil setelah login / register
  // ---------------------------------------------------------------------------
  static Future<void> registerTokenForCurrentUser() async {
    // No-op pada Windows.
  }

  // ---------------------------------------------------------------------------
  // unregisterCurrentToken() – dipanggil saat logout
  // ---------------------------------------------------------------------------
  static Future<void> unregisterCurrentToken() async {
    // No-op pada Windows.
  }

  // ---------------------------------------------------------------------------
  // openFromNotification() – dipanggil dari NotificationsPage
  // ---------------------------------------------------------------------------
  static Future<void> openFromNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    await _open(Navigator.of(context), notification);
  }

  static Future<void> handleNotificationData(Map<String, dynamic> data) async {
    if (!await AuthService.isLoggedIn()) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    final notification = AppNotification.fromJson({
      ...data,
      'data': data['data'] is Map ? data['data'] : data,
    });
    await _open(nav, notification);
  }

  static Future<void> _open(
      NavigatorState nav, AppNotification notification) async {
    if (!await AuthService.isLoggedIn()) return;
    if (notification.category == 'donasi' && notification.orderId != null) {
      nav.pushNamed('/donation_transaction_detail',
          arguments: {'order_id': notification.orderId});
    } else if (notification.category == 'relawan') {
      // Detail routes require a full VolunteerCampaign object, not an integer.
      nav.pushNamed('/volunteer_campaigns');
    } else {
      nav.pushNamed('/notifications');
    }
    final id = notification.data['notification_id']?.toString();
    if (id != null && id.isNotEmpty) {
      try {
        await NotificationRepository.markAsRead(
            id: id, authToken: await AuthService.getToken());
      } catch (_) {
        // Navigation remains available when marking read fails.
      }
    }
  }
}
