// HEG/lib/models/vehicle_model.dart

class VehicleModel {
  final int? vehicleId;
  final String vehicleNo;
  final String vehicleType;
  final String vehicleClass;
  final String? brandModel;
  final String isActive; // 'Y' or 'N'
  final String isBlacklisted; // 'Y' or 'N'

  VehicleModel({
    this.vehicleId,
    required this.vehicleNo,
    required this.vehicleType,
    required this.vehicleClass,
    this.brandModel,
    required this.isActive,
    required this.isBlacklisted,
  });

  // ── Parse from GET response ────────────────────────────
  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    vehicleId: json['vehicleId'],
    vehicleNo: json['vehicleNo'] ?? '',
    vehicleType: json['vehicleType'] ?? '',
    vehicleClass: json['vehicleClass'] ?? '',
    brandModel: json['brandModel'],
    isActive: json['isActive'] ?? 'N',
    isBlacklisted: json['isBlacklisted'] ?? 'N',
  );

  // ── POST body — full object (vehicleNo included) ───────
  Map<String, dynamic> toPostJson() => {
    'vehicleNo': vehicleNo,
    'vehicleType': vehicleType,
    'vehicleClass': vehicleClass,
    'brandModel': brandModel ?? '',
    'isActive': isActive,
    'isBlacklisted': isBlacklisted,
  };

  // ── PUT body — NO vehicleNo (matches Angular's updatePayload) ──
  Map<String, dynamic> toPutJson() => {
    'vehicleType': vehicleType,
    'vehicleClass': vehicleClass,
    'brandModel': brandModel ?? '',
    'isActive': isActive,
    'isBlacklisted': isBlacklisted,
  };

  // ── Helpers used in UI ─────────────────────────────────
  bool get isActiveVehicle => isActive == 'Y';
  bool get isBlacklistedVehicle => isBlacklisted == 'Y';
}
