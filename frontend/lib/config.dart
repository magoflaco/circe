class AppConfig {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static String get wsBase {
    final uri = Uri.parse(apiBase);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.authority}';
  }
  static const String appName = 'Circe';
  static const String version = 'v1.5';
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://monitor.itb.lat',
  );
  static const String apkUrl = String.fromEnvironment(
    'APK_URL',
    defaultValue: 'https://api-monitor.itb.lat/static/circe.apk',
  );
}