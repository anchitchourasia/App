// lib/screens/passes/pass_form_page.dart

import 'package:flutter/material.dart';
import '../../models/pass_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/vpms_service.dart';

class PassFormPage extends StatefulWidget {
  final PassModel? pass; // null = Issue mode, non-null = Edit mode
  final int? prefilledVehicleId; // ← set when opening from Vehicles Master

  const PassFormPage({super.key, this.pass, this.prefilledVehicleId});

  @override
  State<PassFormPage> createState() => _PassFormPageState();
}

class _PassFormPageState extends State<PassFormPage> {
  final _service = VpmsService();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  String? _error;
  String? _success;

  bool get _isEdit => widget.pass != null;

  // ── Vehicle lookup state ─────────────────────────────
  bool _lookingUp = false;
  String? _vehicleLookupError;
  String? _vehicleLookupSuccess;

  // ── Form controllers ─────────────────────────────────
  late String _empType;
  final _employeeNoCtrl = TextEditingController();
  final _empCompanyNoCtrl = TextEditingController();
  final _contractorCodeCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _parkingCtrl = TextEditingController();
  final _vehicleIdCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _validityDateCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  late String _gateNo;
  late String _status;
  late String _isActive;

  static const _gates = ['GATE_01', 'GATE_02', 'GATE_03', 'GATE_04'];
  static const _statuses = ['Active', 'Expired', 'Suspended', 'Pending'];

