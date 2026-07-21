import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/scholarship_service.dart';
import '../../models/user_model.dart';
import '../../models/scholarship_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';
import '../notes/upload_note_screen.dart';
import '../exam_form/exam_form_cc_tab.dart';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});
  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  final _auth = AuthService();
  final _svc = UserService();
  UserModel? _user;

  // Bottom nav: 0 = Home content, 1 = Profile
  int _bottomIndex = 0;

  // Drawer index:
  // 0 = Home, 1 = My Class Students, 2 = Pending Requests,
  // 3 = Notes, 4 = Exam Forms, 5 = Scholarship Forms
  int _drawerIndex = 0;

  static const _ccColor = Color(0xFF0891B2);

  static const _drawerTitles = [
    'Home',
    'My Class Students',
    'Pending Requests',
    'Study Materials',
    'Exam Forms',
    'Scholarship Forms',
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

  Widget _drawerContent() {
    if (_user == null) return const LoadingWidget();
    switch (_drawerIndex) {
      case 0:
        return _HomeTab(user: _user, svc: _svc);
      case 1:
        return _MyStudentsTab(coordId: _user!.id, svc: _svc);
      case 2:
        return _PendingTab(coordId: _user!.id, svc: _svc);
      case 3:
        return NotesScreen(classId: _classId);
      case 4:
        return _user == null
            ? const LoadingWidget()
            : ExamFormCcTab(coordinator: _user!);
      case 5:
        return _user == null
            ? const LoadingWidget()
            : _ScholarshipCcTab(coordinator: _user!);
      default:
        return _HomeTab(user: _user, svc: _svc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerTitles[_drawerIndex],
        ),
        backgroundColor: _ccColor,
        actions: [
          if (_user?.classId.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
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
      drawer: _CCDrawer(
        user: _user,
        selectedIndex: _drawerIndex,
        color: _ccColor,
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
          : _drawerContent(),
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
// CC DRAWER
// ─────────────────────────────────────────────────────────────
class _CCDrawer extends StatelessWidget {
  final UserModel? user;
  final int selectedIndex;
  final Color color;
  final void Function(int) onItemTap;
  final VoidCallback onLogout;

  const _CCDrawer({
    required this.user,
    required this.selectedIndex,
    required this.color,
    required this.onItemTap,
    required this.onLogout,
  });

  static const _items = [
    _DrawerEntry(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _DrawerEntry(
      label: 'My Class Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    _DrawerEntry(
      label: 'Pending Requests',
      icon: Icons.pending_outlined,
      selectedIcon: Icons.pending,
    ),
    _DrawerEntry(
      label: 'Study Materials',
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
    ),
    _DrawerEntry(
      label: 'Exam Forms',
      icon: Icons.edit_document,
      selectedIcon: Icons.edit_document,
    ),
    _DrawerEntry(
      label: 'Scholarship Forms',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = user?.name.isNotEmpty == true ? user!.name : '';
    final classLabel = user?.classId.isNotEmpty == true
        ? ClassConstants.labelFor(user!.classId)
        : 'No class assigned';

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Advisor',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (user?.classId.isNotEmpty == true)
                    Text(
                      classLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final selected = i == selectedIndex;
                return ListTile(
                  leading: Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: selected ? color : Colors.grey[600],
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? color : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  tileColor: selected ? color.withOpacity(0.08) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onItemTap(i);
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DrawerEntry {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _DrawerEntry({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

// ── Home ──────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final UserModel? user;
  final UserService svc;
  const _HomeTab({required this.user, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const LoadingWidget();
    final hasClass = user!.classId.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advisor',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  user!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user!.erpId.isNotEmpty)
                  Text(
                    user!.erpId,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                const SizedBox(height: 12),
                // Class + slot
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: hasClass
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.class_,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ClassConstants.shortLabel(user!.classId),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user!.classLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (user!.hasSlot) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Your slot: Students ${user!.slotStart}–${user!.slotEnd}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      : const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No class assigned yet. Contact your Incharge.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!hasClass)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have not been assigned a class yet. Contact your Incharge to get a class and student slot assigned.',
                      style: TextStyle(color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            )
          else
            StreamBuilder(
              stream: svc.getStudentsForCoordinator(user!.id),
              builder: (_, snap) {
                final approved = snap.data?.length ?? 0;
                return StreamBuilder(
                  stream: svc.getPendingStudentsForCoordinator(user!.id),
                  builder: (_, pSnap) {
                    final pending = pSnap.data?.length ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'My Students',
                            value: '$approved',
                            icon: Icons.check_circle,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Pending',
                            value: '$pending',
                            icon: Icons.pending,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── My Students (approved, assigned to this coordinator) ──────
class _MyStudentsTab extends StatelessWidget {
  final String coordId;
  final UserService svc;
  const _MyStudentsTab({required this.coordId, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (coordId.isEmpty)
      return const EmptyWidget(
        message: 'No class assigned.\nContact your Incharge.',
        icon: Icons.class_outlined,
      );

    return StreamBuilder<List<UserModel>>(
      stream: svc.getStudentsForCoordinator(coordId),
      builder: (_, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = snap.data!;
        if (students.isEmpty)
          return const EmptyWidget(
            message: 'No approved students in your slot yet.',
            icon: Icons.school_outlined,
          );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0891B2).withOpacity(0.07),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF0891B2), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${students.length} approved student(s) in your slot',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                itemBuilder: (_, i) => _StudentTile(s: students[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Pending requests (only this coordinator's students) ───────
class _PendingTab extends StatelessWidget {
  final String coordId;
  final UserService svc;
  const _PendingTab({required this.coordId, required this.svc});

  @override
  Widget build(BuildContext context) {
    if (coordId.isEmpty)
      return const EmptyWidget(
        message: 'No class assigned.\nContact your Incharge.',
        icon: Icons.pending_outlined,
      );

    return StreamBuilder<List<UserModel>>(
      stream: svc.getPendingStudentsForCoordinator(coordId),
      builder: (_, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final pending = snap.data!;
        if (pending.isEmpty)
          return const EmptyWidget(
            message: 'No pending requests in your slot.',
            icon: Icons.check_circle_outline,
          );

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.warning.withOpacity(0.07),
              child: Row(
                children: [
                  const Icon(Icons.pending, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${pending.length} pending request(s) in your slot',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pending.length,
                itemBuilder: (_, i) =>
                    _PendingCard(student: pending[i], svc: svc),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  final UserModel student;
  final UserService svc;
  const _PendingCard({required this.student, required this.svc});

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: AppTheme.warning.withOpacity(0.12),
                  child: Text(
                    student.displayName.isNotEmpty
                        ? student.displayName[0].toUpperCase()
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
                        student.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        student.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (student.mobile.isNotEmpty)
                        Text(
                          student.mobile,
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
            // Class + slot badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ClassConstants.shortLabel(student.classId),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    student.department,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
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
                      await svc.rejectUser(student.id);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${student.displayName}\'s request rejected.',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                    },
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
                    onPressed: () async {
                      await svc.approveUser(student.id);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${student.displayName} approved and can now login.',
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
  }
}

class _StudentTile extends StatelessWidget {
  final UserModel s;
  const _StudentTile({required this.s});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Text(
            s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : 'S',
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          s.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.email, style: const TextStyle(fontSize: 12)),
            if (s.erpId.isNotEmpty)
              Text(
                s.erpId,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(
          Icons.check_circle,
          color: AppTheme.success,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCHOLARSHIP CC TAB
// ─────────────────────────────────────────────────────────────
class _ScholarshipCcTab extends StatelessWidget {
  final UserModel coordinator;
  const _ScholarshipCcTab({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final svc = ScholarshipService();

    if (coordinator.classId.isEmpty) {
      return const EmptyWidget(
        message: 'No class assigned to you yet.\nAsk your Incharge to assign a class first.',
        icon: Icons.class_outlined,
      );
    }

    return StreamBuilder<List<ScholarshipModel>>(
      stream: svc.getPendingForClass(coordinator.classId),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) return const LoadingWidget();

        final forms = snap.data!;
        if (forms.isEmpty) {
          return EmptyWidget(
            message: 'No scholarship applications pending for class:\n${coordinator.classId}\n\nStudents will appear here after they apply.',
            icon: Icons.school_outlined,
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F766E).withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF0F766E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${forms.length} scholarship application(s) pending — ${coordinator.classId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: forms.length,
                itemBuilder: (_, i) => _ScholarshipCcCard(
                  app: forms[i],
                  svc: svc,
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

class _ScholarshipCcCard extends StatelessWidget {
  final ScholarshipModel app;
  final ScholarshipService svc;
  final UserModel coordinator;
  const _ScholarshipCcCard({required this.app, required this.svc, required this.coordinator});

  Future<void> _approve(BuildContext context) async {
    final remarksCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Scholarship Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approving for ${app.studentName}.',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.ccApprove(
      app.id,
      coordinator.name.isNotEmpty ? coordinator.name : coordinator.erpId,
      remarks: remarksCtrl.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${app.studentName}\'s scholarship application approved → Technical Staff.'),
        backgroundColor: AppTheme.success,
      ));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Scholarship Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejecting for ${app.studentName}.',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for Rejection *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.ccReject(
      app.id,
      coordinator.name.isNotEmpty ? coordinator.name : coordinator.erpId,
      remarks: ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'Rejected by Coordinator',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Application rejected.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                  child: Text(
                    app.studentName.isNotEmpty ? app.studentName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.studentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      Text('ERP: ${app.erpId}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${app.branch} ${app.year} — ${app.semester}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _row(Icons.card_giftcard_outlined, 'Scholarship', app.scholarshipType),
            _row(Icons.category_outlined, 'Caste Category', app.casteCategory),
            if (app.mobile.isNotEmpty) _row(Icons.phone_outlined, 'Mobile', app.mobile),
            if (app.pdfFileName.isNotEmpty)
              _row(Icons.attach_file, 'Uploaded Form', app.pdfFileName),
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
                    label: const Text('Approve → Technical'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
