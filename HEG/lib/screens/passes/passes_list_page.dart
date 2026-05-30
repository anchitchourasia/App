// lib/screens/vpms/passes/passes_list_page.dart

import 'package:flutter/material.dart';
import '../../../models/pass_model.dart';
import '../../../services/vpms_service.dart';
import 'pass_detail_page.dart';

class PassesListPage extends StatefulWidget {
  const PassesListPage({super.key});
  @override
  State<PassesListPage> createState() => _PassesListPageState();
}

class _PassesListPageState extends State<PassesListPage> {
  final VpmsService _service = VpmsService();
  List<PassModel> _all = [];
  List<PassModel> _filtered = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterEmpType = 'All';

  static const _statusOptions = ['All', 'Active', 'Inactive'];
  static const _empTypeOptions = ['All', 'Employee', 'Contractor'];

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
      final raw = await _service.getPasses();
      _all = raw.map((e) => PassModel.fromJson(e)).toList();
      _applyFilters();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    _filtered = _all.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          (p.employeeNo?.toLowerCase().contains(q) ?? false) ||
          (p.vehicleNo?.toLowerCase().contains(q) ?? false) ||
          (p.dept?.toLowerCase().contains(q) ?? false) ||
          (p.gateNo?.toLowerCase().contains(q) ?? false);

      final matchStatus =
          _filterStatus == 'All' ||
          (_filterStatus == 'Active' && p.isActive == 'Y') ||
          (_filterStatus == 'Inactive' && p.isActive == 'N');

      final matchEmpType =
          _filterEmpType == 'All' ||
          (p.empType?.toLowerCase() == _filterEmpType.toLowerCase());

      return matchSearch && matchStatus && matchEmpType;
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Pass Registry (${_filtered.length})'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search employee, vehicle, dept, gate...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                  ),
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      ..._statusOptions.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              s,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _filterStatus == s,
                            onSelected: (_) {
                              _filterStatus = s;
                              _applyFilters();
                            },
                            selectedColor: const Color(0xFF1A237E),
                            labelStyle: TextStyle(
                              color: _filterStatus == s
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Type: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      ..._empTypeOptions.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              t,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _filterEmpType == t,
                            onSelected: (_) {
                              _filterEmpType = t;
                              _applyFilters();
                            },
                            selectedColor: const Color(0xFF1A237E),
                            labelStyle: TextStyle(
                              color: _filterEmpType == t
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No passes found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = _filtered[i];
                        final isActive = p.isActive == 'Y';
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => PassDetailPage(pass: p),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(
                                            0xFF2E7D32,
                                          ).withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.badge_outlined,
                                    color: isActive
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pass #${p.passId ?? '—'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Emp: ${p.employeeNo ?? '—'}  •  ${p.empType ?? '—'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Vehicle: ${p.vehicleNo ?? '—'}  •  Gate: ${p.gateNo ?? '—'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Issue: ${p.issueDate}  |  Valid: ${p.validityDate ?? '—'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    _badge(
                                      isActive ? 'ACTIVE' : 'INACTIVE',
                                      isActive
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
    ),
  );
}
