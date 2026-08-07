import 'package:flutter/material.dart';
import 'pass_entry_models.dart';
import 'pass_entry_service.dart';
import '../../widgets/heg_app_bar.dart';
import '../../core/app_config.dart';

class PassEntryPage extends StatefulWidget {
  final int? id;
  final String? mode;

  const PassEntryPage({super.key, this.id, this.mode});

  @override
  State<PassEntryPage> createState() => _PassEntryPageState();
}

class _PassEntryPageState extends State<PassEntryPage> {
  late final PassEntryService _service;

  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _ecController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _reviewRemarkController = TextEditingController();
  final TextEditingController _gateController = TextEditingController();
  final TextEditingController _parkingController = TextEditingController();

  String vehicleNo = '';
  String vehicleType = '';
  String brandModel = '';
  String employeeNo = '';
  String ecNo = '';
  String empType = '';
  String? contractorCode;
  String gateNo = '';
  String parkingToBeUsed = '';
  String status = PassStatus.DRAFT;
  String? remark;
  String enterBy = '';
  String empName = '';
  String empDept = '';
  String empDeptCode = '';
  String empAadhar = '';
  String empContractorCode = '';
  String empContractorName = '';
  List<PassDocument> documents = [PassDocument.empty()];
  int? registryId;
  int? passNo;
  bool fetchingEmployee = false;
  String empFetchError = '';
  bool isSaving = false;
  bool saved = false;
  String saveSuccess = '';
  String saveError = '';
  bool isViewMode = false;
  bool isApproverMode = false;
  bool isConfirmerMode = false;
  String modificationRemark = '';
  String reviewRemark = '';
  bool showPassHistory = false;
  bool isLoadingPassHistory = false;
  String passHistoryError = '';
  List<HistoryRecord> passHistory = [];

  bool get isApproverView => isApproverMode;
  bool get isReadOnlyMode => isViewMode || !canEdit;
  bool get canEdit {
    if (isViewMode || isApproverView) return false;
    final s = status.toUpperCase();
    return s == PassStatus.DRAFT ||
        s == PassStatus.SAVED ||
        s == PassStatus.MODIFY ||
        s == PassStatus.NEEDS_MODIFICATION ||
        s == 'NEEDSMODIFICATION';
  }

  String get todayDate => DateTime.now().toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _service = PassEntryService(
      baseUrl: AppConfig.apiBaseUrl,
      apiKey: AppConfig.apiKey,
    );

    if (widget.mode == 'view') isViewMode = true;
    if (widget.mode == 'approver') isApproverMode = true;

    _syncControllers();

    if (widget.id != null) {
      registryId = widget.id;
      _loadPass(widget.id!);
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _brandController.dispose();
    _ecController.dispose();
    _remarkController.dispose();
    _reviewRemarkController.dispose();
    _gateController.dispose();
    _parkingController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _vehicleController.text = vehicleNo;
    _brandController.text = brandModel;
    _ecController.text = ecNo;
    _remarkController.text = remark ?? '';
    _reviewRemarkController.text = reviewRemark;
    _gateController.text = gateNo;
    _parkingController.text = parkingToBeUsed;
  }

  void _setStateAndSync(VoidCallback fn) {
    setState(fn);
    _syncControllers();
  }

  void onUpperInput(String field, String value) {
    if (isReadOnlyMode) return;
    final v = value.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (field == 'vehicleNo') vehicleNo = v;
    if (field == 'brandModel') brandModel = v;
    if (field == 'ecNo') ecNo = v;
    _syncControllers();
    setState(() {});
  }

  void onVehicleTypeInput(String value) {
    if (isReadOnlyMode) return;
    vehicleType = value.toUpperCase();
    setState(() {});
  }

  void onDocNoInput(int index, String value) {
    if (isReadOnlyMode) return;
    documents[index].documentNo = value.toUpperCase();
    setState(() {});
  }

  void setEmployeeType(String? value) {
    final v = (value ?? '').toUpperCase();
    if (['HEG', 'TACC', 'CONTRACT', 'CRE-PRM'].contains(v)) {
      empType = v;
      _clearEmployeeData();
      employeeNo = '';
      ecNo = '';
      _ecController.clear();
      empFetchError = '';
      setState(() {});
    }
  }

