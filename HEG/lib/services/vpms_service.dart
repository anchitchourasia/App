// HEG/lib/services/vpms_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_model.dart';
import '../models/pass_model.dart';
import '../core/vpms_config.dart'; // ← THIS was missing in repo

Map<String, String> get _headers => {
  'X-API-KEY': VpmsConfig.apiKey,
  'Content-Type': 'application/json',
};

class VpmsService {
  // ══════════════════════════════════════════════════
  // VEHICLES MASTER
  // ══════════════════════════════════════════════════

  Future<List<VehicleModel>> getVehicles() async {
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return List<VehicleModel>.from(VpmsConfig.dummyVehicles);
    }
    // 🌐 LIVE — throws on any failure so UI shows error
    final response = await http
        .get(Uri.parse(VpmsConfig.vehicles), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => VehicleModel.fromJson(e)).toList();
    }
    throw Exception(
      'GET vehicles failed: ${response.statusCode} — ${response.body}',
    );
  }

  Future<void> registerVehicle(VehicleModel vehicle) async {
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
    final response = await http
        .post(
          Uri.parse(VpmsConfig.vehicleRegister),
          headers: _headers,
          body: jsonEncode(vehicle.toPostJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = response.body;
      try {
        msg = jsonDecode(response.body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    if (vehicle.vehicleId == null) throw Exception('vehicleId is null');
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = VpmsConfig.dummyVehicles.indexWhere(
        (v) => v.vehicleId == vehicle.vehicleId,
      );
      if (idx != -1) VpmsConfig.dummyVehicles[idx] = vehicle;
      return;
    }
    final response = await http
        .put(
          Uri.parse('${VpmsConfig.vehicleUpdate}/${vehicle.vehicleId}'),
          headers: _headers,
          body: jsonEncode(vehicle.toPutJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      String msg = response.body;
      try {
        msg = jsonDecode(response.body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ⚠️ Backend returns plain TEXT — don't JSON decode
  Future<void> deleteVehicle(int vehicleId) async {
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 400));
      VpmsConfig.dummyVehicles.removeWhere((v) => v.vehicleId == vehicleId);
      return;
    }
    final response = await http
        .delete(
          Uri.parse('${VpmsConfig.vehicleDelete}/$vehicleId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Delete failed: ${response.statusCode} — ${response.body}',
      );
    }
  }

  // ══════════════════════════════════════════════════
  // PASS REGISTRY
  // ══════════════════════════════════════════════════

  Future<List<PassModel>> getPasses() async {
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return List<PassModel>.from(VpmsConfig.dummyPasses);
    }
    final response = await http
        .get(Uri.parse(VpmsConfig.passes), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PassModel.fromJson(e)).toList();
    }
    throw Exception('GET passes failed: ${response.statusCode}');
  }

  Future<void> issuePass(PassModel pass) async {
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newId =
          VpmsConfig.dummyPasses
              .map((p) => p.passId ?? 0)
              .reduce((a, b) => a > b ? a : b) +
          1;
      VpmsConfig.dummyPasses.insert(
        0,
        PassModel(
          passId: newId,
          issueDate: pass.issueDate,
          validityDate: pass.validityDate,
          employeeNo: pass.employeeNo,
          employeeCompanyNo: pass.employeeCompanyNo,
          dept: pass.dept,
          contractorCode: pass.contractorCode,
          gateNo: pass.gateNo,
          parkingToBeUsed: pass.parkingToBeUsed,
          vehicleId: pass.vehicleId,
          typeOfVehicle: pass.typeOfVehicle,
          mobileNo: pass.mobileNo,
          status: pass.status,
          remarks: pass.remarks,
          isActive: pass.isActive,
          empType: pass.empType,
          enterBy: 'ADMIN',
          enterDate: DateTime.now().toIso8601String().split('T')[0],
        ),
      );
      return;
    }
    final response = await http
        .post(
          Uri.parse(VpmsConfig.passIssue),
          headers: _headers,
          body: jsonEncode(pass.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = response.body;
      try {
        msg = jsonDecode(response.body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> updatePass(PassModel pass) async {
    if (pass.passId == null) throw Exception('passId is null');
    if (VpmsConfig.useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = VpmsConfig.dummyPasses.indexWhere(
        (p) => p.passId == pass.passId,
      );
      if (idx != -1) VpmsConfig.dummyPasses[idx] = pass;
      return;
    }
    final response = await http
        .put(
          Uri.parse('${VpmsConfig.passUpdate}/${pass.passId}'),
          headers: _headers,
          body: jsonEncode(pass.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      String msg = response.body;
      try {
        msg = jsonDecode(response.body)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
