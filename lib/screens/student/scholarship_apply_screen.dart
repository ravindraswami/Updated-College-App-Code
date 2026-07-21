import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/user_model.dart';
import '../../models/scholarship_model.dart';
import '../../services/scholarship_service.dart';
import '../../utils/app_theme.dart';

class ScholarshipApplyScreen extends StatefulWidget {
  final UserModel student;
  const ScholarshipApplyScreen({super.key, required this.student});
  @override
  State<ScholarshipApplyScreen> createState() => _ScholarshipApplyScreenState();
}

class _ScholarshipApplyScreenState extends State<ScholarshipApplyScreen> {
  final _svc = ScholarshipService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarshipModel>>(
      stream: _svc.getStudentScholarships(widget.student.id),
      builder: (context, snap) {
        final list = snap.data ?? [];
        final approved = list.where((r) => r.status == 'approved').toList();
        final active = list.where((r) => r.status != 'approved').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _ScholarshipFormScreen(student: widget.student),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Apply for New Scholarship'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (approved.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.verified, color: AppTheme.success, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Approved Scholarships',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...approved.map((r) => _ScholarshipCard(r)),
                const SizedBox(height: 20),
              ],

              if (active.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.pending, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Application Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...active.map((r) => _ScholarshipCard(r)),
              ],

              if (list.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No scholarship applications yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap the button above to apply.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Scholarship status card ───────────────────────────────────
class _ScholarshipCard extends StatefulWidget {
  final ScholarshipModel req;
  const _ScholarshipCard(this.req);
  @override
  State<_ScholarshipCard> createState() => _ScholarshipCardState();
}

class _ScholarshipCardState extends State<_ScholarshipCard> {
  ScholarshipModel get req => widget.req;
  bool _printing = false;

  Future<void> _printApproval() async {
    setState(() => _printing = true);
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'SCHOLARSHIP APPROVAL LETTER',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(width: 80, height: 2, color: PdfColors.green800),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(160),
                  1: const pw.FlexColumnWidth(),
                },
                children:
                    [
                      ['ERP / Roll No.', req.erpId],
                      ['Scholarship Type', req.scholarshipType],
                      ['Religion / Caste', '${req.religion} / ${req.caste}'],
                      ['Caste Category', req.casteCategory],
                      [
                        'Income (Annual)',
                        ((req as dynamic).annualIncome ?? '').toString(),
                      ],
                      [
                        'Form Filled',
                        req.formFilledStatus == 'yes' ? 'Yes' : 'No',
                      ],
                      ['Application Status', 'APPROVED ✓'],
                      ['Academic Year', req.year],
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
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 100,
                        height: 1,
                        color: PdfColors.black,
                      ),
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
                      pw.Container(
                        width: 130,
                        height: 1,
                        color: PdfColors.black,
                      ),
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
      final bytes = await doc.save();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(req.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    req.scholarshipType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: info.$1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.$2, color: info.$1, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        info.$3,
                        style: TextStyle(
                          color: info.$1,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Category: ${req.casteCategory}  •  ${req.religion} / ${req.caste}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            // Form filled & application status badges
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _Badge(
                  label:
                      'Form Filled: ${req.formFilledStatus == 'yes' ? 'Yes' : 'No'}',
                  color: req.formFilledStatus == 'yes'
                      ? AppTheme.success
                      : AppTheme.warning,
                  icon: req.formFilledStatus == 'yes'
                      ? Icons.check_circle
                      : Icons.cancel,
                ),
                _Badge(
                  label:
                      'Status: ${req.applicationStatus == 'approved' ? 'Approved' : 'Pending'}',
                  color: req.applicationStatus == 'approved'
                      ? AppTheme.success
                      : AppTheme.primary,
                  icon: req.applicationStatus == 'approved'
                      ? Icons.verified
                      : Icons.hourglass_empty,
                ),
                if (req.pdfUrl.isNotEmpty)
                  _Badge(
                    label: 'Form PDF Attached',
                    color: AppTheme.secondary,
                    icon: Icons.picture_as_pdf,
                  ),
              ],
            ),

            const SizedBox(height: 12),
            _ApprovalPipeline(req: req),

            if (req.technicalRemarks.isNotEmpty &&
                req.status == 'rejected') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rejection reason: ${req.technicalRemarks}',
                  style: const TextStyle(color: AppTheme.error, fontSize: 12),
                ),
              ),
            ],

