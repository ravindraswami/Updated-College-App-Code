import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/user_model.dart';
import '../../models/character_cert_model.dart';
import '../../utils/app_theme.dart';

class CharacterCertificateScreen extends StatelessWidget {
  final CharacterCertModel cert;
  final UserModel student;

  const CharacterCertificateScreen({
    super.key,
    required this.cert,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Certificate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadCertificate(context),
            tooltip: 'Download Certificate',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Certificate Header
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: AppTheme.success,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CERTIFICATE OF CHARACTER',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 2, width: 100, color: AppTheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Certificate Details
            Card(
              elevation: 0,
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CertificateField(
                      label: 'Student Name',
                      value: cert.studentName,
                    ),
                    const SizedBox(height: 16),
                    _CertificateField(label: 'ERP ID', value: cert.erpId),
                    const SizedBox(height: 16),
                    _CertificateField(
                      label: 'Branch / Year / Semester',
                      value: '${cert.branch} / ${cert.year} / ${cert.semester}',
                    ),
                    const SizedBox(height: 16),
                    _CertificateField(label: 'Roll Number', value: cert.rollNo),
                    const SizedBox(height: 16),
                    _CertificateField(label: 'Date of Birth', value: cert.dob),
                    const SizedBox(height: 16),
                    _CertificateField(
                      label: 'Conduct Remark',
                      value: cert.conductRemark,
                    ),
                    const SizedBox(height: 16),
                    _CertificateField(label: 'Purpose', value: cert.purpose),
                    const SizedBox(height: 16),
                    _CertificateField(
                      label: 'Approved Date',
                      value: cert.approvedDate.isNotEmpty
                          ? cert.approvedDate.substring(0, 10)
                          : 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  border: Border.all(color: AppTheme.success),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      color: AppTheme.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Certificate Approved',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Download Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Certificate as PDF'),
                onPressed: () => _downloadCertificate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share Certificate'),
                onPressed: () => _shareCertificate(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();
    final name = student.nameAsPerHsc.isNotEmpty
        ? student.nameAsPerHsc
        : student.name;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'CERTIFICATE OF CHARACTER',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(width: 100, height: 2, color: PdfColors.teal),
            pw.SizedBox(height: 20),
            pw.Text(
              'This is to certify that ${name}, S/o D/o ${student.fatherOrHusbandName.isNotEmpty ? student.fatherOrHusbandName : "—"}, '
              'bearing ERP ID ${cert.erpId}, was a bonafide student of this college, '
              'studying in ${cert.branch} — ${cert.year} — ${cert.semester}. '
              'The student\'s conduct and character during the period of study has been found to be "${cert.conductRemark}".',
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(160),
                1: const pw.FlexColumnWidth(),
              },
              children:
                  [
                    ['Student Name', name],
                    ['ERP / Roll No.', cert.erpId],
                    ['Branch', cert.branch],
                    ['Year / Semester', '${cert.year} — ${cert.semester}'],
                    ['Conduct / Character', cert.conductRemark],
                    [
                      'Date of Issue',
                      cert.approvedDate.isNotEmpty
                          ? cert.approvedDate.substring(0, 10)
                          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    ],
                  ].map((row) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            row[0],
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            row[1].isNotEmpty ? row[1] : '—',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
            pw.SizedBox(height: 50),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 100, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Student Signature',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Principal / Authorized Signatory',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.Text(
              'Generated via Smart ERP • ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );
    return doc;
  }

  Future<void> _downloadCertificate(BuildContext context) async {
    try {
      final doc = await _buildPdf();
      final bytes = await doc.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareCertificate(BuildContext context) async {
    try {
      final doc = await _buildPdf();
      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Character_Certificate_${cert.erpId}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

class _CertificateField extends StatelessWidget {
  final String label;
  final String value;

  const _CertificateField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
