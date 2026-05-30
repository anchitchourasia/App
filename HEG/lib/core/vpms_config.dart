// lib/core/vpms_config.dart

class VpmsConfig {
  VpmsConfig._();

  // ════════════════════════════════════════════════════
  // 🔧 TOGGLE: set to false when backend API is ready
  // ════════════════════════════════════════════════════
  static const bool useDummyData = true; // ← change to false for real API
  // ════════════════════════════════════════════════════

  static const String baseUrl =
      'http://192.168.8.28:8090/vehiclePassManagementSystem-0.0.1-SNAPSHOT';

  static const String apiKey = 'VPMS_SECRET_KEY_2026';

  static const String vehicles = '$baseUrl/api/vehicles/list';
  static const String vehicleRegister = '$baseUrl/api/vehicles/register';
  static const String vehicleUpdate = '$baseUrl/api/vehicles/update';
  static const String vehicleDelete = '$baseUrl/api/vehicles/delete';
}
