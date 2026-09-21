import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/academic_data.dart';

class CreateExamScreen extends StatefulWidget {
  final String professorId;
  final ExamModel? editExam;
  const CreateExamScreen({super.key, required this.professorId, this.editExam});
  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  DateTime _examDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'upcoming';
  bool _isLoading = false;
  final _examService = ExamService();

  // Fix 2: targeting
  bool _targetAll = true;
  String? _targetBranch;
  String? _targetYear;
  String? _targetSemester;

  List<Map<String, dynamic>> get _years =>
      _targetBranch != null ? AcademicData.yearsForBranch(_targetBranch!) : [];

  List<Map<String, dynamic>> get _sems =>
      (_targetBranch != null && _targetYear != null)
          ? AcademicData.semsForYear(_targetBranch!, _targetYear!)
          : [];

  @override
  void initState() {
    super.initState();
    if (widget.editExam != null) {
      final e = widget.editExam!;
      _titleCtrl.text = e.title;
      _subjectCtrl.text = e.subject;
      _priceCtrl.text = e.price.toString();
      _durationCtrl.text = e.durationMinutes.toString();
      _examDate = e.examDate;
      _status = e.status;
      _targetAll = e.targetAllStudents || e.targetBranch.isEmpty;
      if (!_targetAll) {
        _targetBranch = e.targetBranch.isNotEmpty ? e.targetBranch : null;
        _targetYear = e.targetYear.isNotEmpty ? e.targetYear : null;
        _targetSemester = e.targetSemester.isNotEmpty ? e.targetSemester : null;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_targetAll && _targetBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a branch or choose "All Students"'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final exam = ExamModel(
        id: widget.editExam?.id ?? '',
        title: _titleCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        examDate: _examDate,
        durationMinutes: int.parse(_durationCtrl.text),
        price: double.parse(_priceCtrl.text),
        professorId: widget.professorId,
        status: _status,
        totalQuestions: widget.editExam?.totalQuestions ?? 0,
        isResultPublished: widget.editExam?.isResultPublished ?? false,
        isReExamAllowed: widget.editExam?.isReExamAllowed ?? false,
        targetAllStudents: _targetAll,
        targetBranch: _targetAll ? '' : (_targetBranch ?? ''),
        targetYear: _targetAll ? '' : (_targetYear ?? ''),
        targetSemester: _targetAll ? '' : (_targetSemester ?? ''),
      );
      if (widget.editExam != null) {
        await _examService.updateExam(exam);
      } else {
        await _examService.createExam(exam);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editExam != null ? 'Exam updated!' : 'Exam created!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editExam != null ? 'Edit Exam' : 'Create Exam'),
        backgroundColor: AppTheme.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Exam Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (v) => v!.isEmpty ? 'Enter subject' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (mins)',
                        prefixIcon: Icon(Icons.timer),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter duration' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter price' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(DateFormat('dd MMM yyyy').format(_examDate)),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: const [
                  DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),

              // ── Fix 2: Target Students ───────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.group, color: AppTheme.secondary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Target Students',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // All students toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('All Students (All Branches & Semesters)'),
                      value: _targetAll,
                      activeColor: AppTheme.secondary,
                      onChanged: (v) => setState(() {
                        _targetAll = v;
                        if (v) {
                          _targetBranch = null;
                          _targetYear = null;
                          _targetSemester = null;
                        }
                      }),
                    ),

                    if (!_targetAll) ...[
                      const SizedBox(height: 12),
                      // Branch dropdown
                      DropdownButtonFormField<String>(
                        value: _targetBranch,
                        decoration: const InputDecoration(
                          labelText: 'Branch',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                          isDense: true,
                        ),
                        items: AcademicData.branches
                            .map((b) => DropdownMenuItem(
                                  value: b['id'] as String,
                                  child: Text(b['label'] as String),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _targetBranch = v;
                          _targetYear = null;
                          _targetSemester = null;
                        }),
                        hint: const Text('Select Branch'),
                      ),
                      if (_targetBranch != null) ...[
                        const SizedBox(height: 12),
                        // Year dropdown
                        DropdownButtonFormField<String>(
                          value: _targetYear,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            prefixIcon: Icon(Icons.calendar_today),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Years in Branch'),
                            ),
                            ..._years.map((y) => DropdownMenuItem(
                                  value: y['id'] as String,
                                  child: Text(y['label'] as String),
                                )),
                          ],
                          onChanged: (v) => setState(() {
                            _targetYear = v?.isEmpty == true ? null : v;
                            _targetSemester = null;
                          }),
                          hint: const Text('All Years'),
                        ),
                      ],
                      if (_targetBranch != null && _targetYear != null && _sems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        // Semester dropdown
                        DropdownButtonFormField<String>(
                          value: _targetSemester,
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                            prefixIcon: Icon(Icons.looks_one_outlined),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Semesters in Year'),
                            ),
                            ..._sems.map((s) => DropdownMenuItem(
                                  value: s['id'] as String,
                                  child: Text(s['label'] as String),
                                )),
                          ],
                          onChanged: (v) => setState(() {
                            _targetSemester = v?.isEmpty == true ? null : v;
                          }),
                          hint: const Text('All Semesters'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.editExam != null ? 'Update Exam' : 'Create Exam',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
