/// Data model for a single CVPS vehicle permission row.
/// This mirrors the VehiclePermissionRow interface in vehicle-permission-list.ts.
class CvpsRequestItem {
  /// Unique request number (primary key).
  final int requestNo;

  /// Contractor code (e.g. contractor ID from CVPS).
  final String contractorCode;

  /// Vehicle number (e.g. MP04 AB 1234).
  final String vehicleNo;

  /// Vehicle type (e.g. FOUR_WHEEL, HEAVY).
  final String vehicleType;

  /// Text describing the nature of job.
  final String natureOfJob;

  /// Permission date (To) formatted as YYYY-MM-DD (web uses formatDate).
  final String permissionTo;

  /// Normalized request status (web’s normalizeRequestStatus).
  final String reqStatus;

  /// Who created this request (emp code).
  final String createdBy;

  /// Created date formatted as YYYY-MM-DD.
  final String createdDate;

  /// Count of personnel (employees array length).
  final int personnelCount;

  /// Count of vehicle documents (vehicleDocuments array length).
  final int vehicleDocumentCount;

  CvpsRequestItem({
    required this.requestNo,
    required this.contractorCode,
    required this.vehicleNo,
    required this.vehicleType,
    required this.natureOfJob,
    required this.permissionTo,
    required this.reqStatus,
    required this.createdBy,
    required this.createdDate,
    required this.personnelCount,
    required this.vehicleDocumentCount,
  });

  /// Factory that maps a CreateRequestDTO JSON into this row.
  /// This is equivalent to mapToRow(dto: CreateRequestDTO) in the web code.
  factory CvpsRequestItem.fromCreateRequestDto(Map<String, dynamic> dto) {
    // request object inside CreateRequestDTO
    final req = dto['request'] as Map<String, dynamic>? ?? {};

    // Helper to extract dates and keep only YYYY-MM-DD.
    String formatDate(dynamic value) {
      if (value == null) return '';
      final s = value.toString();
      // Web splits on 'T', so do the same.
      return s.split('T').first;
    }

    // Web normalizeRequestStatus: DRAFT -> SAVED, CREATED -> SUBMITTED, etc.
    String normalizeStatus(dynamic status) {
      final normalized = (status ?? '').toString().trim().toUpperCase();
      switch (normalized) {
        case 'DRAFT':
          return 'SAVED';
        case 'MODIFY':
          return 'MODIFY';
        case 'CREATED':
          return 'SUBMITTED';
        default:
          return normalized;
      }
    }

    // employees and vehicleDocuments arrays from DTO.
    final employees = dto['employees'] as List<dynamic>? ?? const [];
    final vehicleDocs = dto['vehicleDocuments'] as List<dynamic>? ?? const [];

    return CvpsRequestItem(
      requestNo: int.tryParse('${req['requestNo'] ?? 0}') ?? 0,
      contractorCode: (req['contractorId'] ?? '').toString(),
      vehicleNo: (req['vehicleNo'] ?? '').toString(),
      vehicleType: (req['vehicleType'] ?? '').toString(),
      natureOfJob: (req['natureOfJob'] ?? '').toString(),
      permissionTo: formatDate(req['permissionTo']),
      reqStatus: normalizeStatus(req['reqStatus']),
      createdBy: (req['createdBy'] ?? '').toString(),
      createdDate: formatDate(req['createdDate']),
      personnelCount: employees.length,
      vehicleDocumentCount: vehicleDocs.length,
    );
  }
}
