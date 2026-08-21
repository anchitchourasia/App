import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../core/api_config.dart';
import '../models/cvps_request_item.dart';
import '../models/cvps_document.dart';
import '../models/cvps_driver.dart';
import '../models/cvps_history_entry.dart';

class CvpsApi {
  final http.Client client;

  CvpsApi({http.Client? client}) : client = client ?? http.Client();

  /// GET /api/requests  -> list of CreateRequestDTO
  /// Used by list screen; we convert to CvpsRequestItem.
  Future<List<CvpsRequestItem>> fetchAllRequests() async {
    final uri = Uri.parse(ApiConfig.cvpsGetAllRequests);

    final response = await client
        .get(
          uri,
          headers: {
            'x-api-key': ApiConfig.apiKey,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(milliseconds: 12000));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body is List) {
        final items = body
            .map(
              (e) => CvpsRequestItem.fromCreateRequestDto(
                e as Map<String, dynamic>,
              ),
            )
            .toList();

        // Sort like web: latest requestNo first.
        items.sort((a, b) => b.requestNo.compareTo(a.requestNo));
        return items;
      }

      return [];
    } else {
      throw Exception(
        'Unable to load CVPS requests (HTTP ${response.statusCode})',
      );
    }
  }

  /// GET /api/requests/{requestNo} -> single CreateRequestDTO
  /// Used by form/pass page; we keep raw DTO for full mapping.
  Future<Map<String, dynamic>> fetchRequestById(int requestNo) async {
    final uri = Uri.parse('${ApiConfig.cvpsGetRequestById}/$requestNo');

    final response = await client
        .get(
          uri,
          headers: {
            'x-api-key': ApiConfig.apiKey,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(milliseconds: 12000));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return body;
      }
      throw Exception('Unexpected CVPS DTO format');
    } else {
      throw Exception(
        'Unable to load request $requestNo (HTTP ${response.statusCode})',
      );
    }
  }

  /// GET /api/manpower/documents/{empNo}
  /// Mirrors Angular: cvps.fetchManpowerDocuments(empNo).
  ///
  /// Used only by the Driver Information "View More" dialog.
  /// It does not change CVPS request data, workflow, or payload.
  Future<Map<String, dynamic>?> fetchManpowerDocuments(String empNo) async {
    final code = empNo.trim();

    if (code.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      '${ApiConfig.cvpsBaseUrl}/api/manpower/documents/'
      '${Uri.encodeComponent(code)}',
    );

    final response = await client
        .get(
          uri,
          headers: {
            'x-api-key': ApiConfig.apiKey,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(milliseconds: 12000));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        final nestedData = body['data'];

        if (nestedData is Map<String, dynamic>) {
          return nestedData;
        }

        return body;
      }

      return null;
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw Exception(
      'Unable to load driver details '
      '(HTTP ${response.statusCode})',
    );
  }

  /// GET /api/requests/history/{requestNo}
  /// Mirrors cvps.getRequestHistory(requestNo) in Angular.
  Future<List<Map<String, dynamic>>> fetchRequestHistory(int requestNo) async {
    final uri = Uri.parse(
      '${ApiConfig.cvpsBaseUrl}/api/requests/history/$requestNo',
    );

    final response = await client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(milliseconds: 12000));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } else {
      throw Exception(
        'Unable to load request history (HTTP ${response.statusCode})',
      );
    }
  }

  /// GET CVPS_BP_RECORDS/{contractorCode}
  /// Mirrors cvps.fetchContractorDetails(contractorCode) in Angular.
  Future<Map<String, dynamic>?> fetchContractorDetails(
    String contractorCode,
  ) async {
    final trimmed = contractorCode.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse('${ApiConfig.cvpsBpRecords}/$trimmed');

    final response = await client
        .get(
          uri,
          headers: {
            'x-api-key': ApiConfig.apiKey,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(milliseconds: 12000));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(
        'Unable to fetch contractor details (HTTP ${response.statusCode})',
      );
    }
  }

  // --------------------
  // Document download APIs
  // --------------------

  /// Builds the document download URL, exactly like Spring mapping:
  /// GET /api/documents/download/{filename:.+}
  String getDocumentUrl(String fileName) {
    final encoded = Uri.encodeComponent(fileName);
    return '${ApiConfig.cvpsBaseUrl}/api/documents/download/$encoded';
  }

  /// Downloads a document as raw bytes from CVPS.
  Future<Uint8List> downloadDocumentBytes(String fileName) async {
    final url = getDocumentUrl(fileName);
    final uri = Uri.parse(url);

    final response = await client
        .get(uri, headers: {'Accept': '*/*'})
        .timeout(const Duration(milliseconds: 15000));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Download failed [${response.statusCode}] for $url');
    }
  }

  /// Guesses MIME type from filename (for later open/share behavior).
  String guessMimeType(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }

  // --------------------
  // PASS DETAIL HELPERS (for CVPS Pass Page / PDF)
  // --------------------
}

