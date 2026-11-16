import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/firebase_options.dart';
import '../models/app_notification.dart';
import '../models.dart';
import '../repositories/notification_repository.dart';
import '../repositories/volunteer_repository.dart';
import 'auth_service.dart';

/// Handler pesan FCM saat aplikasi berjalan di background.
/// Wajib berupa fungsi top-level dan diberi pragma agar tidak di-strip.
@pragma('vm:entry-point')
Future<void> dongivBackgroundMessageHandler(RemoteMessage message) async {
  // Riwayat notifikasi sudah disimpan oleh backend, jadi di sini cukup
  // dicatat. Pesan yang membawa "notification" otomatis ditampilkan
  // sistem Android/iOS.
  debugPrint('Notifikasi diterima di background: ${message.messageId}');
}

/// Layanan notifikasi DonGiv (FCM + notifikasi lokal + navigasi).
///
/// Urutan kerja:
///   1. main() memanggil [initialize] sebelum runApp.
///   2. Token perangkat diunggah ke backend setelah user login
///      ([registerTokenForCurrentUser]).
///   3. Saat logout, token dilepas dari akun ([unregisterCurrentToken]).
///   4. Notifikasi yang ditekan dibuka lewat [handleNotificationData].
class NotificationService {
  /// Dipakai MaterialApp.navigatorKey agar notifikasi dari luar halaman
  /// (mis. aplikasi dibuka lewat notifikasi) tetap bisa navigasi.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String notificationChannelId = 'dongiv_updates';
  static const String notificationChannelName = 'Notifikasi DonGiv';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static FirebaseMessaging? _messaging;
  static bool _initialized = false;
  static bool _appReady = false;
  static RemoteMessage? _pendingInitialMessage;

