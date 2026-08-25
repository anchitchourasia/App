// class AppConfig {
//   // VPMS backend on YOUR PC (reachable from phone via company Wi‑Fi / proxy)
//   static const String apiBaseUrl = 'http://localhost:3031/vpms';

//   // CVPS backend on YOUR PC or another host
//   static const String cvpsBaseUrl = 'http://localhost:3033/cvps';

//   static const String apiKey = 'VPMS_SECRET_KEY_2026';
// }
class AppConfig {
  static const String apiBaseUrl = 'http://127.0.0.1:9092/vpms';
  static const String cvpsBaseUrl = 'http://127.0.0.1:9092/cvps';
  static const String apiKey = 'VPMS_SECRET_KEY_2026';
}

// class AppConfig {
//   static const String apiBaseUrl = 'http://192.168.9.130:9092/vpms';
//   static const String cvpsBaseUrl = 'http://192.168.9.130:9092/cvps';
//   static const String dummyGateLogBaseUrl = 'http://10.0.2.2:3033/cvps';
//   static const String apiKey = 'VPMS_SECRET_KEY_2026';
// }
