// lib/screens/vpms/vehicles/vehicles_list_page.dart

import 'package:flutter/material.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/vpms_service.dart';
import 'vehicle_detail_page.dart';
import 'vehicle_form_page.dart'; // ← new file for Add/Edit form

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _all = await _service.getVehicles();
      _applyFilters();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
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

  // ── DELETE with confirm dialog ─────────────────────────────
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

    // Show loading
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
      _load(); // refresh list
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

  // ── Navigate to Add form (POST) ────────────────────────────
  Future<void> _openAddForm() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VehicleFormPage()),
    );
    if (added == true) _load(); // refresh if something was added
  }

  // ── Navigate to Edit form (PUT) ────────────────────────────
  Future<void> _openEditForm(VehicleModel v) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VehicleFormPage(vehicle: v)),
    );
    if (edited == true) _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Text(
          'Vehicles  (${_all.length})',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),

      // ── FAB = Add Vehicle (POST) ───────────────────────────
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
// Vehicle Card — with Edit + Delete action buttons
// ══════════════════════════════════════════════════════════════
class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final Color classColor;
  final IconData classIcon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.classColor,
    required this.classIcon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
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
          // ── Main info row (tap → detail) ─────────────
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Icon
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
                  // Info
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
                            // Class badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: classColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: classColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                vehicle.vehicleClass.replaceAll('_', ' '),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: classColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
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

          // ── Action buttons row (Edit | Delete) ───────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Edit button (PUT)
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
                // Divider
                Container(width: 1, height: 32, color: Colors.grey.shade100),
                // Delete button (DELETE)
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

  String _typeAndBrand() {
    final type = vehicle.vehicleType.isNotEmpty ? vehicle.vehicleType : null;
    final brand = vehicle.brandModel?.isNotEmpty == true
        ? vehicle.brandModel
        : null;
    if (type != null && brand != null) return '$type  •  $brand';
    return type ?? brand ?? '—';
  }
}

// ── Chip row, ErrorView, EmptyView (same as before) ───────────
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
  Widget build(BuildContext context) {
    return Row(
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
}

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
