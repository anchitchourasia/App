// HEG/lib/services/vpms_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_model.dart';
import '../core/vpms_config.dart'; // ← THIS was missing

Map<String, String> get _headers => {
  'X-API-KEY': VpmsConfig.apiKey,
  'Content-Type': 'application/json',
};

class VpmsService {
  // ── GET /api/vehicles/list ──────────────────────────────
  Future<List<VehicleModel>> getVehicles() async {
    // 🔧 DUMMY MODE
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return List<VehicleModel>.from(VpmsConfig.dummyVehicles);
    }
    // 🌐 LIVE API
    final response = await http.get(
      Uri.parse(VpmsConfig.vehicles),
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
    // 🔧 DUMMY MODE
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newId =
          VpmsConfig.dummyVehicles
              .map((v) => v.vehicleId ?? 0)
              .reduce((a, b) => a > b ? a : b) +
          1;
      VpmsConfig.dummyVehicles.add(
        VehicleModel(
          vehicleId: newId,
          vehicleNo: vehicle.vehicleNo,
          vehicleType: vehicle.vehicleType,
          vehicleClass: vehicle.vehicleClass,
          brandModel: vehicle.brandModel,
          isActive: vehicle.isActive,
          isBlacklisted: vehicle.isBlacklisted,
        ),
      );
      return;
    }
    // 🌐 LIVE API
    final response = await http.post(
      Uri.parse(VpmsConfig.vehicleRegister),
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
    if (vehicle.vehicleId == null) throw Exception('vehicleId is null');
    // 🔧 DUMMY MODE
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = VpmsConfig.dummyVehicles.indexWhere(
        (v) => v.vehicleId == vehicle.vehicleId,
      );
      if (idx != -1) VpmsConfig.dummyVehicles[idx] = vehicle;
      return;
    }
    // 🌐 LIVE API
    final response = await http.put(
      Uri.parse('${VpmsConfig.vehicleUpdate}/${vehicle.vehicleId}'),
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
  Future<void> deleteVehicle(int vehicleId) async {
    // 🔧 DUMMY MODE
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 400));
      VpmsConfig.dummyVehicles.removeWhere((v) => v.vehicleId == vehicleId);
      return;
    }
    // 🌐 LIVE API — returns plain text, NOT JSON
    final response = await http.delete(
      Uri.parse('${VpmsConfig.vehicleDelete}/$vehicleId'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Delete failed: ${response.statusCode} — ${response.body}',
      );
    }
  }
}
