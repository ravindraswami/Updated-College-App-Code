import 'package:flutter/material.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart';
import '../../utils/app_theme.dart';

class AddQuestionsScreen extends StatefulWidget {
  final ExamModel exam;
  const AddQuestionsScreen({super.key, required this.exam});
  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctAnswer = 0;
  bool _isAdding = false;
  final _examService = ExamService();

  Future<void> _addQuestion(int totalExisting) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isAdding = true);
    try {
      final q = QuestionModel(
        id: '',
        examId: widget.exam.id,
        questionText: _questionCtrl.text.trim(),
        options: _optionCtrls.map((c) => c.text.trim()).toList(),
        correctAnswerIndex: _correctAnswer,
        questionNumber: totalExisting + 1,
      );
      await _examService.addQuestion(q);
      // Update exam total questions count
      final updated = ExamModel(
        id: widget.exam.id,
        title: widget.exam.title,
        subject: widget.exam.subject,
        examDate: widget.exam.examDate,
        durationMinutes: widget.exam.durationMinutes,
        price: widget.exam.price,
        professorId: widget.exam.professorId,
        status: widget.exam.status,
        totalQuestions: totalExisting + 1,
      );
      await _examService.updateExam(updated);
      _questionCtrl.clear();
      for (final c in _optionCtrls) {
        c.clear();
      }
      setState(() => _correctAnswer = 0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question added!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions: ${widget.exam.title}'),
        backgroundColor: AppTheme.secondary,
      ),
      body: FutureBuilder<List<QuestionModel>>(
        future: _examService.getQuestions(widget.exam.id),
        builder: (ctx, snap) {
          final questions = snap.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.quiz, color: AppTheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '${questions.length} Questions Added',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (questions.isNotEmpty) ...[
                  ...questions.map(
                    (q) => _QuestionTile(
                      question: q,
                      onDelete: () async {
                        await _examService.deleteQuestion(q.id);
                        setState(() {});
                      },
                    ),
                  ),
                  const Divider(height: 32),
                ],
                const Text(
                  'Add New Question',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _questionCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question Text',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.help_outline),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter question' : null,
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: _correctAnswer,
                                onChanged: (v) =>
                                    setState(() => _correctAnswer = v!),
                                activeColor: AppTheme.success,
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionCtrls[i],
                                  decoration: InputDecoration(
                                    labelText:
                                        'Option ${String.fromCharCode(65 + i)}',
                                    prefixText: _correctAnswer == i ? '✓ ' : '',
                                    prefixStyle: const TextStyle(
                                      color: AppTheme.success,
                                    ),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Enter option' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Correct Answer: Option ${String.fromCharCode(65 + _correctAnswer)}',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAdding
                              ? null
                              : () => _addQuestion(questions.length),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _isAdding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Add Question'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onDelete;
  const _QuestionTile({required this.question, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(0.1),
          child: Text(
            '${question.questionNumber}',
            style: const TextStyle(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          question.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: AppTheme.error),
          onPressed: onDelete,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: List.generate(
                question.options.length,
                (i) => Row(
                  children: [
                    Icon(
                      i == question.correctAnswerIndex
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: i == question.correctAnswerIndex
                          ? AppTheme.success
                          : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + i)}. ${question.options[i]}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
