import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/exam_form_model.dart';
import '../../models/subject_model.dart';
import '../../services/exam_form_service.dart';
import '../../services/subject_service.dart';
import '../../services/class_advisor_assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/certificate_widgets.dart' as certw;
import '../shared/certificate_preview_screen.dart';

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
                      text: 'Advisor reviews and approves',
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
  final _advisorSvc = ClassAdvisorAssignmentService();
  String? _session;
  final _subSvc = SubjectService();

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
    if (_session == null) {
      _snack('Please select exam session (Summer / Winter).', isError: true);
      return;
    }

    setState(() => _loading = true);
    final s = widget.student;
    try {
      final selSubjectModels = _currentSubjects
          .where((sub) => _selectedSubjectIds.contains(sub.id))
          .toList();
      final selSubjects = selSubjectModels.map((sub) => sub.displayName).toList();
      final selSubjectIds = selSubjectModels.map((sub) => sub.id).toList();

      // Build per-subject fee / credit / code / title maps
      final Map<String, double> regularFees = {};
      final Map<String, double> regularCredits = {};
      final Map<String, String> regularCodes = {};
      final Map<String, String> regularTitles = {};
      for (final sub in selSubjectModels) {
        regularFees[sub.id] = sub.regularFee;
        regularCredits[sub.id] = sub.totalCredit;
        regularCodes[sub.id] = sub.code;
        regularTitles[sub.id] = sub.name;
      }

      final selBacklogModels = _backlogSubjectList
          .where((sub) => _selectedBacklogIds.contains(sub.id))
          .toList();
      final selBacklog = selBacklogModels
          .map((sub) => '${_backlogSem ?? ''} — ${sub.displayName}')
          .toList();
      final selBacklogIds = selBacklogModels.map((sub) => sub.id).toList();

      final Map<String, double> backlogFees = {};
      final Map<String, double> backlogCredits = {};
      final Map<String, String> backlogCodes = {};
      final Map<String, String> backlogTitles = {};
      for (final sub in selBacklogModels) {
        backlogFees[sub.id] = sub.backlogFee;
        backlogCredits[sub.id] = sub.totalCredit;
        backlogCodes[sub.id] = sub.code;
        backlogTitles[sub.id] = sub.name;
      }

      // Auto-fetch Class Advisor assigned to this student's reg-no range
      String advisorName = '';
      String advisorDesignation = '';
      try {
        final advisor = await _advisorSvc.findAdvisorFor(
          s.branch,
          s.year,
          s.registerNo,
        );
        if (advisor != null) {
          advisorName = advisor.advisorName;
          advisorDesignation = 'Advisor';
        }
      } catch (_) {
        // Non-fatal: advisor lookup failure shouldn't block submission
      }

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
          department: AcademicData.branchFullLabel(s.branch),
          rollNo: s.registerNo,
          dob: s.dob,
          mobile: s.mobile,
          email: s.email,
          subjects: selSubjects,
          subjectIds: selSubjectIds,
          hasBacklog: _hasBacklog && selBacklog.isNotEmpty,
          backlogSubjects: selBacklog,
          backlogSubjectIds: selBacklogIds,
          subjectRegularFees: regularFees,
          subjectBacklogFees: backlogFees,
          subjectCredits: regularCredits,
          backlogSubjectCredits: backlogCredits,
          subjectCodes: regularCodes,
          subjectTitles: regularTitles,
          backlogSubjectCodes: backlogCodes,
          backlogSubjectTitles: backlogTitles,
          session: _session!,
          advisorName: advisorName,
          advisorDesignation: advisorDesignation,
          examYear: DateTime.now().year.toString(),
          examMonth: _months[DateTime.now().month - 1],
          center: '',
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

            // ── Session ──────────────────────────────────────
            const _SectionHeader(title: 'Exam Session'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _session,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Session *',
                prefixIcon: Icon(Icons.wb_sunny_outlined),
                isDense: true,
              ),
              hint: const Text('Select Summer / Winter'),
              items: const ['Summer', 'Winter']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _session = v),
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
                  subtitle: sub.regularFee > 0
                      ? Text(
                          'Regular Fee: ₹${sub.regularFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
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
                                subtitle: sub.backlogFee > 0
                                    ? Text(
                                        'Backlog Fee: ₹${sub.backlogFee.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : null,
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
class _FormStatusCard extends StatefulWidget {
  final ExamFormModel form;
  final ExamFormService svc;
  const _FormStatusCard({required this.form, required this.svc});
  @override
  State<_FormStatusCard> createState() => _FormStatusCardState();
}

class _FormStatusCardState extends State<_FormStatusCard> {
  ExamFormModel get form => widget.form;
  ExamFormService get svc => widget.svc;
  bool _generating = false;

  Future<void> _generateForm() async {
    setState(() => _generating = true);
    try {
      final regularRows = <List<String>>[];
      var sr = 1;
      for (final id in form.subjectIds) {
        final code = form.subjectCodes[id] ?? '';
        final title = form.subjectTitles[id] ?? '';
        final credit = (form.subjectCredits[id] ?? 0).toStringAsFixed(1);
        regularRows.add(['${sr++}', code, title, credit]);
      }

      final backlogRows = <List<String>>[];
      var srB = 1;
      for (final id in form.backlogSubjectIds) {
        final code = form.backlogSubjectCodes[id] ?? '';
        final title = form.backlogSubjectTitles[id] ?? '';
        final credit = (form.backlogSubjectCredits[id] ?? 0).toStringAsFixed(1);
        backlogRows.add(['${srB++}', code, title, credit]);
      }

      Widget courseTable(String heading, List<List<String>> rows, int totalCourses, double totalCredit) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Text(heading, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400, width: 0.6),
              columnWidths: const {
                0: FixedColumnWidth(34),
                1: FixedColumnWidth(80),
                2: FlexColumnWidth(),
                3: FixedColumnWidth(60),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: ['Sr', 'Course Code', 'Course Title', 'Credit']
                      .map((h) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...rows.map((r) => TableRow(
                      children: r
                          .map((v) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                child: Text(v, style: const TextStyle(fontSize: 10)),
                              ))
                          .toList(),
                    )),
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: Text('')),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: Text('')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: Text('Total Courses: $totalCourses',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: Text(totalCredit.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      }

      final infoRows = [
        ['Form ID', form.id.substring(0, 8).toUpperCase()],
        ['Session', form.session],
        ['Student Name', form.name],
        ['Register No.', form.rollNo],
        ['Semester', form.semester],
        ['Department', form.department],
        ['Advisor Name', form.advisorName],
        ['Designation', form.advisorDesignation],
        ['Status', 'APPROVED \u2713'],
        ['Fee Paid', '\u20b9${form.feeAmount.toStringAsFixed(0)}'],
      ];

      final reportWidget = certw.reportSheet(
        width: 850,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            certw.buildLetterheadBlock(),
            const SizedBox(height: 10),
            const Text(
              'EXAMINATION FORM \u2014 APPROVED',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 6),
            Container(width: 90, height: 2, color: Colors.green.shade800),
            const SizedBox(height: 18),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400, width: 0.6),
              columnWidths: const {0: FixedColumnWidth(170), 1: FlexColumnWidth()},
              children: infoRows
                  .map((row) => TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text(row[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text(row[1], style: const TextStyle(fontSize: 11)),
                        ),
                      ]))
                  .toList(),
            ),
            if (regularRows.isNotEmpty)
              courseTable('Regular Subjects', regularRows, form.totalCourseCount, form.totalCreditSum),
            if (backlogRows.isNotEmpty)
              courseTable('Backlog Subjects', backlogRows, form.totalBacklogCourseCount, form.totalBacklogCreditSum),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggestion Codes:  RR = Result Reserved   \u2022   NR = Not Registered   \u2022   OEF = Online Exam Form',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(children: [
                  Container(width: 100, height: 1, color: Colors.black),
                  const SizedBox(height: 4),
                  Text('Student Signature', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                ]),
                Column(children: [
                  Container(width: 130, height: 1, color: Colors.black),
                  const SizedBox(height: 4),
                  Text('Advisor Signature (${form.advisorName})', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                ]),
                Column(children: [
                  Container(width: 130, height: 1, color: Colors.black),
                  const SizedBox(height: 4),
                  Text('Principal / Controller of Examinations', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade300),
            Text(
              'Generated via Smart ERP \u2022 ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ),
      );

      if (!mounted) return;
      await openCertificatePreview(
        context,
        title: 'Examination Form',
        fileName: 'ExamForm_${form.rollNo.isNotEmpty ? form.rollNo : form.id}',
        certificate: reportWidget,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) => _buildCard(context);

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

  Widget _buildCard(BuildContext context) {
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

            // Print button for approved forms
            if (form.status == 'approved') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.image_outlined, size: 16),
                  label: Text(
                    _generating ? 'Generating...' : 'Generate Form Image',
                  ),
                  onPressed: _generating ? null : _generateForm,
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
