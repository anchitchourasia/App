// lib/screens/vpms/passes/pass_form_page.dart

import 'package:flutter/material.dart';
import '../../../models/pass_model.dart';
import '../../../services/vpms_service.dart';

class PassFormPage extends StatefulWidget {
  final PassModel? pass; // null = Add mode, non-null = Edit mode
  const PassFormPage({super.key, this.pass});
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

  // ── Form fields ──────────────────────────────────────
  late String _empType;
  final _employeeNoCtrl = TextEditingController();
  final _empCompanyNoCtrl = TextEditingController();
  final _contractorCodeCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _gateNoCtrl = TextEditingController();
  final _parkingCtrl = TextEditingController();
  final _vehicleIdCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _validityDateCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  late String _status;
  late String _isActive;

  @override
  void initState() {
    super.initState();
    final p = widget.pass;
    _empType = p?.empType ?? 'Company_Employee';
    _status = p?.status ?? 'Active';
    _isActive = p?.isActive ?? 'Y';
    if (p != null) {
      _employeeNoCtrl.text = p.employeeNo ?? '';
      _empCompanyNoCtrl.text = p.employeeCompanyNo ?? '';
      _contractorCodeCtrl.text = p.contractorCode ?? '';
      _deptCtrl.text = p.dept ?? '';
      _gateNoCtrl.text = p.gateNo;
      _parkingCtrl.text = p.parkingToBeUsed ?? '';
      _vehicleIdCtrl.text = '${p.vehicleId ?? ''}';
      _vehicleTypeCtrl.text = p.typeOfVehicle ?? '';
      _mobileCtrl.text = p.mobileNo ?? '';
      _issueDateCtrl.text = p.issueDate;
      _validityDateCtrl.text = p.validityDate;
      _remarksCtrl.text = p.remarks ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _employeeNoCtrl,
      _empCompanyNoCtrl,
      _contractorCodeCtrl,
      _deptCtrl,
      _gateNoCtrl,
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

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
      gateNo: _gateNoCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Pass' : 'Issue Pass',
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
              // ── Emp Type toggle ─────────────────────────
              _card(
                title: 'Employee Type',
                icon: Icons.people_outline,
                child: Row(
                  children: ['Company_Employee', 'Contractor'].map((t) {
                    final sel = _empType == t;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: t == 'Company_Employee' ? 6 : 0,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _empType = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                            child: Center(
                              child: Text(
                                t.replaceAll('_', '\n'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Employee / Contractor fields ─────────────
              _card(
                title: _empType == 'Contractor'
                    ? 'Contractor Details'
                    : 'Employee Details',
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    if (_empType == 'Company_Employee') ...[
                      _field('Employee No *', _employeeNoCtrl, required: true),
                      const SizedBox(height: 12),
                      _field('Company No', _empCompanyNoCtrl),
                    ] else ...[
                      _field(
                        'Contractor Code *',
                        _contractorCodeCtrl,
                        required: true,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _field('Department / Area', _deptCtrl),
                    const SizedBox(height: 12),
                    _field(
                      'Mobile No',
                      _mobileCtrl,
                      keyboard: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Vehicle fields ───────────────────────────
              _card(
                title: 'Vehicle Info',
                icon: Icons.directions_car_outlined,
                child: Column(
                  children: [
                    _field(
                      'Vehicle ID *',
                      _vehicleIdCtrl,
                      required: true,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Type of Vehicle',
                      _vehicleTypeCtrl,
                      hint: 'Auto-filled or enter manually',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Pass dates + gate ────────────────────────
              _card(
                title: 'Pass Details',
                icon: Icons.confirmation_number_outlined,
                child: Column(
                  children: [
                    _datePicker('Issue Date *', _issueDateCtrl, required: true),
                    const SizedBox(height: 12),
                    _datePicker(
                      'Valid Till *',
                      _validityDateCtrl,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Gate No *',
                      _gateNoCtrl,
                      required: true,
                      hint: 'e.g. GATE_01',
                    ),
                    const SizedBox(height: 12),
                    _field('Parking Area', _parkingCtrl, hint: 'e.g. P-Block'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Status + isActive ────────────────────────
              _card(
                title: 'Status',
                icon: Icons.toggle_on_outlined,
                child: Column(
                  children: [
                    _dropdown('Pass Status', _status, [
                      'Active',
                      'Expired',
                      'Suspended',
                      'Pending',
                    ], (v) => setState(() => _status = v!)),
                    const SizedBox(height: 12),
                    _dropdown('Is Active', _isActive, [
                      'Y',
                      'N',
                    ], (v) => setState(() => _isActive = v!)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Remarks ──────────────────────────────────
              _card(
                title: 'Remarks',
                icon: Icons.notes_outlined,
                child: _field(
                  'Remarks',
                  _remarksCtrl,
                  maxLines: 3,
                  hint: 'Optional notes...',
                ),
              ),
              const SizedBox(height: 16),

              // ── Error / Success ──────────────────────────
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_success != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _success!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Save button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
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
                      : Text(
                          _isEdit ? 'Update Pass' : 'Issue Pass',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? hint,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboard,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    ),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
        : null,
  );

  Widget _datePicker(
    String label,
    TextEditingController ctrl, {
    bool required = false,
  }) => TextFormField(
    controller: ctrl,
    readOnly: true,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      suffixIcon: const Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: Color(0xFF1A237E),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    ),
    onTap: () => _pickDate(ctrl),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
        : null,
  );

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    ),
    items: items
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(fontSize: 14)),
          ),
        )
        .toList(),
  );
}
