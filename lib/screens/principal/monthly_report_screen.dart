import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../utils/app_theme.dart';

/// Fix 7 — Month-wise PDF report for Bonafide, Character, Transfer, Exam Form, Scholarship
/// Filters by: report type + month + year + (optional) studentId
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _db = FirebaseFirestore.instance;

  // Filter state
  String _reportType = 'bonafide';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final _studentIdCtrl = TextEditingController();

  bool _loading = false;
  bool _generating = false;
  List<Map<String, dynamic>> _results = [];

  // Report type definitions
  static const _types = {
    'bonafide': _ReportDef('Bonafide', 'bonafide_requests', 'createdAt'),
    'character': _ReportDef('Character Certificate', 'character_cert_requests', 'createdAt'),
    'transfer': _ReportDef('Transfer Certificate', 'tc_requests', 'createdAt'),
    'exam_form': _ReportDef('Exam Form', 'exam_forms', 'createdAt'),
    'scholarship': _ReportDef('Scholarship', 'scholarship_requests', 'createdAt'),
  };

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<int> get _years {
    final now = DateTime.now().year;
    return List.generate(5, (i) => now - i);
  }

  Future<void> _fetchReport() async {
    setState(() { _loading = true; _results = []; });
    try {
      final def = _types[_reportType]!;
      final start = DateTime(_selectedYear, _selectedMonth, 1);
      final end = DateTime(_selectedYear, _selectedMonth + 1, 1);

      Query q = _db.collection(def.collection)
          .where(def.dateField, isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where(def.dateField, isLessThan: Timestamp.fromDate(end));

      final studentId = _studentIdCtrl.text.trim();
      if (studentId.isNotEmpty) {
        q = q.where('erpId', isEqualTo: studentId);
      }

      final snap = await q.orderBy(def.dateField).get();
      setState(() {
        _results = snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          data['_id'] = d.id;
          return data;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePdf() async {
    if (_results.isEmpty) return;
    setState(() => _generating = true);
    try {
      final doc = pw.Document();
      final typeName = _types[_reportType]!.label;
      final monthYear = '${_months[_selectedMonth - 1]} $_selectedYear';
      final studentFilter = _studentIdCtrl.text.trim();
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

      // Determine columns per type
      final columns = _columnsFor(_reportType);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '$typeName — Monthly Report',
                    style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(monthYear,
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Text('Generated: $now',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  if (studentFilter.isNotEmpty) ...[
                    pw.SizedBox(width: 16),
                    pw.Text('Student ID: $studentFilter',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  ],
                  pw.SizedBox(width: 16),
                  pw.Text('Total Records: ${_results.length}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (ctx) => [
            pw.TableHelper.fromTextArray(
              headers: columns.map((c) => c.header).toList(),
              data: _results.map((row) =>
                columns.map((c) => c.extract(row)).toList()
              ).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                for (int i = 0; i < columns.length; i++)
                  i: pw.FlexColumnWidth(columns[i].flex),
              },
            ),
          ],
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Smart ERP — $typeName Report',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  List<_Col> _columnsFor(String type) {
    switch (type) {
      case 'bonafide':
        return [
          _Col('#', 0.4, (r) => ((_results.indexOf(r)) + 1).toString()),
          _Col('Student ID', 1.2, (r) => r['erpId'] ?? '—'),
          _Col('Name', 1.4, (r) => r['studentName'] ?? '—'),
          _Col('Branch', 1.2, (r) => r['branch'] ?? '—'),
          _Col('Sem', 0.6, (r) => r['semester'] ?? '—'),
          _Col('Purpose', 1.4, (r) => r['purpose'] ?? '—'),
          _Col('Status', 0.9, (r) => _capitalize(r['status'] ?? '')),
          _Col('Date', 1.0, (r) => _fmtDate(r['createdAt'])),
        ];
      case 'character':
        return [
          _Col('#', 0.4, (r) => ((_results.indexOf(r)) + 1).toString()),
          _Col('Student ID', 1.2, (r) => r['erpId'] ?? '—'),
          _Col('Name', 1.4, (r) => r['studentName'] ?? '—'),
          _Col('Branch', 1.2, (r) => r['branch'] ?? '—'),
          _Col('Sem', 0.6, (r) => r['semester'] ?? '—'),
          _Col('Conduct', 0.9, (r) => r['conductRemark'] ?? '—'),
          _Col('Status', 0.9, (r) => _capitalize(r['status'] ?? '')),
          _Col('Date', 1.0, (r) => _fmtDate(r['createdAt'])),
        ];
      case 'transfer':
        return [
          _Col('#', 0.4, (r) => ((_results.indexOf(r)) + 1).toString()),
          _Col('Student ID', 1.2, (r) => r['erpId'] ?? '—'),
          _Col('Name', 1.4, (r) => r['studentName'] ?? '—'),
          _Col('Branch', 1.2, (r) => r['branch'] ?? '—'),
          _Col('Year', 0.6, (r) => r['year'] ?? '—'),
          _Col('Sem', 0.6, (r) => r['semester'] ?? '—'),
          _Col('Status', 0.9, (r) => _capitalize(r['status'] ?? '')),
          _Col('Approved', 1.0, (r) => r['approvedDate'] ?? '—'),
        ];
      case 'exam_form':
        return [
          _Col('#', 0.4, (r) => ((_results.indexOf(r)) + 1).toString()),
          _Col('Student ID', 1.2, (r) => r['erpId'] ?? '—'),
          _Col('Branch', 1.1, (r) => r['branch'] ?? '—'),
          _Col('Sem', 0.7, (r) => r['semester'] ?? '—'),
          _Col('Exam Month', 1.0, (r) => '${r['examMonth'] ?? ''} ${r['examYear'] ?? ''}'),
          _Col('Subjects', 1.4, (r) {
            final subs = r['subjects'];
            if (subs is List) return subs.join(', ');
            return '—';
          }),
          _Col('Status', 0.9, (r) => _capitalize(r['status'] ?? '')),
          _Col('Date', 0.9, (r) => _fmtDate(r['createdAt'])),
        ];
      case 'scholarship':
      default:
        return [
          _Col('#', 0.4, (r) => ((_results.indexOf(r)) + 1).toString()),
          _Col('Student ID', 1.2, (r) => r['erpId'] ?? '—'),
          _Col('Name', 1.2, (r) => r['studentName'] ?? '—'),
          _Col('Scholarship', 1.4, (r) => r['scholarshipName'] ?? '—'),
          _Col('Type', 0.9, (r) => r['scholarshipType'] ?? '—'),
          _Col('Category', 0.9, (r) => r['casteCategory'] ?? '—'),
          _Col('Status', 0.9, (r) => _capitalize(r['status'] ?? '')),
          _Col('Date', 0.9, (r) => _fmtDate(r['createdAt'])),
        ];
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '—';
    try {
      DateTime dt;
      if (v is Timestamp) {
        dt = v.toDate();
      } else {
        dt = DateTime.parse(v.toString());
      }
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return v.toString().substring(0, 10);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '—';
    return s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  Color _statusColor(String s) {
    if (s.contains('approved')) return AppTheme.success;
    if (s.contains('reject')) return AppTheme.error;
    if (s.contains('pending')) return AppTheme.warning;
    return Colors.grey;
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeName = _types[_reportType]!.label;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        backgroundColor: const Color(0xFF7C3AED),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: _generating
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF',
              onPressed: _generating ? null : _generatePdf,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filters ─────────────────────────────────────────
          Container(
            color: const Color(0xFF7C3AED).withOpacity(0.06),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report Type
                const Text('Report Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.entries.map((e) {
                      final active = _reportType == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value.label),
                          selected: active,
                          selectedColor: const Color(0xFF7C3AED),
                          labelStyle: TextStyle(
                            color: active ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _reportType = e.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Month
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(_months[i], style: const TextStyle(fontSize: 13)),
                        )),
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Year
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: _years.map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Student ID filter (optional)
                TextFormField(
                  controller: _studentIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student ID (optional)',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                    isDense: true,
                    hintText: 'e.g. 2025BTLT001',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: Text(_loading ? 'Fetching...' : 'Fetch Report'),
                    onPressed: _loading ? null : _fetchReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Results ─────────────────────────────────────────
          if (_results.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text(
                    '$typeName — ${_months[_selectedMonth - 1]} $_selectedYear',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_results.length} records',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.summarize_outlined,
                                size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Select filters and tap "Fetch Report"',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final r = _results[i];
                          final status = r['status'] ?? '';
                          final erpId = r['erpId'] ?? '—';
                          final name = r['studentName'] ?? r['name'] ?? '—';
                          final date = _fmtDate(r['createdAt']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '$erpId  —  $name',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${r['branch'] ?? ''}  ${r['semester'] ?? ''}  •  $date',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _capitalize(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _results.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _generating ? null : _generatePdf,
              backgroundColor: const Color(0xFF7C3AED),
              icon: _generating
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_generating ? 'Generating...' : 'Export PDF'),
            )
          : null,
    );
  }
}

class _ReportDef {
  final String label;
  final String collection;
  final String dateField;
  const _ReportDef(this.label, this.collection, this.dateField);
}

class _Col {
  final String header;
  final double flex;
  final String Function(Map<String, dynamic>) extract;
  const _Col(this.header, this.flex, this.extract);
}
