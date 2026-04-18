import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../models/result_model.dart';
import '../../models/exam_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'certificate_screen.dart';

class ResultScreen extends StatelessWidget {
  final ResultModel result;
  final ExamModel exam;
  const ResultScreen({super.key, required this.result, required this.exam});

  @override
  Widget build(BuildContext context) {
    // ── Result NOT published yet ──
    if (!exam.isResultPublished) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam Submitted'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock,
                    size: 72,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Exam Submitted!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your result will be visible once the Professor publishes it.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('Back to Dashboard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Result published — show full result ──
    final wrong =
        result.totalQuestions -
        result.score -
        (result.totalQuestions - result.answers.length);
    final notAttempted = result.totalQuestions - result.answers.length;
    final passed = result.percentage >= 50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('Home', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Score circle ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 12,
                      percent: (result.percentage / 100).clamp(0.0, 1.0),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${result.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Score',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      progressColor: _gradeColor(result.percentage),
                      backgroundColor: Colors.grey[200]!,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _gradeColor(result.percentage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _gradeLabel(result.percentage),
                        style: TextStyle(
                          color: _gradeColor(result.percentage),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats ──
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Score',
                    '${result.score}/${result.totalQuestions}',
                    Icons.star,
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Correct',
                    '${result.score}',
                    Icons.check_circle,
                    AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Wrong',
                    '$wrong',
                    Icons.cancel,
                    AppTheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    'Skipped',
                    '$notAttempted',
                    Icons.remove_circle,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Certificate button (only if PASSED) ──
            if (passed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Congratulations! You Passed!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openCertificate(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB8860B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text(
                          'View & Download Certificate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCertificate(BuildContext context) async {
    final authService = AuthService();
    final student = await authService.getCurrentUserModel();
    if (student == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CertificateScreen(result: result, exam: exam, student: student),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Color _gradeColor(double pct) {
    if (pct >= 90) return AppTheme.success;
    if (pct >= 75) return AppTheme.primary;
    if (pct >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  String _gradeLabel(double pct) {
    if (pct >= 90) return '⭐ Excellent';
    if (pct >= 75) return '👍 Good';
    if (pct >= 50) return '📝 Average';
    return '📚 Needs Improvement';
  }
}
