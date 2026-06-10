// lib/screens/vpms/vehicles/vehicles_list_page.dart
// ✅ UPDATED: Added auto-refresh polling (mirrors web vehicles.ts startPolling())
//            All existing features preserved 100%.

import 'dart:async'; // ✅ NEW — for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/pass_model.dart';
import '../../../services/vpms_service.dart';
import 'vehicle_detail_page.dart';
import 'vehicle_form_page.dart';

class VehiclesListPage extends StatefulWidget {
  const VehiclesListPage({super.key});
  @override
  State<VehiclesListPage> createState() => _VehiclesListPageState();
}

class _VehiclesListPageState extends State<VehiclesListPage> {
  final _service = VpmsService();

  List<VehicleModel> _all = [];
  List<VehicleModel> _filtered = [];
  bool _loading = true;
  String? _error;

  // ✅ NEW — polling timer + last-updated timestamp
  Timer? _pollTimer;
  DateTime? _lastUpdated;
  static const _pollInterval = Duration(seconds: 30); // matches web 30s

  String _query = '';
  String _filterClass = 'All';
  String _filterStatus = 'All';

  static const _classOptions = [
    'All',
    'Two_Wheeler',
    'Four_Wheeler',
    'Heavy_Machinery',
  ];
  static const _statusOptions = ['All', 'Active', 'Inactive', 'Blacklisted'];

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load(); // first load — shows full spinner
    _startPolling(); // ✅ NEW — background auto-refresh every 30s
  }

  // ✅ NEW — mirrors web ngOnDestroy(): destroy$.next() / complete()
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ✅ NEW — mirrors web startPolling() with interval(30000) + switchMap
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      // guard: don't update if widget is disposed (mirrors takeUntil destroy$)
      if (!mounted) return;
      _load(silent: true);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD
  // silent=true → background poll, no spinner, no error banner overwrite
  // silent=false (default) → first load / manual refresh, shows spinner
  // ─────────────────────────────────────────────────────────────
  Future<void> _load({bool silent = false}) async {
    if (!silent)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      _all = await _service.getVehicles();
      _lastUpdated = DateTime.now(); // ✅ NEW — track last successful fetch
      _applyFilters();
    } catch (e) {
      // ✅ silent polls fail quietly — never overwrite UI with error
      if (!silent) setState(() => _error = e.toString());
    } finally {
      if (!silent) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _query.toLowerCase();
    _filtered = _all.where((v) {
      final matchSearch =
          q.isEmpty ||
          v.vehicleNo.toLowerCase().contains(q) ||
          v.vehicleType.toLowerCase().contains(q) ||
          (v.brandModel?.toLowerCase().contains(q) ?? false);
      final matchClass =
          _filterClass == 'All' || v.vehicleClass == _filterClass;
      final matchStatus =
          _filterStatus == 'All' ||
          (_filterStatus == 'Active' &&
              v.isActiveVehicle &&
              !v.isBlacklistedVehicle) ||
          (_filterStatus == 'Inactive' && !v.isActiveVehicle) ||
          (_filterStatus == 'Blacklisted' && v.isBlacklistedVehicle);
      return matchSearch && matchClass && matchStatus;
    }).toList();
    setState(() {});
  }

  // ── DELETE ───────────────────────────────────────────────────
  Future<void> _confirmDelete(VehicleModel v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete Vehicle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'Are you sure you want to delete\n'),
              TextSpan(
                text: v.vehicleNo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const TextSpan(text: '?\n\nThis action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting vehicle...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      await _service.deleteVehicle(v.vehicleId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${v.vehicleNo} deleted successfully'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── ADD ──────────────────────────────────────────────────────
  Future<void> _openAddForm() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VehicleFormPage()),
    );
    if (added == true) _load();
  }

  // ── EDIT ─────────────────────────────────────────────────────
  Future<void> _openEditForm(VehicleModel v) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VehicleFormPage(vehicle: v)),
    );
    if (edited == true) _load();
  }

  // ── ISSUE PASS ───────────────────────────────────────────────
  void _openIssuePassModal(VehicleModel v) {
    if (v.isBlacklistedVehicle) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 22),
              SizedBox(width: 8),
              Text(
                'Cannot Issue Pass',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                const TextSpan(text: 'Vehicle '),
                TextSpan(
                  text: v.vehicleNo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const TextSpan(text: ' is '),
                const TextSpan(
                  text: 'BLACKLISTED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(
                  text: '.\n\nPass cannot be issued for a blacklisted vehicle.',
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IssuePassSheet(vehicle: v, service: _service),
    );
  }

  Color _classColor(String c) => switch (c) {
    'Two_Wheeler' => const Color(0xFF1B5E20),
    'Four_Wheeler' => const Color(0xFF0D47A1),
    'Heavy_Machinery' => const Color(0xFFBF360C),
    _ => Colors.grey.shade600,
  };

  IconData _classIcon(String c) => switch (c) {
    'Two_Wheeler' => Icons.two_wheeler,
    'Four_Wheeler' => Icons.directions_car_filled,
    'Heavy_Machinery' => Icons.construction,
    _ => Icons.directions_car_filled,
  };

  // ✅ NEW — formats last-updated time for AppBar subtitle
  String get _liveLabel {
    if (_lastUpdated == null) return '';
    final h = _lastUpdated!.hour.toString().padLeft(2, '0');
    final m = _lastUpdated!.minute.toString().padLeft(2, '0');
    return 'Live · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        // ✅ UPDATED title — now shows live timestamp next to count
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Vehicles  (${_all.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ NEW — pulsing green dot to show live status
                if (_lastUpdated != null)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF69F0AE),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            // ✅ NEW — "Live · HH:MM" subtitle
            if (_liveLabel.isNotEmpty)
              Text(
                _liveLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Refresh',
            // ✅ manual refresh → full spinner (silent: false)
            onPressed: () => _load(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                  )
                : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : _filtered.isEmpty
                ? const _EmptyView()
                : RefreshIndicator(
                    color: const Color(0xFF1A237E),
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final v = _filtered[i];
                        return _VehicleCard(
                          vehicle: v,
                          classColor: _classColor(v.vehicleClass),
                          classIcon: _classIcon(v.vehicleClass),
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailPage(
                                vehicle: v,
                                onEdit: () => _openEditForm(v),
                                onDelete: () => _confirmDelete(v),
                              ),
                            ),
                          ),
                          onEdit: () => _openEditForm(v),
                          onDelete: () => _confirmDelete(v),
                          onIssuePass: () => _openIssuePassModal(v),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search vehicle no, type, brand...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Colors.grey.shade600,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1A237E),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
            ),
            onChanged: (v) {
              _query = v;
              _applyFilters();
            },
          ),
          const SizedBox(height: 10),
          _ChipRow(
            label: 'Class',
            options: _classOptions,
            selected: _filterClass,
            onSelect: (v) {
              _filterClass = v;
              _applyFilters();
            },
          ),
          const SizedBox(height: 6),
          _ChipRow(
            label: 'Status',
            options: _statusOptions,
            selected: _filterStatus,
            onSelect: (v) {
              _filterStatus = v;
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ISSUE PASS BOTTOM SHEET — unchanged, all features preserved
// ══════════════════════════════════════════════════════════════
class _IssuePassSheet extends StatefulWidget {
  final VehicleModel vehicle;
  final VpmsService service;
  const _IssuePassSheet({required this.vehicle, required this.service});
  @override
  State<_IssuePassSheet> createState() => _IssuePassSheetState();
}

class _IssuePassSheetState extends State<_IssuePassSheet> {
  bool _saving = false;
  String? _error;
  String? _success;

  String _empType = 'Company_Employee';
  String _gateNo = '';

  final _employeeNoCtrl = TextEditingController();
  final _empCompanyNoCtrl = TextEditingController();
  final _contractorCodeCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _validityDateCtrl = TextEditingController();
  final _parkingCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  static const _gates = ['GATE_01', 'GATE_02', 'GATE_03', 'GATE_04'];

  @override
  void dispose() {
    for (final c in [
      _employeeNoCtrl,
      _empCompanyNoCtrl,
      _contractorCodeCtrl,
      _deptCtrl,
      _mobileCtrl,
      _issueDateCtrl,
      _validityDateCtrl,
      _parkingCtrl,
      _remarksCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _success = null;
    });
    if (_issueDateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Issue Date is required.');
      return;
    }
    if (_validityDateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Validity Date is required.');
      return;
    }
    if (_gateNo.isEmpty) {
      setState(() => _error = 'Gate No is required.');
      return;
    }
    if (_empType == 'Company_Employee' && _employeeNoCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Employee No is required.');
      return;
    }
    if (_empType == 'Contractor' && _contractorCodeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Contractor Code is required.');
      return;
    }
    setState(() => _saving = true);

    final pass = PassModel(
      vehicleId: widget.vehicle.vehicleId,
      typeOfVehicle: widget.vehicle.vehicleType,
      empType: _empType,
      issueDate: _issueDateCtrl.text.trim(),
      validityDate: _validityDateCtrl.text.trim(),
      gateNo: _gateNo,
      parkingToBeUsed: _parkingCtrl.text.trim().isEmpty
          ? null
          : _parkingCtrl.text.trim().toUpperCase(),
      status: 'Active',
      isActive: 'Y',
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
      enterBy: 'ADMIN',
      enterDate: DateTime.now().toIso8601String().split('T')[0],
      dept: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
      mobileNo: _mobileCtrl.text.trim().isEmpty
          ? null
          : _mobileCtrl.text.trim(),
      employeeNo: _empType == 'Company_Employee'
          ? (_employeeNoCtrl.text.trim().isEmpty
                ? null
                : _employeeNoCtrl.text.trim())
          : null,
      employeeCompanyNo: _empType == 'Company_Employee'
          ? (_empCompanyNoCtrl.text.trim().isEmpty
                ? null
                : _empCompanyNoCtrl.text.trim())
          : null,
      contractorCode: _empType == 'Contractor'
          ? (_contractorCodeCtrl.text.trim().isEmpty
                ? null
                : _contractorCodeCtrl.text.trim())
          : null,
    );

    try {
      await widget.service.issuePass(pass);
      setState(
        () => _success =
            '✅ Pass issued successfully for ${widget.vehicle.vehicleNo}!',
      );
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F2F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 14, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    color: Color(0xFF1A237E),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issue Pass',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          v.vehicleNo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // scrollable form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── SECTION 1: Vehicle Details — READ-ONLY ──────────
                    _section(
                      title: 'VEHICLE DETAILS',
                      badge: 'Auto-filled',
                      color: const Color(0xFF1565C0),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _readonlyField(
                                'Vehicle ID',
                                '${v.vehicleId ?? '—'}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _readonlyField('Vehicle No', v.vehicleNo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _readonlyField('Type', v.vehicleType),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _readonlyField(
                                'Class',
                                v.vehicleClass.replaceAll('_', ' '),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── SECTION 2: Person Details ────────────────────────
                    _section(
                      title: 'PERSON DETAILS',
                      color: const Color(0xFFE65100),
                      children: [
                        const Text(
                          'EMPLOYEE TYPE *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: ['Company_Employee', 'Contractor'].map((t) {
                            final sel = _empType == t;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: t == 'Company_Employee' ? 8 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () => setState(() => _empType = t),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFF1A237E)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? const Color(0xFF1A237E)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          sel
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          size: 15,
                                          color: sel
                                              ? Colors.white
                                              : Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          t == 'Company_Employee'
                                              ? 'Company Emp.'
                                              : 'Contractor',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: sel
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        if (_empType == 'Company_Employee') ...[
                          _inputField(
                            label: 'EMPLOYEE NO *',
                            ctrl: _employeeNoCtrl,
                            hint: 'e.g. EMP001',
                            formatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              _UpperCaseFormatter(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _inputField(
                            label: 'EC NO (COMPANY NO)',
                            ctrl: _empCompanyNoCtrl,
                            hint: 'e.g. HEG001',
                            formatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              _UpperCaseFormatter(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _inputField(
                            label: 'DEPARTMENT',
                            ctrl: _deptCtrl,
                            hint: 'e.g. Mechanical',
                          ),
                        ] else ...[
                          _inputField(
                            label: 'CONTRACTOR CODE *',
                            ctrl: _contractorCodeCtrl,
                            hint: 'e.g. CON001',
                            formatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              _UpperCaseFormatter(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _inputField(
                            label: 'WORK AREA / DEPT',
                            ctrl: _deptCtrl,
                            hint: 'e.g. Civil Works',
                          ),
                        ],
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'MOBILE NO',
                          ctrl: _mobileCtrl,
                          hint: 'e.g. 9876543210',
                          keyboard: TextInputType.phone,
                          maxLength: 10,
                          formatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── SECTION 3: Pass Details ──────────────────────────
                    _section(
                      title: 'PASS DETAILS',
                      color: const Color(0xFF2E7D32),
                      children: [
                        _dateField('ISSUE DATE *', _issueDateCtrl),
                        const SizedBox(height: 12),
                        _dateField('VALIDITY DATE *', _validityDateCtrl),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GATE NO *',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF37474F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _gates.contains(_gateNo)
                                  ? _gateNo
                                  : null,
                              hint: const Text(
                                '-- Select Gate --',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              onChanged: (val) =>
                                  setState(() => _gateNo = val ?? ''),
                              decoration: _inputDeco(),
                              items: _gates
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(
                                        g.replaceAll('_', ' '),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'PARKING TO BE USED',
                          ctrl: _parkingCtrl,
                          hint: 'e.g. A-BLOCK, HEAVY YARD',
                          formatters: [_UpperCaseFormatter()],
                        ),
                        const SizedBox(height: 12),
                        _inputField(
                          label: 'REMARKS',
                          ctrl: _remarksCtrl,
                          hint: 'Any remarks...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_error != null) _banner(msg: _error!, isError: true),
                    if (_success != null)
                      _banner(msg: _success!, isError: false),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Issue Pass',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────

  Widget _section({
    required String title,
    required Color color,
    String? badge,
    required List<Widget> children,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
        Divider(height: 20, color: Colors.grey.shade100),
        ...children,
      ],
    ),
  );

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.8),
    ),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
  );

  Widget _readonlyField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF37474F),
        ),
      ),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 13, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _inputField({
    required String label,
    required TextEditingController ctrl,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter> formatters = const [],
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF37474F),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: const TextStyle(fontSize: 14),
        decoration: _inputDeco(hint: hint).copyWith(counterText: ''),
      ),
    ],
  );

  Widget _dateField(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF37474F),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        readOnly: true,
        style: const TextStyle(fontSize: 14),
        decoration: _inputDeco().copyWith(
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF1A237E),
          ),
        ),
        onTap: () => _pickDate(ctrl),
      ),
    ],
  );

  Widget _banner({required String msg, required bool isError}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isError ? Colors.red.shade200 : Colors.green.shade200,
      ),
    ),
    child: Row(
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          size: 18,
          color: isError ? Colors.red.shade600 : Colors.green.shade700,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(
              fontSize: 13,
              color: isError ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── UPPERCASE formatter ────────────────────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

// ══════════════════════════════════════════════════════════════
// VEHICLE CARD — unchanged
// ══════════════════════════════════════════════════════════════
class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final Color classColor;
  final IconData classIcon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onIssuePass;

  const _VehicleCard({
    required this.vehicle,
    required this.classColor,
    required this.classIcon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onIssuePass,
  });

  @override
  Widget build(BuildContext context) {
    final isBlacklisted = vehicle.isBlacklistedVehicle;
    final isInactive = !vehicle.isActiveVehicle;
    final statusColor = isBlacklisted
        ? const Color(0xFFC62828)
        : isInactive
        ? Colors.grey.shade600
        : const Color(0xFF2E7D32);
    final statusLabel = isBlacklisted
        ? 'BLACKLISTED'
        : isInactive
        ? 'INACTIVE'
        : 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: classColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(classIcon, color: classColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.vehicleNo.isNotEmpty
                              ? vehicle.vehicleNo
                              : '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _typeAndBrand(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _badge(
                              vehicle.vehicleClass.replaceAll('_', ' '),
                              classColor,
                            ),
                            const SizedBox(width: 8),
                            _badge(statusLabel, statusColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // Action row: Edit | Delete | Issue Pass
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.shade100),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.shade100),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onIssuePass,
                    icon: Icon(
                      Icons.confirmation_number_outlined,
                      size: 16,
                      color: isBlacklisted
                          ? Colors.grey.shade400
                          : const Color(0xFF1B5E20),
                    ),
                    label: Text(
                      'Issue Pass',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isBlacklisted
                            ? Colors.grey.shade400
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );

  String _typeAndBrand() {
    final type = vehicle.vehicleType.isNotEmpty ? vehicle.vehicleType : null;
    final brand = vehicle.brandModel?.isNotEmpty == true
        ? vehicle.brandModel
        : null;
    if (type != null && brand != null) return '$type  •  $brand';
    return type ?? brand ?? '—';
  }
}

// ── Chip Row ───────────────────────────────────────────────────
class _ChipRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _ChipRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 46,
        child: Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((o) {
              final isSel = selected == o;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelect(o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF1A237E)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel
                            ? const Color(0xFF1A237E)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      o.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}

// ── Error View ─────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Could not connect to server',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Empty View ─────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.directions_car_outlined,
          size: 60,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'No vehicles found',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Try changing your filters',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}
