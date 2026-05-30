// HEG/lib/services/vpms_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_model.dart'; // ← import from YOUR existing model file

const String _baseUrl =
    'http://192.168.8.28:8090/vehiclePassManagementSystem-0.0.1-SNAPSHOT';
const String _apiKey = 'VPMS_SECRET_KEY_2026';

Map<String, String> get _headers => {
  'X-API-KEY': _apiKey,
  'Content-Type': 'application/json',
};

class VpmsService {
  // ── GET /api/vehicles/list ──────────────────────────────
  Future<List<VehicleModel>> getVehicles() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/vehicles/list'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => VehicleModel.fromJson(e)).toList();
    } else {
      throw Exception('GET failed: ${response.statusCode} — ${response.body}');
    }
  }

  // ── POST /api/vehicles/register ────────────────────────
  Future<void> registerVehicle(VehicleModel vehicle) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/vehicles/register'),
      headers: _headers,
      body: jsonEncode(vehicle.toPostJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String serverMsg = response.body;
      try {
        final decoded = jsonDecode(response.body);
        serverMsg = decoded['message'] ?? decoded.toString();
      } catch (_) {}
      throw Exception(serverMsg);
    }
  }

  // ── PUT /api/vehicles/update/{vehicleId} ────────────────
  Future<void> updateVehicle(VehicleModel vehicle) async {
    if (vehicle.vehicleId == null) {
      throw Exception('Cannot update: vehicleId is null');
    }
    final response = await http.put(
      Uri.parse('$_baseUrl/api/vehicles/update/${vehicle.vehicleId}'),
      headers: _headers,
      body: jsonEncode(vehicle.toPutJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      String serverMsg = response.body;
      try {
        final decoded = jsonDecode(response.body);
        serverMsg = decoded['message'] ?? decoded.toString();
      } catch (_) {}
      throw Exception(serverMsg);
    }
  }

  // ── DELETE /api/vehicles/delete/{vehicleId} ─────────────
  // ⚠️ Backend returns plain TEXT — don't JSON decode (same as Angular's responseType:'text')
  Future<void> deleteVehicle(int vehicleId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/vehicles/delete/$vehicleId'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Delete failed: ${response.statusCode} — ${response.body}',
      );
    }
  }
}