  void _clearEmployeeData() {
    empName = '';
    empDept = '';
    empDeptCode = '';
    empAadhar = '';
    empContractorCode = '';
    empContractorName = '';
  }

  String shortName(String name) =>
      name.length > 18 ? '${name.substring(0, 15)}...' : name;

  String formatDateDDMMYYYY(String isoDate) {
    if (isoDate.isEmpty || isoDate.length < 10) return isoDate;
    final p = isoDate.split('-');
    if (p.length != 3) return isoDate;
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  String formatDateTime(String d) {
    if (d.isEmpty) return '—';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return '${dt.day.toString().padLeft(2, '0')} ${_month(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _month(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  Future<void> downloadFile(int? documentId, String fallbackName) async {
    if (documentId == null) return;
    setState(() => isSaving = true);
    try {
      final res = await _service.downloadDocument(documentId);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Download failed');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Downloaded ${fallbackName.isEmpty ? 'document' : fallbackName}',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download document')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _save() {
    if (!canEdit) return;
    _persistPass(isSubmit: false);
  }

  void _submit() {
    if (!canEdit) return;
    _persistPass(isSubmit: true);
  }

  void _approve() {
    if (registryId == null) return;
    _updateStatus('ACTIVE');
  }

  void _reject() {
    if (registryId == null) return;
    _updateStatus(PassStatus.REJECT);
  }

  void _modify() {
    if (registryId == null) return;
    _updateStatus(PassStatus.MODIFY);
  }

  void _confirmPass() {
    if (registryId == null) return;
    _updateStatus(PassStatus.CONFIRMED);
  }

  void _updateStatus(String newStatus) async {
    setState(() {
      isSaving = true;
      saveError = '';
      saveSuccess = '';
    });
    try {
      await _service.updatePassStatus(
        registryId!,
        newStatus,
        remark: reviewRemark.isNotEmpty ? reviewRemark : (remark ?? ''),
        enterBy: enterBy,
      );
      final refreshed = await _service.loadPass(registryId!);
      _applyLoadedPass(refreshed);
      setState(() {
        saveSuccess = 'Workflow action completed successfully.';
      });
      if (showPassHistory) {
        await _loadPassHistory(registryId!);
      }
    } catch (e) {
      setState(() {
        saveError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  bool _validateVehicle() {
    if (vehicleNo.trim().isEmpty) {
      saveError = 'Vehicle Number is required.';
      return false;
    }
    if (vehicleType.trim().isEmpty) {
      saveError = 'Vehicle Type is required.';
      return false;
    }
    if (brandModel.trim().isEmpty) {
      saveError = 'Brand / Model is required.';
      return false;
    }
    return true;
  }

  bool _validateEmployee() {
    if (empType.trim().isEmpty) {
      saveError = 'Please select Employee Type.';
      return false;
    }
    if (ecNo.trim().isEmpty) {
      saveError = 'Employee Code is required.';
      return false;
    }
    if (empName.trim().isEmpty) {
      saveError = 'Please verify Employee Code.';
      return false;
    }
    return true;
  }

  bool _validateGateAndParking() {
    if (gateNo.trim().isEmpty) {
      saveError = 'Gate No is required.';
      return false;
    }
    if (parkingToBeUsed.trim().isEmpty) {
      saveError = 'Parking To Be Used is required.';
      return false;
    }
    return true;
  }

  bool _validateDocuments() {
    if (documents.isEmpty) {
      saveError = 'Please add at least one document.';
      return false;
    }
    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      if (doc.documentType.trim().isEmpty) {
        saveError = 'Please select Document Type for row ${i + 1}.';
        return false;
      }
      if (doc.documentNo.trim().isEmpty) {
        saveError = 'Please enter Document Number for row ${i + 1}.';
        return false;
      }
      if (doc.expiryDate.trim().isEmpty) {
        saveError = 'Please select Expiry Date for row ${i + 1}.';
        return false;
      }
      if (doc.file == null && doc.existingFile.trim().isEmpty) {
        saveError = 'Please upload a file for row ${i + 1}.';
        return false;
      }
    }
    return true;
  }

  bool _validateForm() {
    saveError = '';
    if (!_validateVehicle()) return false;
    if (!_validateEmployee()) return false;
    if (!_validateGateAndParking()) return false;
    if (!_validateDocuments()) return false;
    return true;
  }

  Map<String, dynamic> _buildRequest({required String finalStatus}) {
    return {
      'id': registryId,
      'passNo': passNo,
      'vehicleNo': vehicleNo.trim(),
      'vehicleType': vehicleType.trim(),
      'brandModel': brandModel.trim(),
      'employeeNo': ecNo.trim(),
      'empType': empType,
      'contractorCode': contractorCode,
      'gateNo': gateNo.trim(),
      'parkingToBeUsed': parkingToBeUsed.trim(),
      'status': finalStatus,
      'remark': remark,
      'enterBy': enterBy,
      'documents': documents
          .map(
            (d) => {
              'documentId': d.documentId,
              'documentType': d.documentType,
              'documentNo': d.documentNo,
              'expiryDate': d.expiryDate,
              'fileKey': d.fileKey,
              'fileName': d.fileName,
              'existingFile': d.existingFile,
            },
          )
          .toList(),
    };
  }

  Future<void> _persistPass({required bool isSubmit}) async {
    if (!canEdit) return;
    if (!_validateForm()) {
      setState(() {});
      return;
    }

    setState(() {
      isSaving = true;
      saveError = '';
      saveSuccess = '';
    });

    try {
      final request = _buildRequest(
        finalStatus: isSubmit ? PassStatus.SUBMITTED : PassStatus.SAVED,
      );

      final files = <UploadFilePart>[];
      for (final d in documents) {
        final file = d.file;
        if (file != null && file is String && file.isNotEmpty) {
          files.add(
            UploadFilePart(
              key: d.fileKey.isNotEmpty
                  ? d.fileKey
                  : 'document_${files.length}',
              path: file,
              filename: d.fileName,
            ),
          );
        }
      }

      PassRegistryResponseDTO response;
      if (registryId == null) {
        response = await _service.savePass(request);
      } else {
        response = await _service.updatePass(registryId!, request);
      }

      _applyLoadedPass(response);
      setState(() {
        saved = true;
        saveSuccess = isSubmit
            ? 'Pass submitted successfully.'
            : 'Vehicle pass saved successfully.';
      });
      if (isSubmit) {
        _updateStatus(PassStatus.SUBMITTED);
      }
    } catch (e) {
      setState(() {
        saveError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _applyLoadedPass(PassRegistryResponseDTO response) {
    registryId = response.id;
    passNo = response.passNo;
    vehicleNo = response.vehicleNo;
    vehicleType = response.vehicleType;
    brandModel = response.brandModel;
    employeeNo = response.employeeNo;
    ecNo = response.employeeNo;
    empType = response.empType;
    contractorCode = response.contractorCode.isEmpty
        ? null
        : response.contractorCode;
    gateNo = response.gateNo;
    parkingToBeUsed = response.parkingToBeUsed;
    status = response.reqStatus.isEmpty ? PassStatus.DRAFT : response.reqStatus;
    enterBy = enterBy.isEmpty ? 'SYSTEM' : enterBy;
    documents = response.documents.isNotEmpty
        ? response.documents
        : [PassDocument.empty()];
    saved = true;
    _syncControllers();
  }

  Future<void> _loadPass(int id) async {
    setState(() => isSaving = true);
    try {
      final response = await _service.loadPass(id);
      _applyLoadedPass(response);
      saveSuccess = 'Pass details loaded successfully.';
    } catch (e) {
      saveError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _loadPassHistory(int id) async {
    setState(() {
      isLoadingPassHistory = true;
      passHistoryError = '';
    });
    try {
      final res = await _service.loadHistory(id);
      passHistory = res;
    } catch (_) {
      passHistoryError = 'Unable to load pass history.';
    } finally {
      if (mounted) setState(() => isLoadingPassHistory = false);
    }
  }

  void _toggleHistory() {
    setState(() => showPassHistory = !showPassHistory);
    if (showPassHistory && passHistory.isEmpty && registryId != null) {
      _loadPassHistory(registryId!);
    }
  }

  Future<void> _pickDateForDoc(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(documents[index].expiryDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        documents[index].expiryDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickDateForFields(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  void onEcNoBlur() async {
    if (ecNo.trim().isEmpty || empType.trim().isEmpty) return;
    setState(() {
      fetchingEmployee = true;
      empFetchError = '';
      _clearEmployeeData();
    });
    try {
      final emp = await _service.loadEmployee(ecNo.trim());
      if (emp.empType != null && emp.empType!.trim().isNotEmpty) {
        final selected = empType.trim().toUpperCase();
        final apiType = emp.empType!.trim().toUpperCase();
        if (selected != apiType) {
          empFetchError =
              'Employee Type mismatch. Selected: $selected, Found: $apiType';
          return;
        }
      }
      empName = emp.name ?? '';
      empDept = (emp.deptName ?? '').toUpperCase();
      empDeptCode = emp.deptCode ?? '';
      empAadhar = emp.aadhaarNo ?? '';
      empContractorCode = emp.contractorCode ?? '';
      contractorCode = emp.contractorCode;
      empContractorName = emp.contractorName ?? '';
      employeeNo = ecNo.trim().toUpperCase();
    } catch (e) {
      empFetchError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => fetchingEmployee = false);
    }
  }

  void addDocument() {
    if (isReadOnlyMode) return;
    if (documents.isNotEmpty) {
      final last = documents.last;
      if (last.documentType.isEmpty ||
          last.documentNo.isEmpty ||
          last.expiryDate.isEmpty) {
        saveError =
            'Please complete the current document before adding a new one.';
        setState(() {});
        return;
      }
    }
    setState(() => documents.add(PassDocument.empty()));
  }

  void removeDocument(int index) {
    if (isReadOnlyMode) return;
    if (documents.length == 1) return;
    setState(() => documents.removeAt(index));
  }

  Widget _fieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E3A6E),
      ),
    ),
  );

  Widget _roField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _fieldLabel(label),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _section(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD9E2EC)),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1E3A), Color(0xFF163B6B)],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ],
    ),
  );

  Widget sectionCard(String title, Widget child) => _section(title, child);

  Widget messageBox(String message, {required bool success}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: success ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: success ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A),
      ),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: success ? const Color(0xFF1B5E20) : const Color(0xFFC62828),
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _vehicleSection() => Column(
    children: [
      _fieldLabel('Vehicle Number *'),
      TextField(
        controller: _vehicleController,
        readOnly: !canEdit,
        onChanged: (v) => onUpperInput('vehicleNo', v),
        decoration: const InputDecoration(hintText: 'MP09AB1234'),
      ),
      const SizedBox(height: 10),
      _fieldLabel('Vehicle Type *'),
      DropdownButtonFormField<String>(
        initialValue: vehicleType.isEmpty ? null : vehicleType,
        items: const [
          'BIKE',
          'SCOOTER',
          'CAR',
          'TRUCK',
          'DUMPER',
          'JCB',
          'CRANE',
          'TRACTOR',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: canEdit
            ? (v) => setState(() => vehicleType = v ?? '')
            : null,
      ),
      const SizedBox(height: 10),
      _fieldLabel('Brand / Model *'),
      TextField(
        controller: _brandController,
        readOnly: !canEdit,
        onChanged: (v) => onUpperInput('brandModel', v),
        decoration: const InputDecoration(hintText: 'Honda City / Tata Truck'),
      ),
      const SizedBox(height: 10),
      _roField('Pass No', passNo?.toString() ?? ''),
    ],
  );

  Widget _employeeSection() => Column(
    children: [
      _fieldLabel('Employee Type *'),
      DropdownButtonFormField<String>(
        initialValue: empType.isEmpty ? null : empType,
        items: const [
          'HEG',
          'TACC',
          'CONTRACT',
          'CRE-PRM',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: canEdit ? (v) => setEmployeeType(v) : null,
      ),
      const SizedBox(height: 10),
      _fieldLabel('EC No *'),
      TextField(
        controller: _ecController,
        readOnly: !canEdit,
        onChanged: (v) => onUpperInput('ecNo', v),
        decoration: InputDecoration(
          hintText: 'Enter Employee Code',
          suffixIcon: fetchingEmployee
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        onEditingComplete: onEcNoBlur,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _roField('Employee Name', empName)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Department', empDept)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _roField('Dept Code', empDeptCode)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Aadhar', empAadhar)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _roField('Contractor Code', empContractorCode)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Contractor Name', empContractorName)),
        ],
      ),
      if (empFetchError.isNotEmpty) ...[
        const SizedBox(height: 10),
        messageBox(empFetchError, success: false),
      ],
      if (empName.isNotEmpty && !fetchingEmployee && empFetchError.isEmpty) ...[
        const SizedBox(height: 10),
        messageBox('Employee Found : $empName $empDept', success: true),
      ],
    ],
  );

  Widget _passSection() => Column(
    children: [
      Row(
        children: [
          Expanded(child: _roField('Gate No', gateNo)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Parking To Be Used', parkingToBeUsed)),
        ],
      ),
      const SizedBox(height: 10),
      if (canEdit) ...[
        _fieldLabel('Gate No *'),
        TextField(
          controller: _gateController,
          readOnly: !canEdit,
          onChanged: (v) => setState(() => gateNo = v.toUpperCase()),
        ),
        const SizedBox(height: 10),
        _fieldLabel('Parking To Be Used *'),
        TextField(
          controller: _parkingController,
          readOnly: !canEdit,
          onChanged: (v) => setState(() => parkingToBeUsed = v.toUpperCase()),
        ),
      ],
    ],
  );

  Widget _documentsSection() => Column(
    children: [
      ...documents.asMap().entries.map((entry) {
        final i = entry.key;
        final doc = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E2EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.documentType.isEmpty ? 'Document' : doc.documentType,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (doc.documentId != null)
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () => downloadFile(
                              doc.documentId,
                              doc.existingFile.isNotEmpty
                                  ? doc.existingFile
                                  : doc.fileName,
                            ),
                      icon: const Icon(
                        Icons.download,
                        color: Color(0xFF0B1E3A),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (canEdit) ...[
                _fieldLabel('Document Type'),
                DropdownButtonFormField<String>(
                  initialValue: doc.documentType.isEmpty
                      ? null
                      : doc.documentType,
                  items: allowedDocTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      doc.documentType = v ?? '';
                    });
                  },
                ),
                const SizedBox(height: 8),
                _fieldLabel('Document No'),
                TextField(
                  onChanged: (v) => onDocNoInput(i, v),
                  decoration: const InputDecoration(
                    hintText: 'Enter document number',
                  ),
                ),
                const SizedBox(height: 8),
                _fieldLabel('Expiry Date'),
                TextField(
                  readOnly: true,
                  controller: TextEditingController(text: doc.expiryDate),
                  onTap: () => _pickDateForDoc(i),
                  decoration: const InputDecoration(hintText: 'YYYY-MM-DD'),
                ),
              ] else ...[
                _roField('Document Type', doc.documentType),
                const SizedBox(height: 8),
                _roField('Document No', doc.documentNo),
                const SizedBox(height: 8),
                _roField('Expiry Date', formatDateDDMMYYYY(doc.expiryDate)),
              ],
              const SizedBox(height: 8),
              _roField(
                'File',
                doc.existingFile.isNotEmpty ? doc.existingFile : doc.fileName,
              ),
              if (canEdit) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload File'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => removeDocument(i),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ] else if (doc.documentId != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => downloadFile(
                      doc.documentId,
                      doc.existingFile.isNotEmpty
                          ? doc.existingFile
                          : doc.fileName,
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      if (canEdit)
        OutlinedButton.icon(
          onPressed: addDocument,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add Document'),
        ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Allowed Documents: RC, INSURANCE, LICENSE',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _statusSection() => _section(
    'Workflow Status',
    Row(
      children: [
        Expanded(child: _roField('Current Status', status)),
        const SizedBox(width: 8),
        Expanded(
          child: _roField('Entered By', enterBy.isEmpty ? '-' : enterBy),
        ),
        const SizedBox(width: 8),
        Expanded(child: _roField('Pass No', passNo?.toString() ?? '-')),
      ],
    ),
  );

  Widget _historySection() => _section(
    'Pass History',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _toggleHistory,
          icon: Icon(showPassHistory ? Icons.visibility_off : Icons.history),
          label: Text(showPassHistory ? 'Hide History' : 'Show History'),
        ),
        if (showPassHistory) ...[
          if (isLoadingPassHistory)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (passHistoryError.isNotEmpty)
            messageBox(passHistoryError, success: false),
          if (!isLoadingPassHistory &&
              passHistoryError.isEmpty &&
              passHistory.isNotEmpty)
            ...passHistory.map(
              (h) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.action,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(h.dateOfEntry),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF627D98),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('By: ${h.empCode.isEmpty ? 'SYSTEM' : h.empCode}'),
                    const SizedBox(height: 4),
                    Text(h.remark.isEmpty ? '-' : h.remark),
                  ],
                ),
              ),
            ),
          if (!isLoadingPassHistory &&
              passHistoryError.isEmpty &&
              passHistory.isEmpty)
            const Text('No history available'),
        ],
      ],
    ),
  );

  Widget _remarkSection() => _section(
    isApproverMode ? 'Approver Remark' : 'Confirmer Remark',
    Column(
      children: [
        TextField(
          controller: _reviewRemarkController,
          onChanged: (v) => reviewRemark = v,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter remark'),
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Remark required for workflow action',
            style: TextStyle(fontSize: 12, color: Color(0xFF627D98)),
          ),
        ),
      ],
    ),
  );

  Widget _actionsSection() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (canEdit)
        _actionButton(
          'Save',
          Icons.save,
          _save,
          bg: const Color(0xFF1D4ED8),
          fg: Colors.white,
        ),
      if (canEdit)
        _actionButton(
          'Submit',
          Icons.send,
          _submit,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if (status == 'SUBMITTED' && isConfirmerMode)
        _actionButton(
          'Send Modification',
          Icons.edit,
          _modify,
          bg: const Color(0xFFF59E0B),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED' || status == 'CONFIRMED') && isApproverMode)
        _actionButton(
          'Send Modification',
          Icons.edit,
          _modify,
          bg: const Color(0xFFF59E0B),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED' || status == 'CONFIRMED') && isApproverMode)
        _actionButton(
          'Reject',
          Icons.cancel,
          _reject,
          bg: const Color(0xFFDC2626),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED' || status == 'CONFIRMED') && isApproverMode)
        _actionButton(
          'Approve',
          Icons.check_circle,
          _approve,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED') && isConfirmerMode)
        _actionButton(
          'Reject',
          Icons.cancel,
          _reject,
          bg: const Color(0xFFDC2626),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED') && isConfirmerMode)
        _actionButton(
          'Confirm & Send Approver',
          Icons.check_circle,
          _confirmPass,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if (!canEdit && !isApproverMode && !isConfirmerMode)
        _actionButton(
          'Back',
          Icons.arrow_back,
          goBackToPasses,
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569),
        ),
    ],
  );

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    required Color bg,
    required Color fg,
  }) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: isSaving ? null : onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: const HegAppBar(title: 'Pass Entry'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(),
              if (modificationRemark.isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(
                  'Modification Message',
                  _roField('Confirmer Remark', modificationRemark),
                ),
              ],
              const SizedBox(height: 12),
              sectionCard('Vehicle Details', _vehicleSection()),
              sectionCard('Employee / Contractor Details', _employeeSection()),
              sectionCard('Pass Details', _passSection()),
              sectionCard('Required Documents', _documentsSection()),
              _statusSection(),
              const SizedBox(height: 12),
              if (registryId != null) _historySection(),
              if (isConfirmerMode || isApproverMode) ...[
                const SizedBox(height: 12),
                _remarkSection(),
              ],
              const SizedBox(height: 12),
              _actionsSection(),
              if (isSaving) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
              if (saveSuccess.isNotEmpty)
                messageBox(saveSuccess, success: true),
              if (saveError.isNotEmpty) messageBox(saveError, success: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0B1E3A), Color(0xFF0EA5A4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.badge, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApproverMode
                    ? 'Pass Approval Form'
                    : isReadOnlyMode
                    ? 'Pass View Form'
                    : 'Pass Entry Form',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                registryId != null
                    ? 'ID : $registryId'
                    : 'Request ID generates on Save',
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void goBackToPasses() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
