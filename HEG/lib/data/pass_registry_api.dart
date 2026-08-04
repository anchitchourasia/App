import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pass_registry_item.dart';

class PassRegistryApi {
  static const String baseUrl = 'http://10.0.2.2:3031/vpms';
  static const String apiKey = 'VPMS_SECRET_KEY_2026';
  static const String passListV1 = '$baseUrl/api/passes/listV1';

  static Map<String, String> get headers => const {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
      };

  Future<List<PassRegistryItem>> fetchPassRegistry() async {
    final response = await http.get(Uri.parse(passListV1), headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load pass registry. HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid response format. Expected JSON array.');
    }

    return decoded
        .map((e) => PassRegistryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}