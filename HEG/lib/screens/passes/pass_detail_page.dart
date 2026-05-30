// lib/screens/vpms/passes/pass_detail_page.dart

import 'package:flutter/material.dart';
import '../../../models/pass_model.dart';

class PassDetailPage extends StatelessWidget {
  final PassModel pass;
  const PassDetailPage({super.key, required this.pass});

  @override
  Widget build(BuildContext context) {
    final isActive = pass.isActive == 'Y';
    final color = isActive ? const Color(0xFF2E7D32) : Colors.grey;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Pass #${pass.passId ?? '—'}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, color: color, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pass #${pass.passId ?? '—'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        isActive ? 'ACTIVE PASS' : 'INACTIVE PASS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card('Employee Info', [
              _row('Employee No', pass.employeeNo ?? '—'),
              _row('Emp Type', pass.empType ?? '—'),
              _row('Company No', pass.employeeCompanyNo ?? '—'),
              _row('Department', pass.dept ?? '—'),
              _row('Contractor', pass.contractorCode ?? '—'),
              _row('Mobile', pass.mobileNo ?? '—'),
            ]),
            const SizedBox(height: 12),
            _card('Vehicle & Gate Info', [
              _row('Vehicle No', pass.vehicleNo ?? '—'),
              _row('Vehicle Type', pass.typeOfVehicle ?? '—'),
              _row('Gate No', pass.gateNo ?? '—'),
              _row('Parking Area', pass.parkingToBeUsed ?? '—'),
            ]),
            const SizedBox(height: 12),
            _card('Pass Dates & Status', [
              _row('Issue Date', pass.issueDate),
              _row('Valid Till', pass.validityDate ?? '—'),
              _row('Status', pass.status ?? '—'),
              _row('Is Active', pass.isActive == 'Y' ? 'Yes' : 'No'),
              _row('Remarks', pass.remarks ?? '—'),
            ]),
            const SizedBox(height: 12),
            _card('Audit Info', [
              _row('Entered By', pass.enterBy ?? '—'),
              _row('Entered Date', pass.enterDate ?? '—'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> rows) => Container(
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const Divider(height: 14),
        ...rows,
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
