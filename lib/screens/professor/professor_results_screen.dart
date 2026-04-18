import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/exam_service.dart';
import '../../services/user_service.dart';
import '../../models/result_model.dart';
import '../../models/exam_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProfessorResultsScreen extends StatelessWidget {
  final String professorId;
  const ProfessorResultsScreen({super.key, required this.professorId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppTheme.secondary,
            indicatorColor: AppTheme.secondary,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'Exam Results'),
              Tab(icon: Icon(Icons.people), text: 'All Students'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ExamResultsTab(professorId: professorId),
                const _AllStudentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TAB 1: Exam results with publish + re-exam toggle ───────
class _ExamResultsTab extends StatelessWidget {
  final String professorId;
  const _ExamResultsTab({required this.professorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ExamService().getExamsByProfessor(professorId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final exams = snap.data!;
        if (exams.isEmpty) {
          return const EmptyWidget(
            message: 'No exams created yet',
            icon: Icons.quiz_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (_, i) => _ExamResultCard(exam: exams[i]),
        );
      },
    );
  }
}

class _ExamResultCard extends StatelessWidget {
  final ExamModel exam;
  const _ExamResultCard({required this.exam});

  Future<void> _togglePublish(BuildContext context) async {
    final svc = ExamService();
    if (exam.isResultPublished) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hide Results?'),
          content: const Text('Students will no longer see their results.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Hide'),
            ),
          ],
        ),
      );
      if (confirm == true) await svc.unpublishResult(exam.id);
    } else {
      await svc.publishResult(exam.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Results published for "${exam.title}"'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleReExam(BuildContext context) async {
    final svc = ExamService();
    if (exam.isReExamAllowed) {
      await svc.disallowReExam(exam.id);
    } else {
      await svc.allowReExam(exam.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-exam enabled for "${exam.title}"'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // ── Exam header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.quiz, color: AppTheme.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            exam.subject,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Toggle buttons row ──
                Row(
                  children: [
                    // Publish toggle
                    Expanded(
                      child: _ToggleButton(
                        label: exam.isResultPublished
                            ? 'Published'
                            : 'Publish Result',
                        icon: exam.isResultPublished
                            ? Icons.visibility
                            : Icons.visibility_off,
                        active: exam.isResultPublished,
                        activeColor: AppTheme.success,
                        onTap: () => _togglePublish(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Re-exam toggle
                    Expanded(
                      child: _ToggleButton(
                        label: exam.isReExamAllowed
                            ? 'Re-exam ON'
                            : 'Allow Re-exam',
                        icon: exam.isReExamAllowed
                            ? Icons.replay_circle_filled
                            : Icons.replay,
                        active: exam.isReExamAllowed,
                        activeColor: AppTheme.secondary,
                        onTap: () => _toggleReExam(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Student results list ──
          StreamBuilder<List<ResultModel>>(
            stream: ExamService().getResultsByExam(exam.id),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingWidget(),
                );
              }
              final results = snap.data!;
              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'No students have attempted yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final avg =
                  results.map((r) => r.percentage).reduce((a, b) => a + b) /
                  results.length;
              final pass = results.where((r) => r.percentage >= 75).length;

              return Column(
                children: [
                  // Class average
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.analytics,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avg: ${avg.toStringAsFixed(1)}%   |   Pass: $pass/${results.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Individual results
                  ...results.map(
                    (r) => _StudentResultTile(
                      result: r,
                      exam: exam,
                      showReExamReset: exam.isReExamAllowed,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentResultTile extends StatelessWidget {
  final ResultModel result;
  final ExamModel exam;
  final bool showReExamReset;
  const _StudentResultTile({
    required this.result,
    required this.exam,
    required this.showReExamReset,
  });

  @override
  Widget build(BuildContext context) {
    final color = result.percentage >= 75 ? AppTheme.success : AppTheme.error;
    return FutureBuilder<UserModel?>(
      future: UserService().getUser(result.studentId),
      builder: (ctx, userSnap) {
        final student = userSnap.data;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              CircularPercentIndicator(
                radius: 22,
                lineWidth: 4,
                percent: (result.percentage / 100).clamp(0.0, 1.0),
                center: Text(
                  '${result.percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: color,
                backgroundColor: Colors.grey[200]!,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.name ?? 'Student',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (student?.erpId.isNotEmpty == true)
                      Text(
                        student!.erpId,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    Text(
                      'Score: ${result.score}/${result.totalQuestions}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.percentage >= 75 ? 'PASS' : 'FAIL',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              // Reset button when re-exam is enabled
              if (showReExamReset) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.restart_alt,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                  tooltip: 'Reset attempt for this student',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Reset Attempt?'),
                        content: Text(
                          'Reset attempt for ${student?.name ?? "this student"}?\nThey can re-take the exam.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                            ),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ExamService().resetStudentAttempt(
                        studentId: result.studentId,
                        examId: exam.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Attempt reset! Student can re-take.',
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── TAB 2: All Students list ────────────────────────────────
class _AllStudentsTab extends StatelessWidget {
  const _AllStudentsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: UserService().getUsersByRole('student'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = snap.data!;
        if (students.isEmpty) {
          return const EmptyWidget(
            message: 'No students registered yet',
            icon: Icons.school_outlined,
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.secondary.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.people, color: AppTheme.secondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${students.length} Students Registered',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (_, i) => _StudentTile(student: students[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentTile extends StatelessWidget {
  final UserModel student;
  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.12),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.email, style: const TextStyle(fontSize: 12)),
            if (student.erpId.isNotEmpty)
              Text(
                student.erpId,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              student.department,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              student.year,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable toggle button ───────────────────────────────────
class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? activeColor : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? activeColor : Colors.grey),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: active ? activeColor : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
