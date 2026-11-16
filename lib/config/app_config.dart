class AppConfig {
  // flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}
