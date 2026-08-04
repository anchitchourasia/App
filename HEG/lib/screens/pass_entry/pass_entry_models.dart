class PassDocument {
  final int? documentId;
  String documentType;
  String documentNo;
  String expiryDate;
  String fileKey;
  String fileName;
  String existingFile;
  dynamic file;

  PassDocument({
    required this.documentId,
    required this.documentType,
    required this.documentNo,
    required this.expiryDate,
    required this.fileKey,
    required this.fileName,
    required this.existingFile,
    this.file,
  });

  factory PassDocument.empty() => PassDocument(
        documentId: null,
        documentType: '',
        documentNo: '',
        expiryDate: '',
        fileKey: '',
        fileName: '',
        existingFile: '',
      );
}

class HistoryRecord {
  final int? id;
  final String passNo;
  final String empCode;
  final String action;
  final String remark;
  final String dateOfEntry;

  const HistoryRecord({
    required this.id,
    required this.passNo,
    required this.empCode,
    required this.action,
    required this.remark,
    required this.dateOfEntry,
  });
}

class EmployeeLookupResponse {
  final String? employeeNo;
  final String? name;
  final String? deptCode;
  final String? deptName;
  final String? contractorCode;
  final String? contractorName;
  final String? aadhaarNo;
  final String? empType;

  const EmployeeLookupResponse({
    this.employeeNo,
    this.name,
    this.deptCode,
    this.deptName,
    this.contractorCode,
    this.contractorName,
    this.aadhaarNo,
    this.empType,
  });
}

class PassRegistryResponseDTO {
  final int id;
  final String vehicleNo;
  final String vehicleType;
  final String brandModel;
  final String employeeNo;
  final String empType;
  final String contractorCode;
  final String gateNo;
  final String parkingToBeUsed;
  final String enterBy;
  final String enterDate;
  final String reqStatus;
  final int passNo;
  final List<PassDocument> documents;

  const PassRegistryResponseDTO({
    required this.id,
    required this.vehicleNo,
    required this.vehicleType,
    required this.brandModel,
    required this.employeeNo,
    required this.empType,
    required this.contractorCode,
    required this.gateNo,
    required this.parkingToBeUsed,
    required this.enterBy,
    required this.enterDate,
    required this.reqStatus,
    required this.passNo,
    required this.documents,
  });
}

class PassStatus {
  static const DRAFT = 'DRAFT';
  static const SAVED = 'SAVED';
  static const SUBMITTED = 'SUBMITTED';
  static const CONFIRMED = 'CONFIRMED';
  static const APPROVED = 'APPROVED';
  static const REJECT = 'REJECT';
  static const REGRET = 'REJECT';
  static const MODIFY = 'MODIFY';
  static const NEEDS_MODIFICATION = 'NEEDS_MODIFICATION';
}

const List<String> allowedDocTypes = ['RC', 'INSURANCE', 'LICENSE'];