import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../payment/payment_screen.dart';
import '../exam/exam_start_screen.dart';

class ExamListScreen extends StatefulWidget {
  final String studentId;
  final String branch;
  final String semester;
  const ExamListScreen({
    super.key,
    required this.studentId,
    this.branch = '',
    this.semester = '',
  });
  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _examService = ExamService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: StreamBuilder(
            stream: (widget.branch.isNotEmpty)
                ? _examService.getExamsForStudent(
                    branch: widget.branch,
                    semester: widget.semester,
                  )
                : _examService.getExams(),
            builder: (ctx, examSnap) {
              if (!examSnap.hasData) return const LoadingWidget();
              final all = examSnap.data!;
              return StreamBuilder(
                stream: _examService.getResultsByStudent(widget.studentId),
                builder: (ctx2, resultSnap) {
                  final attemptedExamIds = (resultSnap.data ?? [])
                      .map((r) => r.examId)
                      .toSet();

                  // An exam is "completed" for THIS student once they've
                  // submitted it, even if the exam window is still globally
                  // 'ongoing' — plus any exam the college has marked
                  // 'completed' overall.
                  final completedExams = all
                      .where(
                        (e) =>
                            e.status == 'completed' ||
                            attemptedExamIds.contains(e.id),
                      )
                      .toList();
                  final ongoingExams = all
                      .where(
                        (e) =>
                            e.status == 'ongoing' &&
                            !attemptedExamIds.contains(e.id),
                      )
                      .toList();
                  final upcomingExams = all
                      .where((e) => e.status == 'upcoming')
                      .toList();

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'You have completed ${attemptedExamIds.length} of ${all.length} exam(s)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _ExamList(
                              exams: upcomingExams,
                              studentId: widget.studentId,
                              examService: _examService,
                            ),
                            _ExamList(
                              exams: ongoingExams,
                              studentId: widget.studentId,
                              examService: _examService,
                            ),
                            _ExamList(
                              exams: completedExams,
                              studentId: widget.studentId,
                              examService: _examService,
                            ),
                          ],
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
    );
  }
}

class _ExamList extends StatelessWidget {
  final List<ExamModel> exams;
  final String studentId;
  final ExamService examService;
  const _ExamList({
    required this.exams,
    required this.studentId,
    required this.examService,
  });

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const EmptyWidget(
        message: 'No exams in this category',
        icon: Icons.quiz_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (_, i) => _ExamCard(
        exam: exams[i],
        studentId: studentId,
        examService: examService,
      ),
    );
  }
}

// ─── Exam card state enum ─────────────────────────────────────
enum _CardState {
  loading,
  notEnrolled, // hasn't paid
  enrolled, // paid, hasn't attempted
  attempted, // already submitted — locked
  reExamGranted, // professor allowed re-attempt
}

class _ExamCard extends StatefulWidget {
  final ExamModel exam;
  final String studentId;
  final ExamService examService;
  const _ExamCard({
    required this.exam,
    required this.studentId,
    required this.examService,
  });
  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  _CardState _state = _CardState.loading;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (widget.studentId.isEmpty) return;

    // 1. Check if already attempted
    final result = await widget.examService.getResult(
      widget.studentId,
      widget.exam.id,
    );

    if (result != null) {
      // Has a result — re-exam is only granted to FAILED students
      // (percentage < 75), even when the exam-level re-exam flag is on.
      final failed = result.percentage < 75;
      if (widget.exam.isReExamAllowed && failed) {
        if (mounted) setState(() => _state = _CardState.reExamGranted);
      } else {
        if (mounted) setState(() => _state = _CardState.attempted);
      }
      return;
    }

    // 2. No result yet — check enrollment/payment
    final paid = await widget.examService.isEnrolled(
      widget.studentId,
      widget.exam.id,
    );
    if (mounted) {
      setState(
        () => _state = paid ? _CardState.enrolled : _CardState.notEnrolled,
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ongoing':
        return AppTheme.success;
      case 'completed':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
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
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exam.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(widget.exam.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.exam.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(widget.exam.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.exam.subject,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Info chips
            Row(
              children: [
                _info(
                  Icons.calendar_today,
                  DateFormat('dd MMM yyyy').format(widget.exam.examDate),
                ),
                const SizedBox(width: 12),
                _info(Icons.timer, '${widget.exam.durationMinutes} min'),
                const SizedBox(width: 12),
                _info(Icons.quiz, '${widget.exam.totalQuestions} Qs'),
              ],
            ),
            const Divider(height: 20),

            // Price + Action button row
            Row(
              children: [
                Text(
                  '₹${widget.exam.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                _buildActionButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    switch (_state) {
      case _CardState.loading:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );

      case _CardState.notEnrolled:
        return ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(exam: widget.exam),
              ),
            );
            if (result == true) _checkStatus();
          },
          icon: const Icon(Icons.payment),
          label: const Text('Enroll / Pay'),
        );

      case _CardState.enrolled:
        final now = DateTime.now();
        final examDay = DateTime(
          widget.exam.examDate.year,
          widget.exam.examDate.month,
          widget.exam.examDate.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        if (today.isBefore(examDay)) {
          // Too early — exam hasn't opened yet.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_busy,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Opens on ${DateFormat('dd MMM yyyy').format(widget.exam.examDate)}',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamStartScreen(exam: widget.exam),
            ),
          ).then((_) => _checkStatus()),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Exam'),
        );

      case _CardState.attempted:
        // Already attempted — locked, show status
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.grey, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Already Attempted',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Re-exam not allowed',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        );

      case _CardState.reExamGranted:
        // Professor allowed re-exam
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExamStartScreen(exam: widget.exam),
                ),
              ).then((_) => _checkStatus()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
              ),
              icon: const Icon(Icons.replay),
              label: const Text('Re-Attempt'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Re-exam granted by Professor',
              style: TextStyle(
                color: AppTheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }

  Widget _info(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.grey),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}
