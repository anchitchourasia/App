import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pass_entry_models.dart';

class PassEntryService {
  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  PassEntryService({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {'x-api-key': apiKey};

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<EmployeeLookupResponse> loadEmployee(String employeeNo) async {
    final res = await _client.get(
      _u('/api/employee/report/${Uri.encodeComponent(employeeNo)}'),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Could not fetch employee details');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return EmployeeLookupResponse(
      employeeNo: (data['employeeNo'] ?? data['empCode'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      deptCode: (data['deptCode'] ?? '').toString(),
      deptName: (data['deptName'] ?? '').toString(),
      contractorCode: (data['contractorCode'] ?? '').toString(),
      contractorName: (data['contractorName'] ?? '').toString(),
      aadhaarNo: (data['aadhaarNo'] ?? data['aadharNo'] ?? '').toString(),
      empType: (data['empType'] ?? '').toString(),
    );
  }

  Future<PassRegistryResponseDTO> loadPass(int id) async {
    final res = await _client.get(
      _u('/api/passes/list/$id'),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Unable to load pass details');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return _mapPassResponse(data);
  }

  Future<List<HistoryRecord>> loadHistory(int id) async {
    final res = await _client.get(_u('/api/history/$id'), headers: _headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Unable to load pass history');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return HistoryRecord(
        id: m['id'] as int?,
        passNo: (m['passNo'] ?? '').toString(),
        empCode: (m['empCode'] ?? '').toString(),
        action: (m['action'] ?? '').toString(),
        remark: (m['remark'] ?? '').toString(),
        dateOfEntry: (m['dateOfEntry'] ?? '').toString(),
      );
    }).toList();
  }

  Future<http.Response> downloadDocument(int documentId) {
    return _client.get(
      _u('/api/passes/documents/download/$documentId'),
      headers: _headers,
    );
  }

  Future<PassRegistryResponseDTO> savePass(
    Map<String, dynamic> request, {
    List<UploadFilePart> files = const [],
  }) async {
    return _sendMultipart('POST', '/api/passes/save', request, files);
  }

  Future<PassRegistryResponseDTO> updatePass(
    int id,
    Map<String, dynamic> request, {
    List<UploadFilePart> files = const [],
  }) async {
    return _sendMultipart('PUT', '/api/passes/update/$id', request, files);
  }

  Future<PassRegistryResponseDTO> submitPass({
    int? id,
    required Map<String, dynamic> request,
    List<UploadFilePart> files = const [],
  }) async {
    request['status'] = PassStatus.SUBMITTED;
    if (id == null) {
      return _sendMultipart('POST', '/api/passes/save', request, files);
    }
    return _sendMultipart('PUT', '/api/passes/update/$id', request, files);
  }

  Future<void> updatePassStatus(
    int id,
    String status, {
    String? remark,
    String? enterBy,
  }) async {
    final res = await _client.put(
      _u('/api/passes/status/$id'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'status': status,
        'remark': remark,
        'enterBy': enterBy,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body, 'Status update failed'));
    }
  }

  Future<PassRegistryResponseDTO> _sendMultipart(
    String method,
    String path,
    Map<String, dynamic> request,
    List<UploadFilePart> files,
  ) async {
    final req = http.MultipartRequest(method, _u(path));
    req.headers.addAll(_headers);
    req.fields['request'] = jsonEncode(request);
    for (final f in files) {
      req.files.add(
        await http.MultipartFile.fromPath(f.key, f.path, filename: f.filename),
      );
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _extractError(res.body, 'Unable to process pass request'),
      );
    }
    return _mapPassResponse(jsonDecode(res.body) as Map<String, dynamic>);
  }

  PassRegistryResponseDTO _mapPassResponse(Map<String, dynamic> data) {
    final docsRaw = (data['documents'] as List<dynamic>? ?? []);
    return PassRegistryResponseDTO(
      id: (data['id'] as num).toInt(),
      vehicleNo: (data['vehicleNo'] ?? '').toString(),
      vehicleType: (data['vehicleType'] ?? '').toString(),
      brandModel: (data['brandModel'] ?? '').toString(),
      employeeNo: (data['employeeNo'] ?? '').toString(),
      empType: (data['empType'] ?? '').toString(),
      contractorCode: (data['contractorCode'] ?? '').toString(),
      gateNo: (data['gateNo'] ?? '').toString(),
      parkingToBeUsed: (data['parkingToBeUsed'] ?? '').toString(),
      enterBy: (data['enterBy'] ?? '').toString(),
      enterDate: (data['enterDate'] ?? '').toString(),
      reqStatus: (data['reqStatus'] ?? data['status'] ?? '').toString(),
      passNo: (data['passNo'] as num?)?.toInt() ?? 0,
      documents: docsRaw.map((e) {
        final m = e as Map<String, dynamic>;
        return PassDocument(
          documentId: (m['documentId'] as num?)?.toInt(),
          documentType: (m['documentType'] ?? '').toString(),
          documentNo: (m['documentNo'] ?? '').toString(),
          expiryDate: (m['expiryDate'] ?? '').toString(),
          fileKey: (m['fileKey'] ?? '').toString(),
          fileName: (m['fileName'] ?? '').toString(),
          existingFile: (m['existingFile'] ?? m['fileName'] ?? '').toString(),
          file: null,
        );
      }).toList(),
    );
  }

  String _extractError(String body, String fallback) {
    try {
      final m = jsonDecode(body);
      if (m is Map<String, dynamic>) {
        return (m['message'] ?? m['error'] ?? fallback).toString();
      }
    } catch (_) {}
    return fallback;
  }
}

class UploadFilePart {
  final String key;
  final String path;
  final String filename;

  UploadFilePart({
    required this.key,
    required this.path,
    required this.filename,
  });
}
