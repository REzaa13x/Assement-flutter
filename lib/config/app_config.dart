class AppConfig {
  // flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  /// Resolve backend links using the configured API server, including emulator
  /// aliases. Signed URLs use a relative signature, so the query stays intact.
  static String resolveServerUrl(String raw, {String? apiBaseUrl}) {
    if (raw.trim().isEmpty) return '';
    final api = Uri.parse(apiBaseUrl ?? apiUrl);
    final basePath = api.path.replaceFirst(RegExp(r'/api/?$'), '/');
    final base = api.replace(path: basePath, query: null, fragment: null);
    final url = base.resolve(raw.trim());
    final localHost = url.host == 'localhost' ||
        url.host == '127.0.0.1' ||
        url.host == '10.0.2.2';
    if (localHost && (url.host != api.host || url.port != api.port)) {
      return url
          .replace(scheme: api.scheme, host: api.host, port: api.port)
          .toString();
    }
    return url.toString();
  }
}
