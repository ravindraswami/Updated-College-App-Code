import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart';
import '../../models/result_model.dart';
import '../../services/exam_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../result/result_screen.dart';

enum QuestionStatus { notAnswered, answered, markedReview, answeredMarked }

class ExamScreen extends StatefulWidget {
  final ExamModel exam;
  const ExamScreen({super.key, required this.exam});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  List<QuestionModel> _questions = [];
  final Map<int, int> _answers = {};
  final Map<int, QuestionStatus> _status = {};
  int _currentIndex = 0;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ── Anti-cheat ──────────────────────────────────────────
  int _warningCount = 0;
  static const int _maxWarnings = 3;
  bool _showingWarning = false;

  final _examService = ExamService();
  final _authService = AuthService();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exam.durationMinutes * 60;
    // Register observer to detect app going to background
    WidgetsBinding.instance.addObserver(this);
    _initExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    // Re-enable system UI when leaving exam
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Detect app lifecycle changes (minimize, switch app, notifications) ──
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isLoading || _isSubmitting || _questions.isEmpty) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background / notification bar opened / call received
      _handleCheatAttempt('App switched or minimized');
    }
  }

  void _handleCheatAttempt(String reason) {
    if (_showingWarning || _isSubmitting) return;

    _warningCount++;

    if (_warningCount >= _maxWarnings) {
      // 3rd violation — auto fail immediately
      _autoFail();
    } else {
      // Show warning dialog
      _showWarning(reason);
    }
  }

  void _showWarning(String reason) {
    if (!mounted) return;
    _showingWarning = true;

    final remaining = _maxWarnings - _warningCount;

    showDialog(
      context: context,
      barrierDismissible: false, // can't dismiss by tapping outside
      builder: (_) => WillPopScope(
        onWillPop: () async => false, // block back button inside dialog
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Warning $_warningCount/$_maxWarnings',
                style: const TextStyle(color: AppTheme.warning),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You left the exam screen!\n($reason)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remaining > 0
                            ? 'You have $remaining warning(s) left.\nAfter $_maxWarnings violations, your exam will be cancelled and marked as FAIL.'
                            : 'This is your LAST warning!',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                          fontWeight: remaining == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showingWarning = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'I Understand — Return to Exam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => _showingWarning = false);
  }

  Future<void> _autoFail() async {
    if (_isSubmitting || !mounted) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    // Show auto-fail screen first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.cancel, color: AppTheme.error, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Exam Cancelled',
                style: TextStyle(color: AppTheme.error),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.gavel, color: AppTheme.error, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'You left the exam screen 3 times.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your exam has been automatically submitted and marked as FAIL due to violation of exam rules.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // close dialog
                  await _submitWithZeroScore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitWithZeroScore() async {
    final user = await _authService.getCurrentUserModel();
    if (user == null || !mounted) return;

    // Save result with 0 score
    final result = ResultModel(
      id: '',
      studentId: user.id,
      examId: widget.exam.id,
      answers: const {}, // no answers recorded
      score: 0,
      percentage: 0.0,
      totalQuestions: _questions.length,
      timestamp: DateTime.now(),
    );

    await _examService.saveResult(result);
    await _clearProgress();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, exam: widget.exam),
      ),
    );
  }

  // ── PopScope — intercept back button during exam ──────────
  Future<bool> _onWillPop() async {
    // Treat back button press as a cheat attempt
    _handleCheatAttempt('Back button pressed');
    return false; // never actually pop
  }

  Future<void> _initExam() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _questions = await _examService
          .getQuestions(widget.exam.id)
          .timeout(const Duration(seconds: 15), onTimeout: () => []);
      for (int i = 0; i < _questions.length; i++) {
        _status[i] = QuestionStatus.notAnswered;
      }
      await _restoreProgress();
      _startTimer();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load exam: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreProgress() async {
    try {
      final key = 'exam_${widget.exam.id}';
      final savedTime = _prefs.getInt('${key}_time');
      if (savedTime != null && savedTime > 0) _remainingSeconds = savedTime;
      for (int i = 0; i < _questions.length; i++) {
        final ans = _prefs.getInt('${key}_ans_$i');
        final st = _prefs.getInt('${key}_status_$i');
        if (ans != null) _answers[i] = ans;
        if (st != null) _status[i] = QuestionStatus.values[st];
      }
    } catch (_) {}
  }

  Future<void> _saveProgress() async {
    try {
      final key = 'exam_${widget.exam.id}';
      await _prefs.setInt('${key}_time', _remainingSeconds);
      for (int i = 0; i < _questions.length; i++) {
        if (_answers.containsKey(i)) {
          await _prefs.setInt('${key}_ans_$i', _answers[i]!);
        }
        await _prefs.setInt('${key}_status_$i', _status[i]!.index);
      }
    } catch (_) {}
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        _submitExam(confirmed: true);
      } else {
        if (mounted) setState(() => _remainingSeconds--);
        if (_remainingSeconds % 30 == 0) _saveProgress();
      }
    });
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _answers[_currentIndex] = optionIndex;
      _status[_currentIndex] =
          _status[_currentIndex] == QuestionStatus.markedReview
          ? QuestionStatus.answeredMarked
          : QuestionStatus.answered;
    });
    _saveProgress();
  }

  void _toggleMarkReview() {
    setState(() {
      switch (_status[_currentIndex]) {
        case QuestionStatus.answered:
          _status[_currentIndex] = QuestionStatus.answeredMarked;
          break;
        case QuestionStatus.answeredMarked:
          _status[_currentIndex] = QuestionStatus.answered;
          break;
        case QuestionStatus.markedReview:
          _status[_currentIndex] = QuestionStatus.notAnswered;
          break;
        default:
          _status[_currentIndex] = QuestionStatus.markedReview;
      }
    });
  }

  Future<void> _submitExam({bool confirmed = false}) async {
    if (_isSubmitting) return;
    if (!confirmed) {
      final attempted = _answers.length;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Submit Exam?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryRow('Attempted', '$attempted', AppTheme.answered),
              _summaryRow(
                'Not Attempted',
                '${_questions.length - attempted}',
                AppTheme.error,
              ),
              _summaryRow(
                'Marked for Review',
                '${_status.values.where((s) => s == QuestionStatus.markedReview || s == QuestionStatus.answeredMarked).length}',
                AppTheme.markedReview,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final user = await _authService.getCurrentUserModel();
    if (user == null || !mounted) return;

    int correct = 0;
    final answersMap = <String, int>{};
    for (int i = 0; i < _questions.length; i++) {
      if (_answers.containsKey(i)) {
        answersMap[_questions[i].id] = _answers[i]!;
        if (_answers[i] == _questions[i].correctAnswerIndex) correct++;
      }
    }

    final percentage = _questions.isEmpty
        ? 0.0
        : (correct / _questions.length) * 100;
    final result = ResultModel(
      id: '',
      studentId: user.id,
      examId: widget.exam.id,
      answers: answersMap,
      score: correct,
      percentage: percentage,
      totalQuestions: _questions.length,
      timestamp: DateTime.now(),
    );

    await _examService.saveResult(result);
    await _clearProgress();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, exam: widget.exam),
      ),
    );
  }

  Future<void> _clearProgress() async {
    try {
      final key = 'exam_${widget.exam.id}';
      final keys = _prefs.getKeys().where((k) => k.startsWith(key)).toList();
      for (final k in keys) {
        await _prefs.remove(k);
      }
    } catch (_) {}
  }

  Widget _summaryRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  String get _timerText {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }

  Color get _timerColor {
    if (_remainingSeconds < 60) return AppTheme.error;
    if (_remainingSeconds < 300) return AppTheme.warning;
    return AppTheme.success;
  }

  Color _statusColor(QuestionStatus s) {
    switch (s) {
      case QuestionStatus.answered:
        return AppTheme.answered;
      case QuestionStatus.markedReview:
        return AppTheme.markedReview;
      case QuestionStatus.answeredMarked:
        return AppTheme.markedAnswered;
      default:
        return AppTheme.notAnswered;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.exam.title),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading questions...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initExam();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.title)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No questions found for this exam.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_currentIndex];
    final selectedOption = _answers[_currentIndex];
    final isMarked =
        _status[_currentIndex] == QuestionStatus.markedReview ||
        _status[_currentIndex] == QuestionStatus.answeredMarked;

    // WillPopScope blocks back button — treats it as cheat attempt
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // hide back arrow
          title: Row(
            children: [
              // Warning indicator
              if (_warningCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppTheme.warning,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_warningCount/$_maxWarnings',
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                widget.exam.title,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _timerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _timerColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: _timerColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _timerText,
                    style: TextStyle(
                      color: _timerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Warning bar
            if (_warningCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: AppTheme.warning.withOpacity(0.12),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: AppTheme.warning, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _warningCount == 1
                          ? 'Warning 1/3: Stay on this screen during the exam!'
                          : _warningCount == 2
                          ? '⚠️ Warning 2/3: One more violation = AUTO FAIL!'
                          : '🚨 Final warning — Do NOT leave this screen!',
                      style: TextStyle(
                        color: _warningCount >= 2
                            ? AppTheme.error
                            : AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[200],
              color: AppTheme.primary,
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Q${_currentIndex + 1}/${_questions.length}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _toggleMarkReview,
                          icon: Icon(
                            isMarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isMarked
                                ? AppTheme.markedReview
                                : Colors.grey,
                          ),
                          label: Text(
                            isMarked ? 'Marked' : 'Mark',
                            style: TextStyle(
                              color: isMarked
                                  ? AppTheme.markedReview
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      q.questionText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(q.options.length, (i) {
                      final isSelected = selectedOption == i;
                      return GestureDetector(
                        onTap: () => _selectAnswer(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.grey[200],
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.grey[400]!,
                                  ),
                                ),
                                child: Center(
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : Text(
                                          String.fromCharCode(65 + i),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.options[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentIndex--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Prev'),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showPalette,
                    icon: const Icon(Icons.grid_view, size: 18),
                    label: const Text('Palette'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                    ),
                  ),
                  const Spacer(),
                  if (_currentIndex < _questions.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentIndex++),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitExam,
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Question Palette',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendDot(AppTheme.notAnswered, 'Not Answered'),
                  _legendDot(AppTheme.answered, 'Answered'),
                  _legendDot(AppTheme.markedReview, 'Review'),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _questions.length,
                itemBuilder: (_, i) {
                  final s = _status[i] ?? QuestionStatus.notAnswered;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = i);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _statusColor(s),
                        borderRadius: BorderRadius.circular(8),
                        border: i == _currentIndex
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: s == QuestionStatus.notAnswered
                                ? Colors.black54
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitExam();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  child: const Text('Submit Exam'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}
