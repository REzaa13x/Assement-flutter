import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Konfigurasi Firebase untuk aplikasi DonGiv.
///
/// PENTING: file ini masih berisi nilai placeholder. Push notification (FCM)
/// baru aktif setelah kamu mengisinya.
///
/// CARA MENGISI OTOMATIS (disarankan):
///   1. Buka https://console.firebase.google.com dan buat project Firebase
///      (Android package name: com.example.flutter_application_1)
///   2. Install FlutterFire CLI:
///        dart pub global activate flutterfire_cli
///   3. Dari folder Assement-flutter jalankan:
///        flutterfire configure
///      -> file ini ditimpa otomatis + google-services.json terbit di
///         android/app/
///
/// CARA MENGISI MANUAL:
///   Salin nilai "apiKey", "appId", "messagingSenderId", dan "projectId"
///   dari Firebase Console -> Project settings -> Your apps (SDK setup).
///
/// Selama placeholder belum diganti, aplikasi tetap berjalan normal:
/// hanya push notification yang dinonaktifkan (riwayat notifikasi tetap ada).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'ISI_DENGAN_API_KEY',
        appId: 'ISI_DENGAN_APP_ID',
        messagingSenderId: 'ISI_DENGAN_MESSAGING_SENDER_ID',
        projectId: 'ISI_DENGAN_PROJECT_ID',
      );
}
