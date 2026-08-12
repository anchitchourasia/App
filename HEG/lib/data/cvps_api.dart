import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../core/api_config.dart';
import '../models/cvps_request_item.dart';

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
  /// Used by form page; we keep raw DTO for full mapping.
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
    // IMPORTANT: the {filename} path variable is whatever backend stored.
    // The controller uses @PathVariable String filename, with .+ to allow dots.
    // Angular uses encodeURIComponent, so we do the same.
    final encoded = Uri.encodeComponent(fileName);
    return '${ApiConfig.cvpsBaseUrl}/api/documents/download/$encoded';
  }

  /// Downloads a document as raw bytes from CVPS.
  Future<Uint8List> downloadDocumentBytes(String fileName) async {
    final url = getDocumentUrl(fileName);
    final uri = Uri.parse(url);

    final response = await client
        .get(
          uri,
          headers: {
            // This controller does NOT require x-api-key by itself.
            // If a global filter still checks it, you can uncomment the next line:
            // 'x-api-key': ApiConfig.apiKey,
            'Accept': '*/*',
          },
        )
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
}
