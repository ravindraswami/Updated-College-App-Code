import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/exam_service.dart';
import '../../services/auth_service.dart';
import '../../models/result_model.dart';
import '../../models/exam_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../result/certificate_screen.dart';

class MyResultsScreen extends StatelessWidget {
  final String studentId;
  const MyResultsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    if (studentId.isEmpty) return const LoadingWidget();
    return StreamBuilder(
      stream: ExamService().getResultsByStudent(studentId),
      builder: (ctx, resultSnap) {
        if (!resultSnap.hasData) return const LoadingWidget();
        final results = resultSnap.data!;
        if (results.isEmpty) {
          return const EmptyWidget(
            message: 'No exams attempted yet',
            icon: Icons.bar_chart_outlined,
          );
        }

        return StreamBuilder(
          stream: ExamService().getExams(),
          builder: (ctx2, examSnap) {
            if (!examSnap.hasData) return const LoadingWidget();
            final examMap = {for (final e in examSnap.data!) e.id: e};

            final published = results
                .where((r) => examMap[r.examId]?.isResultPublished == true)
                .toList();
            final pending = results
                .where((r) => examMap[r.examId]?.isResultPublished != true)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (published.isNotEmpty) ...[
                    _StatsHeader(results: published),
                    const SizedBox(height: 20),
                    const Text(
                      'Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...published.map(
                      (r) => _ResultCard(
                        result: r,
                        exam: examMap[r.examId],
                        studentId: studentId,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (pending.isNotEmpty) ...[
                    const Text(
                      'Awaiting Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pending.map(
                      (r) => _PendingResultCard(exam: examMap[r.examId]),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final List<ResultModel> results;
  const _StatsHeader({required this.results});
  @override
  Widget build(BuildContext context) {
    final avg =
        results.map((r) => r.percentage).reduce((a, b) => a + b) /
        results.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 45,
              lineWidth: 8,
              percent: (avg / 100).clamp(0.0, 1.0),
              center: Text(
                '${avg.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              progressColor: AppTheme.primary,
              backgroundColor: Colors.grey[200]!,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Performance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${results.length} result(s) published',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Avg: ${avg.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ResultModel result;
  final ExamModel? exam;
  final String studentId;
  const _ResultCard({
    required this.result,
    required this.exam,
    required this.studentId,
  });

  Color get _color {
    if (result.percentage >= 75) return AppTheme.success;
    if (result.percentage >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final passed = result.percentage >= 50;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 35,
                  lineWidth: 6,
                  percent: (result.percentage / 100).clamp(0.0, 1.0),
                  center: Text(
                    '${result.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                  progressColor: _color,
                  backgroundColor: Colors.grey[200]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam?.title ?? 'Exam',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score: ${result.score}/${result.totalQuestions}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        '${result.answers.length} attempted · '
                        '${result.totalQuestions - result.answers.length} skipped',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    passed ? 'PASS' : 'FAIL',
                    style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Certificate button if passed
            if (passed && exam != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openCertificate(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB8860B),
                    side: const BorderSide(color: Color(0xFFB8860B)),
                  ),
                  icon: const Icon(Icons.workspace_premium, size: 18),
                  label: const Text('View Certificate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCertificate(BuildContext context) async {
    final student = await AuthService().getCurrentUserModel();
    if (student == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CertificateScreen(result: result, exam: exam!, student: student),
      ),
    );
  }
}

class _PendingResultCard extends StatelessWidget {
  final ExamModel? exam;
  const _PendingResultCard({required this.exam});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_clock,
                color: AppTheme.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam?.title ?? 'Exam',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Result not published yet',
                    style: TextStyle(color: AppTheme.warning, fontSize: 13),
                  ),
                  const Text(
                    'Waiting for professor to publish',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
