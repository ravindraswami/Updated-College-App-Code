import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/exam_service.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart';
import '../../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
// Parsed question before saving
// ─────────────────────────────────────────────────────────────────
class _ParsedQ {
  String questionText;
  List<String> options;
  int correctAnswerIndex;
  bool selected;

  _ParsedQ({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.selected = true,
  });
}

// ─────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────
class AddQuestionsScreen extends StatefulWidget {
  final ExamModel exam;
  const AddQuestionsScreen({super.key, required this.exam});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _examService = ExamService();

  // live question count (rebuilt on tab switch)
  int _questionCount = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadCount();
  }

  Future<void> _loadCount() async {
    final qs = await _examService.getQuestions(widget.exam.id);
    if (mounted) setState(() => _questionCount = qs.length);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions: ${widget.exam.title} ($_questionCount added)'),
        backgroundColor: AppTheme.secondary,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Manual Add'),
            Tab(icon: Icon(Icons.upload_file), text: 'Bulk Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ManualTab(
            exam: widget.exam,
            examService: _examService,
            onCountChanged: (c) => setState(() => _questionCount = c),
          ),
          _BulkImportTab(
            exam: widget.exam,
            examService: _examService,
            onImported: () {
              _loadCount();
              _tabCtrl.animateTo(0);
            },
            getCurrentCount: () => _questionCount,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 1 — Manual Add
// ─────────────────────────────────────────────────────────────────
class _ManualTab extends StatefulWidget {
  final ExamModel exam;
  final ExamService examService;
  final void Function(int) onCountChanged;

  const _ManualTab({
    required this.exam,
    required this.examService,
    required this.onCountChanged,
  });

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctAnswer = 0;
  bool _isAdding = false;

  // Image for new question
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _imageBytes = result.files.first.bytes;
        _imageFileName = result.files.first.name;
      });
    }
  }

  Future<String?> _uploadImage(String examId) async {
    if (_imageBytes == null) return null;
    setState(() => _uploadingImage = true);
    try {
      final ref = FirebaseStorage.instance.ref(
        'exam_question_images/$examId/${DateTime.now().millisecondsSinceEpoch}_$_imageFileName',
      );
      await ref.putData(_imageBytes!);
      return await ref.getDownloadURL();
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _addQuestion(int totalExisting) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isAdding = true);
    try {
      final imageUrl = await _uploadImage(widget.exam.id) ?? '';
      final q = QuestionModel(
        id: '',
        examId: widget.exam.id,
        questionText: _questionCtrl.text.trim(),
        options: _optionCtrls.map((c) => c.text.trim()).toList(),
        correctAnswerIndex: _correctAnswer,
        questionNumber: totalExisting + 1,
        imageUrl: imageUrl,
      );
      await widget.examService.addQuestion(q);
      final newCount = totalExisting + 1;
      final updated = ExamModel.fromMap({
        ...widget.exam.toMap(),
        'totalQuestions': newCount,
      }, widget.exam.id);
      await widget.examService.updateExam(updated);
      _questionCtrl.clear();
      for (final c in _optionCtrls) c.clear();
      setState(() {
        _correctAnswer = 0;
        _imageBytes = null;
        _imageFileName = null;
      });
      widget.onCountChanged(newCount);
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
    return FutureBuilder<List<QuestionModel>>(
      future: widget.examService.getQuestions(widget.exam.id),
      builder: (ctx, snap) {
        final questions = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Count header
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

              // Existing questions
              if (questions.isNotEmpty) ...[
                ...questions.map(
                  (q) => _QuestionTile(
                    question: q,
                    examService: widget.examService,
                    exam: widget.exam,
                    onDelete: () async {
                      await widget.examService.deleteQuestion(q.id);
                      widget.onCountChanged(questions.length - 1);
                      // ignore: invalid_use_of_protected_member
                      (ctx as Element).markNeedsBuild();
                    },
                    onRefresh: () => setState(() {}),
                  ),
                ),
                const Divider(height: 32),
              ],

              // Add new question form
              const Text(
                'Add New Question',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 12),

                    // Optional image picker
                    const Text(
                      'Question Image (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_imageBytes != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _imageBytes!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => setState(() {
                                  _imageBytes = null;
                                  _imageFileName = null;
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Attach Image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                          side: const BorderSide(color: AppTheme.secondary),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Options
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
                        onPressed: (_isAdding || _uploadingImage)
                            ? null
                            : () => _addQuestion(questions.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: (_isAdding || _uploadingImage)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          _uploadingImage
                              ? 'Uploading image…'
                              : _isAdding
                              ? 'Adding…'
                              : 'Add Question',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Tab 2 — Bulk Import
// ─────────────────────────────────────────────────────────────────
class _BulkImportTab extends StatefulWidget {
  final ExamModel exam;
  final ExamService examService;
  final VoidCallback onImported;
  final int Function() getCurrentCount;

  const _BulkImportTab({
    required this.exam,
    required this.examService,
    required this.onImported,
    required this.getCurrentCount,
  });

  @override
  State<_BulkImportTab> createState() => _BulkImportTabState();
}

class _BulkImportTabState extends State<_BulkImportTab> {
  List<_ParsedQ> _parsed = [];
  String? _fileName;
  bool _parsing = false;
  bool _importing = false;
  String? _parseError;

  // ── Parse MCQ from plain text ────────────────────────────
  List<_ParsedQ> _parseText(String text) {
    final questions = <_ParsedQ>[];

    // Normalize line endings
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .toList();

    String? currentQ;
    List<String> currentOpts = [];
    int correctIdx = 0;

    // Option line patterns: "A) text", "A. text", "(A) text", "a) text"
    final optPat = RegExp(r'^[(\[]?([A-Da-d])[)\]\.]\s*(.+)$');
    // Answer line: "Ans: B", "Answer: C", "Correct: A", "Key: D"
    final ansPat = RegExp(
      r'^(?:ans(?:wer)?|correct(?:\s+answer)?|key)\s*[:\-]\s*([A-Da-d])',
      caseSensitive: false,
    );
    // Question number: "1. text", "1) text", "Q1. text", "Q.1 text"
    final qNumPat = RegExp(
      r'^(?:Q\.?\s*)?\d+[.\)]\s*(.+)$',
      caseSensitive: false,
    );

    void saveCurrentQ() {
      if (currentQ != null && currentOpts.length == 4) {
        questions.add(
          _ParsedQ(
            questionText: currentQ!,
            options: List<String>.from(currentOpts),
            correctAnswerIndex: correctIdx,
          ),
        );
      }
      currentQ = null;
      currentOpts = [];
      correctIdx = 0;
    }

    for (final line in lines) {
      if (line.isEmpty) continue;

      // Answer line
      final ansMatch = ansPat.firstMatch(line);
      if (ansMatch != null) {
        final letter = ansMatch.group(1)!.toUpperCase();
        correctIdx = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);
        // After answer, save question
        saveCurrentQ();
        continue;
      }

      // Option line
      final optMatch = optPat.firstMatch(line);
      if (optMatch != null && currentQ != null) {
        final optText = optMatch.group(2)!.trim();
        if (currentOpts.length < 4) {
          currentOpts.add(optText);
        }
        continue;
      }

      // Question number line
      final qMatch = qNumPat.firstMatch(line);
      if (qMatch != null) {
        // If we already have a question without answer, save with default
        if (currentQ != null && currentOpts.length == 4) saveCurrentQ();
        currentQ = qMatch.group(1)!.trim();
        currentOpts = [];
        correctIdx = 0;
        continue;
      }

      // Continuation of question text (if no option or number detected)
      if (currentQ != null && currentOpts.isEmpty) {
        currentQ = '$currentQ $line';
      }
    }

    // Save last question
    if (currentQ != null && currentOpts.length == 4) saveCurrentQ();

    return questions;
  }

  Future<void> _pickAndParse() async {
    setState(() {
      _parseError = null;
      _parsed = [];
      _fileName = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _parsing = true;
      _fileName = file.name;
    });

    try {
      String text = '';
      final ext = file.extension?.toLowerCase() ?? '';

      if (ext == 'txt') {
        // Plain text — UTF-8 decode
        text = String.fromCharCodes(file.bytes ?? []);
      } else if (ext == 'pdf') {
        // Extract text from PDF bytes using pdf package
        // We read the raw bytes and extract text content
        text = await _extractPdfText(file.bytes ?? Uint8List(0));
      } else if (ext == 'docx') {
        // DOCX is a ZIP — extract word/document.xml and strip tags
        text = await _extractDocxText(file.bytes ?? Uint8List(0));
      }

      if (text.trim().isEmpty) {
        setState(() {
          _parseError =
              'Could not extract text from this file.\nFor PDF: ensure it is a text-based PDF (not scanned image).\nFor DOCX: ensure it has readable text content.';
          _parsing = false;
        });
        return;
      }

      final parsed = _parseText(text);
      setState(() {
        _parsed = parsed;
        _parsing = false;
        if (parsed.isEmpty) {
          _parseError =
              'No MCQ questions found.\n\nExpected format:\n1. Question text?\nA) Option A\nB) Option B\nC) Option C\nD) Option D\nAns: B';
        }
      });
    } catch (e) {
      setState(() {
        _parseError = 'Parse error: $e';
        _parsing = false;
      });
    }
  }

  Future<String> _extractPdfText(Uint8List bytes) async {
    // Simple PDF text extraction: scan for BT...ET blocks and extract text
    // This works for simple text-based PDFs
    try {
      final raw = String.fromCharCodes(bytes);
      final buffer = StringBuffer();
      // Extract text between BT (Begin Text) and ET (End Text)
      final btEtPattern = RegExp(r'BT(.*?)ET', dotAll: true);
      final tjPattern = RegExp(r'\(((?:[^()\\]|\\.)*)\)\s*Tj', dotAll: false);
      final tjArrayPattern = RegExp(
        r'\[((?:[^\[\]]|\((?:[^()\\]|\\.)*\))*)\]\s*TJ',
      );

      for (final btMatch in btEtPattern.allMatches(raw)) {
        final block = btMatch.group(1) ?? '';
        for (final tjMatch in tjPattern.allMatches(block)) {
          final t = tjMatch.group(1) ?? '';
          buffer.write(_decodePdfString(t));
          buffer.write(' ');
        }
        for (final tjMatch in tjArrayPattern.allMatches(block)) {
          final arr = tjMatch.group(1) ?? '';
          for (final innerTj in tjPattern.allMatches(arr)) {
            final t = innerTj.group(1) ?? '';
            buffer.write(_decodePdfString(t));
          }
          buffer.write(' ');
        }
        buffer.write('\n');
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  String _decodePdfString(String s) {
    return s
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')');
  }

  Future<String> _extractDocxText(Uint8List bytes) async {
    // DOCX is a ZIP file. We find word/document.xml and strip XML tags.
    try {
      // Simple ZIP parser: find "word/document.xml" entry
      final zipContent = _findZipEntry(bytes, 'word/document.xml');
      if (zipContent == null) return '';
      final xmlStr = String.fromCharCodes(zipContent);
      // Strip XML tags, decode common entities
      return xmlStr
          .replaceAll(RegExp(r'<w:br[^/]*/?>'), '\n')
          .replaceAll(RegExp(r'<w:p[ >][^>]*>'), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&apos;', "'")
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    } catch (_) {
      return '';
    }
  }

  Uint8List? _findZipEntry(Uint8List bytes, String targetPath) {
    // Scan ZIP local file headers (PK\x03\x04)
    int i = 0;
    while (i < bytes.length - 30) {
      if (bytes[i] == 0x50 &&
          bytes[i + 1] == 0x4B &&
          bytes[i + 2] == 0x03 &&
          bytes[i + 3] == 0x04) {
        final compMethod = bytes[i + 8] | (bytes[i + 9] << 8);
        final compSize =
            bytes[i + 18] |
            (bytes[i + 19] << 8) |
            (bytes[i + 20] << 16) |
            (bytes[i + 21] << 24);
        final uncompSize =
            bytes[i + 22] |
            (bytes[i + 23] << 8) |
            (bytes[i + 24] << 16) |
            (bytes[i + 25] << 24);
        final fileNameLen = bytes[i + 26] | (bytes[i + 27] << 8);
        final extraLen = bytes[i + 28] | (bytes[i + 29] << 8);

        if (i + 30 + fileNameLen > bytes.length) break;
        final fileNameBytes = bytes.sublist(i + 30, i + 30 + fileNameLen);
        final fileName = String.fromCharCodes(fileNameBytes);
        final dataStart = i + 30 + fileNameLen + extraLen;

        if (fileName == targetPath) {
          if (dataStart + compSize > bytes.length) break;
          final compData = bytes.sublist(dataStart, dataStart + compSize);
          if (compMethod == 0) {
            // Stored — no compression
            return compData;
          } else if (compMethod == 8) {
            // Deflate
            try {
              // Use dart:io ZLibDecoder (rawDeflate)
              // Prepend zlib header for inflate
              return _inflate(compData, uncompSize);
            } catch (_) {
              return null;
            }
          }
          return null;
        }
        i = dataStart + compSize;
      } else {
        i++;
      }
    }
    return null;
  }

  Uint8List? _inflate(Uint8List compData, int expectedSize) {
    // Use dart:convert ZLibDecoder with raw inflate
    try {
      // Add zlib wrapper (CMF=0x78, FLG=0x9C)
      final wrapped = Uint8List(compData.length + 2);
      wrapped[0] = 0x78;
      wrapped[1] = 0x9C;
      wrapped.setRange(2, wrapped.length, compData);
      // dart:convert ZLibDecoder
      // ignore: avoid_dynamic_calls
      final codec = ZLibCodec(raw: false);
      return Uint8List.fromList(codec.decode(wrapped));
    } catch (_) {
      // Try raw inflate
      try {
        final codec = ZLibCodec(raw: true);
        return Uint8List.fromList(codec.decode(compData));
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _importAll() async {
    final toImport = _parsed.where((q) => q.selected).toList();
    if (toImport.isEmpty) return;
    setState(() => _importing = true);
    try {
      int base = widget.getCurrentCount();
      for (final pq in toImport) {
        final q = QuestionModel(
          id: '',
          examId: widget.exam.id,
          questionText: pq.questionText,
          options: pq.options,
          correctAnswerIndex: pq.correctAnswerIndex,
          questionNumber: ++base,
          imageUrl: '',
        );
        await widget.examService.addQuestion(q);
      }
      // Update exam total count
      final updated = ExamModel.fromMap({
        ...widget.exam.toMap(),
        'totalQuestions': base,
      }, widget.exam.id);
      await widget.examService.updateExam(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${toImport.length} questions imported successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      widget.onImported();
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format guide card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.secondary,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Supported MCQ Format (TXT / PDF / DOCX)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _CodeBlock(
                  text:
                      '1. What is photosynthesis?\n'
                      'A) Process of respiration\n'
                      'B) Conversion of light to energy\n'
                      'C) Cell division\n'
                      'D) Protein synthesis\n'
                      'Ans: B\n\n'
                      '2. Next question here?\n'
                      'A) ...\n'
                      'Ans: A',
                ),
                const SizedBox(height: 8),
                Text(
                  '• Answer line: "Ans: B", "Answer: C", "Correct: A"\n'
                  '• Options: A) / A. / (A) formats all supported\n'
                  '• PDF must be text-based (not scanned image)',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pick file button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _parsing ? null : _pickAndParse,
              icon: _parsing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _parsing
                    ? 'Parsing file…'
                    : _fileName != null
                    ? 'Change File  ($_fileName)'
                    : 'Select PDF / DOCX / TXT File',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.secondary,
                side: const BorderSide(color: AppTheme.secondary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Error
          if (_parseError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Preview list
          if (_parsed.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  '${_parsed.length} Questions Found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    for (final q in _parsed) q.selected = true;
                  }),
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    for (final q in _parsed) q.selected = false;
                  }),
                  child: const Text('Deselect All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._parsed.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return _PreviewTile(
                index: i,
                q: q,
                onToggle: (v) => setState(() => q.selected = v),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_importing || _parsed.every((q) => !q.selected))
                    ? null
                    : _importAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _importing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _importing
                      ? 'Importing…'
                      : 'Import ${_parsed.where((q) => q.selected).length} Questions',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Bulk Import — Preview Tile
// ─────────────────────────────────────────────────────────────────
class _PreviewTile extends StatelessWidget {
  final int index;
  final _ParsedQ q;
  final void Function(bool) onToggle;

  const _PreviewTile({
    required this.index,
    required this.q,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: q.selected ? null : Colors.grey[100],
      child: ExpansionTile(
        leading: Checkbox(
          value: q.selected,
          onChanged: (v) => onToggle(v ?? false),
          activeColor: AppTheme.secondary,
        ),
        title: Text(
          'Q${index + 1}. ${q.questionText}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: q.selected ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          'Correct: ${String.fromCharCode(65 + q.correctAnswerIndex)}',
          style: TextStyle(
            color: AppTheme.success,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: List.generate(
                q.options.length,
                (i) => Row(
                  children: [
                    Icon(
                      i == q.correctAnswerIndex
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: i == q.correctAnswerIndex
                          ? AppTheme.success
                          : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + i)}. ${q.options[i]}',
                        style: const TextStyle(fontSize: 13),
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

// ─────────────────────────────────────────────────────────────────
// Manual Tab — Existing Question Tile (with image add/remove)
// ─────────────────────────────────────────────────────────────────
class _QuestionTile extends StatefulWidget {
  final QuestionModel question;
  final ExamService examService;
  final ExamModel exam;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const _QuestionTile({
    required this.question,
    required this.examService,
    required this.exam,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<_QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<_QuestionTile> {
  bool _uploadingImg = false;

  Future<void> _addImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploadingImg = true);
    try {
      final ref = FirebaseStorage.instance.ref(
        'exam_question_images/${widget.exam.id}/${widget.question.id}_${file.name}',
      );
      await ref.putData(file.bytes!);
      final url = await ref.getDownloadURL();
      await widget.examService.updateQuestionImage(widget.question.id, url);
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _uploadingImg = false);
    }
  }

  Future<void> _removeImage() async {
    try {
      // Delete from storage if possible
      if (widget.question.imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .refFromURL(widget.question.imageUrl)
              .delete();
        } catch (_) {}
      }
      await widget.examService.updateQuestionImage(widget.question.id, '');
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final hasImage = q.imageUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary.withOpacity(0.1),
          child: Text(
            '${q.questionNumber}',
            style: const TextStyle(
              color: AppTheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          q.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              const Icon(Icons.image, color: AppTheme.secondary, size: 18),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: widget.onDelete,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Options
                ...List.generate(
                  q.options.length,
                  (i) => Row(
                    children: [
                      Icon(
                        i == q.correctAnswerIndex
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: i == q.correctAnswerIndex
                            ? AppTheme.success
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${String.fromCharCode(65 + i)}. ${q.options[i]}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Image section
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      q.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                              height: 100,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploadingImg ? null : _addImage,
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Change Image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                          side: const BorderSide(color: AppTheme.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: _uploadingImg ? null : _addImage,
                    icon: _uploadingImg
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 16,
                          ),
                    label: Text(_uploadingImg ? 'Uploading…' : 'Add Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: const BorderSide(color: AppTheme.secondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Code-style block for format guide
// ─────────────────────────────────────────────────────────────────
class _CodeBlock extends StatelessWidget {
  final String text;
  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
