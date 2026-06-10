// lib/screens/passes/pass_detail_page.dart

import 'package:flutter/material.dart';
import '../../../models/pass_model.dart';

class PassDetailPage extends StatelessWidget {
  final PassModel pass;
  final String formattedPassId; // ✅ NEW — "PASS-HEG-0008"
  final VoidCallback onEdit;

  const PassDetailPage({
    super.key,
    required this.pass,
    required this.formattedPassId,
    required this.onEdit,
  });

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    const mo = [
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
    return '${dt.day.toString().padLeft(2, '0')} ${mo[dt.month - 1]} ${dt.year}';
  }

  // ✅ FIXED: expiring + surrendered colours (was suspended/pending)
  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'active' => const Color(0xFF2E7D32),
    'expiring' => const Color(0xFFF57F17), // amber
    'expired' => const Color(0xFFC62828),
    'surrendered' => const Color(0xFF37474F), // blueGrey
    _ => Colors.grey.shade600,
  };

  Color _statusBg(String s) => switch (s.toLowerCase()) {
    'active' => const Color(0xFFE8F5E9),
    'expiring' => const Color(0xFFFFF3E0),
    'expired' => const Color(0xFFFFEBEE),
    'surrendered' => const Color(0xFFECEFF1),
    _ => Colors.grey.shade100,
  };

  @override
  Widget build(BuildContext context) {
    final isContractor = pass.empType == 'Contractor';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        // ✅ CHANGED: AppBar shows PASS-HEG-XXXX (monospace)
        title: Text(
          formattedPassId,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontFamily: 'monospace',
          ),
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
            // ── Status header card ──────────────────────────────
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
                  // ✅ NEW: PASS-HEG-XXXX shown at top of header card
                  Text(
                    formattedPassId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                      letterSpacing: 1.0,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
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

            // ── Pass Info ───────────────────────────────────────
            _Section(
              title: 'Pass Info',
              icon: Icons.badge_outlined,
              rows: [
                // ✅ CHANGED: shows PASS-HEG-XXXX instead of raw number
                _Row('Pass ID', formattedPassId),
                _Row('Issue Date', _fmt(pass.issueDate)),
                _Row('Valid Till', _fmt(pass.validityDate)),
                _Row('Gate', pass.gateNo),
                _Row('Parking Area', pass.parkingToBeUsed ?? '—'),
              ],
            ),
            const SizedBox(height: 10),

            // ── Person Details ──────────────────────────────────
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

            // ── Vehicle Info ────────────────────────────────────
            _Section(
              title: 'Vehicle Info',
              icon: Icons.directions_car_outlined,
              rows: [
                _Row('Vehicle ID (FK)', '${pass.vehicleId ?? '—'}'),
                _Row('Type of Vehicle', pass.typeOfVehicle ?? '—'),
              ],
            ),
            const SizedBox(height: 10),

            // ── System Info ─────────────────────────────────────
            _Section(
              title: 'System Info',
              icon: Icons.info_outline,
              rows: [
                _Row('Status', pass.status),
                _Row('Is Active', pass.isActive == 'Y' ? 'Yes' : 'No'),
                _Row('Enter By', pass.enterBy ?? '—'),
                _Row('Enter Date', _fmt(pass.enterDate)),
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

// ── Section widget ────────────────────────────────────────────────
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
                      width: 140,
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
