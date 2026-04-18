import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/note_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';

class UploadNoteScreen extends StatefulWidget {
  final String classId; // pre-filled for coordinators
  const UploadNoteScreen({super.key, this.classId = ''});
  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _shareWithAllClasses = false;
  late String _selectedClassId;

  final _noteService = NoteService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    // If no class pre-filled, default to share with all
    _shareWithAllClasses = widget.classId.isEmpty;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          _showError('Could not read file. Please try again.');
          return;
        }
        setState(() => _selectedFile = file);
      }
    } catch (e) {
      _showError('Could not open file picker. Please try again.');
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showError('Please select a PDF file first.');
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });
    try {
      final user = await _authService.getCurrentUserModel();
      if (user == null) {
        _showError('You are not logged in. Please login again.');
        return;
      }
      setState(() => _uploadProgress = 0.5);
      final classId = _shareWithAllClasses ? '' : _selectedClassId;
      await _noteService.uploadNoteFromBytes(
        title: _titleCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        uploadedBy: user.id,
        platformFile: _selectedFile!,
        classId: classId,
      );
      setState(() => _uploadProgress = 1.0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            classId.isEmpty
                ? 'Notes uploaded successfully and visible to all students.'
                : 'Notes uploaded for ${ClassConstants.shortLabel(classId)} students.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError(_friendlyStorageError(e.toString()));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _friendlyStorageError(String raw) {
    if (raw.contains('unauthorized') || raw.contains('permission-denied')) {
      return 'Upload failed due to permission error. Please contact your administrator.';
    }
    if (raw.contains('network') || raw.contains('connection')) {
      return 'Upload failed. Please check your internet connection and try again.';
    }
    if (raw.contains('quota')) {
      return 'Storage limit reached. Please contact your administrator.';
    }
    return 'Upload failed. Please try again.';
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Study Material')),
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
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please enter a title.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please enter the subject.' : null,
              ),
              const SizedBox(height: 20),

              // Class targeting
              const Text(
                'Who can see this?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _shareWithAllClasses,
                onChanged: (v) => setState(() => _shareWithAllClasses = v),
                title: const Text('Share with all classes'),
                subtitle: const Text('All students can see this material'),
                activeThumbColor: AppTheme.success,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_shareWithAllClasses) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClassId.isNotEmpty
                      ? _selectedClassId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Select Class',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  hint: const Text('Choose a class'),
                  items: ClassConstants.allClassIds
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(
                            '${ClassConstants.shortLabel(id)} — ${ClassConstants.labelFor(id)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedClassId = v ?? ''),
                  validator: (v) =>
                      (!_shareWithAllClasses && (v == null || v.isEmpty))
                      ? 'Please select a class.'
                      : null,
                ),
              ],
              const SizedBox(height: 20),

              // File picker
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedFile != null
                          ? AppTheme.success
                          : AppTheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedFile != null
                        ? AppTheme.success.withOpacity(0.05)
                        : AppTheme.primary.withOpacity(0.04),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons.picture_as_pdf
                            : Icons.cloud_upload_outlined,
                        size: 48,
                        color: _selectedFile != null
                            ? AppTheme.error
                            : AppTheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFile != null
                            ? _selectedFile!.name
                            : 'Tap to select a PDF file',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedFile != null
                              ? AppTheme.primary
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ] else
                        const Text(
                          'PDF files only',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),

              if (_isUploading) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Uploading...'),
                    const Spacer(),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey[200],
                  color: AppTheme.primary,
                  minHeight: 6,
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload),
                  label: Text(
                    _isUploading ? 'Uploading...' : 'Upload Material',
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
      ),
    );
  }
}
