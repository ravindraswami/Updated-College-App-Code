import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../utils/app_theme.dart';
import '../legal/exam_terms_dialog.dart';
import '../legal/legal_screen.dart';
import 'exam_screen.dart';

class ExamStartScreen extends StatelessWidget {
  final ExamModel exam;
  const ExamStartScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Instructions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Exam info banner ──────────────────────────
            Card(
              color: AppTheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exam.subject,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ✅ FIX: Wrap chips in Wrap so they never overflow
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(Icons.timer, '${exam.durationMinutes} mins'),
                        _chip(Icons.quiz, '${exam.totalQuestions} Questions'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Instructions ──────────────────────────────
            const Text(
              'Important Instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._instructions.map((i) => _instructionItem(i)),
            const SizedBox(height: 16),

            // ── Legend ────────────────────────────────────
            _legend(),
            const SizedBox(height: 16),

            // ── Anti-cheat warning ────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Anti-Cheat Policy',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...[
                    '1st violation (app switch / back button) \u2192 Warning',
                    '2nd violation \u2192 Final warning',
                    '3rd violation \u2192 Exam AUTO-CANCELLED, Score = 0',
                  ].map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Full T&C link ─────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LegalScreen(type: LegalType.termsAndConditions),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text(
                  'View Full Terms & Conditions',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Start Exam button ─────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final agreed = await showExamTermsDialog(context, exam.title);
                  if (agreed != true || !context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ExamScreen(exam: exam)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Exam', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    ),
  );

  Widget _instructionItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
      ],
    ),
  );

  // ✅ FIX: legend items in Wrap so "Answered & Marked" never overflows
  Widget _legend() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Status Legend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          // ✅ Use Wrap instead of Row so items flow to next line
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _legendItem(AppTheme.notAnswered, 'Not Answered'),
              _legendItem(AppTheme.answered, 'Answered'),
              _legendItem(AppTheme.markedReview, 'Marked for Review'),
              _legendItem(AppTheme.markedAnswered, 'Answered & Marked'),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _legendItem(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  static const List<String> _instructions = [
    'The exam starts after you agree to the rules.',
    'Timer counts down and auto-submits when it reaches zero.',
    'Navigate between questions using Next/Previous or the palette.',
    'Click any question number in the palette to jump directly to it.',
    'You can mark questions for review and return to them later.',
    'Answers are saved automatically — your progress is safe if the app closes.',
    'Do NOT switch apps, minimize, or press back — each violation is a warning.',
    'After 3 violations, the exam is cancelled and marked FAIL automatically.',
    'Once submitted, answers cannot be changed.',
  ];
}
