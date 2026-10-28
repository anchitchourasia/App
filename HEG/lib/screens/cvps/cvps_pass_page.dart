import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/cvps_api.dart';
import '../../models/cvps_document.dart';
import '../../models/cvps_driver.dart';
import '../../models/cvps_history_entry.dart';
import '../../models/cvps_request_item.dart';
import '../../services/cvps_pass_pdf_service.dart';

class _RemarkStyle {
  final Color fillColor;
  final Color textColor;
  final Color borderColor;

  const _RemarkStyle({
    required this.fillColor,
    required this.textColor,
    required this.borderColor,
  });
}

class CvpsPassPage extends StatefulWidget {
  final int requestNo;

  const CvpsPassPage({super.key, required this.requestNo});

  @override
  State<CvpsPassPage> createState() => _CvpsPassPageState();
}

class _CvpsPassPageState extends State<CvpsPassPage>
    with SingleTickerProviderStateMixin {
  final CvpsApi api = CvpsApi();
  final CvpsPassPdfService _passPdfService = CvpsPassPdfService();

  bool loading = true;
  String? error;

  CvpsRequestItem? _request;
  String _contractorName = '';
  List<CvpsDocument> _vehicleDocs = [];
  List<CvpsDriver> _drivers = [];
  List<CvpsHistoryEntry> _history = [];

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
    _loadPass();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadPass() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final detail = await api.fetchRequestDetail(widget.requestNo);

      final historyEntries = await api.fetchRequestHistoryEntries(
        widget.requestNo,
      );

      final enrichedHistory = <CvpsHistoryEntry>[];
      for (final h in historyEntries) {
        var byName = h.byName;

        if (byName.isEmpty &&
            h.byEmpCode.trim().isNotEmpty &&
            h.byEmpCode.toUpperCase() != 'SYSTEM') {
          final name = await api.fetchEmployeeName(h.byEmpCode);
          if (name != null) {
            byName = name;
          }
        }

        enrichedHistory.add(
          CvpsHistoryEntry(
            id: h.id,
            stage: h.stage,
            action: h.action,
            remark: h.remark,
            byName: byName,
            byEmpCode: h.byEmpCode,
            statusAfter: h.statusAfter,
            createdAt: h.createdAt,
          ),
        );
      }

      setState(() {
        _request = detail.request;
        _contractorName = detail.contractorName;
        _vehicleDocs = detail.vehicleDocuments;
        _drivers = detail.drivers;
        _history = enrichedHistory;
        loading = false;
      });
      _animController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _downloadPass() async {
    if (_request == null) return;
    HapticFeedback.mediumImpact();
    try {
      await _passPdfService.generateAndOpenPassPdf(
        request: _request!,
        vehicleDocuments: _vehicleDocs,
        drivers: _drivers,
        history: _history,
        contractorName: _contractorName,
        formNo: 'W-OHS-SECURITY-12',
        requestNo: _request!.requestNo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Failed to generate pass: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF070D1B),
      appBar: AppBar(
        title: const Text(
          'Vehicle Permission Pass',
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
          if (_request != null)
            IconButton(
              tooltip: 'Download Pass PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _downloadPass,
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
                    const Color(0xFF38BDF8).withValues(alpha: 0.12),
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
                : error != null
                    ? _buildErrorView()
                    : _request == null
                        ? _buildEmptyView()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildPassView(),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
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
              Text(
                error ?? 'Unable to load pass details.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
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

  Widget _buildEmptyView() {
    return const Center(
      child: Text(
        'No pass data found.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPassView() {
    final req = _request!;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _buildHeaderCard(req),
        const SizedBox(height: 14),
        _buildGeneralSection(req),
        const SizedBox(height: 14),
        _buildVehicleSection(req),
        const SizedBox(height: 14),
        _buildDriverSection(),
        const SizedBox(height: 20),
        _buildActions(),
      ],
    );
  }

  Widget _buildHeaderCard(CvpsRequestItem req) {
    final statusColor = _getStatusColor(req.reqStatus);

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Color(0xFF38BDF8),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendors Vehicle / Contractor Permission',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'HEG LIMITED • MANDIDEEP COMPLEX',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  req.reqStatus.trim().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'W-OHS-SECURITY-12',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.trim().toUpperCase();
    switch (s) {
      case 'SUBMITTED':
      case 'CREATED':
        return const Color(0xFF38BDF8);
      case 'CONFIRMED':
        return const Color(0xFFFBBF24);
      case 'APPROVED':
        return const Color(0xFF34D399);
      case 'REJECTED':
        return const Color(0xFFF87171);
      case 'HOLD':
      case 'MODIFY':
        return const Color(0xFFF97316);
      case 'SAVED':
      case 'DRAFT':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Widget _buildGeneralSection(CvpsRequestItem req) {
    return _sectionCard(
      title: 'General Information',
      icon: Icons.info_outline_rounded,
      child: _grid2([
        _field('Permission No.', req.requestNo.toString()),
        _field('Contractor Code', req.contractorCode),
        _field('Contractor Name', _contractorName),
        _field('Request Date', _formatDateForUi(req.createdDate)),
        _field('Nature of Job', req.natureOfJob.isEmpty ? '-' : req.natureOfJob),
        _field('Permission Date To', _formatDateForUi(req.permissionTo)),
        _field('Approved Date', '-'),
        _field('Print Date', '-'),
      ]),
    );
  }

  Widget _buildVehicleSection(CvpsRequestItem req) {
    return _sectionCard(
      title: 'Vehicle Details',
      icon: Icons.directions_car_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grid2([
            _field('Vehicle No.', req.vehicleNo),
            _field('Vehicle Type', req.vehicleType),
          ]),
          const SizedBox(height: 14),
          if (_vehicleDocs.isNotEmpty)
            _vehicleDocsTable()
          else
            _emptyRow('No vehicle documents recorded in pass.'),
        ],
      ),
    );
  }

  Widget _vehicleDocsTable() {
    return Column(
      children: [
        for (var index = 0; index < _vehicleDocs.length; index++) ...[
          _vehicleDocumentCard(_vehicleDocs[index], index + 1),
          if (index != _vehicleDocs.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _vehicleDocumentCard(CvpsDocument document, int index) {
    final remarkText = _remarkText(document.validTill);
    final remarkStyle = _remarkStyle(document.validTill);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Vehicle Document',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _remarkChip(remarkText, remarkStyle),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(
            'Document Type',
            document.documentType.isEmpty ? '-' : document.documentType,
          ),
          const SizedBox(height: 6),
          _detailRow(
            'Document Number',
            document.documentNo.isEmpty ? '-' : document.documentNo,
          ),
          const SizedBox(height: 6),
          _detailRow(
            'Valid Upto',
            document.validTill.isEmpty
                ? '-'
                : _formatDateForUi(document.validTill),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection() {
    return _sectionCard(
      title: 'Driver / Conductor Details',
      icon: Icons.people_outline_rounded,
      child: _drivers.isNotEmpty
          ? _driversTable()
          : _emptyRow('No employee personnel recorded.'),
    );
  }

  Widget _driversTable() {
    return Column(
      children: [
        for (var index = 0; index < _drivers.length; index++) ...[
          _driverCard(_drivers[index], index + 1),
          if (index != _drivers.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _driverCard(CvpsDriver driver, int index) {
    final remarkText = _remarkText(driver.licenseValidTill);
    final remarkStyle = _remarkStyle(driver.licenseValidTill);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  driver.name.isEmpty ? 'Driver / Conductor' : driver.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _remarkChip(remarkText, remarkStyle),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Role', driver.role.isEmpty ? '-' : driver.role),
          const SizedBox(height: 6),
          _detailRow(
            'Contact Number',
            driver.mobileNo.isEmpty ? '-' : driver.mobileNo,
          ),
          const SizedBox(height: 6),
          _detailRow(
            'Aadhaar Number',
            driver.aadhaarNo.isEmpty ? '-' : driver.aadhaarNo,
          ),
          const SizedBox(height: 6),
          _detailRow(
            'License Number',
            driver.licenseNo.isEmpty ? '-' : driver.licenseNo,
          ),
          const SizedBox(height: 6),
          _detailRow(
            'License Valid Upto',
            driver.licenseValidTill.isEmpty
                ? '-'
                : _formatDateForUi(driver.licenseValidTill),
          ),
          const SizedBox(height: 6),
          _detailRow(
            'Eye Test Date',
            driver.eyeTestDate.isEmpty
                ? '-'
                : _formatDateForUi(driver.eyeTestDate),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _downloadPass,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            elevation: 3,
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text(
            'Download Pass PDF',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _grid2(List<Widget> fields) {
    final rows = <Widget>[];

    for (int i = 0; i < fields.length; i += 2) {
      final hasRightField = i + 1 < fields.length;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fields[i]),
              const SizedBox(width: 12),
              Expanded(child: hasRightField ? fields[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayValue,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _remarkChip(String text, _RemarkStyle style) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.fillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: style.textColor,
        ),
      ),
    );
  }

  Widget _emptyRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  String _formatDateForUi(String value) {
    if (value.isEmpty) return '-';
    try {
      final raw = value.split('T').first;
      final parts = raw.split('-');
      if (parts.length != 3) return raw;
      final year = parts[0], month = parts[1], day = parts[2];
      return '$day-$month-$year';
    } catch (_) {
      return value;
    }
  }

  int? _daysDiff(String value) {
    if (value.isEmpty) return null;
    try {
      final target = DateTime.parse(value);
      final today = DateTime.now();
      final base = DateTime(today.year, today.month, today.day);
      return target.difference(base).inDays;
    } catch (_) {
      return null;
    }
  }

  String _remarkText(String value) {
    final diffDays = _daysDiff(value);
    if (diffDays == null) return '-';
    if (diffDays < 0) {
      final n = diffDays.abs();
      return 'Expired $n d ago';
    }
    if (diffDays == 0) return 'Expires today';
    if (diffDays <= 30) {
      return 'Expires in $diffDays d';
    }
    return 'Valid';
  }

  _RemarkStyle _remarkStyle(String value) {
    final diffDays = _daysDiff(value);
    if (diffDays == null) {
      return _RemarkStyle(
        fillColor: Colors.white.withValues(alpha: 0.08),
        textColor: Colors.white70,
        borderColor: Colors.white.withValues(alpha: 0.15),
      );
    }
    if (diffDays < 0) {
      return _RemarkStyle(
        fillColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
        textColor: const Color(0xFFFCA5A5),
        borderColor: const Color(0xFFEF4444).withValues(alpha: 0.5),
      );
    }
    if (diffDays == 0 || diffDays <= 30) {
      return _RemarkStyle(
        fillColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        textColor: const Color(0xFFFDE68A),
        borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
      );
    }
    return _RemarkStyle(
      fillColor: const Color(0xFF10B981).withValues(alpha: 0.2),
      textColor: const Color(0xFFA7F3D0),
      borderColor: const Color(0xFF10B981).withValues(alpha: 0.5),
    );
  }
}
