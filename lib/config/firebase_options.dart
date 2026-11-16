// ===========================================================================
// firebase_options.dart  –  STUB untuk Windows Desktop
// ===========================================================================
// Firebase tidak digunakan di Windows, sehingga kelas ini hanya menyediakan
// placeholder agar kode yang mengimpornya tetap dapat dikompilasi.
// ===========================================================================

class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;

  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
  });
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        apiKey: 'ISI_DENGAN_API_KEY',
        appId: 'ISI_DENGAN_APP_ID',
        messagingSenderId: 'ISI_DENGAN_MESSAGING_SENDER_ID',
        projectId: 'ISI_DENGAN_PROJECT_ID',
      );
}
