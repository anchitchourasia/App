// lib/screens/vpms/passes/pass_detail_page.dart

import 'package:flutter/material.dart';
import '../../../models/pass_model.dart';

class PassDetailPage extends StatelessWidget {
  final PassModel pass;
  final VoidCallback onEdit;

  const PassDetailPage({super.key, required this.pass, required this.onEdit});

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    const m = [
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
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'active' => const Color(0xFF2E7D32),
    'expired' => const Color(0xFFC62828),
    'suspended' => const Color(0xFFE65100),
    'pending' => const Color(0xFF1565C0),
    _ => Colors.grey.shade600,
  };

  Color _statusBg(String s) => switch (s.toLowerCase()) {
    'active' => const Color(0xFFE8F5E9),
    'expired' => const Color(0xFFFFEBEE),
    'suspended' => const Color(0xFFFFF3E0),
    'pending' => const Color(0xFFE3F2FD),
    _ => Colors.grey.shade100,
  };

  @override
  Widget build(BuildContext context) {
    final isContractor = pass.empType == 'Contractor';
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(
          'Pass #${pass.passId ?? '—'}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status header ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg(pass.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pass.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(pass.status),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pass.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isContractor
                          ? const Color(0xFFF3E5F5)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isContractor ? 'Contractor' : 'Company Employee',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isContractor
                            ? const Color(0xFF6A1B9A)
                            : const Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Details sections ──────────────────────
            _Section(
              title: 'Pass Info',
              icon: Icons.badge_outlined,
              rows: [
                _Row('Pass ID', '${pass.passId ?? '—'}'),
                _Row('Issue Date', _fmt(pass.issueDate)),
                _Row('Valid Till', _fmt(pass.validityDate)),
                _Row('Gate', pass.gateNo),
                _Row('Parking Area', pass.parkingToBeUsed ?? '—'),
              ],
            ),
            const SizedBox(height: 10),
            _Section(
              title: isContractor ? 'Contractor Details' : 'Employee Details',
              icon: Icons.person_outline,
              rows: [
                if (!isContractor) ...[
                  _Row('Employee No', pass.employeeNo ?? '—'),
                  _Row('Company No', pass.employeeCompanyNo ?? '—'),
                ] else ...[
                  _Row('Contractor Code', pass.contractorCode ?? '—'),
                ],
                _Row('Department', pass.dept ?? '—'),
                _Row('Mobile No', pass.mobileNo ?? '—'),
              ],
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'Vehicle Info',
              icon: Icons.directions_car_outlined,
              rows: [
                _Row('Vehicle ID', '${pass.vehicleId ?? '—'}'),
                _Row('Vehicle Type', pass.typeOfVehicle ?? '—'),
              ],
            ),
            const SizedBox(height: 10),
            _Section(
              title: 'System Info',
              icon: Icons.info_outline,
              rows: [
                _Row('Enter By', pass.enterBy ?? '—'),
                _Row('Enter Date', _fmt(pass.enterDate)),
                _Row('Is Active', pass.isActive == 'Y' ? 'Yes' : 'No'),
                _Row(
                  'Remarks',
                  (pass.remarks?.isNotEmpty == true) ? pass.remarks! : '—',
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Row> rows;
  const _Section({required this.title, required this.icon, required this.rows});
  @override
  Widget build(BuildContext context) => Container(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
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
        ),
        ...rows.map(
          (r) => Column(
            children: [
              Divider(height: 1, color: Colors.grey.shade100),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}

class _Row {
  final String label, value;
  const _Row(this.label, this.value);
}
