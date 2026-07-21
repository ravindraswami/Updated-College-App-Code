import 'package:flutter/material.dart';
import '../../models/tc_model.dart';
import '../../services/tc_service.dart';
import '../../utils/app_theme.dart';
import 'certificate_pdfs.dart' as cert_pdf;

/// Education Section: full edit form for a Transfer Certificate request.
/// Every field the student submitted (and a few admin-only ones) can be
/// corrected here before the certificate is saved and printed.
class TcEditScreen extends StatefulWidget {
  final TcModel tc;
  const TcEditScreen({super.key, required this.tc});

  @override
  State<TcEditScreen> createState() => _TcEditScreenState();
}

class _TcEditScreenState extends State<TcEditScreen> {
  final _svc = TcService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final tc = widget.tc;
    _c = {
      'studentName': TextEditingController(text: tc.studentName),
      'erpId': TextEditingController(text: tc.erpId),
      'branch': TextEditingController(text: tc.branch),
      'year': TextEditingController(text: tc.year),
      'semester': TextEditingController(text: tc.semester),
      'rollNo': TextEditingController(text: tc.rollNo),
      'registerNo': TextEditingController(text: tc.registerNo),
      'dob': TextEditingController(text: tc.dob),
      'dobInWords': TextEditingController(text: tc.dobInWords),
      'motherName': TextEditingController(text: tc.motherName),
      'religion': TextEditingController(text: tc.religion),
      'caste': TextEditingController(text: tc.caste),
      'casteCategory': TextEditingController(text: tc.casteCategory),
      'dateOfAdmission': TextEditingController(text: tc.dateOfAdmission),
      'semesterAdmitted': TextEditingController(text: tc.semesterAdmitted),
      'lastCollege': TextEditingController(text: tc.lastCollege),
      'lastExamPassed': TextEditingController(text: tc.lastExamPassed),
      'qualifiedForPromotion':
          TextEditingController(text: tc.qualifiedForPromotion),
      'reasonForLeaving': TextEditingController(text: tc.reasonForLeaving),
      'dateOfLeaving': TextEditingController(text: tc.dateOfLeaving),
      'dateOfApplication': TextEditingController(text: tc.dateOfApplication),
      'dues': TextEditingController(text: tc.dues),
      'conduct': TextEditingController(text: tc.conduct),
      'tcRemarks': TextEditingController(text: tc.tcRemarks),
    };
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TcModel _buildUpdatedModel() {
    final tc = widget.tc;
    return TcModel(
      id: tc.id,
      studentId: tc.studentId,
      studentName: _c['studentName']!.text.trim(),
      erpId: _c['erpId']!.text.trim(),
      branch: _c['branch']!.text.trim(),
      year: _c['year']!.text.trim(),
      semester: _c['semester']!.text.trim(),
      rollNo: _c['rollNo']!.text.trim(),
      registerNo: _c['registerNo']!.text.trim(),
      dob: _c['dob']!.text.trim(),
      dobInWords: _c['dobInWords']!.text.trim(),
      motherName: _c['motherName']!.text.trim(),
      religion: _c['religion']!.text.trim(),
      caste: _c['caste']!.text.trim(),
      casteCategory: _c['casteCategory']!.text.trim(),
      dateOfAdmission: _c['dateOfAdmission']!.text.trim(),
      semesterAdmitted: _c['semesterAdmitted']!.text.trim(),
      lastCollege: _c['lastCollege']!.text.trim(),
      lastExamPassed: _c['lastExamPassed']!.text.trim(),
      qualifiedForPromotion: _c['qualifiedForPromotion']!.text.trim(),
      reasonForLeaving: _c['reasonForLeaving']!.text.trim(),
      dateOfLeaving: _c['dateOfLeaving']!.text.trim(),
      dateOfApplication: _c['dateOfApplication']!.text.trim(),
      dues: _c['dues']!.text.trim(),
      conduct: _c['conduct']!.text.trim(),
      tcRemarks: _c['tcRemarks']!.text.trim(),
      status: tc.status,
      isPaid: tc.isPaid,
      charges: tc.charges,
      paymentId: tc.paymentId,
      approvedBy: tc.approvedBy,
      approvedDate: tc.approvedDate,
      createdAt: tc.createdAt,
    );
  }

  Future<void> _save({bool andPrint = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = _buildUpdatedModel();
      await _svc.updateTc(updated);
      if (andPrint) {
        await cert_pdf.printTransferCert(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(andPrint ? 'Saved and sent to print.' : 'TC details saved.'),
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
        title: const Text('Edit Transfer Certificate'),
        backgroundColor: const Color(0xFF0891B2),
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
              _field('erpId', 'ERP / Student ID'),
              _field('registerNo', 'Register No.'),
              _field('rollNo', 'Roll No.'),
              _field('branch', 'Branch'),
              _field('year', 'Year'),
              _field('semester', 'Semester'),
              _field('dob', 'Date of Birth (DD/MM/YYYY)'),
              _field('dobInWords', 'Date of Birth (in words)'),
              _field('motherName', "Mother's Name"),
              _field('religion', 'Religion'),
              _field('caste', 'Caste'),
              _field('casteCategory', 'Category'),
              const SizedBox(height: 8),
              const Text('Academic / TC Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _field('dateOfAdmission', 'Date of Admission'),
              _field('semesterAdmitted', 'Semester Admitted'),
              _field('lastCollege', 'Last College Attended'),
              _field('lastExamPassed', 'Last Exam Passed'),
              _field('qualifiedForPromotion', 'Qualified for Promotion (Yes/No)'),
              _field('reasonForLeaving', 'Reason for Leaving', maxLines: 2),
              _field('dateOfLeaving', 'Date of Leaving'),
              _field('dateOfApplication', 'Date of Application for TC'),
              _field('dues', 'Dues (if any)'),
              _field('conduct', 'Conduct'),
              _field('tcRemarks', 'Remarks', maxLines: 2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _save(andPrint: false),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Only'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _save(andPrint: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.print),
                      label: const Text('Save & Print'),
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
