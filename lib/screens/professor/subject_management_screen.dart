import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/subject_model.dart';
import '../../services/subject_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../widgets/common_widgets.dart';

/// Thin wrapper that gives SubjectManagementBody its own Scaffold + AppBar
/// for use when pushed as a full screen (e.g. from Professor dashboard).
class SubjectManagementScreen extends StatelessWidget {
  final UserModel user;
  final bool canAdd;
  final String fixedBranch;
  const SubjectManagementScreen({
    super.key,
    required this.user,
    this.canAdd = false,
    this.fixedBranch = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subjects')),
      body: SubjectManagementBody(
        user: user,
        canAdd: canAdd,
        fixedBranch: fixedBranch,
      ),
    );
  }
}

/// Reusable body (no Scaffold/AppBar) — safe to embed inside a tab.
class SubjectManagementBody extends StatefulWidget {
  final UserModel user;
  final bool canAdd;
  final String fixedBranch; // '' = free choice; else locked to this branch
  const SubjectManagementBody({
    super.key,
    required this.user,
    this.canAdd = false,
    this.fixedBranch = '',
  });
  @override
  State<SubjectManagementBody> createState() => _SubjectManagementBodyState();
}

class _SubjectManagementBodyState extends State<SubjectManagementBody> {
  final _svc = SubjectService();
  final _userSvc = UserService();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _theoryCtrl = TextEditingController();
  final _practicalCtrl = TextEditingController();
  final _regFeeCtrl = TextEditingController();
  final _blFeeCtrl = TextEditingController();

