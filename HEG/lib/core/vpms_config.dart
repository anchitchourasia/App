// lib/core/vpms_config.dart

import '../models/vehicle_model.dart';
import '../models/pass_model.dart';

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

  // ── Vehicle endpoints ─────────────────────────────
  static const String vehicles = '$baseUrl/api/vehicles/list';
  static const String vehicleRegister = '$baseUrl/api/vehicles/register';
  static const String vehicleUpdate = '$baseUrl/api/vehicles/update';
  static const String vehicleDelete = '$baseUrl/api/vehicles/delete';

  // ── Pass Registry endpoints ───────────────────────
  static const String passes = '$baseUrl/api/passes/list';
  static const String passIssue = '$baseUrl/api/passes/issue';
  static const String passUpdate = '$baseUrl/api/passes/update';

  // MISSING — need to add these:
  static const String documents = '$baseUrl/api/documents/list';
  static const String gateLogs = '$baseUrl/api/gate-logs/list';
  static const String history = '$baseUrl/api/history/list';
  static const String compliance = '$baseUrl/api/compliance/list';

  // ════════════════════════════════════════════════════
  // 📦 DUMMY — Vehicles Master (11 records)
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

  // ════════════════════════════════════════════════════
  // 📦 DUMMY — Pass Registry (10 records)
  //    mirrors the web UI screenshot you shared
  // ════════════════════════════════════════════════════
  static final List<PassModel> dummyPasses = [
    PassModel(
      passId: 8,
      issueDate: '2026-06-01',
      validityDate: '2026-12-31',
      employeeNo: 'EMP883940',
      employeeCompanyNo: 'HEG001',
      dept: 'PRODUCTION',
      contractorCode: null,
      gateNo: 'GATE_01',
      parkingToBeUsed: 'P-Block',
      vehicleId: 65,
      typeOfVehicle: 'Four_Wheeler',
      mobileNo: '9876543210',
      status: 'Active',
      isActive: 'Y',
      empType: 'Company_Employee',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
    PassModel(
      passId: 11,
      issueDate: '2026-06-01',
      validityDate: '2026-12-01',
      employeeNo: null,
      employeeCompanyNo: null,
      dept: 'IT-INFRA',
      contractorCode: 'CON-11',
      gateNo: 'GATE_02',
      parkingToBeUsed: 'A-Block',
      vehicleId: 40,
      typeOfVehicle: 'Commercial Truck',
      mobileNo: '9988776655',
      status: 'Expired',
      isActive: 'N',
      empType: 'Contractor',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
    PassModel(
      passId: 9,
      issueDate: '2026-06-01',
      validityDate: '2026-12-31',
      employeeNo: 'EMP10023',
      employeeCompanyNo: 'HEG002',
      dept: 'ENGINEERING',
      contractorCode: null,
      gateNo: 'GATE_02',
      parkingToBeUsed: 'B-Block',
      vehicleId: 47,
      typeOfVehicle: 'Two_Wheeler',
      mobileNo: '9871234560',
      status: 'Active',
      isActive: 'Y',
      empType: 'Company_Employee',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
    PassModel(
      passId: 12,
      issueDate: '2026-06-01',
      validityDate: '2026-12-31',
      employeeNo: null,
      employeeCompanyNo: null,
      dept: 'RAW_MATERIAL',
      contractorCode: 'CONT-12',
      gateNo: 'GATE_03',
      parkingToBeUsed: 'Heavy Yard',
      vehicleId: 1,
      typeOfVehicle: 'Heavy Tipper',
      mobileNo: '9800001111',
      status: 'Active',
      isActive: 'Y',
      empType: 'Contractor',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
    PassModel(
      passId: 16,
      issueDate: '2026-06-01',
      validityDate: '2026-06-02',
      employeeNo: 'EMP005',
      employeeCompanyNo: 'HEG005',
      dept: 'IT',
      contractorCode: null,
      gateNo: 'GATE_01',
      parkingToBeUsed: 'P-Block',
      vehicleId: 82,
      typeOfVehicle: 'bike',
      mobileNo: '9810101010',
      status: 'Active',
      isActive: 'Y',
      empType: 'Company_Employee',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
    PassModel(
      passId: 19,
      issueDate: '2026-06-02',
      validityDate: '2026-06-03',
      employeeNo: 'EMP005',
      employeeCompanyNo: 'HEG003',
      dept: 'it',
      contractorCode: null,
      gateNo: 'GATE_02',
      parkingToBeUsed: null,
      vehicleId: 83,
      typeOfVehicle: 'bike',
      mobileNo: '9820202020',
      status: 'Expired',
      isActive: 'N',
      empType: 'Company_Employee',
      enterBy: 'ADMIN',
      enterDate: '2026-06-02',
      remarks: '',
    ),
    PassModel(
      passId: 3,
      issueDate: '2026-05-29',
      validityDate: '2026-12-31',
      employeeNo: 'EMP88391',
      employeeCompanyNo: 'HEG004',
      dept: 'PRODUCTION',
      contractorCode: null,
      gateNo: 'GATE_01',
      parkingToBeUsed: 'P-Block',
      vehicleId: 53,
      typeOfVehicle: 'Four_Wheeler',
      mobileNo: '9830303030',
      status: 'Suspended',
      isActive: 'Y',
      empType: 'Contractor',
      enterBy: 'ADMIN',
      enterDate: '2026-05-29',
      remarks: '',
    ),
    PassModel(
      passId: 10,
      issueDate: '2026-06-01',
      validityDate: '2026-06-02',
      employeeNo: 'EMP88',
      employeeCompanyNo: 'HEG006',
      dept: 'IT',
      contractorCode: null,
      gateNo: 'GATE_01',
      parkingToBeUsed: 'A-Block',
      vehicleId: 48,
      typeOfVehicle: 'BIKE',
      mobileNo: '9840404040',
      status: 'Active',
      isActive: 'Y',
      empType: 'Company_Employee',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
    PassModel(
      passId: 17,
      issueDate: '2026-06-15',
      validityDate: '2027-06-15',
      employeeNo: null,
      employeeCompanyNo: null,
      dept: 'QUALITY_ASSURANCE',
      contractorCode: 'EMP-4412',
      gateNo: 'GATE_02',
      parkingToBeUsed: 'B-Block',
      vehicleId: 52,
      typeOfVehicle: 'Two_Wheeler',
      mobileNo: '9850505050',
      status: 'Pending',
      isActive: 'Y',
      empType: 'Contractor',
      enterBy: 'ADMIN',
      enterDate: '2026-06-15',
      remarks: '',
    ),
    PassModel(
      passId: 5,
      issueDate: '2026-06-01',
      validityDate: '2027-06-01',
      employeeNo: null,
      employeeCompanyNo: null,
      dept: 'Human Resources',
      contractorCode: 'EXEC-0024',
      gateNo: 'GATE_01',
      parkingToBeUsed: 'P-Block',
      vehicleId: 62,
      typeOfVehicle: 'Sedan',
      mobileNo: '9860606060',
      status: 'Active',
      isActive: 'Y',
      empType: 'Contractor',
      enterBy: 'ADMIN',
      enterDate: '2026-06-01',
      remarks: '',
    ),
  ];
}
