import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/heg_app_bar.dart';
import 'pass_entry/pass_entry_page.dart';
import '../data/pass_registry_api.dart';
import '../models/pass_registry_item.dart';

class PassDocument {
  final int? documentId;
  final String documentType;
  final String documentNo;
  final String expiryDate;
  final String fileName;
  final String existingFile;

  const PassDocument({
    required this.documentId,
    required this.documentType,
    required this.documentNo,
    required this.expiryDate,
    required this.fileName,
    required this.existingFile,
  });
}

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _ecController = TextEditingController();

  final PassRegistryApi _api = PassRegistryApi();
  Timer? _pollTimer;
  List<PassRegistryItem> _rows = [];
  List<PassRegistryItem> _filteredRows = [];

  bool _loading = false;
  bool _isReadOnly = false;
  bool _showHistory = false;
  bool _isDownloading = false;
  bool _listLoading = true;

  String _query = '';
  String _statusFilter = 'All';
  String _empTypeFilter = 'All';
  String _vehicleTypeFilter = 'All';

  String _saveError = '';
  String _saveSuccess = '';
  String reviewRemark = '';

  String _vehicleNo = 'MP09AB1234';
  String _vehicleType = 'CAR';
  String _brandModel = 'HONDA CITY';
  String _employeeType = 'HEG';
  String _ecNo = '70100';
  String _employeeName = 'DEVENDRA KUMAR RAJAK';
  String _department = 'PLANT';
  String _deptCode = 'D001';
  String _aadhar = '123456789012';
  String _contractorCode = 'C001';
  String _contractorName = 'ABC CONTRACTOR';
  String _gateNo = 'GATE_01';
  String _parkingToBeUsed = 'P1';
  String _status = 'SUBMITTED';
  String _enteredBy = 'SYSTEM';
  int? _registryId = 1;
  int? _passNo = 1;

  final List<PassDocument> _documents = const [
    PassDocument(
      documentId: 1,
      documentType: 'RC',
      documentNo: 'RC-1',
      expiryDate: '2026-07-31',
      fileName: 'rc.pdf',
      existingFile: 'rc.pdf',
    ),
    PassDocument(
      documentId: 2,
      documentType: 'INSURANCE',
      documentNo: 'INS-2',
      expiryDate: '2026-07-31',
      fileName: 'insurance.pdf',
      existingFile: 'insurance.pdf',
    ),
  ];

  final List<_HistoryItem> _history = [
    _HistoryItem(
      action: 'CREATED',
      remark: 'Pass created successfully',
      empCode: 'SYSTEM',
      dateOfEntry: '2026-08-04T09:00:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _vehicleController.text = _vehicleNo;
    _brandController.text = _brandModel;
    _ecController.text = _ecNo;
    _loadRegistry();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _vehicleController.dispose();
    _brandController.dispose();
    _ecController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _loadRegistry(silent: true);
    });
  }

  Future<void> _loadRegistry({bool silent = false}) async {
    if (!silent) setState(() => _listLoading = true);
    try {
      final data = await _api.fetchPassRegistry();
      _rows = data;
      _applyFilters();
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load vehicle registry')),
        );
      }
    } finally {
      if (!silent && mounted) setState(() => _listLoading = false);
    }
  }

  void _applyFilters() {
    final q = _query.trim().toLowerCase();
    _filteredRows = _rows.where((r) {
      final searchOk = q.isEmpty || r.matchesSearch(q);
      final statusOk = r.matchesStatus(_statusFilter);
      final empOk = r.matchesEmpType(_empTypeFilter);
      final vehicleOk = r.matchesVehicleType(_vehicleTypeFilter);
      return searchOk && statusOk && empOk && vehicleOk;
    }).toList();
    setState(() {});
  }

  bool get _canEdit {
    if (_isReadOnly) return false;
    final s = _status.toUpperCase();
    return s == 'DRAFT' ||
        s == 'SAVED' ||
        s == 'MODIFY' ||
        s == 'NEEDS_MODIFICATION' ||
        s == 'NEEDSMODIFICATION';
  }

  void _setVehicleNo(String value) {
    if (!_canEdit) return;
    final v = value.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    setState(() {
      _vehicleNo = v;
      _vehicleController.text = v;
      _vehicleController.selection = TextSelection.collapsed(offset: v.length);
    });
  }

  void _setBrand(String value) {
    if (!_canEdit) return;
    final v = value.toUpperCase();
    setState(() {
      _brandModel = v;
      _brandController.text = v;
      _brandController.selection = TextSelection.collapsed(offset: v.length);
    });
  }

  void _setEc(String value) {
    if (!_canEdit) return;
    final v = value.toUpperCase();
    setState(() {
      _ecNo = v;
      _ecController.text = v;
      _ecController.selection = TextSelection.collapsed(offset: v.length);
    });
  }

  String _fmtDate(String date) {
    if (date.trim().isEmpty) return '-';
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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

  String _fmtDateTime(String d) {
    if (d.isEmpty) return '—';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    return '${dt.day.toString().padLeft(2, '0')} ${_month(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _downloadDocument(PassDocument doc) async {
    if (doc.documentId == null) return;
    setState(() => _isDownloading = true);
    try {
      final client = http.Client();
      final res = await client.get(
        Uri.parse(
          'http://YOUR_API_BASE_URL/api/passes/documents/download/${doc.documentId}',
        ),
        headers: const {'x-api-key': 'VPMS_SECRET_KEY_2026'},
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final Uint8List bytes = res.bodyBytes;
        if (bytes.isEmpty) throw Exception('Empty file');
      } else {
        throw Exception('Download failed');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download document')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _save() {
    if (!_canEdit) return;
    setState(() {
      _saveError = '';
      _saveSuccess = 'Vehicle pass saved successfully.';
      _registryId ??= 1;
      _passNo ??= 1;
      _status = 'SAVED';
    });
  }

  void _submit() {
    if (!_canEdit) return;
    setState(() {
      _saveError = '';
      _saveSuccess = 'Pass submitted successfully.';
      _registryId ??= 1;
      _passNo ??= 1;
      _status = 'SUBMITTED';
    });
  }

  void _approve() => setState(() => _status = 'ACTIVE');
  void _reject() => setState(() => _status = 'REJECT');
  void _modify() => setState(() => _status = 'MODIFY');

  void _toggleHistory() => setState(() => _showHistory = !_showHistory);

  void _openAddPass() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PassEntryPage()),
    );
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

  Widget _chip(String label, String current, ValueChanged<String> onTap) {
    final selected = current.toUpperCase() == label.toUpperCase();
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(label),
    );
  }

  Widget _registryListSection() {
    return _section(
      'Vehicle Registry',
      Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search pass no, vehicle no, employee, contractor...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) {
              _query = v;
              _applyFilters();
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('All', _statusFilter, (v) {
                _statusFilter = v;
                _applyFilters();
              }),
              _chip('Active', _statusFilter, (v) {
                _statusFilter = v;
                _applyFilters();
              }),
              _chip('Needs_Modification', _statusFilter, (v) {
                _statusFilter = v;
                _applyFilters();
              }),
              _chip('Reject', _statusFilter, (v) {
                _statusFilter = v;
                _applyFilters();
              }),
            ],
          ),
          const SizedBox(height: 10),
          if (_listLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredRows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No pass records found'),
            )
          else
            ..._filteredRows.map(
              (item) => Container(
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
                            item.vehicleNo,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          item.status,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Pass No: ${item.passNo}'),
                    Text('Employee: ${item.name} (${item.empType})'),
                    Text('Gate: ${item.gateNo}'),
                    Text('Valid: ${item.validityDate}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vehicleSection() => Column(
    children: [
      _fieldLabel('Vehicle Number *'),
      TextField(
        controller: _vehicleController,
        readOnly: !_canEdit,
        onChanged: _setVehicleNo,
        decoration: const InputDecoration(hintText: 'MP09AB1234'),
      ),
      const SizedBox(height: 10),
      _fieldLabel('Vehicle Type *'),
      DropdownButtonFormField<String>(
        value: _vehicleType,
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
        onChanged: _canEdit
            ? (v) => setState(() => _vehicleType = v ?? '')
            : null,
      ),
      const SizedBox(height: 10),
      _fieldLabel('Brand / Model *'),
      TextField(
        controller: _brandController,
        readOnly: !_canEdit,
        onChanged: _setBrand,
        decoration: const InputDecoration(hintText: 'Honda City / Tata Truck'),
      ),
      const SizedBox(height: 10),
      _roField('Pass No', _passNo?.toString() ?? ''),
    ],
  );

  Widget _employeeSection() => Column(
    children: [
      _fieldLabel('Employee Type *'),
      DropdownButtonFormField<String>(
        value: _employeeType,
        items: const [
          'HEG',
          'TACC',
          'CONTRACT',
          'CRE-PRM',
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: _canEdit
            ? (v) => setState(() => _employeeType = v ?? '')
            : null,
      ),
      const SizedBox(height: 10),
      _fieldLabel('EC No *'),
      TextField(
        controller: _ecController,
        readOnly: !_canEdit,
        onChanged: _setEc,
        decoration: InputDecoration(
          hintText: 'Enter Employee Code',
          suffixIcon: _loading
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
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _roField('Employee Name', _employeeName)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Department', _department)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _roField('Dept Code', _deptCode)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Aadhar', _aadhar)),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: _roField('Contractor Code', _contractorCode)),
          const SizedBox(width: 8),
          Expanded(child: _roField('Contractor Name', _contractorName)),
        ],
      ),
    ],
  );

  Widget _passSection() => Row(
    children: [
      Expanded(child: _roField('Gate No', _gateNo)),
      const SizedBox(width: 8),
      Expanded(child: _roField('Parking To Be Used', _parkingToBeUsed)),
    ],
  );

  Widget _documentsSection() => Column(
    children: _documents
        .map(
          (doc) => Container(
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
                        doc.documentType.isEmpty
                            ? 'Document'
                            : doc.documentType,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (doc.documentId != null)
                      IconButton(
                        onPressed: _isDownloading
                            ? null
                            : () => _downloadDocument(doc),
                        icon: const Icon(
                          Icons.download,
                          color: Color(0xFF0B1E3A),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _roField('Document No', doc.documentNo),
                const SizedBox(height: 8),
                _roField('Expiry Date', _fmtDate(doc.expiryDate)),
                const SizedBox(height: 8),
                _roField(
                  'File',
                  doc.existingFile.isNotEmpty ? doc.existingFile : doc.fileName,
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _statusSection() => _section(
    'Workflow Status',
    Row(
      children: [
        Expanded(child: _roField('Current Status', _status)),
        const SizedBox(width: 8),
        Expanded(child: _roField('Entered By', _enteredBy)),
        const SizedBox(width: 8),
        Expanded(child: _roField('Pass No', _passNo?.toString() ?? '-')),
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
          icon: Icon(_showHistory ? Icons.visibility_off : Icons.history),
          label: Text(_showHistory ? 'Hide History' : 'Show History'),
        ),
        if (_showHistory)
          ..._history.map(
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
                    _fmtDateTime(h.dateOfEntry),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF627D98),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('By: ${h.empCode}'),
                  const SizedBox(height: 4),
                  Text(h.remark),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _remarkSection() => _section(
    'Review Remark',
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
      if (_canEdit)
        _actionButton(
          'Save',
          Icons.save,
          _save,
          bg: const Color(0xFF1D4ED8),
          fg: Colors.white,
        ),
      if (_canEdit)
        _actionButton(
          'Submit',
          Icons.send,
          _submit,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if (_status == 'SUBMITTED' && !_isReadOnly)
        _actionButton(
          'Send Modification',
          Icons.edit,
          _modify,
          bg: const Color(0xFFF59E0B),
          fg: Colors.white,
        ),
      if (_status == 'SUBMITTED' || _status == 'CONFIRMED')
        _actionButton(
          'Approve',
          Icons.check_circle,
          _approve,
          bg: const Color(0xFF15803D),
          fg: Colors.white,
        ),
      if (_status == 'SUBMITTED' || _status == 'CONFIRMED')
        _actionButton(
          'Reject',
          Icons.cancel,
          _reject,
          bg: const Color(0xFFDC2626),
          fg: Colors.white,
        ),
      if (!_canEdit && _status != 'SUBMITTED' && _status != 'CONFIRMED')
        _actionButton(
          'Back',
          Icons.arrow_back,
          () {},
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

  Widget _toast(String text, bool success) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: success ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
      ),
    ),
    child: Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.error_outline,
          color: success ? const Color(0xFF15803D) : const Color(0xFFDC2626),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: const HegAppBar(title: 'Pass Entry'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPass,
        backgroundColor: const Color(0xFF0EA5A4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Pass'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(),
              const SizedBox(height: 12),
              _registryListSection(),
              _section('Vehicle Details', _vehicleSection()),
              _section('Employee / Contractor Details', _employeeSection()),
              _section('Pass Details', _passSection()),
              _section('Required Documents', _documentsSection()),
              _statusSection(),
              const SizedBox(height: 12),
              if (_registryId != null) _historySection(),
              if (reviewRemark.isNotEmpty) _remarkSection(),
              const SizedBox(height: 12),
              _actionsSection(),
              if (_saveSuccess.isNotEmpty) _toast(_saveSuccess, true),
              if (_saveError.isNotEmpty) _toast(_saveError, false),
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
              const Text(
                'Pass Entry Form',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _registryId != null
                    ? 'ID : $_registryId'
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

class _HistoryItem {
  final String action;
  final String remark;
  final String empCode;
  final String dateOfEntry;

  const _HistoryItem({
    required this.action,
    required this.remark,
    required this.empCode,
    required this.dateOfEntry,
  });
}
