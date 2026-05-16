import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  void _downloadCertificate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificate download initiated...'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 3),
      ),
    );
    // TODO: Implement PDF generation and download
  }

  void _shareCertificate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon...'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 3),
      ),
    );
    // TODO: Implement sharing functionality
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
