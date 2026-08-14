import 'package:flutter/material.dart';

import '../../widgets/heg_app_bar.dart';
import '../../data/cvps_api.dart';
import '../../models/cvps_request_item.dart';
import '../../models/cvps_document.dart';
import '../../models/cvps_driver.dart';
import '../../models/cvps_history_entry.dart';
import '../../services/cvps_pass_pdf_service.dart';

class _RemarkStyle {
  final Color fillColor;
  final Color textColor;

  const _RemarkStyle(this.fillColor, this.textColor);
}

class CvpsPassPage extends StatefulWidget {
  final int requestNo;

  const CvpsPassPage({super.key, required this.requestNo});

  @override
  State<CvpsPassPage> createState() => _CvpsPassPageState();
}

class _CvpsPassPageState extends State<CvpsPassPage> {
  final CvpsApi api = CvpsApi();
  final CvpsPassPdfService _passPdfService = CvpsPassPdfService();

  bool loading = true;
  String? error;

  CvpsRequestItem? _request;
  String _contractorName = '';
  List<CvpsDocument> _vehicleDocs = [];
  List<CvpsDriver> _drivers = [];
  List<CvpsHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPass();
  }

  Future<void> _loadPass() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 1) Load full detail (request + docs + drivers + contractorName)
      final detail = await api.fetchRequestDetail(widget.requestNo);

      // 2) Load raw history entries
      final historyEntries = await api.fetchRequestHistoryEntries(
        widget.requestNo,
      );

      // 3) Enrich history entries with employee names (like Angular resolveEmployeeName)
      final enrichedHistory = <CvpsHistoryEntry>[];
      for (final h in historyEntries) {
        var byName = h.byName;

        // Skip SYSTEM entries and empties
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
            stage: h.stage, // already inferred like Angular inferHistoryStage
            action: h.action,
            remark: h.remark,
            byName: byName, // now may contain resolved EMP name
            byEmpCode: h.byEmpCode,
            statusAfter: h.statusAfter,
            createdAt: h.createdAt,
          ),
        );
      }

      // 4) Set state for UI + PDF
      setState(() {
        _request = detail.request;
        _contractorName = detail.contractorName;
        _vehicleDocs = detail.vehicleDocuments;
        _drivers = detail.drivers;
        _history = enrichedHistory;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _downloadPass() async {
    if (_request == null) return;
    print('DEBUG: View CvpsPassPage _downloadPass for ${_request!.requestNo}');
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate pass: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Vehicle Permission Pass';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HegAppBar(title: title),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _buildErrorView()
          : _request == null
          ? _buildEmptyView()
          : _buildPassView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error ?? 'Unable to load pass details.',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text(
        'No pass data found.',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPassView() {
    final req = _request!;

    return Container(
      color: const Color(0xFFF1F5F9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHeaderCard(req),
          const SizedBox(height: 12),
          _buildGeneralSection(req),
          const SizedBox(height: 12),
          _buildVehicleSection(req),
          const SizedBox(height: 12),
          _buildDriverSection(),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  // ── Header card ─────────────────────────

  Widget _buildHeaderCard(CvpsRequestItem req) {
    final statusColor = _getStatusColor(req.reqStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Vendors Vehicle/Contractor Permission Form',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'HEG LIMITED, MANDIDEEP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status pill + form no
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  req.reqStatus.trim().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC4CFDB)),
                ),
                child: const Text(
                  'W-OHS-SECURITY-12',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
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
        return const Color(0xFF3B82F6);
      case 'CONFIRMED':
        return const Color(0xFFF59E0B);
      case 'APPROVED':
        return const Color(0xFF22C55E);
      case 'REJECTED':
        return const Color(0xFFEF4444);
      case 'HOLD':
      case 'MODIFY':
        return const Color(0xFFF97316);
      case 'SAVED':
      case 'DRAFT':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ── General Information section ─────────────────────────

  Widget _buildGeneralSection(CvpsRequestItem req) {
    return _sectionCard(
      title: 'General Information',
      child: Column(
        children: [
          _grid2([
            _field('Contractor Code', req.contractorCode),
            _field('Contractor Name', _contractorName),
            _field('Request Date', _formatDateForUi(req.createdDate)),
            _field(
              'Nature of Job',
              req.natureOfJob.isEmpty ? '-' : req.natureOfJob,
            ),
            _field('Permission Date To', _formatDateForUi(req.permissionTo)),
            _field('Approved Date', '-'),
            _field('Print Date', '-'),
          ]),
        ],
      ),
    );
  }

  // ── Vehicle section ─────────────────────────────────────

  Widget _buildVehicleSection(CvpsRequestItem req) {
    return _sectionCard(
      title: 'Vehicle Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grid2([
            _field('Vehicle No.', req.vehicleNo),
            _field('Vehicle Type', req.vehicleType),
          ]),
          const SizedBox(height: 12),
          if (_vehicleDocs.isNotEmpty)
            _vehicleDocsTable()
          else
            _emptyRow('No vehicle documents available.'),
        ],
      ),
    );
  }

  Widget _vehicleDocsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Vehicle Documents')),
          DataColumn(label: Text('Doc. Number')),
          DataColumn(label: Text('Valid Upto')),
          DataColumn(label: Text('Remark')),
        ],
        rows: _vehicleDocs.map((d) {
          final remarkText = _remarkText(d.validTill);
          final remarkStyle = _remarkStyle(d.validTill);
          return DataRow(
            cells: [
              DataCell(Text(d.documentType.isEmpty ? '-' : d.documentType)),
              DataCell(Text(d.documentNo.isEmpty ? '-' : d.documentNo)),
              DataCell(
                Text(d.validTill.isEmpty ? '-' : _formatDateForUi(d.validTill)),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: remarkStyle.fillColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    remarkText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: remarkStyle.textColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Driver section ──────────────────────────────────────

  Widget _buildDriverSection() {
    return _sectionCard(
      title: 'Driver / Conductor Details',
      child: _drivers.isNotEmpty
          ? _driversTable()
          : _emptyRow('No employee information available.'),
    );
  }

  Widget _driversTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Contact No.')),
          DataColumn(label: Text('Aadhar No.')),
          DataColumn(label: Text('License No.')),
          DataColumn(label: Text('Valid Upto')),
          DataColumn(label: Text('Remark')),
        ],
        rows: _drivers.map((d) {
          final remarkText = _remarkText(d.licenseValidTill);
          final remarkStyle = _remarkStyle(d.licenseValidTill);
          return DataRow(
            cells: [
              DataCell(Text(d.role.isEmpty ? '-' : d.role)),
              DataCell(Text(d.name.isEmpty ? '-' : d.name)),
              DataCell(Text(d.mobileNo.isEmpty ? '-' : d.mobileNo)),
              DataCell(Text(d.aadhaarNo.isEmpty ? '-' : d.aadhaarNo)),
              DataCell(Text(d.licenseNo.isEmpty ? '-' : d.licenseNo)),
              DataCell(
                Text(
                  d.licenseValidTill.isEmpty
                      ? '-'
                      : _formatDateForUi(d.licenseValidTill),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: remarkStyle.fillColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    remarkText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: remarkStyle.textColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Actions (Back + Download Pass) ──────────────────────

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _downloadPass,
          icon: const Icon(Icons.print),
          label: const Text('Download Pass'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── Section card + field helpers ────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
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
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
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
              const SizedBox(width: 16),
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),

        // Makes every value box exactly the full width of its grid column.
        SizedBox(
          width: double.infinity,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  // ── Date + remark helpers ───────────────────────────────

  String _formatDateForUi(String value) {
    if (value.isEmpty) return '-';
    try {
      final raw = value.split('T').first; // "YYYY-MM-DD"
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
      return 'Expired $n day${n == 1 ? '' : 's'} ago';
    }
    if (diffDays == 0) return 'Expires today';
    if (diffDays <= 30) {
      return 'Expires in $diffDays day${diffDays == 1 ? '' : 's'}';
    }
    return 'Valid';
  }

  _RemarkStyle _remarkStyle(String value) {
    final diffDays = _daysDiff(value);
    if (diffDays == null) {
      return _RemarkStyle(Colors.grey.shade100, Colors.grey.shade700);
    }
    if (diffDays < 0) {
      return _RemarkStyle(Colors.red.shade100, Colors.red.shade700);
    }
    if (diffDays == 0 || diffDays <= 30) {
      return _RemarkStyle(Colors.orange.shade100, Colors.orange.shade800);
    }
    return _RemarkStyle(Colors.green.shade100, Colors.green.shade700);
  }
}