  String? _selBranch;
  String? _selYear;
  String? _selSem;
  String? _selScheme;
  String? _selTeacherId;
  String? _selTeacherName;
  bool _adding = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    if (widget.fixedBranch.isNotEmpty) {
      _selBranch = widget.fixedBranch;
    }
  }

  static const _schemes = ['Old', 'New', 'NEP'];

  List<Map<String, dynamic>> get _years =>
      _selBranch != null ? AcademicData.yearsForBranch(_selBranch!) : [];
  List<Map<String, dynamic>> get _sems =>
      (_selBranch != null && _selYear != null)
      ? AcademicData.semsForYear(_selBranch!, _selYear!)
      : [];

  double get _totalCredit =>
      (double.tryParse(_theoryCtrl.text.trim()) ?? 0) +
      (double.tryParse(_practicalCtrl.text.trim()) ?? 0);

  Future<void> _addSubject() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter subject / course name.', isError: true);
      return;
    }
    if (_selBranch == null || _selYear == null || _selSem == null) {
      _snack('Please select Branch, Year and Semester.', isError: true);
      return;
    }
    if (_selScheme == null) {
      _snack('Please select scheme (Old / New / NEP).', isError: true);
      return;
    }
    setState(() => _adding = true);
    try {
      await _svc.addSubject(
        SubjectModel(
          id: '',
          name: _nameCtrl.text.trim(),
          code: _codeCtrl.text.trim().toUpperCase(),
          branch: _selBranch!,
          year: _selYear!,
          semester: _selSem!,
          scheme: _selScheme!,
          theoryCredit: double.tryParse(_theoryCtrl.text.trim()) ?? 0,
          practicalCredit: double.tryParse(_practicalCtrl.text.trim()) ?? 0,
          addedBy: widget.user.id,
          addedByName: widget.user.name.isNotEmpty
              ? widget.user.name
              : widget.user.nameAsPerHsc,
          createdAt: DateTime.now(),
          regularFee: double.tryParse(_regFeeCtrl.text.trim()) ?? 0,
          backlogFee: double.tryParse(_blFeeCtrl.text.trim()) ?? 0,
          teacherId: _selTeacherId ?? '',
          teacherName: _selTeacherName ?? '',
        ),
      );
      _nameCtrl.clear();
      _codeCtrl.clear();
      _theoryCtrl.clear();
      _practicalCtrl.clear();
      _regFeeCtrl.clear();
      _blFeeCtrl.clear();
      setState(() {
        _selTeacherId = null;
        _selTeacherName = null;
      });
      _snack('Course added successfully.', isError: false);
    } catch (e) {
      _snack('Could not add course. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _editFees(SubjectModel sub) async {
    final regCtrl = TextEditingController(
        text: sub.regularFee > 0 ? sub.regularFee.toStringAsFixed(0) : '');
    final blCtrl = TextEditingController(
        text: sub.backlogFee > 0 ? sub.backlogFee.toStringAsFixed(0) : '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Set Fees — ${sub.name}', overflow: TextOverflow.ellipsis),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sub.branch} • ${sub.semester}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: regCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Regular Exam Fee (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: 'e.g. 100',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: blCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Backlog / ATKT Fee (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: 'e.g. 200',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These fees will be shown to students when they fill the exam form.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Fees'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final regFee = double.tryParse(regCtrl.text.trim()) ?? 0;
    final blFee = double.tryParse(blCtrl.text.trim()) ?? 0;
    await _svc.updateFees(sub.id, regFee, blFee);
    _snack('Fees updated for ${sub.name}.', isError: false);
  }

  Future<void> _editTeacher(SubjectModel sub) async {
    return showDialog(
      context: context,
      builder: (_) => _TeacherPickerDialog(
        subject: sub,
        userSvc: _userSvc,
        onPicked: (id, name) async {
          await _svc.assignTeacher(sub.id, id, name);
          if (mounted) {
            _snack('Course Teacher updated for ${sub.name}.', isError: false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Info banner for non-adding roles ────────────────
        if (!widget.canAdd)
          Container(
            width: double.infinity,
            color: Colors.blue.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only the UG Incharge / PG Incharge can add new subjects.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),

        // ── Add subject: collapsible to avoid clutter ───────
        if (widget.canAdd)
          Container(
            color: AppTheme.primary.withOpacity(0.04),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _showForm = !_showForm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Add New Course',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          _showForm
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showForm)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Branch (locked if this Incharge is scoped)
                        if (widget.fixedBranch.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.school_outlined,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AcademicData.branchFullLabel(
                                        widget.fixedBranch),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selBranch,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Branch *',
                              isDense: true,
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            hint: const Text('Select Branch'),
                            items: AcademicData.branches
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b['id'] as String,
                                    child: Text(
                                      b['label'] as String,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selBranch = v;
                              _selYear = null;
                              _selSem = null;
                            }),
                          ),

                        // 2. Year + 3. Semester
                        if (_years.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selYear,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Year *',
                                    isDense: true,
                                  ),
                                  hint: const Text('Year'),
                                  items: _years
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y['id'] as String,
                                          child: Text(
                                            y['label'] as String,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() {
                                    _selYear = v;
                                    _selSem = null;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selSem,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Sem *',
                                    isDense: true,
                                  ),
                                  hint: const Text('Sem'),
                                  items: _sems
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s['id'] as String,
                                          child: Text(
                                            s['label'] as String,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selSem = v),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 4. Scheme: Old / New / NEP
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selScheme,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Scheme *',
                            isDense: true,
                            prefixIcon: Icon(Icons.rule_folder_outlined),
                          ),
                          hint: const Text('Old / New / NEP'),
                          items: _schemes
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _selScheme = v),
                        ),

                        // 5. Course Code + 6. Course Name
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Course Code',
                            hintText: 'BT101',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Course Name *',
                            prefixIcon: Icon(Icons.book_outlined),
                            isDense: true,
                          ),
                        ),

                        // 7. Credit: Theory + Practical = Total
                        const SizedBox(height: 10),
                        StatefulBuilder(
                          builder: (context, setLocal) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _theoryCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Theory',
                                        isDense: true,
                                      ),
                                      onChanged: (_) => setLocal(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _practicalCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Practical',
                                        isDense: true,
                                      ),
                                      onChanged: (_) => setLocal(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Total Credit: ${_totalCredit.toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // 8. Course Teacher
                        const SizedBox(height: 10),
                        StreamBuilder<List<UserModel>>(
                          stream: _userSvc.getUsersByRole('professor'),
                          builder: (ctx, snap) {
                            final teachers = snap.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: _selTeacherId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Course Teacher',
                                isDense: true,
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              hint:
                                  const Text('Select Course Teacher (optional)'),
                              items: teachers
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(
                                        t.name.isNotEmpty
                                            ? t.name
                                            : t.nameAsPerHsc,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                final t =
                                    teachers.firstWhere((e) => e.id == v);
                                setState(() {
                                  _selTeacherId = v;
                                  _selTeacherName = t.name.isNotEmpty
                                      ? t.name
                                      : t.nameAsPerHsc;
                                });
                              },
                            );
                          },
                        ),

                        // 9. Fees: Regular + Backlog
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _regFeeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Regular ₹',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _blFeeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Backlog ₹',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _adding ? null : _addSubject,
                            icon: _adding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Add Course'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // ── Subject list ───────────────────────────────────
        Expanded(
          child: StreamBuilder<List<SubjectModel>>(
            stream: _svc.getAllSubjects(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const LoadingWidget();
              var subjects = snap.data!;
              if (widget.fixedBranch.isNotEmpty) {
                subjects = subjects
                    .where((s) => s.branch == widget.fixedBranch)
                    .toList();
              }
              if (subjects.isEmpty) {
                return const EmptyWidget(
                  message: 'No subjects added yet.',
                  icon: Icons.book_outlined,
                );
              }
              // Group by branch+semester
              final Map<String, List<SubjectModel>> grouped = {};
              for (final s in subjects) {
                final key = '${s.branch} — ${s.semester}';
                grouped.putIfAbsent(key, () => []).add(s);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: grouped.length,
                itemBuilder: (_, i) {
                  final key = grouped.keys.elementAt(i);
                  final list = grouped[key]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 6, top: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      ...list.map((sub) => _SubjectCard(
                            sub: sub,
                            canAdd: widget.canAdd,
                            isOwner: sub.addedBy == widget.user.id,
                            onEditTeacher: () => _editTeacher(sub),
                            onEditFees: () => _editFees(sub),
                            onDelete: () => _confirmDelete(ctx, sub),
                          )),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext ctx, SubjectModel sub) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Delete "${sub.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _svc.deleteSubject(sub.id);
              if (ctx.mounted) _snack('Subject deleted.', isError: false);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Subject card: Card + Padding + Column, no fixed-height overflow ──
class _SubjectCard extends StatelessWidget {
  final SubjectModel sub;
  final bool canAdd;
  final bool isOwner;
  final VoidCallback onEditTeacher;
  final VoidCallback onEditFees;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.sub,
    required this.canAdd,
    required this.isOwner,
    required this.onEditTeacher,
    required this.onEditFees,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sub.code.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sub.code,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (sub.code.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sub.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Scheme: ${sub.scheme}  •  Credit: ${sub.totalCredit.toStringAsFixed(1)} (T:${sub.theoryCredit.toStringAsFixed(1)} + P:${sub.practicalCredit.toStringAsFixed(1)})',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              sub.teacherName.isNotEmpty
                  ? 'Course Teacher: ${sub.teacherName}'
                  : 'Course Teacher: Not assigned',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: sub.teacherName.isNotEmpty
                    ? Colors.indigo
                    : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            if (sub.regularFee > 0 || sub.backlogFee > 0)
              Text(
                'Regular: ₹${sub.regularFee.toStringAsFixed(0)}  •  Backlog: ₹${sub.backlogFee.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.teal,
                    fontWeight: FontWeight.w500),
              )
            else
              const Text('No fees set yet',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 2,
              children: [
                if (canAdd)
                  IconButton(
                    icon: const Icon(Icons.person_add_alt,
                        color: Colors.indigo, size: 20),
                    tooltip: 'Assign Course Teacher',
                    onPressed: onEditTeacher,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                IconButton(
                  icon: const Icon(Icons.currency_rupee,
                      color: Colors.teal, size: 20),
                  tooltip: 'Set Fees',
                  onPressed: onEditFees,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.error, size: 20),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherPickerDialog extends StatefulWidget {
  final SubjectModel subject;
  final UserService userSvc;
  final Future<void> Function(String id, String name) onPicked;

  const _TeacherPickerDialog({
    required this.subject,
    required this.userSvc,
    required this.onPicked,
  });

  @override
  State<_TeacherPickerDialog> createState() => _TeacherPickerDialogState();
}

class _TeacherPickerDialogState extends State<_TeacherPickerDialog> {
  String? _selId;
  String? _selName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selId = widget.subject.teacherId.isNotEmpty ? widget.subject.teacherId : null;
    _selName = widget.subject.teacherName.isNotEmpty ? widget.subject.teacherName : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Course Teacher — ${widget.subject.name}',
          overflow: TextOverflow.ellipsis),
      content: SingleChildScrollView(
        child: StreamBuilder<List<UserModel>>(
          stream: widget.userSvc.getUsersByRole('professor'),
          builder: (ctx, snap) {
            final teachers = snap.data ?? [];
            if (!snap.hasData) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return DropdownButtonFormField<String>(
              value: _selId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Course Teacher',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: teachers
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.name.isNotEmpty ? t.name : t.nameAsPerHsc,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                final t = teachers.firstWhere((e) => e.id == v);
                setState(() {
                  _selId = v;
                  _selName = t.name.isNotEmpty ? t.name : t.nameAsPerHsc;
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving || _selId == null
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onPicked(_selId!, _selName!);
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
