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

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});
  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  final _auth = AuthService();
  final _userSvc = UserService();
  UserModel? _user;
  int _bottomIndex = 0;
  int _drawerIndex = 0;

  static const _drawerItems = [
    DrawerItem(
      label: 'Students',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    DrawerItem(
      label: 'Class Management',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
    ),
    DrawerItem(
      label: 'Staff Approvals',
      icon: Icons.approval_outlined,
      selectedIcon: Icons.approval,
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
        return _StudentsTab(svc: _userSvc);
      case 1:
        return _ClassManagementTab(svc: _userSvc);
      case 2:
        return _ApprovalsTab(svc: _userSvc);
      default:
        return _StudentsTab(svc: _userSvc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerItems[_drawerIndex].label,
        ),
        backgroundColor: AppTheme.success,
      ),
      drawer: AppDrawer(
        user: _user,
        selectedIndex: _drawerIndex,
        items: _drawerItems,
        accentColor: AppTheme.success,
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

// ── Students tab ─────────────────────────────────────────────
class _StudentsTab extends StatelessWidget {
  final UserService svc;
  const _StudentsTab({required this.svc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getUsersByRole('student'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = snap.data!;
        final approved = students.where((s) => s.isApproved).length;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.success.withOpacity(0.06),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total',
                      value: '${students.length}',
                      icon: Icons.people,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Approved',
                      value: '$approved',
                      icon: Icons.check_circle,
                      color: AppTheme.success,
                    ),
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
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Text(
                          s.displayName.isNotEmpty
                              ? s.displayName[0].toUpperCase()
                              : 'S',
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
                      subtitle: Text(
                        '${s.branch} — ${ClassConstants.shortLabel(s.classId)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Icon(
                        s.isApproved ? Icons.check_circle : Icons.pending,
                        color: s.isApproved
                            ? AppTheme.success
                            : AppTheme.warning,
                        size: 20,
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

// ── Class Management tab ──────────────────────────────────────
class _ClassManagementTab extends StatelessWidget {
  final UserService svc;
  const _ClassManagementTab({required this.svc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getUsersByRole('coordinator'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final coordinators = snap.data!.where((c) => c.isApproved).toList();
        if (coordinators.isEmpty)
          return const EmptyWidget(
            message:
                'No approved coordinators yet.\nApprove from Staff Approvals.',
            icon: Icons.people_outlined,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coordinators.length,
          itemBuilder: (_, i) => _CoordCard(coord: coordinators[i], svc: svc),
        );
      },
    );
  }
}

class _CoordCard extends StatelessWidget {
  final UserModel coord;
  final UserService svc;
  const _CoordCard({required this.coord, required this.svc});

  Future<void> _assign(BuildContext context) async {
    String? sel = coord.classId.isNotEmpty ? coord.classId : null;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Assign Class — ${coord.name}'),
          content: DropdownButtonFormField<String>(
            value: sel,
            isExpanded: true,
            hint: const Text('Select class'),
            decoration: const InputDecoration(
              labelText: 'Class',
              prefixIcon: Icon(Icons.class_outlined),
            ),
            items: ClassConstants.allClassIds
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(
                      '${ClassConstants.shortLabel(id)} — ${ClassConstants.labelFor(id)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setSt(() => sel = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (coord.classId.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await svc.removeClassFromCoordinator(coord.id);
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ElevatedButton(
              onPressed: sel == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await svc.assignClassToCoordinator(
                        coordinatorId: coord.id,
                        classId: sel!,
                        classLabel: ClassConstants.labelFor(sel!),
                      );
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${ClassConstants.shortLabel(sel!)} assigned to ${coord.name}.',
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
              ),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasClass = coord.classId.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.secondary.withOpacity(0.15),
                  child: Text(
                    coord.name.isNotEmpty ? coord.name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: AppTheme.secondary,
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
                        coord.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        coord.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _assign(context),
                icon: Icon(hasClass ? Icons.edit : Icons.add, size: 16),
                label: Text(
                  hasClass
                      ? 'Change — ${ClassConstants.shortLabel(coord.classId)}'
                      : 'Assign Class',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasClass
                      ? AppTheme.secondary
                      : AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff Approvals tab ───────────────────────────────────────
class _ApprovalsTab extends StatelessWidget {
  final UserService svc;
  const _ApprovalsTab({required this.svc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getAllUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final pending = snap.data!
            .where(
              (u) =>
                  !u.isApproved &&
                  ['professor', 'coordinator'].contains(u.role),
            )
            .toList();
        if (pending.isEmpty)
          return const EmptyWidget(
            message: 'No pending approvals.',
            icon: Icons.check_circle_outline,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (_, i) {
            final u = pending[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.warning.withOpacity(0.1),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(u.name),
                subtitle: Text(
                  '${u.email}\n${u.role}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
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
                        if (ctx.mounted)
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('${u.name} approved.'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: AppTheme.error),
                      onPressed: () async {
                        await svc.rejectUser(u.id);
                        if (ctx.mounted)
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('${u.name} rejected.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
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
