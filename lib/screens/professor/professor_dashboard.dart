import 'package:flutter/material.dart';
import 'package:smart_exam/screens/professor/exam_management_screen.dart';
import 'package:smart_exam/screens/professor/professor_results_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import 'subject_management_screen.dart';
import '../profile/profile_screen.dart';
import '../notes/notes_screen.dart';
import '../notes/upload_note_screen.dart';

class ProfessorDashboard extends StatefulWidget {
  const ProfessorDashboard({super.key});
  @override
  State<ProfessorDashboard> createState() => _ProfessorDashboardState();
}

class _ProfessorDashboardState extends State<ProfessorDashboard> {
  final _auth = AuthService();
  UserModel? _user;
  int _bottomIndex = 0;
  int _drawerIndex = 0;

  static const _drawerItems = [
    DrawerItem(
      label: 'Exam Management',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
    ),
    DrawerItem(
      label: 'Student Results',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    DrawerItem(
      label: 'Study Materials',
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
    ),
    DrawerItem(
      label: 'Subjects',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
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
        return ExamManagementScreen(professorId: _user!.id);
      case 1:
        return ProfessorResultsScreen(professorId: _user!.id);
      case 2:
        return const NotesScreen();
      case 3:
        return SubjectManagementScreen(professor: _user!);
      default:
        return ExamManagementScreen(professorId: _user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerItems[_drawerIndex].label,
        ),
        backgroundColor: AppTheme.secondary,
        actions: [
          if (_drawerIndex == 2 && _bottomIndex == 0)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload Notes',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadNoteScreen()),
              ),
            ),
        ],
      ),
      drawer: AppDrawer(
        user: _user,
        selectedIndex: _drawerIndex,
        items: _drawerItems,
        accentColor: AppTheme.secondary,
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
