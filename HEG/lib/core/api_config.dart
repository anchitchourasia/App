import 'app_config.dart';

class ApiConfig {
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiKey = AppConfig.apiKey;

  static const String cvpsBaseUrl = AppConfig.cvpsBaseUrl;

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

  // CVPS (existing)
  static String cvpsBase = '$cvpsBaseUrl/api/requests';
  static String cvpsCreateRequest = '$cvpsBaseUrl/api/requests/create';
  static String cvpsUpdateRequest = '$cvpsBaseUrl/api/requests/update';
  static String cvpsGetRequestById = '$cvpsBaseUrl/api/requests';
  static String cvpsGetAllRequests = '$cvpsBaseUrl/api/requests';
  static String cvpsDeleteRequest = '$cvpsBaseUrl/api/requests';
  static String cvpsBpRecords = '$cvpsBaseUrl/api/bp-records';

  // CVPS – new endpoints (mirroring web API_CONFIG)
  static String cvpsGetManpowerDocuments(String empNo) =>
      '$cvpsBaseUrl/api/manpower/documents/$empNo';

  static String cvpsDownloadManpowerDocument(String fileName) =>
      '$cvpsBaseUrl/api/manpower/documents/download/$fileName';

  static String cvpsDepartmentList = '$cvpsBaseUrl/api/dept';
}
