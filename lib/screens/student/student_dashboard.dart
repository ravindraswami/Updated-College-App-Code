import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_exam/screens/student/bonafide_apply_screen.dart';
import 'package:smart_exam/screens/student/character_cert_screen.dart';
import 'package:smart_exam/screens/student/exam_form_apply_screen.dart';
import 'package:smart_exam/screens/student/exam_list_screen.dart';
import 'package:smart_exam/screens/student/my_results_screen.dart';
import 'package:smart_exam/screens/student/scholarship_apply_screen.dart';
import 'package:smart_exam/screens/student/tc_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';

class StudentDashboard extends StatefulWidget {
  final int initialTab;
  const StudentDashboard({super.key, this.initialTab = 0});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _auth = AuthService();
  UserModel? _user;
  DateTime? _lastBackPress;

  // Bottom nav: 0=Home, 1=Profile
  late int _bottomIndex;

  // -1 = show Home dashboard, 0..6 = drawer section open
  int _drawerIndex = -1;

  static const _drawerItems = [
    DrawerItem(
      label: 'Examinations',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
    ),
    DrawerItem(
      label: 'My Results',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    DrawerItem(
      label: 'Study Materials',
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
    ),
    DrawerItem(
      label: 'Bonafide Certificate',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    DrawerItem(
      label: 'Transfer Certificate',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
    ),
    DrawerItem(
      label: 'Character Certificate',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium,
    ),
    DrawerItem(
      label: 'Exam Form',
      icon: Icons.edit_document,
      selectedIcon: Icons.edit_document,
    ),
    DrawerItem(
      label: 'Scholarship',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bottomIndex = widget.initialTab;
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _auth.getCurrentUserModel();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
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
    if (confirm != true) return;
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Go to a drawer section from home card tap
  void _openSection(int index) {
    setState(() {
      _drawerIndex = index;
      _bottomIndex = 0;
    });
  }

  String get _appBarTitle {
    if (_bottomIndex == 1) return 'My Profile';
    if (_drawerIndex == -1) return 'Smart ERP';
    return _drawerItems[_drawerIndex].label;
  }

  Widget _body() {
    if (_user == null) return const Center(child: CircularProgressIndicator());
    if (_drawerIndex == -1) {
      return _StudentHome(user: _user!, onSectionTap: _openSection);
    }
    switch (_drawerIndex) {
      case 0:
        return ExamListScreen(studentId: _user!.id);
      case 1:
        return MyResultsScreen(studentId: _user!.id);
      case 2:
        return NotesScreen(classId: _user?.classId ?? '');
      case 3:
        return BonafideApplyScreen(student: _user!);
      case 4:
        return TcScreen(student: _user!);
      case 5:
        return CharacterCertScreen(student: _user!);
      case 6:
        return ExamFormApplyScreen(student: _user!);
      case 7:
        return ScholarshipApplyScreen(student: _user!);
      default:
        return _StudentHome(user: _user!, onSectionTap: _openSection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // If inside a section, go back to home
        if (_drawerIndex != -1 && _bottomIndex == 0) {
          setState(() => _drawerIndex = -1);
          return;
        }
        // If on Profile tab, go back to Home
        if (_bottomIndex == 1) {
          setState(() => _bottomIndex = 0);
          return;
        }
        // Double-tap back to exit
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        // Second tap within 2 seconds — exit
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle),
          backgroundColor: AppTheme.primary,
          // Show back arrow when inside a section (not home)
          leading: _drawerIndex != -1 && _bottomIndex == 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _drawerIndex = -1),
                )
              : null,
          // Hamburger for drawer — show when on home or sections
          actions: [
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
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _user!.erpId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        drawer: AppDrawer(
          user: _user,
          selectedIndex: _drawerIndex < 0 ? 0 : _drawerIndex,
          items: _drawerItems,
          accentColor: AppTheme.primary,
          onItemTap: (i) => setState(() {
            _drawerIndex = i;
            _bottomIndex = 0;
          }),
          onLogout: _logout,
        ),
        body: _bottomIndex == 1
            ? (_user == null
                  ? const Center(child: CircularProgressIndicator())
                  : ProfileScreen(user: _user!, onLogout: _logout))
            : _body(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _bottomIndex,
          onDestinationSelected: (i) {
            setState(() {
              _bottomIndex = i;
              if (i == 0) _drawerIndex = -1; // go back to home
            });
          },
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STUDENT HOME DASHBOARD
// ─────────────────────────────────────────────────────────────
class _StudentHome extends StatelessWidget {
  final UserModel user;
  final void Function(int) onSectionTap;

  const _StudentHome({required this.user, required this.onSectionTap});

  @override
  Widget build(BuildContext context) {
    final name = user.nameAsPerHsc.isNotEmpty ? user.nameAsPerHsc : user.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome card ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF1E40AF)],
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                Text(
                  name.isNotEmpty ? name : 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoChip(icon: Icons.school_outlined, label: user.branch),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: '${user.year} ${user.semester}',
                    ),
                  ],
                ),
                if (user.classId.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoChip(
                    icon: Icons.class_outlined,
                    label: 'Class: ${user.classId}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Approval status ───────────────────────────────
          if (!user.isApproved) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_outlined, color: AppTheme.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your account is pending approval from your class coordinator.',
                      style: TextStyle(color: AppTheme.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Section cards ─────────────────────────────────
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Row 1
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  index: 0,
                  label: 'Examinations',
                  icon: Icons.quiz,
                  color: const Color(0xFF2563EB),
                  onTap: onSectionTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  index: 1,
                  label: 'My Results',
                  icon: Icons.bar_chart,
                  color: const Color(0xFF7C3AED),
                  onTap: onSectionTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  index: 2,
                  label: 'Study Materials',
                  icon: Icons.book,
                  color: const Color(0xFF0891B2),
                  onTap: onSectionTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  index: 3,
                  label: 'Bonafide Certificate',
                  icon: Icons.badge,
                  color: const Color(0xFF059669),
                  onTap: onSectionTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  index: 4,
                  label: 'Transfer Certificate',
                  icon: Icons.article,
                  color: const Color(0xFFD97706),
                  onTap: onSectionTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  index: 5,
                  label: 'Character Certificate',
                  icon: Icons.workspace_premium,
                  color: const Color(0xFFDC2626),
                  onTap: onSectionTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 4
          Row(
            children: [
              Expanded(
                child: _SectionCard(
                  index: 6,
                  label: 'Exam Form',
                  icon: Icons.edit_document,
                  color: const Color(0xFF0F766E),
                  onTap: onSectionTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SectionCard(
                  index: 7,
                  label: 'Scholarship',
                  icon: Icons.school,
                  color: const Color(0xFF7C3AED),
                  onTap: onSectionTap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Student info summary ──────────────────────────
          const Text(
            'My Profile Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileRow('ERP ID', user.erpId),
                  _ProfileRow('Branch', user.branch),
                  _ProfileRow('Year / Sem', '${user.year}  ${user.semester}'),
                  _ProfileRow(
                    'Class',
                    user.classId.isNotEmpty ? user.classId : '—',
                  ),
                  _ProfileRow(
                    'Mobile',
                    user.mobile.isNotEmpty ? user.mobile : '—',
                  ),
                  _ProfileRow(
                    'Status',
                    user.isApproved ? 'Approved ✓' : 'Pending Approval',
                    valueColor: user.isApproved
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section card widget ───────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final Color color;
  final void Function(int) onTap;
  final bool fullWidth;

  const _SectionCard({
    required this.index,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );

    return fullWidth ? card : card;
  }
}

// ── Info chip for welcome card ────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Profile summary row ───────────────────────────────────────
class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _ProfileRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
