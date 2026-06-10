// lib/screens/passes/passes_list_page.dart

import 'package:flutter/material.dart';
import '../../models/pass_model.dart';
import '../../services/vpms_service.dart';
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
    'Expiring',
    'Surrendered',
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

  // ── Status helpers ───────────────────────────────────────
  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'active' => const Color(0xFF1B5E20),
    'expired' => const Color(0xFFB71C1C),
    'surrendered' => const Color(0xFF4A148C),
    'expiring' => const Color(0xFFF57F17),
    _ => Colors.grey.shade600,
  };

  Color _statusBg(String s) => switch (s.toLowerCase()) {
    'active' => const Color(0xFFE8F5E9),
    'expired' => const Color(0xFFFFEBEE),
    'suspended' => const Color(0xFFFFF3E0),
    'pending' => const Color(0xFFE3F2FD),
    _ => Colors.grey.shade100,
  };

  String _fmt(String d) {
    if (d.isEmpty) return '—';
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_filtered.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
            tooltip: 'Refresh',
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
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = _filtered[i];
                        return _PassCard(
                          pass: p,
                          statusColor: _statusColor(p.status),
                          statusBg: _statusBg(p.status),
                          formatDate: _fmt,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search emp code, contractor, dept, mobile...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Colors.grey.shade500,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1A237E),
                  width: 1.8,
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
          const SizedBox(height: 7),
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

// ═══════════════════════════════════════════════════════════════
// PASS CARD
// ═══════════════════════════════════════════════════════════════
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
        : const Color(0xFF0D47A1);
    final empTypeBg = isContractor
        ? const Color(0xFFF3E5F5)
        : const Color(0xFFE3F2FD);
    final empTypeLabel = isContractor ? 'Contractor' : 'Employee';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Tap area ───────────────────────────────────────
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left icon block ────────────────────────
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: empTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      isContractor ? Icons.badge : Icons.person,
                      color: empTypeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Main info ──────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Pass ID + badges + arrow
                        Row(
                          children: [
                            // Pass ID
                            Text(
                              'Pass ${pass.passId ?? '—'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Emp Type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: empTypeBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: empTypeColor.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                empTypeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: empTypeColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                pass.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: Name (big + bold)
                        Text(
                          pass.displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A237E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Row 3: Dept + Vehicle type
                        _InfoRow(
                          icon: Icons.business_outlined,
                          text: pass.dept ?? '—',
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.directions_car_outlined,
                          text: pass.typeOfVehicle ?? '—',
                        ),
                        const SizedBox(height: 4),

                        // Row 4: Gate + Date range
                        Row(
                          children: [
                            _InfoRow(
                              icon: Icons.sensor_door_outlined,
                              text: pass.gateNo,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _InfoRow(
                                icon: Icons.date_range_outlined,
                                text:
                                    '${formatDate(pass.issueDate)}  →  ${formatDate(pass.validityDate)}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Action buttons ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 17,
                    color: Colors.teal.shade600,
                  ),
                  label: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade100),
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: Colors.blue.shade700,
                  ),
                  label: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small info row helper ────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1A237E).withOpacity(0.45)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF37474F),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ── Chip Row ──────────────────────────────────────────────────────
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
          width: 50,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((o) {
                final sel = selected == o;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelect(o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1A237E)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF1A237E)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        o.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Colors.grey.shade700,
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

// ── Error View ────────────────────────────────────────────────────
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 46,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Could not connect to server',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(
              'Retry',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Empty View ────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.badge_outlined,
            size: 52,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No passes found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF37474F),
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
