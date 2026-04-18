import 'package:flutter/material.dart';
import 'package:smart_exam/screens/student/bonafide_apply_screen.dart';
import 'package:smart_exam/screens/student/exam_list_screen.dart';
import 'package:smart_exam/screens/student/my_results_screen.dart';
import 'package:smart_exam/screens/student/scholarship_apply_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';

class StudentDashboard extends StatefulWidget {
  final int initialTab; // 0=Home, 1=Profile
  const StudentDashboard({super.key, this.initialTab = 0});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _auth = AuthService();
  UserModel? _user;

  // Bottom nav: 0=Home, 1=Profile
  late int _bottomIndex;

  // Drawer content index
  // 0=Exams, 1=Results, 2=Notes, 3=Bonafide, 4=Scholarship
  int _drawerIndex = 0;

  // Drawer items
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

  // Build drawer content page
  Widget _drawerPage() {
    if (_user == null) return const Center(child: CircularProgressIndicator());
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
        return ScholarshipApplyScreen(student: _user!);
      default:
        return ExamListScreen(studentId: _user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerItems[_drawerIndex].label,
        ),
        backgroundColor: AppTheme.primary,
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
        selectedIndex: _drawerIndex,
        items: _drawerItems,
        accentColor: AppTheme.primary,
        onItemTap: (i) => setState(() {
          _drawerIndex = i;
          _bottomIndex = 0; // switch to content view
        }),
        onLogout: _logout,
      ),
      body: _bottomIndex == 1
          ? (_user == null
                ? const Center(child: CircularProgressIndicator())
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
