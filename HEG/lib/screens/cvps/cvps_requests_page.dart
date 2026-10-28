/// CVPS Vehicle Permission list screen.
/// Modernized with executive dark theme, glassmorphic cards, and smooth micro-interactions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/cvps_api.dart';
import '../../data/gate_log_api.dart';
import '../../data/session_store.dart';
import '../../models/cvps_request_item.dart';

class CvpsRequestsPage extends StatefulWidget {
  const CvpsRequestsPage({super.key});

  @override
  State<CvpsRequestsPage> createState() => _CvpsRequestsPageState();
}

class _CvpsRequestsPageState extends State<CvpsRequestsPage>
    with SingleTickerProviderStateMixin {
  final CvpsApi api = CvpsApi();
  final TextEditingController searchController = TextEditingController();

  List<CvpsRequestItem> allRows = [];
  List<CvpsRequestItem> filteredRows = [];

  bool loading = true;
  bool hasError = false;
  String errorMessage = '';

  final Set<int> _gateActionLoading = <int>{};
  final Map<int, String> _lastGateActionByRequest = <int, String>{};

  String searchText = '';
  String statusFilter = 'ALL';

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _loadRows();
  }

  @override
  void dispose() {
    _animController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    setState(() {
      loading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final rows = await api.fetchAllRequests();

      if (!mounted) return;

      setState(() {
        allRows = rows;
        _applyFilters();
        loading = false;
      });

      _animController.forward(from: 0.0);
      await _loadGateActionsForApprovedRows(rows);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadGateActionsForApprovedRows(
    List<CvpsRequestItem> rows,
  ) async {
    final approvedRows = rows.where(
      (row) => row.reqStatus.trim().toUpperCase() == 'APPROVED',
    );

    for (final row in approvedRows) {
      try {
        final lastAction = await GateLogApi.getLatestAction(row.requestNo);

        if (!mounted) return;

        setState(() {
          if (lastAction == null) {
            _lastGateActionByRequest.remove(row.requestNo);
          } else {
            _lastGateActionByRequest[row.requestNo] = lastAction;
          }
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _lastGateActionByRequest[row.requestNo] = 'UNKNOWN';
        });
      }
    }
  }

  void _applyFilters() {
    final search = searchText.trim().toLowerCase();
    final statusUpper = statusFilter.trim().toUpperCase();

    filteredRows = allRows.where((row) {
      final rowStatus = row.reqStatus.trim().toUpperCase();

      final matchesStatus = statusUpper == 'ALL' || rowStatus == statusUpper;

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

  void _onSearchChange(String value) {
    setState(() {
      searchText = value;
      _applyFilters();
    });
  }

  void _onStatusChange(String? value) {
    if (value == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      statusFilter = value;
      _applyFilters();
    });
  }

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
        return 'Modify';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color _getStatusColor(String status) {
    final normalized = status.trim().toUpperCase();
    switch (normalized) {
      case 'SUBMITTED':
      case 'CREATED':
        return const Color(0xFF38BDF8); // sky
      case 'CONFIRMED':
        return const Color(0xFF06B6D4); // cyan
      case 'APPROVED':
        return const Color(0xFF34D399); // emerald
      case 'REJECTED':
        return const Color(0xFFF87171); // red
      case 'HOLD':
      case 'MODIFY':
        return const Color(0xFFFBBF24); // amber
      case 'SAVED':
        return const Color(0xFF94A3B8); // slate
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _viewRequest(CvpsRequestItem row) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/cvpsForm',
      arguments: row.requestNo,
    );
  }

  void _viewPass(CvpsRequestItem row) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/cvpsPass',
      arguments: row.requestNo,
    );
  }

  Future<void> _recordGateAction(CvpsRequestItem row, String action) async {
    final normalizedAction = action.trim().toUpperCase();

    if (normalizedAction != 'IN' && normalizedAction != 'OUT') {
      return;
    }

    if (row.reqStatus.trim().toUpperCase() != 'APPROVED') {
      return;
    }

    if (_gateActionLoading.contains(row.requestNo)) {
      return;
    }

    final enterBy = SessionStore.currentUser?.ec.trim() ?? '';

    if (enterBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFB91C1C),
          content: Text('Logged-in employee code is missing.'),
        ),
      );
      return;
    }

    setState(() {
      _gateActionLoading.add(row.requestNo);
    });

    try {
      await GateLogApi.saveAction(
        permissionNo: row.requestNo,
        action: normalizedAction,
        enterBy: enterBy,
      );

      if (!mounted) return;

      setState(() {
        _lastGateActionByRequest[row.requestNo] = normalizedAction;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: normalizedAction == 'IN'
              ? const Color(0xFF15803D)
              : const Color(0xFFB91C1C),
          content: Text(
            'Gate $normalizedAction recorded for Permission No. ${row.requestNo}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB91C1C),
          content: Text('Could not record Gate $normalizedAction: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gateActionLoading.remove(row.requestNo);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF070D1B),
      appBar: AppBar(
        title: const Text(
          'Permission Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        backgroundColor: const Color(0xFF070D1B).withValues(alpha: 0.75),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRows,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient Base
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF060B14),
                    Color(0xFF0B172B),
                    Color(0xFF0F264A),
                    Color(0xFF1E3A8A),
                  ],
                  stops: [0.0, 0.35, 0.7, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Ambient Glow
          Positioned(
            top: 40,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF34D399).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF60A5FA),
                      strokeWidth: 2.5,
                    ),
                  )
                : hasError
                    ? ErrorView(message: errorMessage, onRetry: _loadRows)
                    : RefreshIndicator(
                        color: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF0F1E36),
                        onRefresh: _loadRows,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                            children: [
                              _buildSummaryPanel(),
                              const SizedBox(height: 14),
                              _buildControlPanel(),
                              const SizedBox(height: 16),
                              if (filteredRows.isEmpty)
                                const EmptyState()
                              else
                                ...filteredRows.map(_buildRequestCard),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.7),
            const Color(0xFF0F1E36).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Permission System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Contractor permission records & gate movements',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  label: 'Total Requests',
                  value: allRows.length.toString(),
                  icon: Icons.folder_open_rounded,
                  accentColor: const Color(0xFF93C5FD),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryStat(
                  label: 'Filtered Result',
                  value: filteredRows.length.toString(),
                  icon: Icons.filter_alt_outlined,
                  accentColor: const Color(0xFFA7F3D0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: searchController,
            onChanged: _onSearchChange,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFF60A5FA),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
              suffixIcon: searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white60),
                      onPressed: () {
                        searchController.clear();
                        _onSearchChange('');
                      },
                    )
                  : null,
              hintText: 'Search request #, contractor, vehicle, nature...',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF60A5FA),
                  width: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Status Filter Dropdown
          DropdownButtonFormField<String>(
            initialValue: statusOptions.contains(statusFilter) ? statusFilter : 'ALL',
            isExpanded: true,
            dropdownColor: const Color(0xFF0F1E36),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Filter by Status',
              labelStyle: TextStyle(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF60A5FA),
                  width: 1.4,
                ),
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

  Widget _buildRequestCard(CvpsRequestItem row) {
    final badgeColor = _getStatusColor(row.reqStatus);
    final isApproved = row.reqStatus.trim().toUpperCase() == 'APPROVED';
    final isGateActionLoading = _gateActionLoading.contains(row.requestNo);

    final lastGateAction = _lastGateActionByRequest[row.requestNo];
    final showInButton = lastGateAction == null || lastGateAction == 'OUT';
    final showOutButton = lastGateAction == 'IN';
    final gateStateUnavailable = lastGateAction == 'UNKNOWN';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Header & Status Chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4.5,
                    height: 52,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.vehicleNo.isEmpty ? 'NO NUMBER' : row.vehicleNo,
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            _topMeta('Req #', row.requestNo.toString()),
                            _topMeta(
                              'Contractor',
                              row.contractorCode.isEmpty ? '-' : row.contractorCode,
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
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.4),
                      ),
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

              const SizedBox(height: 14),
              const Divider(color: Color(0x22FFFFFF), height: 1),
              const SizedBox(height: 12),

              _dataLine('Nature of Job', row.natureOfJob),
              _dataLine('Permission To', row.permissionTo),
              _dataLine('Created By', row.createdBy),
              _dataLine('Created Date', row.createdDate),

              const SizedBox(height: 12),

              // Personnel & Document Counter Box
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      'Personnel',
                      row.personnelCount.toString(),
                      Icons.people_outline_rounded,
                      const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statBox(
                      'Documents',
                      row.vehicleDocumentCount.toString(),
                      Icons.description_outlined,
                      const Color(0xFFA78BFA),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _actionButton(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    foreground: const Color(0xFF93C5FD),
                    background: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    borderColor: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                    onTap: () => _viewRequest(row),
                  ),
                  if (isApproved)
                    _actionButton(
                      label: 'View Pass',
                      icon: Icons.picture_as_pdf_outlined,
                      foreground: const Color(0xFFA7F3D0),
                      background: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderColor: const Color(0xFF34D399).withValues(alpha: 0.4),
                      onTap: () => _viewPass(row),
                    ),
                  if (isApproved && !gateStateUnavailable && showInButton)
                    _actionButton(
                      label: isGateActionLoading ? 'Saving...' : 'Gate IN',
                      icon: isGateActionLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.login_rounded,
                      foreground: const Color(0xFF86EFAC),
                      background: const Color(0xFF15803D).withValues(alpha: 0.25),
                      borderColor: const Color(0xFF22C55E).withValues(alpha: 0.5),
                      onTap: isGateActionLoading
                          ? () {}
                          : () => _recordGateAction(row, 'IN'),
                    ),
                  if (isApproved && !gateStateUnavailable && showOutButton)
                    _actionButton(
                      label: isGateActionLoading ? 'Saving...' : 'Gate OUT',
                      icon: isGateActionLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.logout_rounded,
                      foreground: const Color(0xFFFCA5A5),
                      background: const Color(0xFFB91C1C).withValues(alpha: 0.25),
                      borderColor: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      onTap: isGateActionLoading
                          ? () {}
                          : () => _recordGateAction(row, 'OUT'),
                    ),
                ],
              ),

              if (isApproved && gateStateUnavailable) ...[
                const SizedBox(height: 10),
                _gateStateUnavailableStatus(),
              ] else if (isApproved && lastGateAction != null) ...[
                const SizedBox(height: 10),
                _localGateActionStatus(lastGateAction),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateStateUnavailableStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFB923C).withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFDBA74)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gate status could not be verified. Pull down to refresh.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFED7AA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _localGateActionStatus(String action) {
    final isIn = action == 'IN';
    final foreground = isIn ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5);
    final background = isIn
        ? const Color(0xFF065F46).withValues(alpha: 0.3)
        : const Color(0xFF991B1B).withValues(alpha: 0.3);
    final border = isIn
        ? const Color(0xFF34D399).withValues(alpha: 0.5)
        : const Color(0xFFEF4444).withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isIn ? Icons.login_rounded : Icons.logout_rounded,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Text(
            'Current Gate Status: $action',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          const Spacer(),
          Text(
            'Saved to Registry',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topMeta(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 11.5,
          color: Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
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
      ),
    );
  }
}

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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF87171),
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load CVPS requests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No permission requests found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try altering your search keywords or changing the status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
