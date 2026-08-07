import 'dart:async';
import 'package:flutter/material.dart';
import '../data/pass_registry_api.dart';
import '../models/pass_registry_item.dart';
import '../widgets/heg_app_bar.dart';

class VehicleTrackingPage extends StatefulWidget {
  const VehicleTrackingPage({super.key});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  final PassRegistryApi _api = PassRegistryApi();
  final TextEditingController _searchController = TextEditingController();

  List<PassRegistryItem> _allPasses = [];
  List<PassRegistryItem> _filteredPasses = [];

  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Timer? _pollTimer;
  DateTime? _lastUpdated;

  String _searchText = '';
  String _filterStatus = 'ALL';
  String _filterEmpType = 'ALL';
  String _filterVehicleType = 'ALL';

  int _currentPage = 1;
  int _pageSize = 10;

  static const Duration _pollInterval = Duration(seconds: 30);

  static const Color _bg1 = Color(0xFF0B1E3A);
  static const Color _bg2 = Color(0xFF0EA5A4);

  static const Color _pageBg = Color(0xFFF4F7FB);
  static const Color _panelBg = Colors.white;
  static const Color _panelBorder = Color(0xFFD9E2EC);
  static const Color _textPrimary = Color(0xFF102A43);
  static const Color _textSecondary = Color(0xFF627D98);
  static const Color _accentDark = Color(0xFF0B1E3A);
  static const Color _accentTeal = Color(0xFF0EA5A4);

