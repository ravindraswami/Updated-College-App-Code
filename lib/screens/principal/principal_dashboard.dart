import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/nt_file_service.dart';
import '../../models/nt_file_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'monthly_report_screen.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});
  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  final _auth = AuthService();
  final _userSvc = UserService();
  UserModel? _user;
  int _bottomIndex = 0;
  int _drawerIndex = 0;

  static const _drawerItems = [
    DrawerItem(
      label: 'All Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    DrawerItem(
      label: 'All Staff',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
    ),
    DrawerItem(
      label: 'Pending Approvals',
      icon: Icons.approval_outlined,
      selectedIcon: Icons.approval,
    ),
    DrawerItem(
      label: 'NT Staff Files',
      icon: Icons.folder_special_outlined,
      selectedIcon: Icons.folder_special,
    ),
    DrawerItem(
      label: 'Analytics',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
    ),
    DrawerItem(
      label: 'Monthly Reports',
      icon: Icons.summarize_outlined,
      selectedIcon: Icons.summarize,
    ),
  ];

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
        content: const Text('Are you sure you want to logout?'),
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

  Widget _drawerPage() {
    if (_user == null) return const LoadingWidget();
    switch (_drawerIndex) {
      case 0:
        return _AllStudentsTab(svc: _userSvc);
      case 1:
        return _AllStaffTab(svc: _userSvc);
      case 2:
        return _PendingApprovalsTab(svc: _userSvc);
      case 3:
        return const _NtFilesTab();
      case 4:
        return _AnalyticsTab(svc: _userSvc);
      case 5:
        return const MonthlyReportScreen();
      default:
        return _AllStudentsTab(svc: _userSvc);
    }
  }

  @override
  Widget build(BuildContext context) {
    const principalColor = Color(0xFF7C3AED);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerItems[_drawerIndex].label,
        ),
        backgroundColor: principalColor,
      ),
      drawer: AppDrawer(
        user: _user,
        selectedIndex: _drawerIndex,
        items: _drawerItems,
        accentColor: principalColor,
        onItemTap: (i) => setState(() {
          _drawerIndex = i;
          _bottomIndex = 0;
        }),
        onLogout: _logout,
      ),
      body: _bottomIndex == 1
          ? (_user == null
                ? const LoadingWidget()
                : ProfileScreen(user: _user!, onLogout: _logout))
          : _drawerPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => setState(() => _bottomIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
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

// ─────────────────────────────────────────────────────────────
// All Students Tab
// ─────────────────────────────────────────────────────────────
class _AllStudentsTab extends StatelessWidget {
  final UserService svc;
  const _AllStudentsTab({required this.svc});

  Future<void> _confirmDelete(BuildContext context, UserModel student) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to permanently delete '
          '"${student.displayName}" (${student.erpId})?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await svc.deleteUser(student.id, student.erpId ?? '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.displayName} deleted.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getUsersByRole('student'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = snap.data!;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.purple.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${students.length} Total Students',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF7C3AED).withOpacity(0.1),
                        child: Text(
                          s.displayName.isNotEmpty
                              ? s.displayName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        s.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.branch} • ${s.classId}\nID: ${s.erpId ?? '—'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            s.isApproved
                                ? Icons.check_circle
                                : Icons.pending,
                            color: s.isApproved
                                ? AppTheme.success
                                : AppTheme.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.error),
                            tooltip: 'Delete Student',
                            onPressed: () => _confirmDelete(ctx, s),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// All Staff Tab
// ─────────────────────────────────────────────────────────────
class _AllStaffTab extends StatelessWidget {
  final UserService svc;
  const _AllStaffTab({required this.svc});

  Future<void> _confirmDelete(BuildContext context, dynamic u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text(
          'Are you sure you want to delete "${u.name}" (${AppConstants.roleLabel(u.role)})?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await svc.deleteUser(u.id, u.erpId ?? '');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${u.name} deleted successfully.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getAllUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final staff = snap.data!
            .where(
              (u) => [
                'professor',
                'coordinator',
                'ug_incharge',
                'pg_incharge',
                'hod',
                'principal',
                'technical',
                'non_technical',
              ].contains(u.role),
            )
            .toList();
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: staff.length,
          itemBuilder: (_, i) {
            final u = staff[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  u.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${AppConstants.roleLabel(u.role)}  •  ${u.erpId ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      u.isApproved ? Icons.verified : Icons.pending,
                      color: u.isApproved ? AppTheme.success : AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    // Fix 3: delete button (principal can delete staff/Incharge)
                    if (u.role != 'principal')
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        tooltip: 'Delete ${AppConstants.roleLabel(u.role)}',
                        onPressed: () => _confirmDelete(ctx, u),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pending Approvals Tab
// ─────────────────────────────────────────────────────────────
class _PendingApprovalsTab extends StatelessWidget {
  final UserService svc;
  const _PendingApprovalsTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getAllUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final pending = snap.data!.where((u) => !u.isApproved).toList();
        if (pending.isEmpty) {
          return const EmptyWidget(
            message: 'No pending approvals.',
            icon: Icons.check_circle_outline,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: pending.length,
          itemBuilder: (_, i) {
            final u = pending[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.warning.withOpacity(0.1),
                  child: Text(
                    u.displayName.isNotEmpty
                        ? u.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(u.displayName),
                subtitle: Text(
                  '${AppConstants.roleLabel(u.role)} • ${u.email}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                      ),
                      onPressed: () async {
                        await svc.approveUser(u.id);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('${u.displayName} approved.'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppTheme.error),
                      onPressed: () async {
                        await svc.rejectUser(u.id);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('${u.displayName} rejected.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NT Staff Files Tab  (visible to Principal only)
// ─────────────────────────────────────────────────────────────
class _NtFilesTab extends StatefulWidget {
  const _NtFilesTab();

  @override
  State<_NtFilesTab> createState() => _NtFilesTabState();
}

class _NtFilesTabState extends State<_NtFilesTab> {
  final _svc = NtFileService();
  String _filterUploader = '';
  DateTime? _filterDate;
  String _filterType = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter bar ──────────────────────────────────────
        Container(
          color: const Color(0xFF7C3AED).withOpacity(0.06),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFF7C3AED),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter Files',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  if (_filterUploader.isNotEmpty ||
                      _filterDate != null ||
                      _filterType != 'All')
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _filterUploader = '';
                        _filterDate = null;
                        _filterType = 'All';
                      }),
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // File type chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'PDF', 'Image', 'Word', 'Excel', 'Other']
                      .map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              type,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _filterType == type,
                            onSelected: (_) =>
                                setState(() => _filterType = type),
                            selectedColor: const Color(
                              0xFF7C3AED,
                            ).withOpacity(0.2),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),
              // Search + date filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by uploader name...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => _filterUploader = v.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      _filterDate != null
                          ? '${_filterDate!.day}/${_filterDate!.month}'
                          : 'Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _filterDate = picked);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── File list ────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<NtFileModel>>(
            stream: _svc.getAllFiles(),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var files = snap.data!;

              // Apply filters
              if (_filterUploader.isNotEmpty) {
                files = files
                    .where(
                      (f) => f.uploaderName.toLowerCase().contains(
                        _filterUploader,
                      ),
                    )
                    .toList();
              }
              if (_filterDate != null) {
                files = files
                    .where(
                      (f) =>
                          f.uploadedAt.year == _filterDate!.year &&
                          f.uploadedAt.month == _filterDate!.month &&
                          f.uploadedAt.day == _filterDate!.day,
                    )
                    .toList();
              }
              if (_filterType != 'All') {
                const typeMap = {
                  'PDF': ['pdf'],
                  'Image': ['jpg', 'jpeg', 'png', 'gif', 'webp'],
                  'Word': ['doc', 'docx'],
                  'Excel': ['xls', 'xlsx'],
                };
                if (_filterType == 'Other') {
                  const allKnown = [
                    'pdf',
                    'jpg',
                    'jpeg',
                    'png',
                    'gif',
                    'webp',
                    'doc',
                    'docx',
                    'xls',
                    'xlsx',
                  ];
                  files = files
                      .where(
                        (f) => !allKnown.contains(f.fileType.toLowerCase()),
                      )
                      .toList();
                } else {
                  final validExts = typeMap[_filterType] ?? [];
                  files = files
                      .where(
                        (f) => validExts.contains(f.fileType.toLowerCase()),
                      )
                      .toList();
                }
              }

              if (files.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No files match the current filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${files.length} file(s)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Visible only to Principal',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: files.length,
                      itemBuilder: (_, i) =>
                          _NtPrincipalFileCard(file: files[i]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NT File Card
// ─────────────────────────────────────────────────────────────
class _NtPrincipalFileCard extends StatelessWidget {
  final NtFileModel file;
  const _NtPrincipalFileCard({required this.file});

  Color get _typeColor {
    switch (file.fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Colors.blue;
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File type badge
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
                  // Uploader
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
                          '${file.uploaderName} (${file.uploaderErpId})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Date + time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${file.uploadedAt.day.toString().padLeft(2, '0')}/'
                        '${file.uploadedAt.month.toString().padLeft(2, '0')}/'
                        '${file.uploadedAt.year}  '
                        '${file.uploadedAt.hour.toString().padLeft(2, '0')}:'
                        '${file.uploadedAt.minute.toString().padLeft(2, '0')}',
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Analytics Tab
// ─────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final UserService svc;
  const _AnalyticsTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getAllUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final users = snap.data!;
        final byRole = <String, int>{};
        for (final u in users) {
          byRole[u.role] = (byRole[u.role] ?? 0) + 1;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...byRole.entries.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.people, color: Color(0xFF7C3AED)),
                    title: Text(
                      AppConstants.roleLabel(e.key),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${e.value}',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
