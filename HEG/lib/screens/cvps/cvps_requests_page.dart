/// CVPS Vehicle Permission list screen.
/// Mirrors vehicle-permission-list.ts and uses same Pass Registry UI style.
import 'package:flutter/material.dart';

import '../../widgets/heg_app_bar.dart';
import '../../data/cvps_api.dart';
import '../../models/cvps_request_item.dart';

class CvpsRequestsPage extends StatefulWidget {
  const CvpsRequestsPage({super.key});

  @override
  State<CvpsRequestsPage> createState() => _CvpsRequestsPageState();
}

class _CvpsRequestsPageState extends State<CvpsRequestsPage> {
  // API client to call CVPS backend.
  final CvpsApi api = CvpsApi();

  // Search text controller.
  final TextEditingController searchController = TextEditingController();

  // All rows from API.
  List<CvpsRequestItem> allRows = [];

  // Filtered rows after search/status filter.
  List<CvpsRequestItem> filteredRows = [];

  bool loading = true;
  bool hasError = false;
  String errorMessage = '';

  // Filter state: search string and status.
  String searchText = '';
  String statusFilter = 'ALL';

  // Same gradient colors and panel style as Pass Registry.
  static const Color bg1 = Color(0xFF0B1E3A);
  static const Color bg2 = Color(0xFF0EA5A4);

