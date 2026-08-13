class CvpsDriver {
  final String role;             // e.g. 'Driver', 'Helper'
  final String name;
  final String mobileNo;
  final String aadhaarNo;
  final String licenseNo;
  final String licenseValidTill; // ISO string, e.g. '2026-09-05'

  CvpsDriver({
    required this.role,
    required this.name,
    required this.mobileNo,
    required this.aadhaarNo,
    required this.licenseNo,
    required this.licenseValidTill,
  });
}