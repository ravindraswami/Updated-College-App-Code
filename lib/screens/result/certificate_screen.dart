import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../models/result_model.dart';
import '../../models/exam_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class CertificateScreen extends StatefulWidget {
  final ResultModel result;
  final ExamModel exam;
  final UserModel student;
  const CertificateScreen({
    super.key,
    required this.result,
    required this.exam,
    required this.student,
  });
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final GlobalKey _certKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadCertificate() async {
    setState(() => _isDownloading = true);
    try {
      // Capture the certificate widget as image
      final boundary =
          _certKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (!mounted) return;
      // Show share/save bottom sheet
      _showSaveOptions(pngBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSaveOptions(Uint8List bytes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Certificate Ready!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your certificate has been generated. Use the options below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share, color: AppTheme.primary),
              ),
              title: const Text('Share Certificate'),
              subtitle: const Text('Share as PNG image via any app'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'To save: take a screenshot of the certificate or use flutter_share package.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${bytes.length ~/ 1024} KB PNG generated successfully.\nScreenshot the certificate to save it.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grade = _grade(widget.result.percentage);
    final date = DateFormat('MMMM dd, yyyy').format(widget.result.timestamp);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Certificate'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadCertificate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
              ),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Certificate widget ──
            RepaintBoundary(
              key: _certKey,
              child: _CertificateCard(
                studentName: widget.student.name,
                erpId: widget.student.erpId,
                department: widget.student.department,
                examTitle: widget.exam.title,
                subject: widget.exam.subject,
                score: widget.result.score,
                totalQuestions: widget.result.totalQuestions,
                percentage: widget.result.percentage,
                grade: grade,
                date: date,
              ),
            ),
            const SizedBox(height: 24),

            // ── Download button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadCertificate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.success,
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isDownloading ? 'Generating...' : '⬇  Download Certificate',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _grade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    return 'F';
  }
}

class _CertificateCard extends StatelessWidget {
  final String studentName, erpId, department;
  final String examTitle, subject;
  final int score, totalQuestions;
  final double percentage;
  final String grade, date;

  const _CertificateCard({
    required this.studentName,
    required this.erpId,
    required this.department,
    required this.examTitle,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.grade,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8860B), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top gold banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB8860B),
                  Color(0xFFFFD700),
                  Color(0xFFB8860B),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: const Column(
              children: [
                Icon(Icons.school, color: Colors.white, size: 40),
                SizedBox(height: 6),
                Text(
                  'SMART ERP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Certificate body ──
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Text(
                  'CERTIFICATE OF ACHIEVEMENT',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This is to certify that',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Student name
                Text(
                  studentName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (erpId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ERP ID: $erpId',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                const Text(
                  'has successfully completed',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Exam name
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    examTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Score row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _scoreItem(
                        'Score',
                        '$score/$totalQuestions',
                        AppTheme.primary,
                      ),
                      _vDivider(),
                      _scoreItem(
                        'Percentage',
                        '${percentage.toStringAsFixed(1)}%',
                        AppTheme.success,
                      ),
                      _vDivider(),
                      _scoreItem('Grade', grade, _gradeColor(percentage)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Department
                if (department.isNotEmpty)
                  Text(
                    'Department: $department',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Date: $date',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Seal
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFB8860B),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Color(0xFFB8860B),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Bottom gold strip ──
          Container(
            width: double.infinity,
            height: 12,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB8860B),
                  Color(0xFFFFD700),
                  Color(0xFFB8860B),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ],
  );

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: Colors.grey[300]);

  Color _gradeColor(double pct) {
    if (pct >= 80) return AppTheme.success;
    if (pct >= 60) return AppTheme.primary;
    if (pct >= 50) return AppTheme.warning;
    return AppTheme.error;
  }
}
