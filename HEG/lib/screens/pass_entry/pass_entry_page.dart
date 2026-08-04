import 'package:flutter/material.dart';
import 'pass_entry_models.dart';
import 'pass_entry_service.dart';
import 'pass_entry_widgets.dart';
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

  bool get isReadOnlyMode {
    if (isViewMode) return true;
    return !canEdit;
  }

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

    _vehicleController.text = vehicleNo;
    _brandController.text = brandModel;
    _ecController.text = ecNo;

    if (widget.mode == 'view') isViewMode = true;
    if (widget.mode == 'approver') isApproverMode = true;

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
    super.dispose();
  }

  void _syncControllers() {
    _vehicleController.text = vehicleNo;
    _brandController.text = brandModel;
    _ecController.text = ecNo;
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
    setState(() {
      saveError = '';
      saveSuccess = 'Vehicle pass saved successfully.';
      registryId ??= 1;
      passNo ??= 1;
      status = 'SAVED';
      saved = true;
    });
  }

  void _submit() {
    if (!canEdit) return;
    setState(() {
      saveError = '';
      saveSuccess = 'Pass submitted successfully.';
      registryId ??= 1;
      passNo ??= 1;
      status = 'SUBMITTED';
      saved = true;
    });
  }

  void _approve() => setState(() => status = 'ACTIVE');
  void _reject() => setState(() => status = 'REJECT');
  void _modify() => setState(() => status = 'MODIFY');

  void _toggleHistory() {
    setState(() => showPassHistory = !showPassHistory);
    if (showPassHistory && passHistory.isEmpty && registryId != null) {
      loadPassHistory(registryId!);
    }
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
        messageBox('Employee Found : $empName  $empDept', success: true),
      ],
    ],
  );

  Widget _passSection() => Row(
    children: [
      Expanded(child: _roField('Gate No', gateNo)),
      const SizedBox(width: 8),
      Expanded(child: _roField('Parking To Be Used', parkingToBeUsed)),
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
              _roField('Document Type', doc.documentType),
              const SizedBox(height: 8),
              _roField('Document No', doc.documentNo),
              const SizedBox(height: 8),
              _roField('Expiry Date', formatDateDDMMYYYY(doc.expiryDate)),
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
          onPressed: togglePassHistory,
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
          savePass,
          bg: const Color(0xFF1D4ED8),
          fg: Colors.white,
        ),
      if (canEdit)
        _actionButton(
          'Submit',
          Icons.send,
          onSubmit,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if (status == 'SUBMITTED' && isConfirmerMode)
        _actionButton(
          'Send Modification',
          Icons.edit,
          sendForModify,
          bg: const Color(0xFFF59E0B),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED' || status == 'CONFIRMED') && isApproverMode)
        _actionButton(
          'Send Modification',
          Icons.edit,
          sendForModify,
          bg: const Color(0xFFF59E0B),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED' || status == 'CONFIRMED') && isApproverMode)
        _actionButton(
          'Reject',
          Icons.cancel,
          rejectPass,
          bg: const Color(0xFFDC2626),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED' || status == 'CONFIRMED') && isApproverMode)
        _actionButton(
          'Approve',
          Icons.check_circle,
          approvePass,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED') && isConfirmerMode)
        _actionButton(
          'Reject',
          Icons.cancel,
          rejectPass,
          bg: const Color(0xFFDC2626),
          fg: Colors.white,
        ),
      if ((status == 'SUBMITTED') && isConfirmerMode)
        _actionButton(
          'Confirm & Send Approver',
          Icons.check_circle,
          confirmPass,
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
      onPressed: onTap,
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
}