  @override
  void initState() {
    super.initState();
    final p = widget.pass;
    _empType = p?.empType ?? 'Company_Employee';
    _status = p?.status ?? 'Active';
    _isActive = p?.isActive ?? 'Y';
    _gateNo = (p?.gateNo.isNotEmpty == true) ? p!.gateNo : 'GATE_01';

    if (p != null) {
      _employeeNoCtrl.text = p.employeeNo ?? '';
      _empCompanyNoCtrl.text = p.employeeCompanyNo ?? '';
      _contractorCodeCtrl.text = p.contractorCode ?? '';
      _deptCtrl.text = p.dept ?? '';
      _parkingCtrl.text = p.parkingToBeUsed ?? '';
      _vehicleIdCtrl.text = '${p.vehicleId ?? ''}';
      _vehicleTypeCtrl.text = p.typeOfVehicle ?? '';
      _mobileCtrl.text = p.mobileNo ?? '';
      _issueDateCtrl.text = p.issueDate;
      _validityDateCtrl.text = p.validityDate;
      _remarksCtrl.text = p.remarks ?? '';
      // pre-show vehicle lookup success if already has type
      if ((p.typeOfVehicle ?? '').isNotEmpty) {
        _vehicleLookupSuccess = '✅ Vehicle found: ${p.typeOfVehicle}';
      }
    }

    // ── Pre-fill vehicleId when launched from Vehicles Master ──
    if (widget.prefilledVehicleId != null && p == null) {
      _vehicleIdCtrl.text = '${widget.prefilledVehicleId}';
      // auto-trigger lookup after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _lookupVehicle());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _employeeNoCtrl,
      _empCompanyNoCtrl,
      _contractorCodeCtrl,
      _deptCtrl,
      _parkingCtrl,
      _vehicleIdCtrl,
      _vehicleTypeCtrl,
      _mobileCtrl,
      _issueDateCtrl,
      _validityDateCtrl,
      _remarksCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // VEHICLE ID LOOKUP  (matches web onVehicleIdBlur)
  // ══════════════════════════════════════════════════════
  Future<void> _lookupVehicle() async {
    final idStr = _vehicleIdCtrl.text.trim();
    setState(() {
      _vehicleLookupError = null;
      _vehicleLookupSuccess = null;
      _vehicleTypeCtrl.text = '';
    });
    if (idStr.isEmpty || idStr == '0') return;

    final id = int.tryParse(idStr);
    if (id == null) {
      setState(() => _vehicleLookupError = 'Vehicle ID must be a number.');
      return;
    }

    setState(() => _lookingUp = true);

    try {
      final List<VehicleModel> vehicles = await _service.getVehicles();
      final found = vehicles.cast<VehicleModel?>().firstWhere(
        (v) => v?.vehicleId == id,
        orElse: () => null,
      );
      if (found != null) {
        setState(() {
          _vehicleTypeCtrl.text = found.vehicleType;
          _vehicleLookupSuccess = '✅ Vehicle found: ${found.vehicleType}';
        });
      } else {
        setState(
          () => _vehicleLookupError =
              'Vehicle ID $id not found in Vehicles Master.',
        );
      }
    } catch (e) {
      setState(
        () => _vehicleLookupError =
            'Could not reach Vehicles Master. Check backend.',
      );
    } finally {
      setState(() => _lookingUp = false);
    }
  }

  // ══════════════════════════════════════════════════════
  // DATE PICKER
  // ══════════════════════════════════════════════════════
  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? now,
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

  // ══════════════════════════════════════════════════════
  // SAVE
  // ══════════════════════════════════════════════════════
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleLookupError != null) {
      setState(() => _error = 'Fix Vehicle ID error before saving.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    final pass = PassModel(
      passId: widget.pass?.passId,
      issueDate: _issueDateCtrl.text.trim(),
      validityDate: _validityDateCtrl.text.trim(),
      employeeNo: _empType == 'Company_Employee'
          ? _employeeNoCtrl.text.trim()
          : null,
      employeeCompanyNo: _empType == 'Company_Employee'
          ? _empCompanyNoCtrl.text.trim()
          : null,
      contractorCode: _empType == 'Contractor'
          ? _contractorCodeCtrl.text.trim()
          : null,
      dept: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
      gateNo: _gateNo,
      parkingToBeUsed: _parkingCtrl.text.trim().isEmpty
          ? null
          : _parkingCtrl.text.trim(),
      vehicleId: int.tryParse(_vehicleIdCtrl.text.trim()),
      typeOfVehicle: _vehicleTypeCtrl.text.trim().isEmpty
          ? null
          : _vehicleTypeCtrl.text.trim(),
      mobileNo: _mobileCtrl.text.trim().isEmpty
          ? null
          : _mobileCtrl.text.trim(),
      status: _status,
      remarks: _remarksCtrl.text.trim().isEmpty
          ? null
          : _remarksCtrl.text.trim(),
      isActive: _isActive,
      empType: _empType,
      enterBy: 'ADMIN',
      enterDate: DateTime.now().toIso8601String().split('T')[0],
    );

    try {
      if (_isEdit) {
        await _service.updatePass(pass);
      } else {
        await _service.issuePass(pass);
      }
      setState(
        () => _success = _isEdit
            ? 'Pass updated successfully!'
            : 'Pass issued successfully!',
      );
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Pass — #${widget.pass?.passId}' : 'Issue New Pass',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── SECTION 1: Employee Type ─────────────────
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    sel
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 16,
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t == 'Company_Employee'
                                        ? 'Company Employee'
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
                  const SizedBox(height: 16),

                  // Employee / Contractor fields
                  if (_empType == 'Company_Employee') ...[
                    _field(
                      'EMPLOYEE NO *',
                      _employeeNoCtrl,
                      required: true,
                      hint: 'e.g. EMP001',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'EC NO (COMPANY NO)',
                      _empCompanyNoCtrl,
                      hint: 'e.g. HEG-001',
                    ),
                    const SizedBox(height: 12),
                    _field('DEPARTMENT', _deptCtrl, hint: 'e.g. Mechanical'),
                  ] else ...[
                    _field(
                      'CONTRACTOR CODE *',
                      _contractorCodeCtrl,
                      required: true,
                      hint: 'e.g. CONT-01',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'WORK AREA / DEPARTMENT',
                      _deptCtrl,
                      hint: 'e.g. Civil Works',
                    ),
                  ],
                  const SizedBox(height: 12),
                  _field(
                    'MOBILE NO',
                    _mobileCtrl,
                    keyboard: TextInputType.phone,
                    hint: 'e.g. 9876543210',
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── SECTION 2: Vehicle Details ────────────────
              _section(
                title: 'VEHICLE DETAILS',
                color: const Color(0xFF1565C0),
                children: [
                  // Vehicle ID with lookup
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VEHICLE ID (FK) *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehicleIdCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                              decoration: _inputDeco(hint: 'e.g. 101'),
                              onEditingComplete: _lookupVehicle,
                              onFieldSubmitted: (_) => _lookupVehicle(),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Vehicle ID is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Lookup button
                          GestureDetector(
                            onTap: _lookingUp ? null : _lookupVehicle,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _lookingUp
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Enter Vehicle ID from Vehicles Master table',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      // Lookup result
                      if (_vehicleLookupError != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _vehicleLookupError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_vehicleLookupSuccess != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _vehicleLookupSuccess!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Type of Vehicle (read-only, auto-filled)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TYPE OF VEHICLE *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _vehicleTypeCtrl,
                        readOnly: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: _inputDeco(
                          hint: 'Auto-filled when Vehicle ID is entered',
                          fillColor: Colors.grey.shade100,
                          suffixIcon: Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-filled when Vehicle ID is entered',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── SECTION 3: Pass Details ───────────────────
              _section(
                title: 'PASS DETAILS',
                color: const Color(0xFF2E7D32),
                children: [
                  _labelField(
                    'ISSUE DATE *',
                    _datePicker('Issue Date *', _issueDateCtrl, required: true),
                  ),
                  const SizedBox(height: 12),
                  _labelField(
                    'VALIDITY DATE *',
                    _datePicker(
                      'Validity Date *',
                      _validityDateCtrl,
                      required: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Gate No dropdown
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
                        initialValue: _gates.contains(_gateNo) ? _gateNo : 'GATE_01',
                        onChanged: (v) => setState(() => _gateNo = v!),
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
                  _field(
                    'PARKING TO BE USED',
                    _parkingCtrl,
                    hint: 'e.g. LOT_A',
                  ),
                  const SizedBox(height: 12),

                  // Status dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _statuses.contains(_status) ? _status : 'Active',
                        onChanged: (v) => setState(() => _status = v!),
                        decoration: _inputDeco(),
                        items: _statuses
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Is Active dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IS ACTIVE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _isActive,
                        onChanged: (v) => setState(() => _isActive = v!),
                        decoration: _inputDeco(),
                        items: const [
                          DropdownMenuItem(
                            value: 'Y',
                            child: Text('Yes', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'N',
                            child: Text('No', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'REMARKS',
                    _remarksCtrl,
                    maxLines: 3,
                    hint: 'Any remarks...',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Error / Success banners ───────────────────
              if (_error != null) _banner(msg: _error!, isError: true),
              if (_success != null) _banner(msg: _success!, isError: false),

              // ── Save button ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEdit
                                  ? Icons.check
                                  : Icons.confirmation_number_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit ? 'Update Pass' : 'Issue Pass',
                              style: const TextStyle(
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
    );
  }

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════
  Widget _section({
    required String title,
    required Color color,
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
          ],
        ),
        Divider(height: 20, color: Colors.grey.shade100),
        ...children,
      ],
    ),
  );

  InputDecoration _inputDeco({
    String? hint,
    Color? fillColor,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
    suffixIcon: suffixIcon,
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
    fillColor: fillColor ?? const Color(0xFFF9FAFB),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? hint,
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
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14),
        decoration: _inputDeco(hint: hint),
        validator: required
            ? (v) =>
                  (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    ],
  );

  Widget _labelField(String label, Widget child) => Column(
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
      child,
    ],
  );

  Widget _datePicker(
    String label,
    TextEditingController ctrl, {
    bool required = false,
  }) => TextFormField(
    controller: ctrl,
    readOnly: true,
    style: const TextStyle(fontSize: 14),
    decoration: _inputDeco(
      suffixIcon: const Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: Color(0xFF1A237E),
      ),
    ),
    onTap: () => _pickDate(ctrl),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
        : null,
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
