import 'package:flutter/material.dart';

import '../../data/cvps_api.dart';

class DriverDetailsData {
  final String role;
  final String empNo;
  final String name;
  final String eyeTestDate;
  final String eyeTestFileName;
  final String mobileNo;
  final String aadhaarNo;
  final String licenseNo;
  final String licenseType;
  final String licenseFrom;
  final String licenseTo;
  final String aadhaarFileName;
  final String photoFileName;
  final String licenseFileName;

  const DriverDetailsData({
    required this.role,
    required this.empNo,
    required this.name,
    required this.eyeTestDate,
    required this.eyeTestFileName,
    required this.mobileNo,
    required this.aadhaarNo,
    required this.licenseNo,
    required this.licenseType,
    required this.licenseFrom,
    required this.licenseTo,
    required this.aadhaarFileName,
    required this.photoFileName,
    required this.licenseFileName,
  });

  DriverDetailsData copyWithApiData(Map<String, dynamic> data) {
    return DriverDetailsData(
      role: _first(data, ['empType', 'empJob', 'role'], role),
      empNo: _first(data, ['empNo', 'employeeNo', 'employeeCode'], empNo),
      name: _first(
        data,
        ['empName', 'employeeName', 'name', 'EMP_NAME', 'EMPLOYEENAME'],
        name,
      ),
      eyeTestDate: _first(
        data,
        ['eyeTestDate', 'eyetestdate'],
        eyeTestDate,
      ),
      eyeTestFileName: _fileName(
        _first(
          data,
          ['eyeTestFile', 'eyeTestFileName', 'eyeTestDocument'],
          eyeTestFileName,
        ),
      ),
      mobileNo: _first(
        data,
        ['mobileNo', 'mobile', 'phoneNo', 'phone', 'contactNo'],
        mobileNo,
      ),
      aadhaarNo: _first(
        data,
        ['aadhaarNo', 'aadharNo', 'aadhaar', 'aadhar'],
        aadhaarNo,
      ),
      licenseNo: _first(
        data,
        ['licenseNo', 'licenseNumber', 'licenceNo', 'dlNo'],
        licenseNo,
      ),
      licenseType: _first(
        data,
        ['licenseType', 'licenceType', 'dlType'],
        licenseType,
      ),
      licenseFrom: _date(
        _first(
          data,
          ['licenseActDate', 'licenseFrom', 'licenseValidFrom', 'validFrom'],
          licenseFrom,
        ),
      ),
      licenseTo: _date(
        _first(
          data,
          ['licenseExpDate', 'licenseTo', 'licenseValidTo', 'validTill'],
          licenseTo,
        ),
      ),
      aadhaarFileName: _fileName(
        _first(
          data,
          ['aadharFile', 'aadhaarFile', 'aadhaarFileName'],
          aadhaarFileName,
        ),
      ),
      photoFileName: _fileName(
        _first(
          data,
          ['empPhoto', 'photoFile', 'photoFileName'],
          photoFileName,
        ),
      ),
      licenseFileName: _fileName(
        _first(
          data,
          ['licenseFile', 'licenceFile', 'licenseFileName'],
          licenseFileName,
        ),
      ),
    );
  }

  static String _first(
    Map<String, dynamic> data,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  static String _fileName(String value) {
    if (value.trim().isEmpty) return '';
    return value.replaceAll('\\', '/').split('/').last;
  }

  static String _date(String value) {
    if (value.trim().isEmpty) return '';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }
}

class DriverDetailsSheet extends StatefulWidget {
  final CvpsApi api;
  final DriverDetailsData driver;

  const DriverDetailsSheet({
    super.key,
    required this.api,
    required this.driver,
  });

  @override
  State<DriverDetailsSheet> createState() => _DriverDetailsSheetState();
}

class _DriverDetailsSheetState extends State<DriverDetailsSheet> {
  late DriverDetailsData _driver;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    if (_driver.empNo.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.api.fetchManpowerDocuments(
        _driver.empNo.trim(),
      );

      if (result != null) {
        final data = _unwrapResponse(result);

        if (mounted) {
          setState(() {
            _driver = _driver.copyWithApiData(data);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load additional driver details.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> _unwrapResponse(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FB),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_search_outlined,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Driver Information',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102A43),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(14),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            if (_error != null)
                              _message(_error!),
                            _section(
                              'Basic Details',
                              [
                                _field('Name', _driver.name),
                                _field('Role', _driver.role),
                                _field('Employee Code', _driver.empNo),
                                _field('Mobile Number', _driver.mobileNo),
                                _field('Aadhaar Number', _driver.aadhaarNo),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _section(
                              'Driving Licence',
                              [
                                _field('Licence Number', _driver.licenseNo),
                                _field('Licence Type', _driver.licenseType),
                                _field('Valid From', _driver.licenseFrom),
                                _field('Valid To', _driver.licenseTo),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _section(
                              'Documents',
                              [
                                _field('Aadhaar File', _driver.aadhaarFileName),
                                _field('Photo File', _driver.photoFileName),
                                _field('Licence File', _driver.licenseFileName),
                                _field('Eye Test Date', _driver.eyeTestDate),
                                _field('Eye Test File', _driver.eyeTestFileName),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    final display = value.trim().isEmpty ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            display,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}