/// Represents full CVPS request detail mapped from CreateRequestDTO:
/// request + vehicleDocuments + drivers + contractorName.
class CvpsRequestDetail {
  final CvpsRequestItem request;
  final String contractorName;
  final List<CvpsDocument> vehicleDocuments;
  final List<CvpsDriver> drivers;

  CvpsRequestDetail({
    required this.request,
    required this.contractorName,
    required this.vehicleDocuments,
    required this.drivers,
  });
}

extension CvpsApiDetail on CvpsApi {
  /// Fetches the raw CreateRequestDTO, then maps it into our models.
  Future<CvpsRequestDetail> fetchRequestDetail(int requestNo) async {
    final raw = await fetchRequestById(requestNo);

    final reqDto = raw['request'] as Map<String, dynamic>? ?? {};
    final docsDto = raw['vehicleDocuments'] as List<dynamic>? ?? const [];
    final employeesDto = raw['employees'] as List<dynamic>? ?? const [];

    // Map request part to CvpsRequestItem using request-only factory.
    final requestItem = CvpsRequestItem.fromRequestMap(reqDto);

    // Map vehicleDocuments
    final vehicleDocs = docsDto
        .map((e) => e as Map<String, dynamic>)
        .map(
          (m) => CvpsDocument(
            documentType: (m['documentType'] ?? '').toString(),
            documentNo: (m['documentNo'] ?? '').toString(),
            validTill: (m['validTill'] ?? m['validTo'] ?? '').toString(),
          ),
        )
        .toList();

    // Map drivers from employees (similar to TS passEmployees computed)
    final drivers = employeesDto.map((e) => e as Map<String, dynamic>).map((m) {
      final docs = (m['documents'] as List<dynamic>? ?? const [])
          .map((d) => d as Map<String, dynamic>)
          .toList();

      String aadhaarNo = '';
      String licenseNo = '';
      String licenseValidTill = '';

      for (final d in docs) {
        final t = (d['documentType'] ?? '').toString().toUpperCase().trim();
        if (t.contains('AADHAAR') ||
            t.contains('AADHAR') ||
            t.contains('ADHAR')) {
          aadhaarNo = (d['documentNo'] ?? '').toString();
        }
        if (t == 'DL' || t.contains('LICENSE')) {
          licenseNo = (d['documentNo'] ?? '').toString();
          licenseValidTill = (d['validTill'] ?? '').toString();
        }
      }

      final role =
          (m['empJob'] ?? m['empType'] ?? m['role'] ?? m['jobType'] ?? '-')
              .toString()
              .trim();

      return CvpsDriver(
        role: role,
        name: (m['name'] ?? '').toString(),
        mobileNo: (m['mobileNo'] ?? '').toString(),
        aadhaarNo: aadhaarNo,
        licenseNo: licenseNo,
        licenseValidTill: licenseValidTill,
      );
    }).toList();

    // Contractor name via BP records (like Angular resolveContractorName)
    String contractorName = '';
    final contractorCode = (reqDto['contractorId'] ?? '').toString().trim();
    if (contractorCode.isNotEmpty) {
      final bp = await fetchContractorDetails(contractorCode);
      contractorName = (bp?['contractorName'] ?? '').toString().toUpperCase();
    }

    return CvpsRequestDetail(
      request: requestItem,
      contractorName: contractorName,
      vehicleDocuments: vehicleDocs,
      drivers: drivers,
    );
  }

  /// Converts history DTOs into CvpsHistoryEntry.
  Future<List<CvpsHistoryEntry>> fetchRequestHistoryEntries(
    int requestNo,
  ) async {
    final rows = await fetchRequestHistory(requestNo);
    return rows.map((m) => CvpsHistoryEntry.fromJson(m)).toList();
  }
}

/// Extra helper to mirror Angular resolveEmployeeName(empCode, stage).
extension CvpsApiEmployee on CvpsApi {
  /// GET EMPLOYEE_REPORT/{empCode}
  /// Returns uppercased employee name or null if not found.
  Future<String?> fetchEmployeeName(String empCode) async {
    final trimmed = empCode.trim();
    if (trimmed.isEmpty) return null;

    // Match API_CONFIG.EMPLOYEE_REPORT from Angular
    final uri = Uri.parse('${ApiConfig.employeeReport}/$trimmed');

    final response = await client
        .get(
          uri,
          headers: {
            'x-api-key': ApiConfig.apiKey,
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(milliseconds: 12000));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final rawName =
            body['name'] ??
            body['empName'] ??
            body['employeeName'] ??
            body['EMPNAME'] ??
            body['EMPLOYEENAME'];

        if (rawName != null) {
          final name = rawName.toString().trim();
          if (name.isNotEmpty) {
            return name.toUpperCase();
          }
        }
      }
      return null;
    } else {
      // On error, just return null, like Angular's catchError(() => of(null))
      return null;
    }
  }
}
