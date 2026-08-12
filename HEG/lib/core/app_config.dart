class AppConfig {
  // VPMS (same as web apiBaseUrl but using 10.0.2.2 for Android emulator)
  static const String apiBaseUrl = 'http://10.0.2.2:3031/vpms';

  // CVPS backend (same as web cvpsBaseUrl, but use 10.0.2.2 instead of localhost)
  static const String cvpsBaseUrl = 'http://10.0.2.2:3033/cvps';

  static const String apiKey = 'VPMS_SECRET_KEY_2026';
}
