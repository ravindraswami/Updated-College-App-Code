import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';
import '../../widgets/common_widgets.dart';
import '../notes/upload_note_screen.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});
  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  final _auth = AuthService();
  final _svc = UserService();
  UserModel? _user;
  int _tab = 0;

  static const _hodColor = AppTheme.success;

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
      _HomeTab(user: _user, svc: _svc),
      _StudentsTab(svc: _svc),
      _ClassManagementTab(svc: _svc),
      _ApprovalsTab(svc: _svc),
      _user == null
          ? const LoadingWidget()
          : ProfileScreen(user: _user!, onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Portal'),
        backgroundColor: _hodColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload Notes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadNoteScreen()),
            ),
          ),
          if (_user?.erpId.isNotEmpty == true)
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
                    _user!.erpId,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
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
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
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

// ── Home ──────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final UserModel? user;
  final UserService svc;
  const _HomeTab({required this.user, required this.svc});
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
              gradient: const LinearGradient(
                colors: [AppTheme.success, Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Head of Department',
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
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: svc.getAllUsers(),
            builder: (_, snap) {
              final users = snap.data ?? [];
              final students = users.where((u) => u.role == 'student').length;
              final coords = users.where((u) => u.role == 'coordinator').length;
              final pending = users
                  .where((u) => !u.isApproved && u.role != 'student')
                  .length;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Students',
                          value: '$students',
                          icon: Icons.school,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Coordinators',
                          value: '$coords',
                          icon: Icons.people,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'Pending Staff Approvals',
                    value: '$pending',
                    icon: Icons.pending_actions,
                    color: AppTheme.warning,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Students tab (view all) ───────────────────────────────────
class _StudentsTab extends StatelessWidget {
  final UserService svc;
  const _StudentsTab({required this.svc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getUsersByRole('student'),
      builder: (_, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = snap.data!;
        if (students.isEmpty)
          return const EmptyWidget(
            message: 'No students yet.',
            icon: Icons.school_outlined,
          );
        return ListView.builder(
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
                  '${s.branch} • ${ClassConstants.shortLabel(s.classId)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Icon(
                  s.isApproved ? Icons.check_circle : Icons.pending,
                  color: s.isApproved ? AppTheme.success : AppTheme.warning,
                  size: 20,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Class Management — assign class + slot to coordinators ────
class _ClassManagementTab extends StatelessWidget {
  final UserService svc;
  const _ClassManagementTab({required this.svc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getUsersByRole('coordinator'),
      builder: (_, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final coords = snap.data!.where((c) => c.isApproved).toList();
        if (coords.isEmpty) {
          return const EmptyWidget(
            message:
                'No approved coordinators yet.\nApprove from Staff Approvals tab.',
            icon: Icons.people_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coords.length,
          itemBuilder: (_, i) => _CoordCard(coord: coords[i], svc: svc),
        );
      },
    );
  }
}

class _CoordCard extends StatelessWidget {
  final UserModel coord;
  final UserService svc;
  const _CoordCard({required this.coord, required this.svc});

  Future<void> _showAssignDialog(BuildContext context) async {
    String? selClass = coord.classId.isNotEmpty ? coord.classId : null;
    final startCtrl = TextEditingController(
      text: coord.hasSlot ? '${coord.slotStart}' : '',
    );
    final endCtrl = TextEditingController(
      text: coord.hasSlot ? '${coord.slotEnd}' : '',
    );

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Assign Class to ${coord.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class dropdown
                DropdownButtonFormField<String>(
                  value: selClass,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  hint: const Text('Select class'),
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
                  onChanged: (v) => setSt(() => selClass = v),
                ),
                const SizedBox(height: 16),
                // Slot range
                const Text(
                  'Student Slot Range',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Text(
                  'e.g. CC-1 gets students 1–20, CC-2 gets 21–40',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'From (e.g. 1)',
                          prefixIcon: Icon(Icons.start),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: endCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'To (e.g. 20)',
                          prefixIcon: Icon(Icons.last_page),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '• Student 1–20 → CC-1\n• Student 21–40 → CC-2\n• Student 41–60 → CC-3\n\n'
                    'Students are routed to the coordinator whose slot has capacity when they register.',
                    style: TextStyle(fontSize: 11, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class assignment removed.'),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ElevatedButton(
              onPressed: selClass == null
                  ? null
                  : () async {
                      final start = int.tryParse(startCtrl.text) ?? -1;
                      final end = int.tryParse(endCtrl.text) ?? -1;
                      if (start < 1 || end < start) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid slot range (e.g. 1 to 20).',
                            ),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await svc.assignClassToCoordinator(
                        coordinatorId: coord.id,
                        classId: selClass!,
                        classLabel: ClassConstants.labelFor(selClass!),
                        slotStart: start,
                        slotEnd: end,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${coord.name} assigned to '
                              '${ClassConstants.shortLabel(selClass!)} — Students $start–$end.',
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
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
            // Coordinator info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.secondary.withOpacity(0.12),
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
                      if (coord.erpId.isNotEmpty)
                        Text(
                          coord.erpId,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Class + slot info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasClass
                    ? AppTheme.success.withOpacity(0.07)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasClass
                      ? AppTheme.success.withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
              ),
              child: hasClass
                  ? Row(
                      children: [
                        const Icon(
                          Icons.class_,
                          color: AppTheme.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ClassConstants.shortLabel(coord.classId),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.success,
                                ),
                              ),
                              Text(
                                coord.classLabel,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (coord.hasSlot)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Students ${coord.slotStart}–${coord.slotEnd}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.class_outlined,
                          color: Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'No class assigned yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignDialog(context),
                icon: Icon(hasClass ? Icons.edit : Icons.add, size: 16),
                label: Text(
                  hasClass ? 'Edit Assignment' : 'Assign Class & Slot',
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

// ── Staff Approvals ───────────────────────────────────────────
class _ApprovalsTab extends StatelessWidget {
  final UserService svc;
  const _ApprovalsTab({required this.svc});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getAllUsers(),
      builder: (_, snap) {
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
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(u.name),
                subtitle: Text(
                  '${u.role} • ${u.email}',
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
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
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
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
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
