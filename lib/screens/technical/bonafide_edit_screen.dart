import 'package:flutter/material.dart';
import '../../models/bonafide_model.dart';
import '../../services/bonafide_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/certificate_widgets.dart' as cert;
import '../shared/certificate_preview_screen.dart';

/// Education Section: full edit form for a Bonafide Certificate request.
/// Every field can be corrected here before the certificate image is
/// generated — mirrors TcEditScreen / CharacterCertEditScreen.
class BonafideEditScreen extends StatefulWidget {
  final BonafideModel bonafide;
  const BonafideEditScreen({super.key, required this.bonafide});

  @override
  State<BonafideEditScreen> createState() => _BonafideEditScreenState();
}

class _BonafideEditScreenState extends State<BonafideEditScreen> {
  final _svc = BonafideService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final b = widget.bonafide;
    _c = {
      'studentName': TextEditingController(text: b.studentName),
      'erpId': TextEditingController(text: b.erpId),
      'branch': TextEditingController(text: b.branch),
      'year': TextEditingController(text: b.year),
      'semester': TextEditingController(text: b.semester),
      'rollNo': TextEditingController(text: b.rollNo),
      'purpose': TextEditingController(text: b.purpose),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  BonafideModel _buildUpdatedModel() {
    final b = widget.bonafide;
    return BonafideModel(
      id: b.id,
      studentId: b.studentId,
      studentName: _c['studentName']!.text.trim(),
      erpId: _c['erpId']!.text.trim(),
      branch: _c['branch']!.text.trim(),
      year: _c['year']!.text.trim(),
      semester: _c['semester']!.text.trim(),
      rollNo: _c['rollNo']!.text.trim(),
      purpose: _c['purpose']!.text.trim(),
      applyDate: b.applyDate,
      status: b.status,
      isPaid: b.isPaid,
      paymentId: b.paymentId,
      paymentDate: b.paymentDate,
      paymentScreenshotUrl: b.paymentScreenshotUrl,
      charges: b.charges,
      approvedBy: b.approvedBy,
      approvedDate: b.approvedDate,
      pdfUrl: b.pdfUrl,
      createdAt: b.createdAt,
    );
  }

  Future<void> _save({bool andGenerate = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = _buildUpdatedModel();
      await _svc.updateBonafide(updated);
      if (!mounted) return;
      if (andGenerate) {
        await openCertificatePreview(
          context,
          title: 'Bonafide Certificate',
          fileName: 'Bonafide_${updated.studentName.replaceAll(' ', '_')}',
          certificate: cert.buildBonafideCertificate(updated),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(andGenerate ? 'Saved and certificate generated.' : 'Bonafide details saved.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => (key == 'studentName' && (v == null || v.trim().isEmpty))
            ? 'Required'
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bonafide Certificate'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Student Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _field('studentName', "Student's Full Name"),
              _field('erpId', 'ERP / Registration No.'),
              _field('rollNo', 'Roll No.'),
              _field('branch', 'Branch'),
              _field('year', 'Year'),
              _field('semester', 'Semester'),
              _field('purpose', 'Purpose', maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _save(andGenerate: false),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Only'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(andGenerate: true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.image_outlined),
                      label: const Text('Save & Generate'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
