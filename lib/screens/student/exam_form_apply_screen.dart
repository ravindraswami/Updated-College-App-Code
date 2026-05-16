import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/exam_form_model.dart';
import '../../models/subject_model.dart';
import '../../services/exam_form_service.dart';
import '../../services/subject_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../widgets/common_widgets.dart';

class ExamFormApplyScreen extends StatelessWidget {
  final UserModel student;
  const ExamFormApplyScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final svc = ExamFormService();
    return StreamBuilder<List<ExamFormModel>>(
      stream: svc.getStudentForms(student.id),
      builder: (ctx, snap) {
        final forms = snap.data ?? [];
        final approved = forms.where((f) => f.status == 'approved').toList();
        final others = forms.where((f) => f.status != 'approved').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // How it works
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Exam Form Process',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    _StepRow(
                      step: '1',
                      text:
                          'Submit form — subjects auto-loaded from your semester',
                    ),
                    _StepRow(
                      step: '2',
                      text: 'Class Coordinator reviews and approves',
                    ),
                    _StepRow(
                      step: '3',
                      text: 'Technical Staff adds fee and confirms',
                    ),
                    _StepRow(step: '4', text: 'Pay fee → form is approved'),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => _ExamFormFillScreen(student: student),
                    ),
                  ),
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Fill Exam Form'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (approved.isNotEmpty) ...[
                _SectionLabel(
                  icon: Icons.verified,
                  label: 'Approved Forms',
                  color: AppTheme.success,
                ),
                const SizedBox(height: 8),
                ...approved.map((f) => _FormStatusCard(form: f, svc: svc)),
                const SizedBox(height: 20),
              ],

              if (others.isNotEmpty) ...[
                _SectionLabel(
                  icon: Icons.receipt_long,
                  label: 'My Form Requests',
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 8),
                ...others.map((f) => _FormStatusCard(form: f, svc: svc)),
              ],

              if (forms.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.edit_document,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No exam forms submitted yet.',
                        style: TextStyle(color: Colors.grey),
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

// ── Exam Form Fill Screen ─────────────────────────────────────
class _ExamFormFillScreen extends StatefulWidget {
  final UserModel student;
  const _ExamFormFillScreen({required this.student});
  @override
  State<_ExamFormFillScreen> createState() => _ExamFormFillScreenState();
}

class _ExamFormFillScreenState extends State<_ExamFormFillScreen> {
  final _svc = ExamFormService();
  final _subSvc = SubjectService();

  final _centerCtrl = TextEditingController();
  bool _hasBacklog = false;

  // Current sem subjects — auto-loaded from Firestore
  List<SubjectModel> _currentSubjects = [];
  final Set<String> _selectedSubjectIds = {};
  bool _loadingSubjects = false;

  // Backlog
  String? _backlogSem; // student picks which sem they have backlog in
  List<SubjectModel> _backlogSubjectList = [];
  final Set<String> _selectedBacklogIds = {};
  bool _loadingBacklog = false;

  String? _examYear;
  String? _examMonth;

  final _years = ['2024', '2025', '2026', '2027'];
  final _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubjects();
  }

  Future<void> _loadCurrentSubjects() async {
    final s = widget.student;
    if (s.branch.isEmpty || s.semester.isEmpty) return;
    setState(() => _loadingSubjects = true);
    _subSvc.getSubjectsBySemester(s.branch, s.semester).listen((subjects) {
      if (mounted)
        setState(() {
          _currentSubjects = subjects;
          _loadingSubjects = false;
        });
    });
  }

  Future<void> _loadBacklogSubjects(String sem) async {
    final s = widget.student;
    setState(() {
      _loadingBacklog = true;
      _backlogSubjectList = [];
      _selectedBacklogIds.clear();
    });
    _subSvc.getSubjectsBySemester(s.branch, sem).listen((subjects) {
      if (mounted)
        setState(() {
          _backlogSubjectList = subjects;
          _loadingBacklog = false;
        });
    });
  }

  // All sems BEFORE current semester
  List<Map<String, dynamic>> get _previousSems {
    final s = widget.student;
    if (s.branch.isEmpty) return [];
    final allYears = AcademicData.yearsForBranch(s.branch);
    final List<Map<String, dynamic>> allSems = [];
    for (final year in allYears) {
      final yearId = year['id'] as String;
      final sems = AcademicData.semsForYear(s.branch, yearId);
      for (final sem in sems) {
        final semId = sem['id'] as String;
        if (semId == s.semester) return allSems; // stop before current
        allSems.add({
          'id': semId,
          'label': '${year['label']} — ${sem['label']}',
        });
      }
    }
    return allSems;
  }

  Future<void> _submit() async {
    if (_selectedSubjectIds.isEmpty) {
      _snack('Please select at least one subject.', isError: true);
      return;
    }
    if (_examYear == null || _examMonth == null) {
      _snack('Please select exam year and month.', isError: true);
      return;
    }

    setState(() => _loading = true);
    final s = widget.student;
    try {
      final selSubjects = _currentSubjects
          .where((sub) => _selectedSubjectIds.contains(sub.id))
          .map((sub) => sub.displayName)
          .toList();
      final selBacklog = _backlogSubjectList
          .where((sub) => _selectedBacklogIds.contains(sub.id))
          .map((sub) => '${_backlogSem ?? ''} — ${sub.displayName}')
          .toList();

      await _svc.submitForm(
        ExamFormModel(
          id: '',
          studentId: s.id,
          classId: s.classId,
          name: s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
          prn: s.registerNo,
          erpId: s.erpId,
          branch: s.branch,
          year: s.year,
          semester: s.semester,
          department: '',
          rollNo: s.registerNo,
          dob: s.dob,
          mobile: s.mobile,
          email: s.email,
          subjects: selSubjects,
          hasBacklog: _hasBacklog && selBacklog.isNotEmpty,
          backlogSubjects: selBacklog,
          examYear: _examYear!,
          examMonth: _examMonth!,
          center: _centerCtrl.text.trim(),
          submittedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      _snack(
        'Exam form submitted! Your class coordinator will review it.',
        isError: false,
      );
      Navigator.pop(context);
    } catch (e) {
      _snack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Fill Exam Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-filled student info
            Card(
              color: AppTheme.primary.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Details (Auto-filled)',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      'Name',
                      s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
                    ),
                    _InfoRow('ERP ID', s.erpId),
                    _InfoRow('Branch', s.branch),
                    _InfoRow('Year / Sem', '${s.year} — ${s.semester}'),
                    _InfoRow(
                      'Roll No.',
                      s.registerNo.isNotEmpty ? s.registerNo : '—',
                    ),
                    _InfoRow('Mobile', s.mobile),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Current Semester Subjects ──────────────────────
            const _SectionHeader(
              title: 'Subjects Appearing For (Current Semester)',
            ),
            const SizedBox(height: 4),
            Text(
              '${s.branch} — ${s.semester}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),

            if (_loadingSubjects)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_currentSubjects.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warning,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No subjects found for your semester. Contact your professor to add subjects.',
                        style: TextStyle(color: AppTheme.warning, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...(_currentSubjects.map(
                (sub) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _selectedSubjectIds.contains(sub.id),
                  onChanged: (v) => setState(() {
                    if (v == true)
                      _selectedSubjectIds.add(sub.id);
                    else
                      _selectedSubjectIds.remove(sub.id);
                  }),
                  title: Text(
                    sub.displayName,
                    style: const TextStyle(fontSize: 13),
                  ),
                  secondary: sub.code.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sub.code,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              )),

            const SizedBox(height: 20),

            // ── Backlog section ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _hasBacklog,
                        onChanged: (v) => setState(() {
                          _hasBacklog = v;
                          if (!v) {
                            _backlogSem = null;
                            _backlogSubjectList = [];
                            _selectedBacklogIds.clear();
                          }
                        }),
                        activeColor: AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'I have Backlog subjects',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  if (_hasBacklog) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Select the semester of your backlog:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _backlogSem,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Backlog Semester *',
                        isDense: true,
                        prefixIcon: Icon(Icons.history_edu_outlined),
                      ),
                      hint: const Text('Select semester'),
                      items: _previousSems
                          .map(
                            (sem) => DropdownMenuItem(
                              value: sem['id'] as String,
                              child: Text(
                                sem['label'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _backlogSem = v;
                        });
                        if (v != null) _loadBacklogSubjects(v);
                      },
                    ),

                    if (_backlogSem != null) ...[
                      const SizedBox(height: 12),
                      if (_loadingBacklog)
                        const Center(child: CircularProgressIndicator())
                      else if (_backlogSubjectList.isEmpty)
                        const Text(
                          'No subjects found for this semester.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select your backlog subjects:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            ..._backlogSubjectList.map(
                              (sub) => CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                value: _selectedBacklogIds.contains(sub.id),
                                onChanged: (v) => setState(() {
                                  if (v == true)
                                    _selectedBacklogIds.add(sub.id);
                                  else
                                    _selectedBacklogIds.remove(sub.id);
                                }),
                                title: Text(
                                  sub.displayName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Exam Year + Month ──────────────────────────────
            const _SectionHeader(title: 'Exam Details'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _examYear,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exam Year *',
                      isDense: true,
                    ),
                    hint: const Text('Year'),
                    items: _years
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) => setState(() => _examYear = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _examMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exam Month *',
                      isDense: true,
                    ),
                    hint: const Text('Month'),
                    items: _months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _examMonth = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _centerCtrl,
              decoration: const InputDecoration(
                labelText: 'Exam Center (Optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'e.g. Solapur',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Exam Form',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form status card ──────────────────────────────────────────
class _FormStatusCard extends StatelessWidget {
  final ExamFormModel form;
  final ExamFormService svc;
  const _FormStatusCard({required this.form, required this.svc});

  Color get _color {
    switch (form.status) {
      case 'pending_cc':
        return AppTheme.warning;
      case 'pending_technical':
        return AppTheme.primary;
      case 'fee_pending':
        return const Color(0xFFD97706);
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (form.status) {
      case 'pending_cc':
        return 'Awaiting CC Review';
      case 'pending_technical':
        return 'Awaiting Technical Review';
      case 'fee_pending':
        return 'Fee Payment Pending';
      case 'approved':
        return 'Approved ✓';
      case 'rejected':
        return 'Rejected';
      default:
        return form.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${form.branch} — ${form.semester}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _label,
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Exam: ${form.examMonth} ${form.examYear}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              'Subjects: ${form.subjects.join(", ")}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (form.hasBacklog && form.backlogSubjects.isNotEmpty)
              Text(
                'Backlog: ${form.backlogSubjects.join(", ")}',
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),

            // Pay fee button
            if (form.status == 'fee_pending') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fee: ₹${form.feeAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment, size: 16),
                  label: Text(
                    'Pay ₹${form.feeAmount.toStringAsFixed(0)} Exam Fee',
                  ),
                  onPressed: () async {
                    await svc.payFee(form.id);
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment successful! Your form is now approved.',
                          ),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: AppTheme.primary,
    ),
  );
}

class _StepRow extends StatelessWidget {
  final String step;
  final String text;
  const _StepRow({required this.step, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
