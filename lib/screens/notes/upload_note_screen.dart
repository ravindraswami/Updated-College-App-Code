import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/note_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';

class UploadNoteScreen extends StatefulWidget {
  // pre-fill classId for coordinator; empty = choose manually (Incharge/Professor)
  final String classId;
  const UploadNoteScreen({super.key, this.classId = ''});
  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {
  final _subjectCtrl = TextEditingController();

  // Fix 4: multiple files
  List<PlatformFile> _files = [];

  bool _uploading = false;
  double _progress = 0;
  int _uploadedCount = 0;
  bool _shareWithAll = false;
  String? _selectedClassId;
  String? _selectedBranch;
  String? _selectedYear;

  final _svc = NoteService();
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.classId.isNotEmpty) {
      _selectedClassId = widget.classId;
      _shareWithAll = false;
    } else {
      _shareWithAll = true;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
      allowMultiple: true, // Fix 4: allow multiple
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        // Merge, avoiding duplicates by name
        final existing = {for (final f in _files) f.name};
        final newFiles = result.files.where((f) => !existing.contains(f.name));
        _files = [..._files, ...newFiles];
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
  }

  Future<void> _upload() async {
    if (_subjectCtrl.text.trim().isEmpty) {
      _snack('Please enter the subject.', isError: true);
      return;
    }
    if (_files.isEmpty) {
      _snack('Please select at least one PDF file.', isError: true);
      return;
    }
    if (!_shareWithAll &&
        (_selectedClassId == null || _selectedClassId!.isEmpty)) {
      _snack('Please select a class.', isError: true);
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _uploadedCount = 0;
    });
    try {
      final user = await _auth.getCurrentUserModel();
      if (user == null) {
        _snack('Not logged in. Please login again.', isError: true);
        return;
      }

      for (int i = 0; i < _files.length; i++) {
        final file = _files[i];
        // Use filename (without extension) as title
        final title = file.name.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
        setState(() => _progress = (i + 0.5) / _files.length);

        await _svc.uploadNoteFromBytes(
          title: title,
          subject: _subjectCtrl.text.trim(),
          uploadedBy: user.id,
          platformFile: file,
          classId: _shareWithAll ? '' : (_selectedClassId ?? ''),
        );
        setState(() {
          _uploadedCount = i + 1;
          _progress = (i + 1) / _files.length;
        });
      }

      if (!mounted) return;
      _snack(
        '${_files.length} file(s) uploaded successfully${_shareWithAll ? ' — visible to all students' : ' for ${ClassConstants.shortLabel(_selectedClassId!)} students'}.',
        isError: false,
      );
      Navigator.pop(context);
    } catch (e) {
      _snack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCoordinator = widget.classId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Study Material')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.subject),
                helperText: 'Applied to all uploaded files',
              ),
            ),
            const SizedBox(height: 20),

            // ── Class targeting ──────────────────────────────
            const Text(
              'Who can see this?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),

            if (isCoordinator) ...[
              SwitchListTile(
                value: _shareWithAll,
                onChanged: (v) => setState(() => _shareWithAll = v),
                title: const Text('Share with all classes'),
                subtitle: const Text('All students can see this material'),
                activeColor: AppTheme.success,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_shareWithAll)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.class_,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visible only to ${ClassConstants.shortLabel(widget.classId)} students',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              SwitchListTile(
                value: _shareWithAll,
                onChanged: (v) => setState(() {
                  _shareWithAll = v;
                  if (v) {
                    _selectedClassId = null;
                    _selectedBranch = null;
                    _selectedYear = null;
                  }
                }),
                title: const Text('Share with all classes'),
                subtitle: const Text('All students can see this material'),
                activeColor: AppTheme.success,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_shareWithAll) ...[
                const SizedBox(height: 8),
                // Branch
                DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  hint: const Text('Select branch'),
                  items: ClassConstants.allBranchIds
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(
                            ClassConstants.branchLabel(b),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedBranch = v;
                    _selectedYear = null;
                    _selectedClassId = null;
                  }),
                ),
                const SizedBox(height: 12),
                // Year
                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  hint: const Text('Select year'),
                  items:
                      (_selectedBranch != null
                              ? ClassConstants.yearsForBranch(_selectedBranch!)
                              : <YearEntry>[])
                          .map(
                            (y) => DropdownMenuItem(
                              value: y.id,
                              child: Text(y.label),
                            ),
                          )
                          .toList(),
                  onChanged: _selectedBranch == null
                      ? null
                      : (v) => setState(() {
                          _selectedYear = v;
                          _selectedClassId = null;
                        }),
                ),
                const SizedBox(height: 12),
                // Semester
                DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  hint: const Text('Select semester'),
                  items:
                      (_selectedBranch != null && _selectedYear != null
                              ? ClassConstants.semsForBranchYear(
                                  _selectedBranch!,
                                  _selectedYear!,
                                )
                              : <String>[])
                          .map(
                            (id) => DropdownMenuItem(
                              value: id,
                              child: Text(
                                ClassConstants.labelFor(id),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: _selectedYear == null
                      ? null
                      : (v) => setState(() => _selectedClassId = v),
                ),
              ],
            ],

            const SizedBox(height: 20),

            // ── File picker ──────────────────────────────────
            Row(
              children: [
                const Text(
                  'PDF Files',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _uploading ? null : _pickFiles,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Files'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Empty state
            if (_files.isEmpty)
              GestureDetector(
                onTap: _uploading ? null : _pickFiles,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.primary.withOpacity(0.04),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap to select PDF files',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        'You can select multiple files at once',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              // File list
              Column(
                children: [
                  ...List.generate(_files.length, (i) {
                    final f = _files[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: AppTheme.error,
                          size: 28,
                        ),
                        title: Text(
                          f.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${(f.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: _uploading
                            ? (_uploadedCount > i
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.success,
                                      size: 20,
                                    )
                                  : const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ))
                            : IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppTheme.error,
                                  size: 18,
                                ),
                                onPressed: () => _removeFile(i),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _uploading ? null : _pickFiles,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add More Files'),
                  ),
                ],
              ),

            if (_uploading) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Uploading $_uploadedCount of ${_files.length}...',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                color: AppTheme.primary,
                minHeight: 6,
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _uploading
                      ? 'Uploading...'
                      : _files.isEmpty
                      ? 'Upload Material'
                      : 'Upload ${_files.length} File${_files.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
