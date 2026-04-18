import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class NonTechnicalDashboard extends StatefulWidget {
  const NonTechnicalDashboard({super.key});
  @override
  State<NonTechnicalDashboard> createState() => _NonTechnicalDashboardState();
}

class _NonTechnicalDashboardState extends State<NonTechnicalDashboard> {
  final _auth = AuthService();
  final _userSvc = UserService();
  UserModel? _user;
  int _bottomIndex = 0;
  int _drawerIndex = 0;

  static const _drawerItems = [
    DrawerItem(
      label: 'Student Directory',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
    ),
    DrawerItem(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
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
        return _StudentDirectoryTab(svc: _userSvc);
      case 1:
        return const EmptyWidget(
          message: 'No notices posted yet.',
          icon: Icons.campaign_outlined,
        );
      default:
        return _StudentDirectoryTab(svc: _userSvc);
    }
  }

  @override
  Widget build(BuildContext context) {
    const ntColor = Color(0xFF92400E);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _bottomIndex == 1 ? 'My Profile' : _drawerItems[_drawerIndex].label,
        ),
        backgroundColor: ntColor,
      ),
      drawer: AppDrawer(
        user: _user,
        selectedIndex: _drawerIndex,
        items: _drawerItems,
        accentColor: ntColor,
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

class _StudentDirectoryTab extends StatefulWidget {
  final UserService svc;
  const _StudentDirectoryTab({required this.svc});
  @override
  State<_StudentDirectoryTab> createState() => _StudentDirectoryTabState();
}

class _StudentDirectoryTabState extends State<_StudentDirectoryTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.svc.getUsersByRole('student'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final all = snap.data!.where((s) => s.isApproved).toList();
        final filtered = _search.isEmpty
            ? all
            : all
                  .where(
                    (s) =>
                        s.displayName.toLowerCase().contains(
                          _search.toLowerCase(),
                        ) ||
                        s.erpId.toLowerCase().contains(_search.toLowerCase()),
                  )
                  .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search student name or ERP ID...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyWidget(
                      message: 'No students found.',
                      icon: Icons.search_off,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF92400E,
                              ).withOpacity(0.1),
                              child: Text(
                                s.displayName.isNotEmpty
                                    ? s.displayName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              s.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${s.erpId} • ${s.classId}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              s.mobile.isNotEmpty ? s.mobile : '—',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
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
