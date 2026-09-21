import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../services/exam_form_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../exam_form/registration_pdf.dart';

class _TeacherRow {
  final ExamFormModel form;
  final String subjectId;
  final String subjectCode;
  final String subjectTitle;
  final bool isBacklog;
  _TeacherRow({
    required this.form,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectTitle,
    required this.isBacklog,
  });
}

/// Course Teacher: sees ONLY the subject(s) assigned to them, and only the
/// students who registered for that subject — never other subjects.
class CourseTeacherRegistrationScreen extends StatelessWidget {
  final String teacherId;
  final String teacherName;
  const CourseTeacherRegistrationScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    final svc = ExamFormService();
    return StreamBuilder<List<ExamFormModel>>(
      stream: svc.getPendingForTeacher(teacherId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final forms = snap.data!;
        final rows = <_TeacherRow>[];
        for (final f in forms) {
          for (final id in f.subjectIds) {
            if (f.subjectTeacherIds[id] == teacherId &&
                (f.teacherSignatures[id] ?? '').isEmpty) {
              rows.add(_TeacherRow(
                form: f,
                subjectId: id,
                subjectCode: f.subjectCodes[id] ?? '',
                subjectTitle: f.subjectTitles[id] ?? '',
                isBacklog: false,
              ));
            }
          }
          for (final id in f.backlogSubjectIds) {
            if (f.backlogSubjectTeacherIds[id] == teacherId &&
                (f.teacherSignatures[id] ?? '').isEmpty) {
              rows.add(_TeacherRow(
                form: f,
                subjectId: id,
                subjectCode: f.backlogSubjectCodes[id] ?? '',
                subjectTitle: f.backlogSubjectTitles[id] ?? '',
                isBacklog: true,
              ));
            }
          }
        }

        if (rows.isEmpty) {
          return const EmptyWidget(
            message: 'No students pending your sign-off right now.',
            icon: Icons.school_outlined,
          );
        }

        final grouped = <String, List<_TeacherRow>>{};
        for (final r in rows) {
          grouped.putIfAbsent(r.subjectTitle, () => []).add(r);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries
              .map((e) => _SubjectGroupCard(
                    subjectTitle: e.key,
                    rows: e.value,
                    teacherId: teacherId,
                    teacherName: teacherName,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _SubjectGroupCard extends StatelessWidget {
  final String subjectTitle;
  final List<_TeacherRow> rows;
  final String teacherId;
  final String teacherName;
  const _SubjectGroupCard({
    required this.subjectTitle,
    required this.rows,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subjectTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text('${rows.length} pending',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Divider(),
            ...rows.map((r) => _StudentRow(row: r, teacherId: teacherId, teacherName: teacherName)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => printCourseTeacherTable(
                  context,
                  rows.first.subjectCode,
                  subjectTitle,
                  rows
                      .map((r) => CourseTeacherRow(
                            form: r.form,
                            subjectId: r.subjectId,
                            isBacklog: r.isBacklog,
                          ))
                      .toList(),
                ),
                icon: const Icon(Icons.image_outlined, size: 16),
                label: const Text('Generate Student List'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final _TeacherRow row;
  final String teacherId;
  final String teacherName;
  const _StudentRow({required this.row, required this.teacherId, required this.teacherName});

  Future<void> _sign(BuildContext context, String signature) async {
    await ExamFormService().teacherSignSubject(
      formId: row.form.id,
      subjectId: row.subjectId,
      teacherUid: teacherId,
      signature: signature,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed "$signature" for ${row.form.name}'), backgroundColor: AppTheme.success),
      );
    }
  }

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Registration Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rejecting the whole registration form for ${row.form.name}. '
              'They will need to pay the fee and fill the form again.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final reason = ctrl.text.trim().isNotEmpty
        ? ctrl.text.trim()
        : 'Rejected by Course Teacher';
    await ExamFormService().teacherRejectForm(row.form.id, teacherName, reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${row.form.name}\'s registration form.'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = row.form;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${f.year} / ${f.semester} · ${row.isBacklog ? 'Backlog' : 'Regular'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.error, size: 20),
            tooltip: 'Reject Form',
            onPressed: () => _reject(context),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (v) => _sign(context, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'RR', child: Text('RR — Regular')),
              PopupMenuItem(value: 'OFE', child: Text('OFE')),
              PopupMenuItem(value: 'NR', child: Text('NR — Not Registered')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sign', style: TextStyle(fontSize: 12.5, color: AppTheme.primary)),
                  Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