  // ---------------------------------------------------------------------------
  // Inisialisasi
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initLocalNotifications();
    } catch (e) {
      debugPrint('Notifikasi lokal tidak dapat diinisialisasi: $e');
    }

    try {
      await _initFirebaseMessaging();
    } catch (e) {
      // Firebase belum dikonfigurasi / gagal -> fitur lain tetap berjalan
      debugPrint('FCM tidak dapat diinisialisasi: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          notificationChannelId,
          notificationChannelName,
          description:
              'Pemberitahuan status donasi dan pengingat kegiatan relawan',
          importance: Importance.high,
        ),
      );
    }
  }

  static Future<void> _initFirebaseMessaging() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (_isPlaceholder(options)) {
      debugPrint(
        'Firebase belum dikonfigurasi (firebase_options.dart masih placeholder). '
        'Jalankan `flutterfire configure` untuk mengaktifkan push notification.',
      );
      return;
    }

    await Firebase.initializeApp(options: options);

    // Handler background harus didaftarkan sebelum runApp
    FirebaseMessaging.onBackgroundMessage(dongivBackgroundMessageHandler);

    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;

    // Minta izin notifikasi sesuai platform & versi OS
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _requestLocalNotificationPermission();

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      // Notifikasi tetap tampil saat aplikasi terbuka (iOS)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Foreground: tampilkan lewat notifikasi lokal agar muncul di panel
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Aplikasi dibuka dari notifikasi (state background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationData(_stringifyData(message.data));
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingInitialMessage = initialMessage;
    }

    // Token bisa berubah (mis. setelah clear data) -> sinkronkan ulang
    messaging.onTokenRefresh.listen((token) {
      _uploadToken(token);
    });

    // Jika user sudah login saat aplikasi dibuka, langsung sinkronkan token
    if (await AuthService.isLoggedIn()) {
      await registerTokenForCurrentUser();
    }
  }

  static Future<void> _requestLocalNotificationPermission() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // POST_NOTIFICATIONS (Android 13+); no-op pada versi lebih lama
      await android?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Token perangkat
  // ---------------------------------------------------------------------------

  /// Unggah token FCM ke backend untuk user yang sedang login.
  static Future<void> registerTokenForCurrentUser() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;

      final authToken = await AuthService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _uploadToken(fcmToken, authToken: authToken);
    } catch (e) {
      debugPrint('Gagal mendaftarkan token perangkat: $e');
    }
  }

  static Future<void> _uploadToken(String fcmToken, {String? authToken}) async {
    try {
      final token = authToken ?? await AuthService.getToken();
      if (token == null || token.isEmpty) return; // belum login -> jangan kirim

      await NotificationRepository.registerDeviceToken(
        authToken: token,
        fcmToken: fcmToken,
        platform: _platformName(),
        appVersion: '1.0.0',
      );
    } catch (e) {
      debugPrint('Gagal mengunggah token perangkat: $e');
    }
  }

  /// Lepaskan token dari akun saat ini (dipanggil saat logout).
  static Future<void> unregisterCurrentToken() async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;

      final authToken = await AuthService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await NotificationRepository.removeDeviceToken(
        authToken: authToken,
        fcmToken: fcmToken,
      );
    } catch (e) {
      debugPrint('Gagal melepas token perangkat: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Penerimaan notifikasi
  // ---------------------------------------------------------------------------

  static void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = _stringifyData(message.data);

    final title = notification?.title ?? data['title'];
    final body = notification?.body ?? data['message'] ?? data['body'];

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    _showLocalNotification(
      title: title ?? 'Notifikasi DonGiv',
      body: body ?? '',
      payload: jsonEncode(data),
    );
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelName,
            channelDescription:
                'Pemberitahuan status donasi dan pengingat kegiatan relawan',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Gagal menampilkan notifikasi lokal: $e');
    }
  }

  static void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        handleNotificationData(decoded);
      }
    } catch (e) {
      debugPrint('Payload notifikasi tidak valid: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Navigasi
  // ---------------------------------------------------------------------------

  /// Ditandai HomePage/Membersihkan penunggu ketika aplikasi sudah siap
  /// (route awal sudah ditentukan) sehingga navigasi dari notifikasi
  /// tidak menimpa halaman splash/login.
  static void markAppReady() {
    if (_appReady) return;
    _appReady = true;
    _consumePendingInitialMessage();
  }

  static Future<void> _consumePendingInitialMessage() async {
    final message = _pendingInitialMessage;
    if (message == null) return;
    _pendingInitialMessage = null;

    // Tunggu halaman utama tampil (splash berdurasi ±1 detik)
    for (var attempt = 0; attempt < 30; attempt++) {
      if (_appReady && navigatorKey.currentContext != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await handleNotificationData(_stringifyData(message.data), context: context);
  }

  /// Buka halaman tujuan berdasarkan data notifikasi.
  ///
  /// Dipanggil saat: notifikasi ditekan (background/terminated), notifikasi
  /// lokal ditekan (foreground), atau item riwayat notifikasi diketuk.
  static Future<void> handleNotificationData(
    Map<String, dynamic> data, {
    BuildContext? context,
  }) async {
    final category = (data['category'] ?? '').toString();
    final notificationId = (data['notification_id'] ?? '').toString();

    // Dapatkan navigator di awal (atau fallback ke navigatorKey)
    final navigator = (context != null && context.mounted)
        ? Navigator.of(context)
        : navigatorKey.currentState;
    if (navigator == null) return;

    // Tandai sudah dibaca (best effort, hanya jika login)
    if (notificationId.isNotEmpty) {
      try {
        final authToken = await AuthService.getToken();
        if (authToken != null && authToken.isNotEmpty) {
          await NotificationRepository.markAsRead(
            id: notificationId,
            authToken: authToken,
          );
        }
      } catch (e) {
        debugPrint('Gagal menandai notifikasi dibaca: $e');
      }
    }

    // Hanya buka halaman yang butuh login jika user memang login
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;

    final categoryLower = category.toLowerCase();

    if (categoryLower == 'donation' || categoryLower == 'donasi') {
      final orderId = (data['order_id'] ?? '').toString();
      if (orderId.isNotEmpty) {
        navigator.pushNamed('/donation_transaction_detail', arguments: {
          'order_id': orderId,
        });
      } else {
        // Fallback ke riwayat donasi
        navigator.pushNamed('/donation_history');
      }
    } else if (categoryLower == 'volunteer' || categoryLower == 'relawan') {
      final campaignId = int.tryParse('${data['campaign_id']}');
      if (campaignId != null && campaignId > 0) {
        await _openVolunteerCampaign(navigator, campaignId);
      } else {
        // Fallback: arahkan ke riwayat lamaran / kegiatan relawan
        navigator.pushNamed('/volunteer_history');
      }
    } else if (categoryLower == 'kampanye') {
      navigator.pushNamed('/campaign_history');
    }
  }

  /// Navigasi untuk item riwayat notifikasi (dipakai halaman notifikasi).
  static Future<void> openFromNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final data = <String, dynamic>{
      ...notification.data,
      'category': notification.category,
      'notification_id': notification.id,
    };
    await handleNotificationData(data, context: context);
  }

  static Future<void> _openVolunteerCampaign(
    NavigatorState navigator,
    int campaignId,
  ) async {
    try {
      final response =
          await VolunteerRepository.getVolunteerCampaignRaw(campaignId);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map ? decoded['data'] : null;

        if (data is Map) {
          final campaign =
              VolunteerCampaign.fromJson(Map<String, dynamic>.from(data));
          navigator.pushNamed('/volunteer_campaign_detail',
              arguments: campaign);
          return;
        }
      }

      debugPrint(
          'Kegiatan relawan $campaignId tidak ditemukan (${response.statusCode})');
    } catch (e) {
      debugPrint('Gagal memuat detail kegiatan relawan: $e');
    }

    // Fallback: buka daftar kegiatan relawan
    navigator.pushNamed('/volunteer_campaigns');
  }

  // ---------------------------------------------------------------------------
  // utilitas
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _stringifyData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, '$value'));
  }

  static String _platformName() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'android';
    }
  }

  static bool _isPlaceholder(FirebaseOptions options) {
    return options.apiKey.startsWith('ISI_DENGAN') ||
        options.projectId.startsWith('ISI_DENGAN');
  }
}
