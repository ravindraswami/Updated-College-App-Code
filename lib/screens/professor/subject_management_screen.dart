import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/subject_model.dart';
import '../../services/subject_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';
import '../../widgets/common_widgets.dart';

class SubjectManagementScreen extends StatefulWidget {
  final UserModel professor;
  const SubjectManagementScreen({super.key, required this.professor});
  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final _svc = SubjectService();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _selBranch;
  String? _selYear;
  String? _selSem;
  bool _adding = false;

  List<Map<String, dynamic>> get _years =>
      _selBranch != null ? AcademicData.yearsForBranch(_selBranch!) : [];
  List<Map<String, dynamic>> get _sems =>
      (_selBranch != null && _selYear != null)
      ? AcademicData.semsForYear(_selBranch!, _selYear!)
      : [];

  Future<void> _addSubject() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter subject name.', isError: true);
      return;
    }
    if (_selBranch == null || _selYear == null || _selSem == null) {
      _snack('Please select Branch, Year and Semester.', isError: true);
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
          addedBy: widget.professor.id,
          addedByName: widget.professor.name.isNotEmpty
              ? widget.professor.name
              : widget.professor.nameAsPerHsc,
          createdAt: DateTime.now(),
        ),
      );
      _nameCtrl.clear();
      _codeCtrl.clear();
      _snack(
        'Subject added successfully. It is now visible to all students and staff.',
        isError: false,
      );
    } catch (e) {
      _snack('Could not add subject. Please try again.', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subjects')),
      body: Column(
        children: [
          // ── Add subject form ───────────────────────────────
          Container(
            color: AppTheme.primary.withOpacity(0.04),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Subject',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name *',
                          prefixIcon: Icon(Icons.book_outlined),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                          hintText: 'BT101',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Branch
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
                if (_years.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                            labelText: 'Semester *',
                            isDense: true,
                          ),
                          hint: const Text('Semester'),
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
                          onChanged: (v) => setState(() => _selSem = v),
                        ),
                      ),
                    ],
                  ),
                ],
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
                    label: const Text('Add Subject'),
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
                final subjects = snap.data!;
                if (subjects.isEmpty) {
                  return const EmptyWidget(
                    message: 'No subjects added yet.',
                    icon: Icons.book_outlined,
                  );
                }
                // Group by semester
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(bottom: 6, top: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ...list.map(
                          (sub) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sub.code.isNotEmpty ? sub.code : '—',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                sub.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Added by: ${sub.addedByName}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: sub.addedBy == widget.professor.id
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppTheme.error,
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmDelete(ctx, sub),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
