import 'app_config.dart';

class ApiConfig {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiKey = AppConfig.apiKey;

  // AUTH
  static String authorityByEmp = '$baseUrl/api/authority';
  static String authorityUpdate = '$baseUrl/api/authority/update';
  static String employeeReport = '$baseUrl/api/reports/employee-department';

  // PASSES / SAVE
  static String passSave = '$baseUrl/api/passes/save';
  static String passUpdate = '$baseUrl/api/passes/update';
  static String passListV1 = '$baseUrl/api/passes/listV1';
  static String passList = '$baseUrl/api/passes/list';
  static String passHistory = '$baseUrl/api/history';
  static String passStatusUpdate = '$baseUrl/api/passes/status';

  // DOCUMENTS DOWNLOAD
  static String documentsDownload = '$baseUrl/api/passes/documents/download';

  // GATE / COMPLIANCE
  static String gateLogs = '$baseUrl/api/gate-logs/list';
  static String compliance = '$baseUrl/api/compliance/list';
}
