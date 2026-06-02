// lib/models/pass_model.dart

class PassModel {
  final int? passId;
  final String issueDate;
  final String validityDate;
  final String? employeeNo;
  final String? employeeCompanyNo;
  final String? dept;
  final String? contractorCode;
  final String gateNo;
  final String? parkingToBeUsed;
  final int? vehicleId;
  final String? typeOfVehicle;
  final String? mobileNo;
  final String status;
  final String? remarks;
  final String isActive;
  final String empType;
  final String? enterBy;
  final String? enterDate;

  PassModel({
    this.passId,
    required this.issueDate,
    required this.validityDate,
    this.employeeNo,
    this.employeeCompanyNo,
    this.dept,
    this.contractorCode,
    required this.gateNo,
    this.parkingToBeUsed,
    this.vehicleId,
    this.typeOfVehicle,
    this.mobileNo,
    required this.status,
    this.remarks,
    required this.isActive,
    required this.empType,
    this.enterBy,
    this.enterDate,
  });

  // ── Parse from GET response ──────────────────────────
  factory PassModel.fromJson(Map<String, dynamic> json) => PassModel(
    passId: json['passId'],
    issueDate: json['issueDate'] ?? '',
    validityDate: json['validityDate'] ?? '',
    employeeNo: json['employeeNo'],
    employeeCompanyNo: json['employeeCompanyNo'],
    dept: json['dept'],
    contractorCode: json['contractorCode'],
    gateNo: json['gateNo'] ?? '',
    parkingToBeUsed: json['parkingToBeUsed'],
    vehicleId: json['vehicle']?['vehicleId'] ?? json['vehicleId'],
    typeOfVehicle: json['typeOfVehicle'],
    mobileNo: json['mobileNo'],
    status: json['status'] ?? 'Active',
    remarks: json['remarks'],
    isActive: json['isActive'] ?? 'Y',
    empType: json['empType'] ?? 'Company_Employee',
    enterBy: json['enterBy'],
    enterDate: json['enterDate'],
  );

  // ── POST / PUT body ──────────────────────────────────
  Map<String, dynamic> toJson() => {
    'vehicle': {'vehicleId': vehicleId},
    'typeOfVehicle': typeOfVehicle,
    'empType': empType,
    'dept': dept,
    'mobileNo': mobileNo,
    'issueDate': issueDate,
    'validityDate': validityDate,
    'gateNo': gateNo,
    'parkingToBeUsed': parkingToBeUsed,
    'status': status,
    'isActive': isActive,
    'remarks': remarks,
    'enterBy': 'ADMIN',
    'enterDate': DateTime.now().toIso8601String().split('T')[0],
    'employeeNo': empType == 'Company_Employee' ? employeeNo : null,
    'employeeCompanyNo': empType == 'Company_Employee'
        ? employeeCompanyNo
        : null,
    'contractorCode': empType == 'Contractor' ? contractorCode : null,
  };

  // ── Helpers ──────────────────────────────────────────
  String get displayName =>
      (empType == 'Contractor' ? contractorCode : employeeNo) ?? '—';

  bool get isExpired {
    if (validityDate.isEmpty) return false;
    return DateTime.tryParse(validityDate)?.isBefore(DateTime.now()) ?? false;
  }
}
