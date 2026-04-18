
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_exam_screen.dart';
import 'add_questions_screen.dart';

class ExamManagementScreen extends StatelessWidget {
  final String professorId;
  const ExamManagementScreen({super.key, required this.professorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateExamScreen(professorId: professorId)),
        ),
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.add),
        label: const Text('New Exam'),
      ),
      body: StreamBuilder(
        stream: ExamService().getExamsByProfessor(professorId),
        builder: (ctx, snap) {
          if (!snap.hasData) return const LoadingWidget();
          final exams = snap.data!;
          if (exams.isEmpty) return const EmptyWidget(message: 'No exams created yet\nTap + to create one', icon: Icons.quiz_outlined);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (_, i) => _ExamManagementCard(exam: exams[i], professorId: professorId),
          );
        },
      ),
    );
  }
}

class _ExamManagementCard extends StatelessWidget {
  final ExamModel exam;
  final String professorId;
  const _ExamManagementCard({required this.exam, required this.professorId});

  void _deleteExam(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text('Delete "${exam.title}"? This also removes all questions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) await ExamService().deleteExam(exam.id);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(exam.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'questions', child: Row(children: [Icon(Icons.quiz, size: 18), SizedBox(width: 8), Text('Questions')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
                onSelected: (v) {
                  if (v == 'delete') _deleteExam(context);
                  if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => CreateExamScreen(professorId: professorId, editExam: exam)));
                  if (v == 'questions') Navigator.push(context, MaterialPageRoute(builder: (_) => AddQuestionsScreen(exam: exam)));
                },
              ),
            ]),
            Text(exam.subject, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(children: [
              _chip(Icons.calendar_today, DateFormat('dd MMM yyyy').format(exam.examDate)),
              const SizedBox(width: 8),
              _chip(Icons.timer, '${exam.durationMinutes} min'),
              const SizedBox(width: 8),
              _chip(Icons.quiz, '${exam.totalQuestions} Qs'),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _chip(Icons.currency_rupee, exam.price.toStringAsFixed(0)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddQuestionsScreen(exam: exam)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add Questions'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.secondary),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    ),
  );
}
