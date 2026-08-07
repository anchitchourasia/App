import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'pass_entry_models.dart';
import 'pass_entry_widgets.dart';

class PassEntryForm extends StatefulWidget {
  final int? registryId;
  final bool isViewMode;
  final bool isApproverMode;

  const PassEntryForm({
    super.key,
    this.registryId,
    this.isViewMode = false,
    this.isApproverMode = false,
  });

  @override
  State<PassEntryForm> createState() => _PassEntryFormState();
}

class _PassEntryFormState extends State<PassEntryForm> {
  // ---------- Vehicle ----------
  final _vehicleNoCtrl = TextEditingController();
  String _vehicleType = '';
  final _brandModelCtrl = TextEditingController();

  // ---------- Employee ----------
  final _ecNoCtrl = TextEditingController();
  String _empType = ''; // HEG, TACC, CONTRACT, CRE-PRM

  bool _fetchingEmployee = false;
  String? _empFetchError;

  String _empName = '';
  String _empDept = '';
  String _empDeptCode = '';
  String _empAadhar = '';
  String _empContractorCode = '';
  String _empContractorName = '';

  // ---------- Pass Details ----------
  String _gateNo = '';
  String _parkingToBeUsed = '';

  // ---------- Workflow ----------
  String _status = 'DRAFT';
  int? _passNo;
  String? _remark;
  String _enterBy = '';

  // ---------- Documents ----------
  final List<PassDocumentModel> _documents = [
    PassDocumentModel(
      documentType: '',
      documentNo: '',
      expiryDate: '',
      fileKey: 'document_0',
      fileName: '',
    ),
  ];

  // ---------- UI State ----------
  bool _isSaving = false;
  String? _saveSuccess;
  String? _saveError;

  bool get _isReadOnly => widget.isViewMode;

  // ---------- Constants (same as web) ----------
  static const _vehicleTypes = [
    'BIKE',
    'SCOOTER',
    'CAR',
    'TRUCK',
    'DUMPER',
    'JCB',
    'CRANE',
    'TRACTOR',
  ];

  static const _empTypes = ['HEG', 'TACC', 'CONTRACT', 'CRE-PRM'];

  static const _gates = ['GATE_01', 'GATE_02', 'GATE_03', 'GATE_04', 'GATE_05'];

  static const _parkings = ['P1', 'P2', 'P3', 'P4', 'P5'];

  static const _allowedDocTypes = ['RC', 'INSURANCE', 'LICENSE'];

  // ---------- API config (match web) ----------
  // Replace with your real base URL / key
  static const _baseUrl = 'http://localhost:3031/vpms';
  static const _apiKey = 'VPMS_SECRET_KEY_2026';

