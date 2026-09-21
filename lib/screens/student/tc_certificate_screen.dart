import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/tc_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/image_export.dart';

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

  Future<void> _saveImage() async {
    setState(() => _saving = true);
    try {
      final bytes = await ImageExportUtils.captureBoundary(_repaintKey);
      GalSaveResult result = const GalSaveResult(false, 'Could not render the image.');
      if (bytes != null) {
        result = await ImageExportUtils.saveToGallery(bytes, 'TC_${widget.tc.erpId}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Saved to "Smart ERP" album in your gallery.'
                  : (result.error ?? 'Could not save image.'),
            ),
            backgroundColor: result.success ? AppTheme.success : AppTheme.error,
            duration: Duration(seconds: result.success ? 3 : 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _saving = true);
    try {
      final bytes = await ImageExportUtils.captureBoundary(_repaintKey);
      if (bytes != null) {
        await ImageExportUtils.shareImage(
          bytes,
          'TC_${widget.tc.erpId}_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Transfer Certificate',
        );
      }
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
              onPressed: _saveImage,
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Save as Image',
            ),
            IconButton(
              onPressed: _shareImage,
              icon: const Icon(Icons.share),
              tooltip: 'Share as Image',
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
            icon: const Icon(Icons.download_rounded),
            label: const Text('Save Image'),
            onPressed: _saving ? null : _saveImage,
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