            // Print button for approved scholarships
            if (req.status == 'approved') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _printing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print, size: 16),
                  label: Text(
                    _printing
                        ? 'Preparing PDF...'
                        : 'Print / Download Approval Letter',
                  ),
                  onPressed: _printing ? null : _printApproval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, IconData, String) _statusInfo(String status) {
    switch (status) {
      case 'pending_cc':
        return (AppTheme.warning, Icons.hourglass_top, 'Pending CC');
      case 'cc_approved':
      case 'pending_technical':
        return (AppTheme.primary, Icons.how_to_reg, 'CC Approved');
      case 'cc_rejected':
        return (AppTheme.error, Icons.cancel, 'CC Rejected');
      case 'approved':
        return (AppTheme.success, Icons.verified, 'Approved');
      case 'rejected':
        return (AppTheme.error, Icons.cancel, 'Rejected');
      default:
        return (Colors.grey, Icons.help_outline, status);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ── Approval pipeline ─────────────────────────────────────────
class _ApprovalPipeline extends StatelessWidget {
  final ScholarshipModel req;
  const _ApprovalPipeline({required this.req});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Student\nApplied', Icons.person),
      _Step('Coordinator\nReview', Icons.supervisor_account),
      _Step('Technical\nStaff', Icons.manage_accounts),
    ];
    int activeStep = 0;
    if (req.status == 'cc_approved' || req.status == 'pending_technical')
      activeStep = 1;
    if (req.status == 'approved') activeStep = 2;
    final isRejected = req.status == 'rejected' || req.status == 'cc_rejected';

    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        final isDone = i <= activeStep;
        final color = isRejected && i > 0
            ? AppTheme.error
            : isDone
            ? AppTheme.success
            : Colors.grey[300]!;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(step.icon, color: color, size: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDone ? color : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < activeStep ? AppTheme.success : Colors.grey[200],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}

// ─────────────────────────────────────────────────────────────
// SCHOLARSHIP FORM SCREEN
// ─────────────────────────────────────────────────────────────
class _ScholarshipFormScreen extends StatefulWidget {
  final UserModel student;
  const _ScholarshipFormScreen({required this.student});
  @override
  State<_ScholarshipFormScreen> createState() => _ScholarshipFormScreenState();
}

class _ScholarshipFormScreenState extends State<_ScholarshipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ScholarshipService();

  // Student-entered fields only
  String? _scholarshipType;
  String _formFilledStatus = 'no'; // radio: yes/no
  String _applicationStatus = 'pending'; // radio: pending/approved

  // PDF upload
  PlatformFile? _pdfFile;
  bool _isSubmitting = false;

  static const _scholarshipTypes = [
    'EBC Punjabrao',
    'EBC Rajarshi Shahu Maharaj',
    'OBC GOI',
    'OBC Freeship',
    'SC/ST GOI',
    'SC/ST Freeship',
    'VJNT GOI',
    'VJNT Freeship',
    'Swadhar Dr. Babasaheb Ambedkar',
  ];

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          _showSnack('Could not read file. Please try again.', isError: true);
          return;
        }
        setState(() => _pdfFile = file);
      }
    } catch (_) {
      _showSnack(
        'Could not open file picker. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _svc.submitScholarship(
        student: widget.student,
        scholarshipType: _scholarshipType!,
        formFilledStatus: _formFilledStatus,
        applicationStatus: _applicationStatus,
        pdfBytes: _pdfFile?.bytes?.toList(),
        pdfFileName: _pdfFile?.name ?? '',
      );
      if (!mounted) return;
      _showSnack(
        'Application submitted! Your class coordinator will review it.',
        isError: false,
      );
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Could not submit. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final studentName = s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name;

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Scholarship')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Auto-filled student info ────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_fix_high,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Auto-filled from your profile',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    _infoRow('Full Name', studentName),
                    _infoRow('ERP ID', s.erpId),
                    _infoRow('Branch', s.branch),
                    _infoRow('Year / Semester', '${s.year} — ${s.semester}'),
                    _infoRow(
                      'Caste Category',
                      s.actualCasteCategory.isNotEmpty
                          ? s.actualCasteCategory
                          : '—',
                    ),
                    _infoRow('Religion / Caste', '${s.religion} / ${s.caste}'),
                    _infoRow(
                      "Mother's Name",
                      s.motherName.isNotEmpty ? s.motherName : '—',
                    ),
                    _infoRow('Mobile', s.mobile.isNotEmpty ? s.mobile : '—'),
                    _infoRow(
                      'Address',
                      [
                        s.address,
                        s.district,
                        s.state,
                      ].where((v) => v.isNotEmpty).join(', '),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Section 1: Scholarship type ─────────────────
              _sectionHeader('Scholarship Details'),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _scholarshipType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Which Scholarship to Apply For',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                hint: const Text('Select scholarship type'),
                items: _scholarshipTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _scholarshipType = v),
                validator: (v) =>
                    v == null ? 'Please select a scholarship type.' : null,
              ),
              const SizedBox(height: 20),

              // ── Section 2: Form filled? (Radio Yes/No) ──────
              _sectionHeader('Scholarship Form Status'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Has scholarship form been filled?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'yes',
                              groupValue: _formFilledStatus,
                              onChanged: (v) =>
                                  setState(() => _formFilledStatus = v!),
                              activeColor: AppTheme.success,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text('Yes'),
                            const SizedBox(width: 8),
                            Radio<String>(
                              value: 'no',
                              groupValue: _formFilledStatus,
                              onChanged: (v) =>
                                  setState(() => _formFilledStatus = v!),
                              activeColor: AppTheme.error,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text('No'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Section 3: Upload filled PDF ────────────────
              _sectionHeader('Upload Scholarship Form (PDF)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSubmitting ? null : _pickPdf,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _pdfFile != null
                          ? AppTheme.success
                          : AppTheme.primary,
                      width: 1.8,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _pdfFile != null
                        ? AppTheme.success.withOpacity(0.04)
                        : AppTheme.primary.withOpacity(0.03),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _pdfFile != null
                            ? Icons.picture_as_pdf
                            : Icons.upload_file,
                        size: 40,
                        color: _pdfFile != null
                            ? AppTheme.error
                            : AppTheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pdfFile != null
                            ? _pdfFile!.name
                            : 'Tap to upload filled form (PDF)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _pdfFile != null
                              ? AppTheme.primary
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_pdfFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_pdfFile!.size / 1024).toStringAsFixed(1)} KB  •  tap to change',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ] else
                        const Text(
                          'Optional — PDF only',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Section 4: Application status (Radio) ───────
              _sectionHeader('Application Approval Status'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.approval,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Current application status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'pending',
                              groupValue: _applicationStatus,
                              onChanged: (v) =>
                                  setState(() => _applicationStatus = v!),
                              activeColor: AppTheme.warning,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text('Pending'),
                            const SizedBox(width: 8),
                            Radio<String>(
                              value: 'approved',
                              groupValue: _applicationStatus,
                              onChanged: (v) =>
                                  setState(() => _applicationStatus = v!),
                              activeColor: AppTheme.success,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text('Approved'),
                          ],
                        ),
                      ],
                    ),
                    // Explanation
                    Padding(
                      padding: const EdgeInsets.only(left: 30, bottom: 8),
                      child: Text(
                        _applicationStatus == 'pending'
                            ? 'Your application is still being processed at government level.'
                            : 'Your scholarship has been approved at government level.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _applicationStatus == 'approved'
                              ? AppTheme.success
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Approval flow info ──────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: AppTheme.primary, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Approval Process',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Student  →  Advisor  →  Administrative',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You can track the status from the Scholarship section.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text(
                    'Submit Application',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: AppTheme.primary,
    ),
  );
}