  String get _employeeReportUrl => '$_baseUrl/api/reports/employee-department';
  String get _passSaveUrl => '$_baseUrl/api/passes/save';
  String get _passUpdateUrl => '$_baseUrl/api/passes/update';
  String get _passListUrl => '$_baseUrl/api/passes/list';
  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
    if (widget.registryId != null) {
      _loadPass(widget.registryId!);
    }
  }

  @override
  void dispose() {
    _vehicleNoCtrl.dispose();
    _brandModelCtrl.dispose();
    _ecNoCtrl.dispose();
    super.dispose();
  }

  void _loadLoggedInUser() {
    // TODO: read from your session store / secure storage
    _enterBy = 'SYSTEM';
  }

  // ---------- Employee lookup ----------
  Future<void> _loadEmployee() async {
    setState(() {
      _empFetchError = null;
      _fetchingEmployee = true;
    });

    final empNo = _ecNoCtrl.text.trim().toUpperCase();
    if (empNo.isEmpty) {
      setState(() => _fetchingEmployee = false);
      return;
    }

    try {
      final res = await http
          .get(
            Uri.parse('$_employeeReportUrl/$empNo'),
            headers: {'x-api-key': _apiKey},
          )
          .timeout(const Duration(milliseconds: 12000));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        final apiType = (data['empType'] ?? '').toString().trim().toUpperCase();
        if (apiType != _empType.trim().toUpperCase()) {
          setState(() {
            _empFetchError =
                'Employee Type mismatch. Selected: $_empType, Found: $apiType';
            _fetchingEmployee = false;
          });
          _clearEmployeeData();
          return;
        }

        setState(() {
          _empName = (data['name'] ?? '').toString();
          _empDept = (data['deptName'] ?? '').toString().toUpperCase();
          _empDeptCode = (data['deptCode'] ?? '').toString();
          _empAadhar = (data['aadhaarNo'] ?? data['aadharNo'] ?? '').toString();
          _empContractorCode = (data['contractorCode'] ?? '').toString();
          _empContractorName = (data['contractorName'] ?? '').toString();
          _fetchingEmployee = false;
        });
      } else {
        setState(() {
          _empFetchError =
              'Could not fetch employee details (${res.statusCode})';
          _fetchingEmployee = false;
        });
        _clearEmployeeData();
      }
    } catch (e) {
      setState(() {
        _empFetchError = 'Could not fetch employee details (Network Error)';
        _fetchingEmployee = false;
      });
      _clearEmployeeData();
    }
  }

  void _clearEmployeeData() {
    setState(() {
      _empName = '';
      _empDept = '';
      _empDeptCode = '';
      _empAadhar = '';
      _empContractorCode = '';
      _empContractorName = '';
    });
  }

  // ---------- Pass load ----------
  Future<void> _loadPass(int id) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/api/passes/list/$id'),
            headers: {'x-api-key': _apiKey},
          )
          .timeout(const Duration(milliseconds: 12000));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        setState(() {
          _vehicleNoCtrl.text = (data['vehicleNo'] ?? '').toString();
          _vehicleType = (data['vehicleType'] ?? '').toString();
          _brandModelCtrl.text = (data['brandModel'] ?? '').toString();
          _ecNoCtrl.text = (data['employeeNo'] ?? '').toString();
          _empType = (data['empType'] ?? '').toString();
          _gateNo = (data['gateNo'] ?? '').toString();
          _parkingToBeUsed = (data['parkingToBeUsed'] ?? '').toString();
          _status = (data['reqStatus'] ?? 'DRAFT').toString();
          _passNo = data['passNo'] as int?;
          _enterBy = (data['enterBy'] ?? '').toString();

          final docsJson = data['documents'] as List<dynamic>?;
          if (docsJson != null && docsJson.isNotEmpty) {
            _documents.clear();
            _documents.addAll(
              docsJson
                  .map(
                    (d) => PassDocumentModel(
                      documentId: d['documentId'] as int?,
                      documentType: (d['documentType'] ?? '').toString(),
                      documentNo: (d['documentNo'] ?? '').toString(),
                      expiryDate: (d['expiryDate'] ?? '').toString(),
                      fileKey: (d['fileKey'] ?? '').toString(),
                      fileName: (d['fileName'] ?? '').toString(),
                    ),
                  )
                  .toList(),
            );
          }

          _isSaving = false;
          _saveSuccess = 'Pass details loaded successfully.';
        });

        if (_ecNoCtrl.text.isNotEmpty) {
          _loadEmployee();
        }
      } else {
        setState(() {
          _saveError = 'Unable to load pass details.';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _saveError = 'Unable to load pass details.';
        _isSaving = false;
      });
    }
  }

  // ---------- Validation ----------
  bool _validateVehicle() {
    if (_vehicleNoCtrl.text.trim().isEmpty) {
      _saveError = 'Vehicle Number is required.';
      return false;
    }
    if (_vehicleType.trim().isEmpty) {
      _saveError = 'Vehicle Type is required.';
      return false;
    }
    if (_brandModelCtrl.text.trim().isEmpty) {
      _saveError = 'Brand / Model is required.';
      return false;
    }
    return true;
  }

  bool _validateEmployee() {
    if (_empType.trim().isEmpty) {
      _saveError = 'Please select Employee Type.';
      return false;
    }
    if (_ecNoCtrl.text.trim().isEmpty) {
      _saveError = 'Employee Code is required.';
      return false;
    }
    if (_empName.trim().isEmpty) {
      _saveError = 'Please verify Employee Code.';
      return false;
    }
    return true;
  }

  bool _validateGateAndParking() {
    if (_gateNo.trim().isEmpty) {
      _saveError = 'Gate No is required.';
      return false;
    }
    if (_parkingToBeUsed.trim().isEmpty) {
      _saveError = 'Parking To Be Used is required.';
      return false;
    }
    return true;
  }

  bool _validateDocuments() {
    if (_documents.isEmpty) {
      _saveError = 'Please add at least one document.';
      return false;
    }

    for (var i = 0; i < _documents.length; i++) {
      final doc = _documents[i];
      if (doc.documentType.trim().isEmpty) {
        _saveError = 'Please select Document Type for row ${i + 1}.';
        return false;
      }
      if (doc.documentNo.trim().isEmpty) {
        _saveError = 'Please enter Document Number for row ${i + 1}.';
        return false;
      }
      if (doc.expiryDate.trim().isEmpty) {
        _saveError = 'Please select Expiry Date for row ${i + 1}.';
        return false;
      }
      if (doc.filePath == null || doc.filePath!.isEmpty) {
        _saveError = 'Please upload a file for row ${i + 1}.';
        return false;
      }
    }
    return true;
  }

  bool _validateForm() {
    _saveError = null;
    if (!_validateVehicle()) return false;
    if (!_validateEmployee()) return false;
    if (!_validateGateAndParking()) return false;
    if (!_validateDocuments()) return false;
    return true;
  }

  // ---------- Build request ----------
  PassRequestModel _buildRequest({String? statusOverride}) {
    return PassRequestModel(
      id: widget.registryId,
      passNo: _passNo,
      vehicleNo: _vehicleNoCtrl.text.trim(),
      vehicleType: _vehicleType.trim(),
      brandModel: _brandModelCtrl.text.trim(),
      employeeNo: _ecNoCtrl.text.trim(),
      empType: _empType.trim(),
      contractorCode: _empContractorCode.trim().isEmpty
          ? null
          : _empContractorCode.trim(),
      gateNo: _gateNo.trim(),
      parkingToBeUsed: _parkingToBeUsed.trim(),
      status: statusOverride ?? _status,
      remark: _remark,
      enterBy: _enterBy,
      documents: _documents,
    );
  }

  // ---------- Save / Submit ----------
  Future<void> _savePass({bool submit = false}) async {
    if (!_validateForm()) return;

    String? statusToUse = _status;
    if (submit) {
      statusToUse = 'SUBMITTED';
      if (_status.toUpperCase() == 'MODIFY' ||
          _status.toUpperCase() == 'NEEDS_MODIFICATION' ||
          _status.toUpperCase() == 'NEEDSMODIFICATION') {
        statusToUse = 'DRAFT';
      }
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
      _saveSuccess = null;
    });

    final request = _buildRequest(statusOverride: statusToUse);
    final jsonPart = jsonEncode(request.toJson());

    final formData = http.MultipartRequest('POST', Uri.parse(_passSaveUrl));
    formData.headers['x-api-key'] = _apiKey;

    formData.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonPart,
        filename: 'request.json',
      ),
    );

    for (var i = 0; i < _documents.length; i++) {
      final doc = _documents[i];
      if (doc.filePath != null && doc.filePath!.isNotEmpty) {
        final file = File(doc.filePath!);
        if (await file.exists()) {
          formData.files.add(
            await http.MultipartFile.fromPath(
              doc.fileKey.isNotEmpty ? doc.fileKey : 'document_$i',
              file.path,
            ),
          );
        }
      }
    }

    try {
      final streamedResponse = await formData.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _passNo = data['passNo'] as int?;
          _status = (data['reqStatus'] ?? 'DRAFT').toString();
          _saveSuccess = submit
              ? 'Pass submitted successfully.'
              : 'Vehicle pass saved successfully.';
          _isSaving = false;
        });
      } else {
        setState(() {
          _saveError = 'Unable to save vehicle pass.';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _saveError = 'Unable to save vehicle pass.';
        _isSaving = false;
      });
    }
  }

  // ---------- Document helpers ----------
  List<String> _availableDocTypes(int index) {
    final selectedTypes = _documents
        .asMap()
        .entries
        .where((e) => e.key != index && e.value.documentType.isNotEmpty)
        .map((e) => e.value.documentType)
        .toList();

    return _allowedDocTypes
        .where(
          (t) =>
              !selectedTypes.contains(t) || _documents[index].documentType == t,
        )
        .toList();
  }

  void _addDocument() {
    if (_isReadOnly) return;
    final lastDoc = _documents.last;
    if (lastDoc.documentType.isEmpty ||
        lastDoc.documentNo.isEmpty ||
        lastDoc.expiryDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete the current document before adding a new one.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _documents.add(
        PassDocumentModel(
          documentType: '',
          documentNo: '',
          expiryDate: '',
          fileKey: 'document_${_documents.length}',
          fileName: '',
        ),
      );
    });
  }

  void _removeDocument(int index) {
    if (_isReadOnly || _documents.length == 1) return;
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _pickFileForDoc(int index) async {
    if (_isReadOnly) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size must be less than 5 MB.')),
      );
      return;
    }

    setState(() {
      _documents[index] = PassDocumentModel(
        documentType: _documents[index].documentType,
        documentNo: _documents[index].documentNo,
        expiryDate: _documents[index].expiryDate,
        fileKey: _documents[index].fileKey,
        fileName: file.name,
        filePath: file.path,
      );
    });
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        _buildVehicleSection(),
        const SizedBox(height: 12),
        _buildEmployeeSection(),
        const SizedBox(height: 12),
        _buildPassDetailsSection(),
        const SizedBox(height: 12),
        _buildStatusSection(),
        const SizedBox(height: 12),
        _buildDocumentsSection(),
        const SizedBox(height: 12),
        _buildActionButtons(),
        if (_saveSuccess != null) ...[
          const SizedBox(height: 12),
          _buildAlert(success: true, message: _saveSuccess!),
        ],
        if (_saveError != null) ...[
          const SizedBox(height: 12),
          _buildAlert(success: false, message: _saveError!),
        ],
      ],
    );
  }

  Widget _buildVehicleSection() {
    return PassSection(
      icon: Icons.directions_car,
      title: 'Vehicle Details',
      children: [
        PassGrid2(
          children: [
            PassField(
              label: 'Vehicle Number',
              hintText: 'MP09AB1234',
              controller: _vehicleNoCtrl,
              readOnly: _isReadOnly,
              onSubmitted: (_) {},
              textTransform: TextTransform.uppercase,
            ),
            PassDropdown(
              label: 'Vehicle Type',
              value: _vehicleType.isEmpty ? null : _vehicleType,
              items: _vehicleTypes,
              hint: '-- Select Vehicle Type --',
              onChanged: (v) => setState(() => _vehicleType = v ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PassGrid2(
          children: [
            PassField(
              label: 'Brand / Model',
              hintText: 'Honda City / Tata Truck',
              controller: _brandModelCtrl,
              readOnly: _isReadOnly,
              onSubmitted: (_) {},
              textTransform: TextTransform.uppercase,
            ),
            PassField(
              label: 'Pass No',
              hintText: 'Enter Pass No',
              initialValue: _passNo?.toString() ?? '',
              readOnly: true,
              onSubmitted: (_) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmployeeSection() {
    return PassSection(
      icon: Icons.badge,
      title: 'Employee / Contractor Details',
      children: [
        PassGrid3(
          children: [
            PassDropdown(
              label: 'Employee Type',
              value: _empType.isEmpty ? null : _empType,
              items: _empTypes,
              hint: '-- Select Employee Type --',
              onChanged: (v) {
                setState(() {
                  _empType = v ?? '';
                  _clearEmployeeData();
                  _ecNoCtrl.clear();
                  _empFetchError = null;
                });
              },
            ),
            PassField(
              label: 'EC No',
              hintText: 'Enter Employee Code',
              controller: _ecNoCtrl,
              readOnly: _isReadOnly,
              onSubmitted: (_) => _loadEmployee(),
              suffix: _fetchingEmployee
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              hintTextExtra: _empType.isEmpty
                  ? 'Select Employee Type First'
                  : 'Employee details fetched automatically',
            ),
            PassField(
              label: 'Employee Name',
              initialValue: _empName,
              readOnly: true,
              placeholder: 'Auto Filled',
              onSubmitted: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        PassGrid3(
          children: [
            PassField(
              label: 'Department',
              initialValue: _empDept,
              readOnly: true,
              placeholder: 'Auto Filled',
              onSubmitted: (_) {},
            ),
            PassField(
              label: 'Department Code',
              initialValue: _empDeptCode,
              readOnly: true,
              placeholder: 'Auto Filled',
              onSubmitted: (_) {},
            ),
            PassField(
              label: 'Aadhar Number',
              initialValue: _empAadhar,
              readOnly: true,
              placeholder: 'Auto Filled',
              onSubmitted: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        PassGrid2(
          children: [
            PassField(
              label: 'Contractor Code',
              initialValue: _empContractorCode,
              readOnly: true,
              placeholder: 'Auto Filled',
              onSubmitted: (_) {},
            ),
            PassField(
              label: 'Contractor Name',
              initialValue: _empContractorName,
              readOnly: true,
              placeholder: 'Auto Filled',
              onSubmitted: (_) {},
            ),
          ],
        ),
        if (_empFetchError != null) ...[
          const SizedBox(height: 8),
          _buildFetchError(_empFetchError!),
        ],
        if (_empName.isNotEmpty &&
            !_fetchingEmployee &&
            _empFetchError == null) ...[
          const SizedBox(height: 8),
          _buildFetchSuccess(),
        ],
      ],
    );
  }

  Widget _buildPassDetailsSection() {
    return PassSection(
      icon: Icons.card_membership,
      title: 'Pass Details',
      children: [
        PassGrid2(
          children: [
            PassDropdown(
              label: 'Gate No',
              value: _gateNo.isEmpty ? null : _gateNo,
              items: _gates,
              hint: '-- Select Gate --',
              onChanged: (v) => setState(() => _gateNo = v ?? ''),
            ),
            PassDropdown(
              label: 'Parking To Be Used',
              value: _parkingToBeUsed.isEmpty ? null : _parkingToBeUsed,
              items: _parkings,
              hint: '-- Select Parking Area --',
              onChanged: (v) => setState(() => _parkingToBeUsed = v ?? ''),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return PassSection(
      icon: Icons.schema,
      title: 'Workflow Status',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF93C5FD)),
          ),
          child: Column(
            children: [
              _statusRow('Current Status', _status),
              const SizedBox(height: 6),
              _statusRow('Entered By', _enterBy.isEmpty ? '-' : _enterBy),
              const SizedBox(height: 6),
              _statusRow('Pass No', _passNo?.toString() ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A6E),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2040),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return PassSection(
      icon: Icons.file_present,
      title: 'Required Documents',
      badge: '${_documents.length} Added',
      children: [
        _buildDocTableHeader(),
        ...List.generate(_documents.length, (i) => _buildDocRow(i)),
        const SizedBox(height: 8),
        _buildAddDocButton(),
        const SizedBox(height: 6),
        _buildDocInfo(),
      ],
    );
  }

  Widget _buildDocTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2040), Color(0xFF1A3560)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Document Type',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Document No',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Expiry Date',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'File',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildDocRow(int index) {
    final doc = _documents[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? const Color(0xFFF8FAFD) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8D6E8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: PassDropdownSmall(
                  value: doc.documentType.isEmpty ? null : doc.documentType,
                  items: _availableDocTypes(index),
                  hint: '-- Select Type --',
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _documents[index] = PassDocumentModel(
                        documentId: doc.documentId,
                        documentType: v,
                        documentNo: '',
                        expiryDate: '',
                        fileKey: doc.fileKey,
                        fileName: doc.fileName,
                        filePath: doc.filePath,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: PassFieldSmall(
                  hintText: 'Document Number',
                  initialValue: doc.documentNo,
                  readOnly: _isReadOnly,
                  onChanged: (v) => setState(() {
                    _documents[index].documentNo = v;
                  }),
                  textTransform: TextTransform.uppercase,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: PassDateFieldSmall(
                  value: doc.expiryDate.isEmpty ? null : doc.expiryDate,
                  onDateSelected: (d) => setState(() {
                    _documents[index].expiryDate = d;
                  }),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: _buildDocFileCell(index)),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFFF87171),
                  onPressed: () => _removeDocument(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocFileCell(int index) {
    final doc = _documents[index];
    if (doc.filePath != null && doc.filePath!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          border: Border.all(color: const Color(0xFF86EFAC)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                doc.fileName.isEmpty ? 'Uploaded' : doc.fileName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _pickFileForDoc(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFF),
          border: Border.all(
            color: const Color(0xFF93C5FD),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload, size: 14, color: Color(0xFF1D4ED8)),
            SizedBox(width: 4),
            Text(
              'Upload File',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddDocButton() {
    final canAdd = !_isReadOnly && _documents.length < _allowedDocTypes.length;
    return GestureDetector(
      onTap: canAdd ? _addDocument : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: canAdd ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          border: Border.all(
            color: canAdd ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle, size: 16, color: Color(0xFF1D4ED8)),
            SizedBox(width: 6),
            Text(
              'Add Document',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        border: Border.all(color: const Color(0xFFDDE4EF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, size: 14, color: Color(0xFF94A3B8)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Allowed Documents: RC, INSURANCE, LICENSE',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canEdit =
        !_isReadOnly &&
        (_status == 'DRAFT' ||
            _status == 'SAVED' ||
            _status == 'MODIFY' ||
            _status == 'NEEDS_MODIFICATION' ||
            _status == 'NEEDSMODIFICATION');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (canEdit)
            PassActionButton(
              label: 'Clear',
              icon: Icons.close,
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF475569),
              onPressed: () {
                // TODO: clear form or navigate back
              },
            ),
          if (canEdit)
            PassActionButton(
              label: _isSaving ? 'Saving...' : 'Save',
              icon: _isSaving ? Icons.hourglass_bottom : Icons.save,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: _isSaving ? null : () => _savePass(submit: false),
            ),
          if (canEdit)
            PassActionButton(
              label: 'Submit',
              icon: Icons.send,
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              onPressed: _isSaving ? null : () => _savePass(submit: true),
            ),
          if (_isReadOnly)
            PassActionButton(
              label: 'Back',
              icon: Icons.arrow_back,
              backgroundColor: const Color(0xFFF1F5F9),
              foregroundColor: const Color(0xFF475569),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildFetchError(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, size: 16, color: Color(0xFF7F1D1D)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFetchSuccess() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFF86EFAC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF14532D)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Employee Found : $_empName  $_empDept',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14532D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert({required bool success, required String message}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        border: Border.all(
          color: success ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            size: 18,
            color: success ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: success
                    ? const Color(0xFF14532D)
                    : const Color(0xFF7F1D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