  @override
  void initState() {
    super.initState();
    _loadPasses();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      _loadPasses(silent: true);
    });
  }

  Future<void> _loadPasses({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final rows = await _api.fetchPassRegistry();
      if (!mounted) return;

      setState(() {
        _allPasses = rows;
        _lastUpdated = DateTime.now();
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    _filteredPasses = _allPasses.where((row) {
      return row.matchesSearch(_searchText) &&
          row.matchesStatus(_filterStatus) &&
          row.matchesEmpType(_filterEmpType) &&
          row.matchesVehicleType(_filterVehicleType);
    }).toList();

    final total = totalPages;
    if (_currentPage > total) _currentPage = total;
  }

  List<String> get empTypeOptions {
    final set = <String>{'ALL'};
    for (final row in _allPasses) {
      final value = row.empType.trim().toUpperCase();
      if (value.isNotEmpty) set.add(value);
    }
    return set.toList();
  }

  List<String> get vehicleTypeOptions {
    final set = <String>{'ALL'};
    for (final row in _allPasses) {
      final value = row.vehicleType.trim().toUpperCase();
      if (value.isNotEmpty) set.add(value);
    }
    return set.toList();
  }

  List<String> get statusOptions => const [
    'ALL',
    'DRAFT',
    'SAVED',
    'SUBMITTED',
    'CONFIRMED',
    'ACTIVE',
    'NEEDS_MODIFICATION',
    'REJECT',
  ];

  int get totalPages {
    final total = (_filteredPasses.length / _pageSize).ceil();
    return total <= 0 ? 1 : total;
  }

  List<PassRegistryItem> get pagedPasses {
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    if (start >= _filteredPasses.length) return [];
    return _filteredPasses.sublist(
      start,
      end > _filteredPasses.length ? _filteredPasses.length : end,
    );
  }

  int get activeCount =>
      _allPasses.where((e) => e.status.trim().toUpperCase() == 'ACTIVE').length;

  int get draftCount => _allPasses.where((e) {
    final s = e.status.trim().toUpperCase();
    return s == 'DRAFT' || s == 'SAVED';
  }).length;

  int get rejectCount => _allPasses.where((e) {
    final s = e.status.trim().toUpperCase();
    return s == 'REJECT' || s == 'REJECTED' || s == 'REGRET';
  }).length;

  void _onSearch(String value) {
    setState(() {
      _searchText = value;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _onStatusChange(String? value) {
    if (value == null) return;
    setState(() {
      _filterStatus = value;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _onEmpTypeChange(String? value) {
    if (value == null) return;
    setState(() {
      _filterEmpType = value;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _onVehicleTypeChange(String? value) {
    if (value == null) return;
    setState(() {
      _filterVehicleType = value;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages) return;
    setState(() {
      _currentPage = page;
    });
  }

  String _formatDate(String date) {
    if (date.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(date);
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yyyy = dt.year.toString();
      return '$dd/$mm/$yyyy';
    } catch (_) {
      return date;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'SAVED':
      case 'DRAFT':
        return const Color(0xFF2563EB);
      case 'SUBMITTED':
        return const Color(0xFFD97706);
      case 'CONFIRMED':
        return const Color(0xFF0891B2);
      case 'ACTIVE':
      case 'APPROVED':
        return const Color(0xFF15803D);
      case 'NEEDS_MODIFICATION':
      case 'NEEDSMODIFICATION':
      case 'MODIFY':
        return const Color(0xFFB45309);
      case 'REJECT':
      case 'REJECTED':
      case 'REGRET':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _viewPass(PassRegistryItem row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PassDetailsSheet(
        row: row,
        formatDate: _formatDate,
        statusColor: _statusColor(row.status),
      ),
    );
  }

  void _printSticker(PassRegistryItem row) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Print sticker for: ${row.passNo}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HegAppBar(title: 'Pass Registry'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bg1, _bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _hasError
            ? _ErrorView(message: _errorMessage, onRetry: () => _loadPasses())
            : RefreshIndicator(
                color: _accentTeal,
                onRefresh: () => _loadPasses(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  children: [
                    _buildSummaryPanel(),
                    const SizedBox(height: 10),
                    _buildControlPanel(),
                    const SizedBox(height: 12),
                    if (pagedPasses.isEmpty)
                      const _EmptyState()
                    else
                      ...pagedPasses.map((row) => _buildPassCard(row)),
                    const SizedBox(height: 12),
                    _buildPaginationPanel(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryPanel() {
    final lastUpdatedText = _lastUpdated == null
        ? '-'
        : '${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Pass Registry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Read-only registry view with search and filters',
            style: TextStyle(
              color: Colors.white.withAlpha(185),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryStat('Total', _allPasses.length.toString()),
              ),
              const SizedBox(width: 8),
              Expanded(child: _summaryStat('Active', activeCount.toString())),
              const SizedBox(width: 8),
              Expanded(child: _summaryStat('Draft', draftCount.toString())),
              const SizedBox(width: 8),
              Expanded(child: _summaryStat('Reject', rejectCount.toString())),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Last updated: $lastUpdatedText',
                style: TextStyle(
                  color: Colors.white.withAlpha(190),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Page $_currentPage/$totalPages',
                style: TextStyle(
                  color: Colors.white.withAlpha(190),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(165),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: _textSecondary,
              ),
              hintText: 'Search pass no, vehicle no, employee, contractor',
              hintStyle: const TextStyle(fontSize: 13, color: _textSecondary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accentTeal, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Status',
                  _filterStatus,
                  statusOptions,
                  _onStatusChange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  'Emp Type',
                  _filterEmpType,
                  empTypeOptions,
                  _onEmpTypeChange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDropdown(
            'Vehicle Type',
            _filterVehicleType,
            vehicleTypeOptions,
            _onVehicleTypeChange,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentTeal, width: 1.2),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPassCard(PassRegistryItem row) {
    final badgeColor = _statusColor(row.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 56,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.vehicleNo.isEmpty ? '-' : row.vehicleNo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _topMeta(
                            'Pass',
                            row.passNo.isEmpty ? '-' : row.passNo,
                          ),
                          _topMeta(
                            'Gate',
                            row.gateNo.isEmpty ? '-' : row.gateNo,
                          ),
                          _topMeta(
                            'Type',
                            row.vehicleType.isEmpty ? '-' : row.vehicleType,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: badgeColor.withAlpha(40)),
                  ),
                  child: Text(
                    row.status.isEmpty ? 'UNKNOWN' : row.status,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _panelBorder),
            const SizedBox(height: 12),
            _dataLine('Employee', row.name),
            _dataLine('EC No', row.employeeNo),
            _dataLine('Emp Type', row.empType),
            _dataLine('Department', row.deptName),
            if (row.contractorName.isNotEmpty)
              _dataLine('Contractor', row.contractorName),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dateBox('Issue Date', _formatDate(row.issueDate)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateBox('Validity', _formatDate(row.validityDate)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  foreground: _accentDark,
                  background: const Color(0xFFEAF2FF),
                  onTap: () => _viewPass(row),
                ),
                _actionButton(
                  label: 'Sticker',
                  icon: Icons.print_outlined,
                  foreground: const Color(0xFF334155),
                  background: const Color(0xFFF1F5F9),
                  onTap: () => _printSticker(row),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _topMeta(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: _textSecondary,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color foreground,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: foreground.withAlpha(28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _panelBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Rows per page',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: [10, 20, 50].map((size) {
                  final selected = _pageSize == size;
                  return ChoiceChip(
                    label: Text(
                      '$size',
                      style: TextStyle(
                        color: selected ? Colors.white : _textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: selected,
                    selectedColor: _accentTeal,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: _panelBorder),
                    onSelected: (_) {
                      setState(() {
                        _pageSize = size;
                        _currentPage = 1;
                        _applyFilters();
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: _currentPage > 1
                    ? () => _changePage(_currentPage - 1)
                    : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _panelBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Prev'),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Page $_currentPage of $totalPages',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _currentPage < totalPages
                    ? () => _changePage(_currentPage + 1)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassDetailsSheet extends StatelessWidget {
  final PassRegistryItem row;
  final String Function(String) formatDate;
  final Color statusColor;

  const _PassDetailsSheet({
    required this.row,
    required this.formatDate,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBCCCDC),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pass Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF102A43),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1E3A), Color(0xFF0EA5A4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.vehicleNo.isEmpty ? '-' : row.vehicleNo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _detailChip('Pass No', row.passNo),
                          _detailChip('Gate', row.gateNo),
                          _detailChip('Type', row.vehicleType),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withAlpha(28)),
                        ),
                        child: Text(
                          row.status.isEmpty ? 'UNKNOWN' : row.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _detailSection(
                  title: 'Employee Information',
                  children: [
                    _detailRow('Employee Name', row.name),
                    _detailRow('Employee No', row.employeeNo),
                    _detailRow('Employee Type', row.empType),
                    _detailRow('Department Code', row.deptCode),
                    _detailRow('Department Name', row.deptName),
                  ],
                ),
                const SizedBox(height: 12),
                _detailSection(
                  title: 'Vehicle & Pass',
                  children: [
                    _detailRow('Pass ID', row.passId.toString()),
                    _detailRow('Pass No', row.passNo),
                    _detailRow('Vehicle No', row.vehicleNo),
                    _detailRow('Vehicle Type', row.vehicleType),
                    _detailRow('Gate No', row.gateNo),
                    _detailRow('Status', row.status),
                    _detailRow('Issue Date', formatDate(row.issueDate)),
                    _detailRow('Validity Date', formatDate(row.validityDate)),
                  ],
                ),
                const SizedBox(height: 12),
                _detailSection(
                  title: 'Contractor / Additional',
                  children: [
                    _detailRow('Contractor Code', row.contractorCode),
                    _detailRow('Contractor Name', row.contractorName),
                    _detailRow('Aadhaar / Mobile', row.aadhaarNo),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1E3A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _detailChip(String label, String value) {
    final safeValue = value.isEmpty ? '-' : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $safeValue',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF102A43),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final safeValue = value.trim().isEmpty ? '-' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF627D98),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              safeValue,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9E2EC)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load pass registry',
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF627D98),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1E3A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF9FB3C8)),
          SizedBox(height: 10),
          Text(
            'No pass records found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102A43),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing search text or filter values.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF627D98),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
