// lib/core/vpms_config.dart

import '../models/vehicle_model.dart';

class VpmsConfig {
  VpmsConfig._();

  // ════════════════════════════════════════════════════
  // 🔧 TOGGLE: set to false when backend API is ready
  // ════════════════════════════════════════════════════
  static const bool useDummyData = false; // ← change to false for real API
  // ════════════════════════════════════════════════════

  static const String baseUrl =
      'http://192.168.8.28:8090/vehiclePassManagementSystem-0.0.1-SNAPSHOT';

  static const String apiKey = 'VPMS_SECRET_KEY_2026';

  static const String vehicles = '$baseUrl/api/vehicles/list';
  static const String vehicleRegister = '$baseUrl/api/vehicles/register';
  static const String vehicleUpdate = '$baseUrl/api/vehicles/update';
  static const String vehicleDelete = '$baseUrl/api/vehicles/delete';

  // ════════════════════════════════════════════════════
  // 📦 DUMMY DATA — mirrors Angular's DUMMY_VEHICLES
  //    same 11 records you see in your web UI table
  // ════════════════════════════════════════════════════
  static final List<VehicleModel> dummyVehicles = [
    VehicleModel(
      vehicleId: 65,
      vehicleNo: 'MP29HEG2003',
      vehicleType: 'CAR',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'HONDA',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 40,
      vehicleNo: 'MP04HEG1111',
      vehicleType: 'cycle',
      vehicleClass: 'Two_Wheeler',
      brandModel: 'hero',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 47,
      vehicleNo: 'DL01CAB1234',
      vehicleType: 'SUV',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'Toyota Fortuner',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 53,
      vehicleNo: 'MP-04-XX-9999',
      vehicleType: 'SUV',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'audi A3',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 48,
      vehicleNo: 'MP-04-XX-8888',
      vehicleType: 'SUV',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'Tata Harrier',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 52,
      vehicleNo: 'MP-04-XX-7777',
      vehicleType: 'SUV',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'audi',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 62,
      vehicleNo: 'MP04CC1264',
      vehicleType: 'SUV',
      vehicleClass: 'Four_Wheeler',
      brandModel: null,
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 81,
      vehicleNo: 'MP04HE2026',
      vehicleType: 'SUV',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'Tata Nexon',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 82,
      vehicleNo: 'MP04HEG5555',
      vehicleType: 'Sedan',
      vehicleClass: 'Four_Wheeler',
      brandModel: 'Honda City',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 1,
      vehicleNo: 'MP04HEG2026',
      vehicleType: 'Heavy Logistics Truck',
      vehicleClass: 'Heavy_Machinery',
      brandModel: 'Tata Prima 2830.K',
      isActive: 'Y',
      isBlacklisted: 'N',
    ),
    VehicleModel(
      vehicleId: 83,
      vehicleNo: 'MP04HEG9999',
      vehicleType: 'Bike',
      vehicleClass: 'Two_Wheeler',
      brandModel: 'Royal Enfield',
      isActive: 'N',
      isBlacklisted: 'N',
    ),
  ];
}
