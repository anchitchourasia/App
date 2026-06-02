// lib/screens/vpms/passes/passes_list_page.dart

import 'package:flutter/material.dart';
import '../../../models/pass_model.dart';
import '../../../services/vpms_service.dart';
import 'pass_detail_page.dart';
import 'pass_form_page.dart';

class PassesListPage extends StatefulWidget {
  const PassesListPage({super.key});
  @override
  State<PassesListPage> createState() => _PassesListPageState();
}

class _PassesListPageState extends State<PassesListPage> {
  final _service = VpmsService();

  List<PassModel> _all = [];
  List<PassModel> _filtered = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  String _filterStatus = 'All';
  String _filterEmpType = 'All';

  static const _statusOptions = [
    'All',
    'Active',
    'Expired',
    'Suspended',
    'Pending',
  ];
  static const _empTypeOptions = ['All', 'Company_Employee', 'Contractor'];

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
      _all = await _service.getPasses();
      _applyFilters();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _query.toLowerCase();
    _filtered = _all.where((p) {
      final matchSearch =
          q.isEmpty ||
          (p.employeeNo ?? '').toLowerCase().contains(q) ||
          (p.contractorCode ?? '').toLowerCase().contains(q) ||
          (p.dept ?? '').toLowerCase().contains(q) ||
          (p.mobileNo ?? '').toLowerCase().contains(q) ||
          '${p.passId}'.contains(q);
      final matchStatus = _filterStatus == 'All' || p.status == _filterStatus;
      final matchEmpType =
          _filterEmpType == 'All' || p.empType == _filterEmpType;
      return matchSearch && matchStatus && matchEmpType;
    }).toList();
    setState(() {});
  }

  Future<void> _openAddForm() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PassFormPage()),
    );
    if (added == true) _load();
  }

  Future<void> _openEditForm(PassModel p) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PassFormPage(pass: p)),
    );
    if (edited == true) _load();
  }

  // ── Status colors ───────────────────────────────────
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

  String _formatDate(String d) {
    if (d.isEmpty) return '—';
    final dt = DateTime.tryParse(d);
    if (dt == null) return d;
    const months = [
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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Pass Registry',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filtered.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
            onPressed: _load,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Issue Pass',
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
                        final p = _filtered[i];
                        return _PassCard(
                          pass: p,
                          statusColor: _statusColor(p.status),
                          statusBg: _statusBg(p.status),
                          formatDate: _formatDate,
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => PassDetailPage(
                                pass: p,
                                onEdit: () => _openEditForm(p),
                              ),
                            ),
                          ),
                          onEdit: () => _openEditForm(p),
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
              hintText: 'Search emp code, contractor, dept, mobile...',
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
            label: 'Status',
            options: _statusOptions,
            selected: _filterStatus,
            onSelect: (v) {
              _filterStatus = v;
              _applyFilters();
            },
          ),
          const SizedBox(height: 6),
          _ChipRow(
            label: 'Type',
            options: _empTypeOptions,
            selected: _filterEmpType,
            onSelect: (v) {
              _filterEmpType = v;
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Pass Card
// ══════════════════════════════════════════════════════
class _PassCard extends StatelessWidget {
  final PassModel pass;
  final Color statusColor;
  final Color statusBg;
  final String Function(String) formatDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _PassCard({
    required this.pass,
    required this.statusColor,
    required this.statusBg,
    required this.formatDate,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isContractor = pass.empType == 'Contractor';
    final empTypeColor = isContractor
        ? const Color(0xFF6A1B9A)
        : const Color(0xFF1565C0);
    final empTypeBg = isContractor
        ? const Color(0xFFF3E5F5)
        : const Color(0xFFE3F2FD);

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
          // ── Main card body ───────────────────────────
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Pass ID + Status + EmpType + Arrow
                  Row(
                    children: [
                      // Pass ID badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ' Pass ${pass.passId ?? '—'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Emp Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: empTypeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isContractor ? 'Contractor' : 'Employee',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: empTypeColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pass.status,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade400,
                        size: 13,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: Name / code
                  Row(
                    children: [
                      Icon(
                        isContractor
                            ? Icons.badge_outlined
                            : Icons.person_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pass.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 3: Dept + Vehicle
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pass.dept ?? '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.directions_car_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pass.typeOfVehicle ?? '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 4: Gate + Dates
                  Row(
                    children: [
                      Icon(
                        Icons.sensor_door_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pass.gateNo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${formatDate(pass.issueDate)} → ${formatDate(pass.validityDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Action button row ────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Colors.teal.shade700,
                    ),
                    label: Text(
                      'View',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
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
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
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
}

// ── Chip Row ─────────────────────────────────────────
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

// ── Error + Empty Views ──────────────────────────────
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
        Icon(Icons.badge_outlined, size: 60, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          'No passes found',
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
