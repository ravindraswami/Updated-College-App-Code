import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/exam_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/student_list_widget.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});
  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  final _authService = AuthService();
  UserModel? _user;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PrincipalHomeTab(user: _user),
      const StudentListWidget(),
      _AllUsersTab(),
      _CollegeAnalyticsTab(),
      _user == null
          ? const LoadingWidget()
          : ProfileScreen(user: _user!, onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Principal Portal'),
            const Spacer(),
            if (_user?.erpId.isNotEmpty == true)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.error,
      ),
      body: _user == null ? const LoadingWidget() : pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
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
            label: 'All Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
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

class _PrincipalHomeTab extends StatelessWidget {
  final UserModel? user;
  const _PrincipalHomeTab({required this.user});
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
                colors: [AppTheme.error, Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Principal',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  user?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: UserService().getAllUsers(),
            builder: (_, snap) {
              final users = snap.data ?? [];
              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Users',
                      value: '${users.length}',
                      icon: Icons.people,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Students',
                      value:
                          '${users.where((u) => u.role == "student").length}',
                      icon: Icons.school,
                      color: AppTheme.secondary,
                    ),
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

class _AllUsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: UserService().getAllUsers(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final users = snap.data!;
        if (users.isEmpty) {
          return const EmptyWidget(
            message: 'No users registered',
            icon: Icons.people_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.roleColor(u.role).withOpacity(0.15),
                  child: Icon(
                    AppTheme.roleIcon(u.role),
                    color: AppTheme.roleColor(u.role),
                    size: 20,
                  ),
                ),
                title: Text(u.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.email, style: const TextStyle(fontSize: 12)),
                    if (u.erpId.isNotEmpty)
                      Text(
                        u.erpId,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoleBadge(role: u.role),
                    const SizedBox(height: 4),
                    Icon(
                      u.isApproved ? Icons.check_circle : Icons.pending,
                      color: u.isApproved ? AppTheme.success : AppTheme.warning,
                      size: 16,
                    ),
                  ],
                ),
                onTap: () => _showActions(context, u),
              ),
            );
          },
        );
      },
    );
  }

  void _showActions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(user.email, style: const TextStyle(color: Colors.grey)),
            if (user.erpId.isNotEmpty)
              Text(
                user.erpId,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            if (!user.isApproved)
              ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                ),
                title: const Text('Approve User'),
                onTap: () {
                  UserService().approveUser(user.id);
                  Navigator.pop(context);
                },
              ),
            if (user.isApproved)
              ListTile(
                leading: const Icon(Icons.block, color: AppTheme.error),
                title: const Text('Revoke Access'),
                onTap: () {
                  UserService().rejectUser(user.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CollegeAnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ExamService().getAllResults(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final results = snap.data!;
        if (results.isEmpty) {
          return const EmptyWidget(
            message: 'No data yet',
            icon: Icons.analytics_outlined,
          );
        }
        final avg =
            results.map((r) => r.percentage).reduce((a, b) => a + b) /
            results.length;
        final pass = results.where((r) => r.percentage >= 75).length;
        final passRate = pass / results.length * 100;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'College-Wide Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Attempts',
                      value: '${results.length}',
                      icon: Icons.quiz,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Avg Score',
                      value: '${avg.toStringAsFixed(1)}%',
                      icon: Icons.analytics,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Pass Rate',
                      value: '${passRate.toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Passed',
                      value: '$pass',
                      icon: Icons.check_circle,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Score Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ScoreBar(
                '90-100%',
                results.where((r) => r.percentage >= 90).length,
                results.length,
                AppTheme.success,
              ),
              _ScoreBar(
                '75-90%',
                results
                    .where((r) => r.percentage >= 75 && r.percentage < 90)
                    .length,
                results.length,
                AppTheme.primary,
              ),
              _ScoreBar(
                '50-75%',
                results
                    .where((r) => r.percentage >= 50 && r.percentage < 75)
                    .length,
                results.length,
                AppTheme.warning,
              ),
              _ScoreBar(
                'Below 50%',
                results.where((r) => r.percentage < 50).length,
                results.length,
                AppTheme.error,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ScoreBar(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey[200],
                color: color,
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
