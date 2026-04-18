import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';
import '../notes/upload_note_screen.dart';
import '../../models/scholarship_model.dart';
import '../../services/scholarship_service.dart';
import '../notes/pdf_viewer_screen.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});
  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  final _auth = AuthService();
  final _userSvc = UserService();
  UserModel? _user;
  int _bottomIndex = 0; // 0=Home, 1=Profile
  int _drawerIndex = 0; // 0=MyClass, 1=Pending, 2=Notes, 3=ScholarshipReview

  static const _drawerItems = [
    DrawerItem(
      label: 'My Class Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    DrawerItem(
      label: 'Pending Requests',
      icon: Icons.pending_outlined,
      selectedIcon: Icons.pending,
    ),
    DrawerItem(
      label: 'Study Materials',
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
    ),
    DrawerItem(
      label: 'Scholarship Review',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
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

  String get _classId => _user?.classId ?? '';

  Widget _drawerPage() {
    if (_user == null) return const LoadingWidget();
    switch (_drawerIndex) {
      case 0:
        return _MyClassTab(classId: _classId, svc: _userSvc);
      case 1:
        return _PendingTab(classId: _classId, svc: _userSvc);
      case 2:
        return NotesScreen(classId: _classId);
      case 3:
        return _ScholarshipReviewTab(coordinator: _user!);
      default:
        return _MyClassTab(classId: _classId, svc: _userSvc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerItems[_drawerIndex].label,
        ),
        backgroundColor: const Color(0xFF0891B2),
        actions: [
          if (_user?.classId.isNotEmpty == true && _bottomIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ClassConstants.shortLabel(_user!.classId),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          if (_drawerIndex == 2 && _bottomIndex == 0)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload Notes',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadNoteScreen(classId: _classId),
                ),
              ),
            ),
        ],
      ),
      drawer: AppDrawer(
        user: _user,
        selectedIndex: _drawerIndex,
        items: _drawerItems,
        accentColor: const Color(0xFF0891B2),
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

// ── My class students tab ─────────────────────────────────────
class _MyClassTab extends StatelessWidget {
  final String classId;
  final UserService svc;
  const _MyClassTab({required this.classId, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (classId.isEmpty)
      return const EmptyWidget(
        message: 'No class assigned.\nContact your HOD.',
        icon: Icons.class_outlined,
      );
    return StreamBuilder(
      stream: svc.getStudentsByClass(classId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = snap.data!.where((s) => s.isApproved).toList();
        if (students.isEmpty)
          return EmptyWidget(
            message:
                'No approved students in ${ClassConstants.shortLabel(classId)} yet.',
            icon: Icons.school_outlined,
          );
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0891B2).withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF0891B2), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${ClassConstants.shortLabel(classId)} — ${students.length} Students',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (_, i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        students[i].displayName.isNotEmpty
                            ? students[i].displayName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      students[i].displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      students[i].email,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Pending approvals tab ─────────────────────────────────────
class _PendingTab extends StatelessWidget {
  final String classId;
  final UserService svc;
  const _PendingTab({required this.classId, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (classId.isEmpty)
      return const EmptyWidget(
        message: 'No class assigned.\nContact your HOD.',
        icon: Icons.pending_outlined,
      );
    return StreamBuilder(
      stream: svc.getPendingStudentsForClass(classId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final pending = snap.data!;
        if (pending.isEmpty)
          return EmptyWidget(
            message:
                'No pending requests for ${ClassConstants.shortLabel(classId)}.',
            icon: Icons.check_circle_outline,
          );
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.warning.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.pending, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${pending.length} pending request(s) — ${ClassConstants.shortLabel(classId)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pending.length,
                itemBuilder: (_, i) {
                  final s = pending[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.warning.withOpacity(
                                  0.12,
                                ),
                                child: Text(
                                  s.displayName.isNotEmpty
                                      ? s.displayName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      s.email,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await svc.rejectUser(s.id);
                                    if (ctx.mounted)
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${s.displayName}\'s request rejected.',
                                          ),
                                          backgroundColor: AppTheme.error,
                                        ),
                                      );
                                  },
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                    side: const BorderSide(
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await svc.approveUser(s.id);
                                    if (ctx.mounted)
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${s.displayName} approved.',
                                          ),
                                          backgroundColor: AppTheme.success,
                                        ),
                                      );
                                  },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                  ),
                                ),
                              ),
                            ],
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

// ── Scholarship review tab — CC approves/rejects ─────────────
class _ScholarshipReviewTab extends StatelessWidget {
  final UserModel coordinator;
  const _ScholarshipReviewTab({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final classId = coordinator.classId;

    if (classId.isEmpty) {
      return const EmptyWidget(
        message: 'No class assigned.\nContact your HOD.',
        icon: Icons.school_outlined,
      );
    }

    return StreamBuilder<List<ScholarshipModel>>(
      stream: ScholarshipService().getPendingForClass(classId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyWidget(
            message: 'No pending scholarship requests\nfor your class.',
            icon: Icons.school_outlined,
          );
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primary.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length} pending scholarship request(s)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) => _ScholarshipRequestCard(
                  item: list[i],
                  coordinator: coordinator,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScholarshipRequestCard extends StatelessWidget {
  final ScholarshipModel item;
  final UserModel coordinator;
  const _ScholarshipRequestCard({
    required this.item,
    required this.coordinator,
  });

  String get _statusLabel {
    switch (item.status) {
      case 'pending_cc':
        return 'Pending your approval';
      case 'pending_technical':
        return 'Forwarded to Technical';
      case 'approved':
        return 'Approved';
      case 'cc_rejected':
        return 'Rejected by you';
      case 'rejected':
        return 'Rejected by Technical';
      default:
        return item.status;
    }
  }

  Color get _statusColor {
    switch (item.status) {
      case 'approved':
        return AppTheme.success;
      case 'cc_rejected':
      case 'rejected':
        return AppTheme.error;
      case 'pending_technical':
        return AppTheme.secondary;
      default:
        return AppTheme.warning;
    }
  }

  Future<void> _approve(BuildContext ctx) async {
    final remarksCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Approve Scholarship Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Approve ${item.studentName}\'s application for "${item.scholarshipType}"?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                hintText: 'Add any notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Approve & Forward'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ScholarshipService().ccApprove(
      item.id,
      coordinator.displayName,
      remarks: remarksCtrl.text.trim(),
    );
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            '${item.studentName}\'s request approved and forwarded to Technical staff.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext ctx) async {
    final remarksCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Scholarship Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${item.studentName}\'s application?'),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection',
                hintText: 'Please provide a reason...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ScholarshipService().ccReject(
      item.id,
      coordinator.displayName,
      remarks: remarksCtrl.text.trim(),
    );
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('${item.studentName}\'s request has been rejected.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: Text(
                    item.studentName.isNotEmpty
                        ? item.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        item.erpId,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${item.branch} • ${item.year} • ${item.semester}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Scholarship details
            _row('Scholarship Type', item.scholarshipType),
            _row('Caste Category', item.casteCategory),
            _row('Religion / Caste', '${item.religion} / ${item.caste}'),
            _row('Mobile', item.mobile),
            _row('Applied On', _formatDate(item.createdAt)),

            // PDF button
            if (item.pdfUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: '${item.studentName} — Scholarship Form',
                      pdfUrl: item.pdfUrl,
                    ),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf, color: AppTheme.error),
                label: const Text('View Scholarship Form'),
              ),
            ],

            // Action buttons (only if pending_cc)
            if (item.status == 'pending_cc') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(context),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // CC remarks (if already acted)
            if (item.ccRemarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'Your remarks: ${item.ccRemarks}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
