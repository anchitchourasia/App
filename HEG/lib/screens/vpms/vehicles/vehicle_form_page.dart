// lib/screens/vpms/vehicles/vehicle_form_page.dart

import 'package:flutter/material.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/vpms_service.dart';

class VehicleFormPage extends StatefulWidget {
  // If vehicle is null → ADD (POST)
  // If vehicle is passed → EDIT (PUT)
  final VehicleModel? vehicle;
  const VehicleFormPage({super.key, this.vehicle});

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = VpmsService();
  bool _submitting = false;

  // Controllers
  late final TextEditingController _vehicleNoCtrl;
  late final TextEditingController _vehicleTypeCtrl;
  late final TextEditingController _brandModelCtrl;

  // Dropdown values
  String _vehicleClass = 'Four_Wheeler';
  String _isActive = 'Y';
  String _isBlacklisted = 'N';

  bool get _isEditMode => widget.vehicle != null;

  static const _classOptions = [
    'Two_Wheeler',
    'Four_Wheeler',
    'Heavy_Machinery',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    final v = widget.vehicle;
    _vehicleNoCtrl = TextEditingController(text: v?.vehicleNo ?? '');
    _vehicleTypeCtrl = TextEditingController(text: v?.vehicleType ?? '');
    _brandModelCtrl = TextEditingController(text: v?.brandModel ?? '');
    if (v != null) {
      _vehicleClass = v.vehicleClass;
      _isActive = v.isActive;
      _isBlacklisted = v.isBlacklisted;
    }
  }

  @override
  void dispose() {
    _vehicleNoCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _brandModelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final vehicle = VehicleModel(
      vehicleId: widget.vehicle?.vehicleId,
      vehicleNo: _vehicleNoCtrl.text.trim().toUpperCase(),
      vehicleType: _vehicleTypeCtrl.text.trim(),
      vehicleClass: _vehicleClass,
      brandModel: _brandModelCtrl.text.trim().isEmpty
          ? null
          : _brandModelCtrl.text.trim(),
      isActive: _isActive,
      isBlacklisted: _isBlacklisted,
    );

    try {
      if (_isEditMode) {
        await _service.updateVehicle(vehicle); // PUT
      } else {
        await _service.registerVehicle(vehicle); // POST
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Vehicle updated successfully'
                : 'Vehicle registered successfully',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context, true); // return true = refresh list
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Vehicle' : 'Add Vehicle',
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
              _formCard([
                // Vehicle No
                _field(
                  controller: _vehicleNoCtrl,
                  label: 'Vehicle Number *',
                  hint: 'e.g. MP04HEG2026',
                  icon: Icons.pin,
                  readOnly: _isEditMode, // can't change vehicle no on edit
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Vehicle number is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Vehicle Type
                _field(
                  controller: _vehicleTypeCtrl,
                  label: 'Vehicle Type *',
                  hint: 'e.g. Car, SUV, Truck, Motorcycle',
                  icon: Icons.directions_car_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Vehicle type is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Vehicle Class dropdown
                _dropdownField(
                  label: 'Vehicle Class *',
                  icon: Icons.category_outlined,
                  value: _vehicleClass,
                  items: _classOptions,
                  onChanged: (v) => setState(() => _vehicleClass = v!),
                ),
                const SizedBox(height: 14),

                // Brand / Model
                _field(
                  controller: _brandModelCtrl,
                  label: 'Brand / Model',
                  hint: 'e.g. Tata Nexon, Honda City',
                  icon: Icons.branding_watermark_outlined,
                ),
                const SizedBox(height: 14),

                // Is Active toggle
                _toggleRow(
                  label: 'Active Status',
                  value: _isActive == 'Y',
                  onColor: const Color(0xFF2E7D32),
                  onLabel: 'Active',
                  offLabel: 'Inactive',
                  onChanged: (v) => setState(() => _isActive = v ? 'Y' : 'N'),
                ),
                const SizedBox(height: 8),

                // Is Blacklisted toggle
                _toggleRow(
                  label: 'Blacklist Status',
                  value: _isBlacklisted == 'Y',
                  onColor: Colors.red,
                  onLabel: 'Blacklisted',
                  offLabel: 'Not Blacklisted',
                  onChanged: (v) =>
                      setState(() => _isBlacklisted = v ? 'Y' : 'N'),
                ),
              ]),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isEditMode
                              ? Icons.save_outlined
                              : Icons.add_circle_outline,
                        ),
                  label: Text(
                    _submitting
                        ? 'Saving...'
                        : _isEditMode
                        ? 'Save Changes'
                        : 'Register Vehicle',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode
                        ? Colors.blue.shade700
                        : const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form card wrapper ──────────────────────────────────────
  Widget _formCard(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  // ── Text field ─────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : const Color(0xFFF8F9FF),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      ),
    );
  }

  // ── Dropdown field ─────────────────────────────────────────
  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
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
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      items: items
          .map(
            (i) =>
                DropdownMenuItem(value: i, child: Text(i.replaceAll('_', ' '))),
          )
          .toList(),
    );
  }

  // ── Toggle row ─────────────────────────────────────────────
  Widget _toggleRow({
    required String label,
    required bool value,
    required Color onColor,
    required String onLabel,
    required String offLabel,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                value ? onLabel : offLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value ? onColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: onColor),
      ],
    );
  }
}
