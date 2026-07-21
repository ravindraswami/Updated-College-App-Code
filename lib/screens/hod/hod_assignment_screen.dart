import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/subject_model.dart';
import '../../models/class_advisor_assignment_model.dart';
import '../../services/subject_service.dart';
import '../../services/user_service.dart';
import '../../services/class_advisor_assignment_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../widgets/common_widgets.dart';

/// Thin wrapper with its own Scaffold + AppBar, for full-screen navigation.
class HodAssignmentScreen extends StatelessWidget {
  final UserModel hod;
  final String fixedBranch;
  const HodAssignmentScreen({super.key, required this.hod, this.fixedBranch = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Advisor & Course Teacher')),
      body: HodAssignmentBody(hod: hod, fixedBranch: fixedBranch),
    );
  }
}

/// Reusable body (no Scaffold/AppBar) — safe to embed inside a tab.
class HodAssignmentBody extends StatefulWidget {
  final UserModel hod;
  final String fixedBranch; // '' = free choice; else locked to this branch
  const HodAssignmentBody({super.key, required this.hod, this.fixedBranch = ''});

  @override
  State<HodAssignmentBody> createState() => _HodAssignmentBodyState();
}

class _HodAssignmentBodyState extends State<HodAssignmentBody> {
  final _subjectSvc = SubjectService();
  final _userSvc = UserService();
  final _advisorSvc = ClassAdvisorAssignmentService();

  final _regStartCtrl = TextEditingController();
  final _regEndCtrl = TextEditingController();

  String _selBranch = AcademicData.branches.first['id'] as String;
  String? _selSemChip; // currently expanded semester id
  String? _selAdvisorYear;
  String? _selAdvisorId;
  String? _selAdvisorName;
  bool _savingAdvisor = false;

  @override
  void initState() {
    super.initState();
    if (widget.fixedBranch.isNotEmpty) {
      _selBranch = widget.fixedBranch;
    }
  }

