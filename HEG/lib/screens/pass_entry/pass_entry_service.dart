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

  Map<String, String> get _headers => {
        'x-api-key': apiKey,
      };

  Future<PassRegistryResponseDTO> loadPass(int id) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/passes/list/$id'),
      headers: _headers,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Unable to load pass details');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return _mapPassResponse(data);
  }

  Future<List<HistoryRecord>> loadHistory(int id) async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/history/$id'),
      headers: _headers,
    );

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
      Uri.parse('$baseUrl/api/passes/documents/download/$documentId'),
      headers: _headers,
    );
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
      reqStatus: (data['reqStatus'] ?? '').toString(),
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
        );
      }).toList(),
    );
  }
}