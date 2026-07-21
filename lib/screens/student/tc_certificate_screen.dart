import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/user_model.dart';
import '../../models/tc_model.dart';
import '../../utils/app_theme.dart';

class TcCertificateScreen extends StatefulWidget {
  final TcModel tc;
  final UserModel student;
  const TcCertificateScreen({
    super.key,
    required this.tc,
    required this.student,
  });
  @override
  State<TcCertificateScreen> createState() => _TcCertificateScreenState();
}

class _TcCertificateScreenState extends State<TcCertificateScreen> {
  final _repaintKey = GlobalKey();
  bool _saving = false;

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final tc = widget.tc;
    final student = widget.student;
    final name = student.nameAsPerHsc.isNotEmpty
        ? student.nameAsPerHsc
        : student.name;

    final rows = [
      ['Student Name', name],
      ['ERP / Roll No.', tc.erpId],
      ['Registration No.', tc.registerNo.isNotEmpty ? tc.registerNo : '—'],
      ['Branch', tc.branch],
      ['Year / Semester', '${tc.year} — ${tc.semester}'],
      ['Date of Birth', tc.dob],
      ["Mother's Name", tc.motherName],
      ['Religion', tc.religion],
      ['Caste / Category', '${tc.caste} (${tc.casteCategory})'],
      ['Date of Admission', tc.dateOfAdmission],
      ['Last Exam Passed', tc.lastExamPassed],
      ['Reason for Leaving', tc.reasonForLeaving],
      [
        'Date of Issue',
        tc.approvedDate.isNotEmpty
            ? tc.approvedDate.substring(0, 10)
            : DateFormat('dd/MM/yyyy').format(DateTime.now()),
      ],
    ];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'TRANSFER CERTIFICATE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'TC No: TC-${tc.id.substring(0, 8).toUpperCase()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 12),
            pw.Text(
              'This is to certify that the following student was a bonafide student of this institution and has been granted Transfer Certificate as per their request.',
              style: const pw.TextStyle(fontSize: 11),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(160),
                1: const pw.FlexColumnWidth(),
              },
              children: rows.map((row) {
                return pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    child: pw.Text(row[0],
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    child: pw.Text(
                        row[1].isNotEmpty ? row[1] : '—',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ]);
              }).toList(),
            ),
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(children: [
                  pw.Container(width: 100, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Student Signature',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey)),
                ]),
                pw.Column(children: [
                  pw.Container(width: 130, height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal / Authorized Signatory',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey)),
                ]),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated via Smart ERP • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<void> _printOrDownload() async {
    setState(() => _saving = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareAsPdf() async {
    setState(() => _saving = true);
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'TC_${widget.tc.erpId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Certificate'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else ...[
            IconButton(
              onPressed: _printOrDownload,
              icon: const Icon(Icons.print),
              tooltip: 'Print / Save PDF',
            ),
            IconButton(
              onPressed: _shareAsPdf,
              icon: const Icon(Icons.share),
              tooltip: 'Share as PDF',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _repaintKey,
          child: _TcDocument(tc: widget.tc, student: widget.student),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print / Download PDF'),
            onPressed: _saving ? null : _printOrDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _TcDocument extends StatelessWidget {
  final TcModel tc;
  final UserModel student;
  const _TcDocument({required this.tc, required this.student});

  @override
  Widget build(BuildContext context) {
    final name = student.nameAsPerHsc.isNotEmpty
        ? student.nameAsPerHsc
        : student.name;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: const Icon(Icons.school, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart ERP College',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Text(
                      'Maharashtra, India',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 2, color: AppTheme.primary),
          Container(height: 1, color: AppTheme.primary.withOpacity(0.3), margin: const EdgeInsets.only(top: 2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'TRANSFER CERTIFICATE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TC No: TC-${tc.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'This is to certify that the following student was a bonafide student of this institution and has been granted Transfer Certificate as per their request.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 16),
          _tcTable([
            ['Student Name', name],
            ['ERP / Roll No.', tc.erpId],
            ['Registration No.', tc.registerNo.isNotEmpty ? tc.registerNo : '—'],
            ['Branch', tc.branch],
            ['Year / Semester', '${tc.year} — ${tc.semester}'],
            ['Date of Birth', tc.dob],
            ["Mother's Name", tc.motherName],
            ['Religion', tc.religion],
            ['Caste / Category', '${tc.caste} (${tc.casteCategory})'],
            ['Date of Admission', tc.dateOfAdmission],
            ['Last Exam Passed', tc.lastExamPassed],
            ['Reason for Leaving', tc.reasonForLeaving],
            [
              'Date of Issue',
              tc.approvedDate.isNotEmpty
                  ? tc.approvedDate.substring(0, 10)
                  : DateFormat('dd/MM/yyyy').format(DateTime.now()),
            ],
          ]),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 100, height: 1, color: Colors.black),
                const SizedBox(height: 4),
                const Text('Student Signature',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 120, height: 1, color: Colors.black),
                const SizedBox(height: 4),
                const Text('Principal / Authorized Signatory',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Text(
            'Generated via Smart ERP • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _tcTable(List<List<String>> rows) {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!, width: 0.5),
      columnWidths: const {0: FixedColumnWidth(160), 1: FlexColumnWidth()},
      children: rows
          .map((row) => TableRow(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(row[0],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(row[1].isNotEmpty ? row[1] : '—',
                      style: const TextStyle(fontSize: 12)),
                ),
              ]))
          .toList(),
    );
  }
}
