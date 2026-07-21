import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';
import '../../utils/constants.dart';
import '../../utils/academic_data.dart';
import '../../widgets/common_widgets.dart';
import '../notes/upload_note_screen.dart';
import '../professor/subject_management_screen.dart';
import 'hod_assignment_screen.dart';
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
    final scopeBranch = AppConstants.branchForInchargeRole(_user?.role ?? '');
    final portalTitle = _user == null
        ? 'Incharge Portal'
        : '${AppConstants.roleLabel(_user!.role)} Portal';

    final pages = [
      _HomeTab(user: _user, svc: _svc, scopeBranch: scopeBranch),
      _StudentsTab(svc: _svc, scopeBranch: scopeBranch),
      _user == null
          ? const LoadingWidget()
          : _SubjectsTab(hod: _user!, scopeBranch: scopeBranch),
      _ApprovalsTab(svc: _svc),
      _user == null
          ? const LoadingWidget()
          : ProfileScreen(user: _user!, onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(portalTitle),
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
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
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
  final String scopeBranch;
  const _HomeTab({required this.user, required this.svc, this.scopeBranch = ''});
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
                Text(
                  user == null ? 'Incharge' : AppConstants.roleLabel(user!.role),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              final students = users
                  .where((u) =>
                      u.role == 'student' &&
                      (scopeBranch.isEmpty || u.branch == scopeBranch))
                  .length;
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
                          title: 'Advisors',
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
  final String scopeBranch; // '' = unscoped (legacy hod sees all)
  const _StudentsTab({required this.svc, this.scopeBranch = ''});

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
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await svc.deleteUser(student.id, student.erpId);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: svc.getUsersByRole('student'),
      builder: (_, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final students = scopeBranch.isEmpty
            ? snap.data!
            : snap.data!.where((s) => s.branch == scopeBranch).toList();
        if (students.isEmpty)
          return EmptyWidget(
            message: scopeBranch.isEmpty
                ? 'No students yet.'
                : 'No students yet in ${AcademicData.branchFullLabel(scopeBranch)}.',
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
                  '${s.branch} • ${ClassConstants.shortLabel(s.classId)}\nID: ${s.erpId}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s.isApproved ? Icons.check_circle : Icons.pending,
                      color: s.isApproved ? AppTheme.success : AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.error,
                      ),
                      tooltip: 'Delete Student',
                      onPressed: () => _confirmDelete(context, s),
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

// ── Subjects tab: Manage Subjects + Assign Advisor/Teacher, no top clutter ──
class _SubjectsTab extends StatefulWidget {
  final UserModel hod;
  final String scopeBranch;
  const _SubjectsTab({required this.hod, this.scopeBranch = ''});

  @override
  State<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<_SubjectsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppTheme.success.withOpacity(0.08),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.success,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.success,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Manage Subjects'),
              Tab(text: 'Assign Advisor / Teacher'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              SubjectManagementBody(
                user: widget.hod,
                canAdd: true,
                fixedBranch: widget.scopeBranch,
              ),
              HodAssignmentBody(
                hod: widget.hod,
                fixedBranch: widget.scopeBranch,
              ),
            ],
          ),
        ),
      ],
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
    // Pre-fill branch/year from existing classId
    String? selBranch = selClass != null
        ? ClassConstants.branchFrom(selClass)
        : null;
    String? selYear;
    // Infer year from existing sem
    if (selClass != null) {
      final sem = ClassConstants.semesterFrom(selClass);
      const semToYear = {
        'SEM-I': 'FY',
        'SEM-II': 'FY',
        'SEM-III': 'SY',
        'SEM-IV': 'SY',
        'SEM-V': 'TY',
        'SEM-VI': 'TY',
        'SEM-VII': 'LY',
        'SEM-VIII': 'LY',
      };
      selYear = semToYear[sem];
    }

    final startCtrl = TextEditingController(
      text: coord.hasSlot ? '${coord.slotStart}' : '',
    );
    final endCtrl = TextEditingController(
      text: coord.hasSlot ? '${coord.slotEnd}' : '',
    );

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          final branches = ClassConstants.allBranchIds;
          final years = selBranch != null
              ? ClassConstants.yearsForBranch(selBranch!)
              : <YearEntry>[];
          final sems = (selBranch != null && selYear != null)
              ? ClassConstants.semsForBranchYear(selBranch!, selYear!)
              : <String>[];

          return AlertDialog(
            title: Text('Assign Class to ${coord.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branch
                  DropdownButtonFormField<String>(
                    value: selBranch,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    hint: const Text('Select branch'),
                    items: branches
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
                    onChanged: (v) => setSt(() {
                      selBranch = v;
                      selYear = null;
                      selClass = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Year
                  DropdownButtonFormField<String>(
                    value: selYear,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    hint: const Text('Select year'),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(
                            value: y.id,
                            child: Text(y.label),
                          ),
                        )
                        .toList(),
                    onChanged: selBranch == null
                        ? null
                        : (v) => setSt(() {
                            selYear = v;
                            selClass = null;
                          }),
                  ),
                  const SizedBox(height: 12),
                  // Semester
                  DropdownButtonFormField<String>(
                    value: selClass,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Semester',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    hint: const Text('Select semester'),
                    items: sems
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
                    onChanged: selYear == null
                        ? null
                        : (v) => setSt(() => selClass = v),
                  ),
                  const SizedBox(height: 16),
                  // Slot range
                  const Text(
                    'Student Slot Range',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Text(
                    'Enter the serial number range from the Student ID.\n'
                    'e.g. 2025BTLT001–025 → enter 1 to 25 for CC1\n'
                    '     2025BTLT026–050 → enter 26 to 50 for CC2',
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
                            labelText: 'To (e.g. 25)',
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
                      '• 2025BTLT001–025  →  CC1 (enter 1 to 25)\n'
                      '• 2025BTLT026–050  →  CC2 (enter 26 to 50)\n\n'
                      'When a student registers, the trailing serial of their\n'
                      'Student ID is matched to the coordinator\'s range.',
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
                                'Please enter a valid slot range (e.g. 1 to 25).',
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
          );
        },
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
                                    'Serial ${coord.slotStart.toString().padLeft(3, '0')}–${coord.slotEnd.toString().padLeft(3, '0')}',
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
