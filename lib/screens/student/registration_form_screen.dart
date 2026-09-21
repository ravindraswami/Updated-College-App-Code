import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/exam_form_model.dart';
import '../../models/subject_model.dart';
import '../../services/exam_form_service.dart';
import '../../services/subject_service.dart';
import '../../services/fee_config_service.dart';
import '../../services/class_advisor_assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../exam_form/registration_pdf.dart';
import 'payment_screen.dart';

/// Registration Form (formerly "Exam Form"):
/// pay fee → Education verifies → form opens → student fills Regular +
/// Backlog subject tables → Course Teacher(s) sign → Advisor signs →
/// visible to Education.
class RegistrationFormScreen extends StatelessWidget {
  final UserModel student;
  const RegistrationFormScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final svc = ExamFormService();
    return StreamBuilder<List<ExamFormModel>>(
      stream: svc.getStudentForms(student.id),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final regs =
            snap.data!.where((f) => f.startedAsRegistration).toList();
        final active = regs
            .where((f) => f.status != 'completed' && f.status != 'rejected')
            .toList();
        final history = regs
            .where((f) => f.status == 'completed' || f.status == 'rejected')
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        Icon(Icons.info_outline, color: AppTheme.primary, size: 16),
                        SizedBox(width: 8),
                        Text('Registration Form Process',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary)),
                      ],
                    ),
                    SizedBox(height: 6),
                    _StepRow(step: '1', text: 'Pay the registration fee'),
                    _StepRow(step: '2', text: 'Education Section verifies payment'),
                    _StepRow(step: '3', text: 'Form opens — fill Regular & Backlog subjects'),
                    _StepRow(step: '4', text: 'Your Course Teacher(s) sign off'),
                    _StepRow(step: '5', text: 'Your Advisor gives final approval'),
                  ],
                ),
              ),
              if (active.isEmpty) _StartCard(student: student),
              ...active.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StatusCard(form: f, student: student),
                  )),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...history.map((f) => _HistoryTile(form: f)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String text;
  const _StepRow({required this.step, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: AppTheme.primary,
            child: Text(step, style: const TextStyle(fontSize: 10, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _StartCard extends StatefulWidget {
  final UserModel student;
  const _StartCard({required this.student});
  @override
  State<_StartCard> createState() => _StartCardState();
}

class _StartCardState extends State<_StartCard> {
  final _svc = ExamFormService();
  final _feeSvc = FeeConfigService();
  bool _starting = false;

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final fees = await _feeSvc.getFees();
      final fee = fees['registrationFee']!;
      final s = widget.student;
      final formId = await _svc.startRegistration(
        studentId: s.id,
        classId: s.classId,
        name: s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
        erpId: s.erpId,
        branch: s.branch,
        year: s.year,
        semester: s.semester,
        rollNo: s.registerNo,
        mobile: s.mobile,
        registrationFee: fee,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            requestId: formId,
            amount: fee,
            studentName: s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
            paymentFor: PaymentFor.registration,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No active registration form.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Start a new registration for this semester by paying the fee.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _starting ? null : _start,
              icon: _starting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payment),
              label: Text(_starting ? 'Starting...' : 'Pay Fee & Start Registration'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ExamFormModel form;
  final UserModel student;
  const _StatusCard({required this.form, required this.student});

  @override
  Widget build(BuildContext context) {
    final signedCount = form.allSignableSubjectIds
        .where((id) => (form.teacherSignatures[id] ?? '').isNotEmpty)
        .length;
    final totalSubjects = form.allSignableSubjectIds.length;

    Widget action;
    String message;
    IconData icon;
    Color color;

    switch (form.status) {
      case 'awaiting_payment':
        icon = Icons.payment;
        color = AppTheme.warning;
        message = 'Payment not completed yet.';
        action = ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentScreen(
                requestId: form.id,
                amount: form.registrationFee,
                studentName: form.name,
                paymentFor: PaymentFor.registration,
              ),
            ),
          ),
          icon: const Icon(Icons.payment, size: 16),
          label: const Text('Complete Payment'),
          style: ElevatedButton.styleFrom(backgroundColor: color),
        );
        break;
      case 'payment_verification':
        icon = Icons.hourglass_top;
        color = AppTheme.warning;
        message = 'Payment submitted. Waiting for Education Section to verify.';
        action = const SizedBox.shrink();
        break;
      case 'form_open':
        icon = Icons.edit_document;
        color = AppTheme.success;
        message = 'Verified! Fill your subject details now.';
        action = ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrationFormFillScreen(form: form, student: student),
            ),
          ),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Fill Registration Form'),
          style: ElevatedButton.styleFrom(backgroundColor: color),
        );
        break;
      case 'teacher_review':
        icon = Icons.school_outlined;
        color = AppTheme.primary;
        message = 'Submitted. Course Teacher sign-off: $signedCount / $totalSubjects subjects.';
        action = const SizedBox.shrink();
        break;
      case 'advisor_review':
        icon = Icons.verified_user_outlined;
        color = AppTheme.primary;
        message = 'All Course Teachers signed. Waiting for Advisor approval.';
        action = const SizedBox.shrink();
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        message = ExamFormModel.statusLabel(form.status);
        action = const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (action is! SizedBox) ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ExamFormModel form;
  const _HistoryTile({required this.form});

  @override
  Widget build(BuildContext context) {
    final completed = form.status == 'completed';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          completed ? Icons.check_circle : Icons.cancel,
          color: completed ? AppTheme.success : AppTheme.error,
        ),
        title: Text('${form.semester} — ${form.year}'),
        subtitle: Text(
          completed
              ? 'Completed on ${form.advisorApprovedDate.isNotEmpty ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(form.advisorApprovedDate) ?? DateTime.now()) : ''}'
              : 'Rejected: ${form.rejectReason}',
          style: const TextStyle(fontSize: 11.5),
        ),
        trailing: completed
            ? IconButton(
                icon: const Icon(Icons.image_outlined),
                tooltip: 'Generate',
                onPressed: () => printStudentSubjectTable(context, form),
              )
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILL FORM — Regular Course + Backlog tabs
// ═══════════════════════════════════════════════════════════════
class RegistrationFormFillScreen extends StatefulWidget {
  final ExamFormModel form;
  final UserModel student;
  const RegistrationFormFillScreen({super.key, required this.form, required this.student});

  @override
  State<RegistrationFormFillScreen> createState() => _RegistrationFormFillScreenState();
}

class _RegistrationFormFillScreenState extends State<RegistrationFormFillScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _subjectSvc = SubjectService();
  final _examFormSvc = ExamFormService();
  final _advisorSvc = ClassAdvisorAssignmentService();

  List<SubjectModel> _regularSubjects = [];
  List<SubjectModel> _pastSubjects = [];
  // Req #2: regular subjects are auto-loaded but the student can uncheck
  // any subject they are not appearing for (e.g. exemption/backlog carry-over).
  final Set<String> _selectedRegularIds = {};
  final Set<String> _selectedBacklogIds = {};
  final Map<String, String> _backlogChoice = {}; // subjectId -> OFE/RR
  String _advisorId = '';
  String _advisorName = '';
  bool _loading = true;
  bool _submitting = false;
  // Req #4: student can correct the Course Teacher name shown per subject
  // before submitting. Pre-filled from the subject master, but editable.
  final Map<String, TextEditingController> _teacherNameCtrls = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final s = widget.student;
    final regularStream = _subjectSvc.getSubjectsBySemester(s.branch, s.semester);
    final regular = await regularStream.first;
    final past = await _subjectSvc.getBacklogSubjects(s.branch, s.year);
    final advisor = await _advisorSvc.findAdvisorFor(
      s.branch,
      s.year,
      s.registerNo.isNotEmpty ? s.registerNo : s.erpId,
      semester: s.semester,
    );
    if (mounted) {
      setState(() {
        _regularSubjects = regular;
        _pastSubjects = past.where((sub) => sub.semester != s.semester).toList();
        _advisorId = advisor?.advisorId ?? '';
        _advisorName = advisor?.advisorName ?? '';
        // Default: all auto-loaded subjects are checked; student can uncheck.
        _selectedRegularIds
          ..clear()
          ..addAll(_regularSubjects.map((sub) => sub.id));
        for (final sub in _regularSubjects) {
          _teacherNameCtrls.putIfAbsent(
              sub.id, () => TextEditingController(text: sub.teacherName));
        }
        _loading = false;
      });
    }
  }

  double get _regularTotalCredits => _regularSubjects
      .where((s) => _selectedRegularIds.contains(s.id))
      .fold(0.0, (a, b) => a + b.totalCredit);

  double get _backlogTotalCredits => _selectedBacklogIds.fold(
      0.0, (a, id) => a + (_pastSubjects.firstWhere((s) => s.id == id).totalCredit));

  Future<void> _submit() async {
    if (_selectedRegularIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one regular subject.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (_selectedBacklogIds.any((id) => (_backlogChoice[id] ?? '').isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose OFE or RR for every selected backlog subject.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final regularList =
          _regularSubjects.where((s) => _selectedRegularIds.contains(s.id)).toList();
      final subjectIds = regularList.map((s) => s.id).toList();
      final subjects = regularList.map((s) => s.name).toList();
      final subjectCodes = {for (final s in regularList) s.id: s.code};
      final subjectTitles = {for (final s in regularList) s.id: s.name};
      final subjectCredits = {for (final s in regularList) s.id: s.totalCredit};
      final subjectTeacherIds = {for (final s in regularList) s.id: s.teacherId};
      final subjectTeacherNames = {
        for (final s in regularList)
          s.id: (_teacherNameCtrls[s.id]?.text.trim().isNotEmpty ?? false)
              ? _teacherNameCtrls[s.id]!.text.trim()
              : s.teacherName
      };

      final backlogList = _pastSubjects.where((s) => _selectedBacklogIds.contains(s.id)).toList();
      final backlogSubjectIds = backlogList.map((s) => s.id).toList();
      final backlogSubjects = backlogList.map((s) => s.name).toList();
      final backlogSubjectCodes = {for (final s in backlogList) s.id: s.code};
      final backlogSubjectTitles = {for (final s in backlogList) s.id: s.name};
      final backlogSubjectCredits = {for (final s in backlogList) s.id: s.totalCredit};
      final backlogSubjectTeacherIds = {for (final s in backlogList) s.id: s.teacherId};
      final backlogSubjectTeacherNames = {for (final s in backlogList) s.id: s.teacherName};
      final backlogSelections = {
        for (final s in backlogList) s.id: _backlogChoice[s.id] ?? ''
      };

      final filled = widget.form.copyWith(
        subjects: subjects,
        subjectIds: subjectIds,
        subjectCodes: subjectCodes,
        subjectTitles: subjectTitles,
        subjectCredits: subjectCredits,
        subjectTeacherIds: subjectTeacherIds,
        subjectTeacherNames: subjectTeacherNames,
        hasBacklog: backlogList.isNotEmpty,
        backlogSubjects: backlogSubjects,
        backlogSubjectIds: backlogSubjectIds,
        backlogSubjectCodes: backlogSubjectCodes,
        backlogSubjectTitles: backlogSubjectTitles,
        backlogSubjectCredits: backlogSubjectCredits,
        backlogSubjectTeacherIds: backlogSubjectTeacherIds,
        backlogSubjectTeacherNames: backlogSubjectTeacherNames,
        backlogSelections: backlogSelections,
        advisorId: _advisorId,
        advisorName: _advisorName,
      );

      await _examFormSvc.submitRegistrationDetails(widget.form.id, filled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitted! Your Course Teachers will review next.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    for (final c in _teacherNameCtrls.values) {
      c.dispose();
    }
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Form'),
        backgroundColor: AppTheme.primary,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Regular Course'),
            Tab(text: 'Backlog'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _RegularTab(
                  subjects: _regularSubjects,
                  selectedIds: _selectedRegularIds,
                  totalCredits: _regularTotalCredits,
                  advisorName: _advisorName,
                  teacherNameCtrls: _teacherNameCtrls,
                  onToggle: (id, val) => setState(() {
                    if (val) {
                      _selectedRegularIds.add(id);
                    } else {
                      _selectedRegularIds.remove(id);
                    }
                  }),
                ),
                _BacklogTab(
                  subjects: _pastSubjects,
                  selectedIds: _selectedBacklogIds,
                  choices: _backlogChoice,
                  totalCredits: _backlogTotalCredits,
                  onToggle: (id, val) => setState(() {
                    if (val) {
                      _selectedBacklogIds.add(id);
                    } else {
                      _selectedBacklogIds.remove(id);
                      _backlogChoice.remove(id);
                    }
                  }),
                  onChoice: (id, choice) => setState(() => _backlogChoice[id] = choice),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting...' : 'Submit Registration Form'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
    );
  }
}

class _RegularTab extends StatelessWidget {
  final List<SubjectModel> subjects;
  final Set<String> selectedIds;
  final double totalCredits;
  final String advisorName;
  final Map<String, TextEditingController> teacherNameCtrls;
  final void Function(String id, bool val) onToggle;
  const _RegularTab({
    required this.subjects,
    required this.selectedIds,
    required this.totalCredits,
    required this.advisorName,
    required this.teacherNameCtrls,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All subjects for your current semester are auto-loaded and checked. '
            'Uncheck any subject you are not appearing for, and correct the '
            'Course Teacher name if it looks wrong.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          _SubjectTable(
            rows: subjects
                .map((s) => _RowData(
                      id: s.id,
                      code: s.code,
                      title: s.name,
                      theory: s.theoryCredit,
                      practical: s.practicalCredit,
                      credit: s.totalCredit,
                      teacherNameCtrl: teacherNameCtrls[s.id],
                      selected: selectedIds.contains(s.id),
                    ))
                .toList(),
            advisorName: advisorName,
            onToggle: onToggle,
          ),
          const SizedBox(height: 10),
          Text(
            'Total Subjects: ${selectedIds.length}      Total Credits: ${totalCredits.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const _SignatureFooter(),
        ],
      ),
    );
  }
}

class _BacklogTab extends StatelessWidget {
  final List<SubjectModel> subjects;
  final Set<String> selectedIds;
  final Map<String, String> choices;
  final double totalCredits;
  final void Function(String id, bool val) onToggle;
  final void Function(String id, String choice) onChoice;
  const _BacklogTab({
    required this.subjects,
    required this.selectedIds,
    required this.choices,
    required this.totalCredits,
    required this.onToggle,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select ONLY the subjects you have a backlog in, and choose OFE or RR for each.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          if (subjects.isEmpty)
            const Text('No past-semester subjects found.', style: TextStyle(color: Colors.grey)),
          ...subjects.map((s) {
            final selected = selectedIds.contains(s.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (v) => onToggle(s.id, v ?? false),
                        ),
                        Expanded(
                          child: Text(
                            '${s.code}  —  ${s.name}  (${s.semester}, ${s.totalCredit.toStringAsFixed(1)} cr)',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    if (selected) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Wrap(
                          spacing: 8,
                          children: ['OFE', 'RR'].map((opt) {
                            final chosen = choices[s.id] == opt;
                            return ChoiceChip(
                              label: Text(opt),
                              selected: chosen,
                              onSelected: (_) => onChoice(s.id, opt),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            'Total Subjects: ${selectedIds.length}      Total Credits: ${totalCredits.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const _SignatureFooter(),
        ],
      ),
    );
  }
}

class _RowData {
  final String id;
  final String code;
  final String title;
  final double theory;
  final double practical;
  final double credit;
  final TextEditingController? teacherNameCtrl;
  final bool selected;
  _RowData({
    required this.id,
    required this.code,
    required this.title,
    required this.theory,
    required this.practical,
    required this.credit,
    this.teacherNameCtrl,
    required this.selected,
  });
}

class _SubjectTable extends StatelessWidget {
  final List<_RowData> rows;
  final String advisorName;
  final void Function(String id, bool val) onToggle;
  const _SubjectTable({
    required this.rows,
    required this.advisorName,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        // Fixed extra-tall rows so the editable "Course Teacher" TextField
        // always fits — this was the cause of the bottom overflow error.
        dataRowMinHeight: 64,
        dataRowMaxHeight: 68,
        columns: const [
          DataColumn(label: Text('Appear')),
          DataColumn(label: Text('Sr No')),
          DataColumn(label: Text('Course No')),
          DataColumn(label: Text('Course Title')),
          DataColumn(label: Text('Credits (Th+Pr)')),
          DataColumn(label: Text('Course Teacher')),
          DataColumn(label: Text('Advisor')),
          DataColumn(label: Text('Sign of Advisor (RR)')),
          DataColumn(label: Text('Sign of Course Teacher')),
          DataColumn(label: Text('Remark')),
        ],
        rows: List.generate(rows.length, (i) {
          final r = rows[i];
          return DataRow(cells: [
            DataCell(
              Checkbox(
                value: r.selected,
                onChanged: (v) => onToggle(r.id, v ?? false),
              ),
            ),
            DataCell(Text('${i + 1}')),
            DataCell(Text(r.code)),
            DataCell(Text(r.title)),
            DataCell(Text('${r.theory.toStringAsFixed(1)} + ${r.practical.toStringAsFixed(1)} = ${r.credit.toStringAsFixed(1)}')),
            DataCell(
              SizedBox(
                width: 160,
                height: 40,
                child: TextField(
                  controller: r.teacherNameCtrl,
                  enabled: r.selected,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: 'Teacher name',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            DataCell(Text(advisorName.isNotEmpty ? advisorName : '—')),
            const DataCell(Text('Pending')),
            const DataCell(Text('Pending')),
            const DataCell(Text('-')),
          ]);
        }),
      ),
    );
  }
}

class _SignatureFooter extends StatelessWidget {
  const _SignatureFooter();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Signature of Student', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
          Text('Signature of Advisor', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
        ],
      ),
    );
  }
}