  static const Color panelBg = Colors.white;
  static const Color panelBorder = Color(0xFFD9E2EC);
  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF627D98);
  static const Color accentTeal = Color(0xFF0EA5A4);
  static const Color accentDark = Color(0xFF0B1E3A);

  // Status filter options (same as web statusOptions).
  final List<String> statusOptions = const [
    'ALL',
    'SAVED',
    'CREATED',
    'CONFIRMED',
    'APPROVED',
    'REJECTED',
    'HOLD',
    'MODIFY',
    'SUBMITTED',
  ];

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Loads all CVPS requests from backend and applies filters.
  Future<void> _loadRows() async {
    setState(() {
      loading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final rows = await api.fetchAllRequests();
      setState(() {
        allRows = rows;
        _applyFilters();
        loading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  /// Applies search + status filters to allRows to produce filteredRows.
  /// Mirrors filteredRows computed() in vehicle-permission-list.ts.
  void _applyFilters() {
    final search = searchText.trim().toLowerCase();
    final statusUpper = statusFilter.trim().toUpperCase();

    filteredRows = allRows.where((row) {
      final rowStatus = row.reqStatus.trim().toUpperCase();

      // Status match: ALL or exact status.
      final matchesStatus = statusUpper == 'ALL' || rowStatus == statusUpper;

      // Search match: requestNo, contractorCode, vehicleNo, vehicleType,
      // natureOfJob, createdBy.
      final matchesSearch =
          search.isEmpty ||
          row.requestNo.toString().contains(search) ||
          row.contractorCode.toLowerCase().contains(search) ||
          row.vehicleNo.toLowerCase().contains(search) ||
          row.vehicleType.toLowerCase().contains(search) ||
          row.natureOfJob.toLowerCase().contains(search) ||
          row.createdBy.toLowerCase().contains(search);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  /// Called when search text changes.
  void _onSearchChange(String value) {
    setState(() {
      searchText = value;
      _applyFilters();
    });
  }

  /// Called when status dropdown changes.
  void _onStatusChange(String? value) {
    if (value == null) return;
    setState(() {
      statusFilter = value;
      _applyFilters();
    });
  }

  /// Returns human-readable label for a status, same as getStatusLabel(status).
  String _getStatusLabel(String status) {
    final normalized = status.trim().toUpperCase();
    switch (normalized) {
      case 'CREATED':
      case 'SUBMITTED':
        return 'Submitted';
      case 'SAVED':
        return 'Saved';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'HOLD':
        return 'Hold';
      case 'MODIFY':
        return 'MODIFY';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  /// Returns a color for status badge, similar to getStatusClass/status colors.
  Color _getStatusColor(String status) {
    final normalized = status.trim().toUpperCase();
    switch (normalized) {
      case 'SUBMITTED':
      case 'CREATED':
        return const Color(0xFF2563EB); // blue
      case 'CONFIRMED':
        return const Color(0xFF0891B2); // teal
      case 'APPROVED':
        return const Color(0xFF16A34A); // green
      case 'REJECTED':
        return const Color(0xFFDC2626); // red
      case 'HOLD':
      case 'MODIFY':
        return const Color(0xFFF59E0B); // amber
      case 'SAVED':
        return const Color(0xFF6B7280); // gray
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// When user taps View button on a row.
  /// This should open a full CVPS form screen in view mode.
  /// For now, we navigate to '/cvpsForm' with requestNo as argument.
  void _viewRequest(CvpsRequestItem row) {
    Navigator.pushNamed(
      context,
      '/cvpsForm', // you will define this route in main.dart
      arguments: row.requestNo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HegAppBar(title: 'Permission Requests'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : hasError
            ? ErrorView(message: errorMessage, onRetry: _loadRows)
            : RefreshIndicator(
                color: accentTeal,
                onRefresh: _loadRows,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  children: [
                    _buildSummaryPanel(),
                    const SizedBox(height: 10),
                    _buildControlPanel(),
                    const SizedBox(height: 12),
                    if (filteredRows.isEmpty)
                      const EmptyState()
                    else
                      ...filteredRows.map(_buildRequestCard),
                  ],
                ),
              ),
      ),
    );
  }

  /// Summary at top: shows total & filtered counts.
  Widget _buildSummaryPanel() {
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
            'Vehicle Permission Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contractor vehicle permissions with search and filters',
            style: TextStyle(
              color: Colors.white.withAlpha(185),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryStat('Total', allRows.length.toString())),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryStat('Filtered', filteredRows.length.toString()),
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

  /// Search + status filter panel, same style as Pass Registry.
  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
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
            controller: searchController,
            onChanged: _onSearchChange,
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: textSecondary,
              ),
              hintText: 'Search request no, contractor, vehicle, status...',
              hintStyle: const TextStyle(fontSize: 13, color: textSecondary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentTeal, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: statusOptions.contains(statusFilter) ? statusFilter : 'ALL',
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Status',
              labelStyle: const TextStyle(
                color: textSecondary,
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
                borderSide: const BorderSide(color: panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentTeal, width: 1.2),
              ),
            ),
            items: statusOptions
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _onStatusChange,
          ),
        ],
      ),
    );
  }

  /// Builds a single CVPS request card, same card style as Pass Registry.
  /// Includes a View button that opens the form screen.
  Widget _buildRequestCard(CvpsRequestItem row) {
    final badgeColor = _getStatusColor(row.reqStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelBorder),
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
                // Status stripe
                Container(
                  width: 5,
                  height: 56,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                // Vehicle + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.vehicleNo.isEmpty ? '-' : row.vehicleNo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _topMeta('Req No', row.requestNo.toString()),
                          _topMeta(
                            'Contractor',
                            row.contractorCode.isEmpty
                                ? '-'
                                : row.contractorCode,
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
                // Status badge
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
                    _getStatusLabel(row.reqStatus),
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
            const Divider(height: 1, color: panelBorder),
            const SizedBox(height: 12),
            _dataLine('Nature of Job', row.natureOfJob),
            _dataLine('Permission To', row.permissionTo),
            _dataLine('Created By', row.createdBy),
            _dataLine('Created Date', row.createdDate),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statBox('Personnel', row.personnelCount.toString()),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statBox(
                    'Documents',
                    row.vehicleDocumentCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons (for now only View)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  foreground: accentDark,
                  background: const Color(0xFFEAF2FF),
                  onTap: () => _viewRequest(row),
                ),
                // Later you can add Edit/Delete/Pass buttons here.
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
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: textPrimary,
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: textPrimary,
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
}

/// Simple error view (reuse style from Pass Registry).
class ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

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
                'Failed to load CVPS requests',
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
                onPressed: () => onRetry(),
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

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

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
            'No permission requests found',
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
