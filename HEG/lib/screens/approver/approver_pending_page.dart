import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/pass_registry_api.dart';
import '../../models/pass_registry_item.dart';
import '../pass_entry/pass_entry_page.dart';

class ApproverPendingPage extends StatefulWidget {
  const ApproverPendingPage({super.key});

  @override
  State<ApproverPendingPage> createState() => _ApproverPendingPageState();
}

class _ApproverPendingPageState extends State<ApproverPendingPage>
    with SingleTickerProviderStateMixin {
  final PassRegistryApi api = PassRegistryApi();
  final TextEditingController searchController = TextEditingController();

  List<PassRegistryItem> allPasses = [];
  List<PassRegistryItem> pendingPasses = [];

  bool loading = true;
  bool hasError = false;
  String errorMessage = '';

  Timer? pollTimer;
  DateTime? lastUpdated;

  String searchText = '';

  int currentPage = 1;
  int pageSize = 10;

  static const Duration pollInterval = Duration(seconds: 30);

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

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
    loadPasses();
    startPolling();
  }

  @override
  void dispose() {
    _animController.dispose();
    pollTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(pollInterval, (_) {
      if (!mounted) return;
      loadPasses(silent: true);
    });
  }

  Future<void> loadPasses({bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
        hasError = false;
        errorMessage = '';
      });
    }

    try {
      final rows = await api.fetchPassRegistry();
      if (!mounted) return;
      setState(() {
        allPasses = rows;
        pendingPasses = rows.where((row) {
          final status = row.status.trim().toUpperCase();
          return status == 'SUBMITTED' || status == 'CONFIRMED';
        }).toList();
        lastUpdated = DateTime.now();
        applyFilters();
      });
      _animController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          hasError = true;
          errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted && !silent) {
        setState(() => loading = false);
      }
    }
  }

  void applyFilters() {
    pendingPasses = allPasses.where((row) {
      final status = row.status.trim().toUpperCase();
      final isPending = status == 'SUBMITTED' || status == 'CONFIRMED';
      if (!isPending) return false;
      return row.matchesSearch(searchText);
    }).toList();

    final totalPagesLocal = (pendingPasses.length / pageSize).ceil();

    if (totalPagesLocal <= 0) {
      currentPage = 1;
    } else {
      if (currentPage < 1) currentPage = 1;
      if (currentPage > totalPagesLocal) currentPage = totalPagesLocal;
    }
  }

  List<PassRegistryItem> get pagedPasses {
    if (pendingPasses.isEmpty) return [];

    final totalPagesLocal = (pendingPasses.length / pageSize).ceil();
    final safePage = currentPage < 1
        ? 1
        : (currentPage > totalPagesLocal ? totalPagesLocal : currentPage);

    final start = (safePage - 1) * pageSize;
    var end = start + pageSize;
    if (start >= pendingPasses.length) return [];
    if (end > pendingPasses.length) end = pendingPasses.length;

    return pendingPasses.sublist(start, end);
  }

  int get totalPages {
    final total = (pendingPasses.length / pageSize).ceil();
    return total == 0 ? 1 : total;
  }

  void onSearch(String value) {
    setState(() {
      searchText = value;
      currentPage = 1;
      applyFilters();
    });
  }

  void changePage(int page) {
    if (page < 1 || page > totalPages) return;
    HapticFeedback.selectionClick();
    setState(() => currentPage = page);
  }

  void reviewPass(PassRegistryItem row) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassEntryPage(
        registryId: row.passId,
        isViewMode: false,
        isApproverMode: true,
      ),
    );
    await loadPasses(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF070D1B),
      appBar: AppBar(
        title: const Text(
          'Pending Approvals',
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
            onPressed: () => loadPasses(),
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

          // Ambient Amber/Gold Priority Glow
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
                    const Color(0xFFFBBF24).withValues(alpha: 0.14),
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
                      color: Color(0xFFFBBF24),
                      strokeWidth: 2.5,
                    ),
                  )
                : hasError
                    ? ErrorView(message: errorMessage, onRetry: () => loadPasses())
                    : RefreshIndicator(
                        color: const Color(0xFFFBBF24),
                        backgroundColor: const Color(0xFF0F1E36),
                        onRefresh: () => loadPasses(),
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
                              if (pagedPasses.isEmpty)
                                const EmptyState()
                              else
                                ...pagedPasses.map(_buildPassCard),
                              const SizedBox(height: 16),
                              _buildPaginationPanel(),
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
    final lastUpdatedText = lastUpdated == null
        ? '-'
        : '${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}';

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
          color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
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
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFFFBBF24),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Approver Queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Passes awaiting your immediate review & sign-off',
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
                  'Pending Passes',
                  pendingPasses.length.toString(),
                  const Color(0xFFFDE68A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryStat(
                  'Current Page',
                  '$currentPage of $totalPages',
                  const Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Auto-refreshed at: $lastUpdatedText',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
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
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFFFBBF24),
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
                    onSearch('');
                  },
                )
              : null,
          hintText: 'Search pending pass #, vehicle, employee...',
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
              color: Color(0xFFFBBF24),
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassCard(PassRegistryItem row) {
    const badgeColor = Color(0xFFFBBF24); // amber for pending

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.08),
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
                            _topMeta('Pass #', row.passNo.isEmpty ? '-' : row.passNo),
                            _topMeta('Gate', row.gateNo.isEmpty ? '-' : row.gateNo),
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
                      row.status.isEmpty ? 'PENDING' : row.status,
                      style: const TextStyle(
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

              _dataLine('Employee', row.name),
              _dataLine('EC No', row.employeeNo),
              _dataLine('Emp Type', row.empType),
              _dataLine('Department', row.deptName),
              if (row.contractorName.isNotEmpty)
                _dataLine('Contractor', row.contractorName),

              const SizedBox(height: 14),

              // Action button to review pass
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => reviewPass(row),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text(
                    'Review & Act on Pass',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            width: 100,
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

  Widget _buildPaginationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: currentPage > 1 ? () => changePage(currentPage - 1) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white24,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 12),
            label: const Text('Prev'),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: currentPage < totalPages ? () => changePage(currentPage + 1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

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
                'Failed to load pending queue',
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
                label: const Text('Retry'),
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
          const Icon(
            Icons.task_alt_rounded,
            size: 44,
            color: Color(0xFF34D399),
          ),
          const SizedBox(height: 12),
          const Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No pending passes awaiting approver review at this moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
