class AppConfig {
  // ── Credentials & URLs from assets/.env ──────────────────────────────────
  // For Android Emulator use 'http://10.0.2.2:8080'
  // For USB physical device or Desktop use 'http://127.0.0.1:8080'
  //static const String envBaseUrl = 'http://127.0.0.1:8080';
  static const String envBaseUrl = 'http://10.0.2.2:8080';
  static const String envApiKey = 'HEG_12345_SECRET';

  // Chat & WebSocket backend configuration (mirrors .env)
  static const String chatBaseUrl = envBaseUrl;
  static const String chatApiKey = envApiKey;

  // ── VPMS & CVPS Services ─────────────────────────────────────────────────
  //static const String apiBaseUrl = 'http://127.0.0.1:9092/vpms';
  static const String apiBaseUrl = 'http://192.168.9.130:9092/vpms';
  //static const String cvpsBaseUrl = 'http://127.0.0.1:9092/cvps';
  static const String cvpsBaseUrl = 'http://192.168.9.130:9092/cvps';

  // Replace 10.0.2.2 with 127.0.0.1 for USB physical device: static const String dummyGateLogBaseUrl = 'http://10.0.2.2:8080/cvps';
  static const String dummyGateLogBaseUrl = 'http://10.0.2.2:8080/cvps';
  //static const String dummyGateLogBaseUrl = 'http://127.0.0.1:8080/cvps';
  static const String dummyGateLogApiKey = envApiKey;

  static const String apiKey = 'VPMS_SECRET_KEY_2026';
}
