// lib/screens/vpms/vehicles/vehicle_detail_page.dart

import 'package:flutter/material.dart';
import '../../../models/vehicle_model.dart';

class VehicleDetailPage extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleDetailPage({
    super.key,
    required this.vehicle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = vehicle.isBlacklistedVehicle
        ? const Color(0xFFC62828)
        : !vehicle.isActiveVehicle
        ? Colors.grey.shade600
        : const Color(0xFF2E7D32);
    final statusLabel = vehicle.isBlacklistedVehicle
        ? 'BLACKLISTED'
        : !vehicle.isActiveVehicle
        ? 'INACTIVE'
        : 'ACTIVE';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(
          vehicle.vehicleNo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car_filled,
                      color: statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleNo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DetailCard(
              title: 'Vehicle Information',
              rows: [
                if (vehicle.vehicleId != null)
                  _RowData('Vehicle ID', vehicle.vehicleId.toString()),
                _RowData('Vehicle No', vehicle.vehicleNo),
                _RowData('Vehicle Type', vehicle.vehicleType),
                _RowData(
                  'Vehicle Class',
                  vehicle.vehicleClass.replaceAll('_', ' '),
                ),
                _RowData(
                  'Brand / Model',
                  vehicle.brandModel?.isNotEmpty == true
                      ? vehicle.brandModel!
                      : '—',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailCard(
              title: 'Status Information',
              rows: [
                _RowData(
                  'Is Active',
                  vehicle.isActiveVehicle ? 'Yes' : 'No',
                  valueColor: vehicle.isActiveVehicle
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                ),
                _RowData(
                  'Is Blacklisted',
                  vehicle.isBlacklistedVehicle ? 'Yes' : 'No',
                  valueColor: vehicle.isBlacklistedVehicle
                      ? Colors.red
                      : const Color(0xFF2E7D32),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Bottom action bar: Edit + Delete ───────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Edit (PUT)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delete (DELETE)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<_RowData> rows;
  const _DetailCard({required this.title, required this.rows});
  @override
  Widget build(BuildContext context) => Container(
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
        const Divider(height: 16),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 115,
                  child: Text(
                    r.label,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: r.valueColor ?? Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RowData {
  final String label, value;
  final Color? valueColor;
  const _RowData(this.label, this.value, {this.valueColor});
}
