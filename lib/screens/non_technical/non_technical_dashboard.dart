import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/auth_service.dart';
import '../../services/nt_file_service.dart';
import '../../models/user_model.dart';
import '../../models/nt_file_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'package:intl/intl.dart';

class NonTechnicalDashboard extends StatefulWidget {
  const NonTechnicalDashboard({super.key});
  @override
  State<NonTechnicalDashboard> createState() => _NonTechnicalDashboardState();
}

class _NonTechnicalDashboardState extends State<NonTechnicalDashboard> {
  final _auth = AuthService();
  final _svc = NtFileService();
  UserModel? _user;
  int _tab = 0;

  static const _ntColor = Color(0xFF7C3AED); // purple

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _auth.getCurrentUserModel();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(user: _user, color: _ntColor),
      _UploadTab(user: _user, svc: _svc),
      _MyFilesTab(user: _user, svc: _svc),
      _user == null
          ? const LoadingWidget()
          : ProfileScreen(user: _user!, onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Non-Technical Staff'),
        automaticallyImplyLeading: false,
        backgroundColor: _ntColor,
        actions: [
          if (_user?.erpId.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _user!.erpId,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
      body: _user == null ? const LoadingWidget() : pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'My Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Home tab ──────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final UserModel? user;
  final Color color;
  const _HomeTab({required this.user, required this.color});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Non-Technical Staff',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user?.erpId.isNotEmpty == true)
                  Text(
                    user!.erpId,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your uploaded files are visible only to the Principal.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1A7C3AED),
                child: Icon(Icons.upload_file, color: Color(0xFF7C3AED)),
              ),
              title: const Text(
                'Upload a File',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('PDF, images, Word, Excel — any file'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upload tab ────────────────────────────────────────────────
class _UploadTab extends StatefulWidget {
  final UserModel? user;
  final NtFileService svc;
  const _UploadTab({required this.user, required this.svc});
  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  PlatformFile? _file;
  bool _uploading = false;
  double _progress = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a title for this file.', isError: true);
      return;
    }
    if (_file == null) {
      _snack('Please select a file to upload.', isError: true);
      return;
    }
    setState(() {
      _uploading = true;
      _progress = 0.2;
    });
    try {
      final u = widget.user!;
      setState(() => _progress = 0.5);
      await widget.svc.uploadFile(
        uploadedBy: u.id,
        uploaderName: u.name,
        uploaderErpId: u.erpId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        file: _file!,
      );
      setState(() => _progress = 1.0);
      _snack(
        'File uploaded successfully. Principal can now view it.',
        isError: false,
      );
      setState(() {
        _titleCtrl.clear();
        _descCtrl.clear();
        _file = null;
      });
    } catch (e) {
      _snack(
        'Upload failed. Please check your internet connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload File for Principal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your file will be visible only to the Principal.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'File Title / Label',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _uploading ? null : _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _file != null
                      ? AppTheme.success
                      : const Color(0xFF7C3AED),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _file != null
                    ? AppTheme.success.withOpacity(0.05)
                    : const Color(0x0A7C3AED),
              ),
              child: Column(
                children: [
                  Icon(
                    _file != null
                        ? Icons.insert_drive_file
                        : Icons.cloud_upload_outlined,
                    size: 48,
                    color: _file != null
                        ? AppTheme.success
                        : const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _file != null ? _file!.name : 'Tap to select any file',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _file != null
                          ? AppTheme.primary
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_file != null)
                    Text(
                      '${(_file!.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    )
                  else
                    const Text(
                      'PDF, Images, Word, Excel, etc.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),

          if (_uploading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Uploading...'),
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
              color: const Color(0xFF7C3AED),
              backgroundColor: Colors.grey[200],
              minHeight: 6,
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_uploading || widget.user == null) ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
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
              label: Text(_uploading ? 'Uploading...' : 'Upload to Principal'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Files tab ──────────────────────────────────────────────
class _MyFilesTab extends StatelessWidget {
  final UserModel? user;
  final NtFileService svc;
  const _MyFilesTab({required this.user, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const LoadingWidget();
    return StreamBuilder<List<NtFileModel>>(
      stream: svc.getMyFiles(user!.id),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final files = snap.data!;
        if (files.isEmpty) {
          return const EmptyWidget(
            message:
                'No files uploaded yet.\nUse the Upload tab to send files to the Principal.',
            icon: Icons.folder_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: files.length,
          itemBuilder: (_, i) =>
              _FileCard(file: files[i], svc: svc, showDelete: true),
        );
      },
    );
  }
}

// ── File card (reused in both NT and Principal dashboards) ────
class NtFileCard extends StatelessWidget {
  final NtFileModel file;
  final NtFileService svc;
  final bool showDelete;
  const NtFileCard({
    super.key,
    required this.file,
    required this.svc,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) =>
      _FileCard(file: file, svc: svc, showDelete: showDelete);
}

class _FileCard extends StatelessWidget {
  final NtFileModel file;
  final NtFileService svc;
  final bool showDelete;
  const _FileCard({
    required this.file,
    required this.svc,
    required this.showDelete,
  });

  Color get _typeColor {
    switch (file.fileType.toLowerCase()) {
      case 'pdf':
        return AppTheme.error;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return AppTheme.primary;
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
        return AppTheme.success;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  file.fileType.toUpperCase().isEmpty
                      ? 'FILE'
                      : file.fileType.toUpperCase(),
                  style: TextStyle(
                    color: _typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (file.description.isNotEmpty)
                    Text(
                      file.description,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          file.uploaderName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'dd MMM yyyy  HH:mm',
                        ).format(file.uploadedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showDelete)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.error,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${file.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await svc.deleteFile(file.id, file.fileUrl);
              if (ctx.mounted)
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('File deleted.'),
                    backgroundColor: AppTheme.error,
                  ),
                );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