  /// Returns all {year, sem} pairs for the selected branch, flattened.
  List<Map<String, String>> get _allSemsForBranch {
    final years = AcademicData.yearsForBranch(_selBranch);
    final result = <Map<String, String>>[];
    for (final y in years) {
      final sems = AcademicData.semsForYear(_selBranch, y['id'] as String);
      for (final s in sems) {
        result.add({
          'yearId': y['id'] as String,
          'yearLabel': y['label'] as String,
          'semId': s['id'] as String,
          'semLabel': s['label'] as String,
        });
      }
    }
    return result;
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addAdvisorAssignment() async {
    final start = _regStartCtrl.text.trim();
    final end = _regEndCtrl.text.trim();
    if (start.isEmpty || end.isEmpty) {
      _snack('Please enter register number range.', isError: true);
      return;
    }
    if (_selAdvisorYear == null) {
      _snack('Please select year.', isError: true);
      return;
    }
    if (_selAdvisorId == null) {
      _snack('Please select an Advisor.', isError: true);
      return;
    }
    setState(() => _savingAdvisor = true);
    try {
      await _advisorSvc.addAssignment(
        ClassAdvisorAssignmentModel(
          id: '',
          branch: _selBranch,
          year: _selAdvisorYear!,
          regNoStart: start,
          regNoEnd: end,
          advisorId: _selAdvisorId!,
          advisorName: _selAdvisorName!,
          createdAt: DateTime.now(),
        ),
      );
      _regStartCtrl.clear();
      _regEndCtrl.clear();
      setState(() {
        _selAdvisorId = null;
        _selAdvisorName = null;
      });
      _snack('Advisor assigned for range $start – $end.');
    } catch (e) {
      _snack('Could not save assignment. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _savingAdvisor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branch selector (locked if this Incharge is scoped) ──
          if (widget.fixedBranch.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AcademicData.branchFullLabel(widget.fixedBranch),
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
                labelText: 'Branch',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: AcademicData.branches
                  .map(
                    (b) => DropdownMenuItem(
                      value: b['id'] as String,
                      child: Text(b['label'] as String,
                          overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _selBranch = v!;
                _selSemChip = null;
                _selAdvisorYear = null;
              }),
            ),

          const SizedBox(height: 20),
          const Text(
            'Course Teacher Assignment — by Semester',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a semester to view its subjects and assign a Course Teacher.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          // ── Semester chips ───────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSemsForBranch.map((s) {
              final selected = _selSemChip == s['semId'];
              return ChoiceChip(
                label: Text(s['semLabel']!, style: const TextStyle(fontSize: 12)),
                selected: selected,
                selectedColor: AppTheme.primary.withOpacity(0.2),
                onSelected: (_) => setState(
                  () => _selSemChip = selected ? null : s['semId'],
                ),
              );
            }).toList(),
          ),

          if (_selSemChip != null) ...[
            const SizedBox(height: 14),
            _SemesterSubjectsPanel(
              branch: _selBranch,
              semester: _selSemChip!,
              subjectSvc: _subjectSvc,
              userSvc: _userSvc,
            ),
          ],

          const Divider(height: 40),

          // ── Class Advisor Assignment ─────────────────────
          const Text(
            'Class Advisor Assignment — by Register No. Range',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'e.g. 001–025 → Advisor A, 026–050 → Advisor B, etc.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: _selAdvisorYear,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Year',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: AcademicData.yearsForBranch(_selBranch)
                .map(
                  (y) => DropdownMenuItem(
                    value: y['id'] as String,
                    child: Text(y['label'] as String,
                        overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selAdvisorYear = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _regStartCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reg No From',
                    hintText: 'e.g. 001',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _regEndCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reg No To',
                    hintText: 'e.g. 025',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<UserModel>>(
            stream: _userSvc.getUsersByRole('coordinator'),
            builder: (ctx, snap) {
              final advisors = snap.data ?? [];
              return DropdownButtonFormField<String>(
                value: _selAdvisorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Advisor',
                  isDense: true,
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                items: advisors
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          a.name.isNotEmpty ? a.name : a.nameAsPerHsc,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  final a = advisors.firstWhere((e) => e.id == v);
                  setState(() {
                    _selAdvisorId = v;
                    _selAdvisorName = a.name.isNotEmpty ? a.name : a.nameAsPerHsc;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savingAdvisor ? null : _addAdvisorAssignment,
              icon: _savingAdvisor
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Assign Advisor to Range'),
            ),
          ),

          const SizedBox(height: 16),
          StreamBuilder<List<ClassAdvisorAssignmentModel>>(
            stream: _advisorSvc.getAssignments(_selBranch),
            builder: (ctx, snap) {
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No advisor assignments yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                );
              }
              return Column(
                children: list.map((a) => _AdvisorCard(
                      assignment: a,
                      onDelete: () async {
                        await _advisorSvc.deleteAssignment(a.id);
                        if (context.mounted) _snack('Assignment removed.');
                      },
                    )).toList(),
              );
            },
          ),

          const Divider(height: 40),

          // ── Bottom Summary ────────────────────────────────
          const Text(
            'Summary',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 10),
          _SummaryPanel(
            branch: _selBranch,
            subjectSvc: _subjectSvc,
            advisorSvc: _advisorSvc,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Advisor assignment card (Card+Padding, no ListTile overflow) ──
class _AdvisorCard extends StatelessWidget {
  final ClassAdvisorAssignmentModel assignment;
  final VoidCallback onDelete;

  const _AdvisorCard({required this.assignment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.groups_outlined, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reg No ${a.rangeLabel}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    AcademicData.yearFullLabel(a.year),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    'Advisor: ${a.advisorName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subjects list for one semester, with teacher-assign dropdown per row ──
class _SemesterSubjectsPanel extends StatelessWidget {
  final String branch;
  final String semester;
  final SubjectService subjectSvc;
  final UserService userSvc;

  const _SemesterSubjectsPanel({
    required this.branch,
    required this.semester,
    required this.subjectSvc,
    required this.userSvc,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubjectModel>>(
      stream: subjectSvc.getSubjectsBySemester(branch, semester),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final subjects = snap.data!;
        if (subjects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No subjects added for this semester yet.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }
        return StreamBuilder<List<UserModel>>(
          stream: userSvc.getUsersByRole('professor'),
          builder: (ctx2, snap2) {
            final teachers = snap2.data ?? [];
            return Column(
              children: subjects.map((sub) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          'Credit: ${sub.totalCredit.toStringAsFixed(1)}  •  ${sub.scheme}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: sub.teacherId.isNotEmpty ? sub.teacherId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Course Teacher',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Not assigned'),
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
                            if (v == null) return;
                            final t = teachers.firstWhere((e) => e.id == v);
                            subjectSvc.assignTeacher(
                              sub.id,
                              v,
                              t.name.isNotEmpty ? t.name : t.nameAsPerHsc,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// ── Bottom summary: subject->teacher counts + advisor range counts ──
class _SummaryPanel extends StatelessWidget {
  final String branch;
  final SubjectService subjectSvc;
  final ClassAdvisorAssignmentService advisorSvc;

  const _SummaryPanel({
    required this.branch,
    required this.subjectSvc,
    required this.advisorSvc,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SubjectModel>>(
      stream: subjectSvc.getAllSubjects(),
      builder: (ctx, subSnap) {
        final allSubjects =
            (subSnap.data ?? []).where((s) => s.branch == branch).toList();
        final assignedCount =
            allSubjects.where((s) => s.teacherName.isNotEmpty).length;
        final unassignedCount = allSubjects.length - assignedCount;

        return StreamBuilder<List<ClassAdvisorAssignmentModel>>(
          stream: advisorSvc.getAssignments(branch),
          builder: (ctx2, advSnap) {
            final advList = advSnap.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use a Wrap instead of a tight Row so cards reflow on
                // narrow screens instead of overflowing to the right.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statCard('Total Subjects', allSubjects.length.toString(),
                        Icons.book_outlined, AppTheme.primary),
                    _statCard('Teacher Assigned', assignedCount.toString(),
                        Icons.check_circle_outline, Colors.green),
                    _statCard('Not Assigned', unassignedCount.toString(),
                        Icons.error_outline, Colors.orange),
                    _statCard('Advisor Assignments', advList.length.toString(),
                        Icons.groups_outlined, Colors.indigo),
                  ],
                ),
                const SizedBox(height: 14),
                if (allSubjects.isNotEmpty) ...[
                  const Text(
                    'Subject → Course Teacher',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...allSubjects.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${s.displayName}  →  ${s.teacherName.isNotEmpty ? s.teacherName : "Not assigned"}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: s.teacherName.isNotEmpty
                              ? Colors.black87
                              : Colors.orange[800],
                        ),
                      ),
                    ),
                  ),
                ],
                if (advList.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Reg No Range → Advisor',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...advList.map(
                    (a) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${a.rangeLabel} (${AcademicData.yearFullLabel(a.year)})  →  ${a.advisorName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
