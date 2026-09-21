import 'package:flutter/material.dart';
import '../../models/character_cert_model.dart';
import '../../services/character_cert_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../utils/certificate_widgets.dart' as cert;
import '../shared/certificate_preview_screen.dart';

/// Education Section: full edit form for a Character Certificate request.
/// Every field can be corrected here before the certificate image is
/// generated — mirrors TcEditScreen / BonafideEditScreen.
class CharacterCertEditScreen extends StatefulWidget {
  final CharacterCertModel cert;
  const CharacterCertEditScreen({super.key, required this.cert});

  @override
  State<CharacterCertEditScreen> createState() => _CharacterCertEditScreenState();
}

class _CharacterCertEditScreenState extends State<CharacterCertEditScreen> {
  final _svc = CharacterCertService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final c = widget.cert;
    _c = {
      'studentName': TextEditingController(text: c.studentName),
      'erpId': TextEditingController(text: c.erpId),
      'branch': TextEditingController(text: c.branch),
      'year': TextEditingController(text: c.year),
      'semester': TextEditingController(text: c.semester),
      'rollNo': TextEditingController(text: c.rollNo),
      'dob': TextEditingController(text: c.dob),
      'conductRemark': TextEditingController(text: c.conductRemark),
      'purpose': TextEditingController(text: c.purpose),
      'academicYear': TextEditingController(
        text: c.academicYear.isNotEmpty
            ? c.academicYear
            : AcademicData.defaultAcademicYearFor(admissionDate: '', yearId: c.year),
      ),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  CharacterCertModel _buildUpdatedModel() {
    final c = widget.cert;
    return CharacterCertModel(
      id: c.id,
      studentId: c.studentId,
      studentName: _c['studentName']!.text.trim(),
      erpId: _c['erpId']!.text.trim(),
      branch: _c['branch']!.text.trim(),
      year: _c['year']!.text.trim(),
      semester: _c['semester']!.text.trim(),
      rollNo: _c['rollNo']!.text.trim(),
      dob: _c['dob']!.text.trim(),
      conductRemark: _c['conductRemark']!.text.trim(),
      purpose: _c['purpose']!.text.trim(),
      status: c.status,
      isPaid: c.isPaid,
      charges: c.charges,
      paymentId: c.paymentId,
      approvedBy: c.approvedBy,
      approvedDate: c.approvedDate,
      createdAt: c.createdAt,
      academicYear: _c['academicYear']!.text.trim(),
    );
  }

  Future<void> _save({bool andGenerate = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = _buildUpdatedModel();
      await _svc.updateCert(updated);
      if (!mounted) return;
      if (andGenerate) {
        await openCertificatePreview(
          context,
          title: 'Character Certificate',
          fileName: 'CharacterCert_${updated.studentName.replaceAll(' ', '_')}',
          certificate: cert.buildCharacterCertCertificate(updated),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(andGenerate ? 'Saved and certificate generated.' : 'Character certificate details saved.'),
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
        title: const Text('Edit Character Certificate'),
        backgroundColor: const Color(0xFFB45309),
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
              _field('dob', 'Date of Birth'),
              _field('conductRemark', 'Conduct Remark'),
              _field('purpose', 'Purpose', maxLines: 2),
              _field('academicYear', 'Academic Year (During the Year) — e.g. 2024-25'),
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
