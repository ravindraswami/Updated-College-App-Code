import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/scholarship_service.dart';
import '../../services/bonafide_service.dart';
import '../../services/tc_service.dart';
import '../../services/character_cert_service.dart';
import '../../services/exam_form_service.dart';
import '../../models/exam_form_model.dart';
import '../../models/user_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/bonafide_model.dart';
import '../../models/tc_model.dart';
import '../../models/character_cert_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../exam_form/exam_form_technical_tab.dart';

class TechnicalDashboard extends StatefulWidget {
  const TechnicalDashboard({super.key});
  @override
  State<TechnicalDashboard> createState() => _TechnicalDashboardState();
}

class _TechnicalDashboardState extends State<TechnicalDashboard> {
  final _auth = AuthService();
  final _scholarshipSvc = ScholarshipService();
  final _bonafideSvc = BonafideService();
  final _tcSvc = TcService();
  final _ccSvc = CharacterCertService();
  final _examFormSvc = ExamFormService();
  UserModel? _user;
  int _bottomIndex = 0; // 0=Home content, 1=Profile
  int _drawerIndex = 0; // which drawer item is selected

  static const _techColor = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Widget _currentPage() {
    switch (_drawerIndex) {
      case 0:
        return _TechHomeTab(
          user: _user,
          color: _techColor,
          scholarshipSvc: _scholarshipSvc,
          bonafideSvc: _bonafideSvc,
          tcSvc: _tcSvc,
          ccSvc: _ccSvc,
          examFormSvc: _examFormSvc,
        );
      case 1:
        return _BonafideTab(svc: _bonafideSvc, user: _user);
      case 2:
        return _TcTab(svc: _tcSvc, techUid: _user?.id ?? '');
      case 3:
        return _CharCertTab(svc: _ccSvc, techUid: _user?.id ?? '');
      case 4:
        return _ScholarshipTab(svc: _scholarshipSvc, user: _user);
      case 5:
        return ExamFormTechnicalTab(technicalUser: _user);
      default:
        return _TechHomeTab(
          user: _user,
          color: _techColor,
          scholarshipSvc: _scholarshipSvc,
          bonafideSvc: _bonafideSvc,
          tcSvc: _tcSvc,
          ccSvc: _ccSvc,
          examFormSvc: _examFormSvc,
        );
    }
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

  // ── Back: single → go to Home, double on Home → exit ────────
  DateTime? _lastBackPress;

  Future<bool> _onWillPop() async {
    if (_drawerIndex != 0 || _bottomIndex != 0) {
      setState(() {
        _drawerIndex = 0;
        _bottomIndex = 0;
      });
      return false;
    }
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
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Pages built inline to avoid stream reconnection
    const _drawerTitles = [
      'Home',
      'Bonafide Requests',
      'TC Requests',
      'Character Certificates',
      'Scholarship Reviews',
      'Exam Forms',
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _bottomIndex == 1 ? 'My Profile' : _drawerTitles[_drawerIndex],
          ),
          backgroundColor: _techColor,
        ),
        drawer: _TechDrawer(
          user: _user,
          selectedIndex: _drawerIndex,
          color: _techColor,
          onItemTap: (i) => setState(() {
            _drawerIndex = i;
            _bottomIndex = 0;
          }),
          onLogout: _logout,
        ),
        body: _user == null
            ? const LoadingWidget()
            : _bottomIndex == 1
            ? ProfileScreen(user: _user!, onLogout: _logout)
            : _currentPage(),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────
class _TechHomeTab extends StatelessWidget {
  final UserModel? user;
  final Color color;
  final ScholarshipService scholarshipSvc;
  final BonafideService bonafideSvc;
  final TcService tcSvc;
  final CharacterCertService ccSvc;
  final ExamFormService examFormSvc;

  const _TechHomeTab({
    required this.user,
    required this.color,
    required this.scholarshipSvc,
    required this.bonafideSvc,
    required this.tcSvc,
    required this.ccSvc,
    required this.examFormSvc,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome banner ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.75)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Technical Staff',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  displayName,
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
          const SizedBox(height: 20),

          // ── Pending counts ─────────────────────────────────
          const Text(
            'Pending Requests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<BonafideModel>>(
                  stream: bonafideSvc.getPendingBonafides(),
                  builder: (_, snap) => _CountCard(
                    title: 'Bonafide',
                    subtitle: 'Awaiting approval',
                    count: snap.data?.length ?? 0,
                    icon: Icons.badge,
                    color: const Color(0xFF7C3AED),
                    onTap: () => _goToTab(context, 1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StreamBuilder<List<TcModel>>(
                  stream: tcSvc.getPendingTcs(),
                  builder: (_, snap) => _CountCard(
                    title: 'TC',
                    subtitle: 'Awaiting approval',
                    count: snap.data?.length ?? 0,
                    icon: Icons.article,
                    color: const Color(0xFF0891B2),
                    onTap: () => _goToTab(context, 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<CharacterCertModel>>(
                  stream: ccSvc.getPendingCerts(),
                  builder: (_, snap) => _CountCard(
                    title: 'Char. Cert',
                    subtitle: 'Awaiting approval',
                    count: snap.data?.length ?? 0,
                    icon: Icons.workspace_premium,
                    color: const Color(0xFFB45309),
                    onTap: () => _goToTab(context, 3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StreamBuilder<List<ExamFormModel>>(
                  stream: examFormSvc.getPendingForTechnical(),
                  builder: (_, snap) => _CountCard(
                    title: 'Exam Forms',
                    subtitle: 'Awaiting review',
                    count: snap.data?.length ?? 0,
                    icon: Icons.edit_document,
                    color: const Color(0xFF1D4ED8),
                    onTap: () => _goToTab(context, 5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              Expanded(
                child: StreamBuilder<List<ScholarshipModel>>(
                  stream: scholarshipSvc.getPendingTechnical(),
                  builder: (_, snap) => _CountCard(
                    title: 'Scholarship',
                    subtitle: 'Awaiting review',
                    count: snap.data?.length ?? 0,
                    icon: Icons.school,
                    color: color,
                    onTap: () => _goToTab(context, 4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Recent activity ────────────────────────────────
          const Text(
            'Recent Scholarship Activity',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<ScholarshipModel>>(
            stream: scholarshipSvc.getAllScholarships(),
            builder: (_, snap) {
              if (!snap.hasData) return const LoadingWidget();
              final list = snap.data!.take(5).toList();
              if (list.isEmpty) {
                return const Text(
                  'No activity yet.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                children: list
                    .map(
                      (s) => _ActivityTile(
                        title: s.studentName,
                        subtitle:
                            '${s.scholarshipType} • ${_statusLabel(s.status)}',
                        icon: Icons.school_outlined,
                        statusColor: _statusColor(s.status),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'pending_cc':
        return AppTheme.warning;
      case 'pending_technical':
        return const Color(0xFF0F766E);
      case 'approved':
        return AppTheme.success;
      default:
        return AppTheme.error;
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'pending_cc':
        return 'Pending CC';
      case 'pending_technical':
        return 'Pending Technical';
      case 'approved':
        return 'Approved';
      default:
        return 'Rejected';
    }
  }
}

// Helper: navigate to a tab from any child widget
void _goToTab(BuildContext context, int index) {
  final state = context.findAncestorStateOfType<_TechnicalDashboardState>();
  state?.setState(() => state._drawerIndex = index);
}

// ─────────────────────────────────────────────────────────────
// COUNT CARD
// ─────────────────────────────────────────────────────────────
class _CountCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CountCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: count > 0 ? color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: count > 0 ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIVITY TILE
// ─────────────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color statusColor;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BONAFIDE TAB
// ─────────────────────────────────────────────────────────────
class _BonafideTab extends StatelessWidget {
  final BonafideService svc;
  final UserModel? user;

  const _BonafideTab({required this.svc, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BonafideModel>>(
      stream: svc.getPendingBonafides(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyWidget(
            message: 'No bonafide requests pending approval.',
            icon: Icons.badge_outlined,
          );
        }
        return Column(
          children: [
            _TabHeader(
              icon: Icons.badge,
              color: const Color(0xFF7C3AED),
              label: '${list.length} bonafide request(s) pending',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _BonafideCard(request: list[i], svc: svc, user: user),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BonafideCard extends StatelessWidget {
  final BonafideModel request;
  final BonafideService svc;
  final UserModel? user;

  const _BonafideCard({
    required this.request,
    required this.svc,
    required this.user,
  });

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Bonafide Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rejecting request for ${request.studentName}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final reason = ctrl.text.trim().isNotEmpty
        ? ctrl.text.trim()
        : 'Rejected by Technical Staff';
    await svc.rejectBonafide(request.id, reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? 'Technical Staff';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              name: request.studentName,
              sub: '${request.branch} • ${request.year} • ${request.semester}',
              erpId: request.erpId,
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.info_outline,
              label: 'Purpose',
              value: request.purpose,
            ),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Applied On',
              value: request.applyDate,
            ),
            _InfoRow(
              icon: Icons.receipt_outlined,
              label: 'Roll No.',
              value: request.rollNo,
            ),
            const SizedBox(height: 8),
            _PaidBadge(amount: request.charges),
            const SizedBox(height: 12),
            _ActionButtons(
              onReject: () => _reject(context),
              onApprove: () async {
                await svc.approveBonafide(
                  bonafideId: request.id,
                  approvedBy: staffName,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${request.studentName}\'s bonafide approved!',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              approveLabel: 'Approve',
              approveColor: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TC TAB
// ─────────────────────────────────────────────────────────────
class _TcTab extends StatelessWidget {
  final TcService svc;
  final String techUid;

  const _TcTab({required this.svc, required this.techUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TcModel>>(
      stream: svc.getPendingTcs(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyWidget(
            message: 'No pending TC requests.',
            icon: Icons.article_outlined,
          );
        }
        return Column(
          children: [
            _TabHeader(
              icon: Icons.article,
              color: const Color(0xFF0891B2),
              label: '${list.length} TC request(s) pending review',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _TcCard(tc: list[i], svc: svc, techUid: techUid),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TcCard extends StatelessWidget {
  final TcModel tc;
  final TcService svc;
  final String techUid;

  const _TcCard({required this.tc, required this.svc, required this.techUid});

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject TC Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rejecting TC for ${tc.studentName}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.rejectTc(
      tc.id,
      reason: ctrl.text.trim().isNotEmpty
          ? ctrl.text.trim()
          : 'Rejected by Technical Staff',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TC request rejected.'),
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              name: tc.studentName,
              sub: '${tc.branch} • ${tc.year} • ${tc.semester}',
              erpId: tc.erpId,
              color: const Color(0xFF0891B2),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.notes,
              label: 'Reason for Leaving',
              value: tc.reasonForLeaving,
            ),
            _InfoRow(
              icon: Icons.school_outlined,
              label: 'Last Exam Passed',
              value: tc.lastExamPassed,
            ),
            _InfoRow(
              icon: Icons.receipt_outlined,
              label: 'Register No.',
              value: tc.registerNo,
            ),
            _InfoRow(icon: Icons.cake_outlined, label: 'DOB', value: tc.dob),
            _InfoRow(
              icon: Icons.people_outline,
              label: "Mother's Name",
              value: tc.motherName,
            ),
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: tc.casteCategory,
            ),
            const SizedBox(height: 8),
            _PaidBadge(amount: tc.charges),
            const SizedBox(height: 12),
            _ActionButtons(
              onReject: () => _reject(context),
              onApprove: () async {
                await svc.approveTc(tc.id, techUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'TC approved. Student can now download their certificate.',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              approveLabel: 'Approve TC',
              approveColor: AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHARACTER CERTIFICATE TAB
// ─────────────────────────────────────────────────────────────
class _CharCertTab extends StatelessWidget {
  final CharacterCertService svc;
  final String techUid;

  const _CharCertTab({required this.svc, required this.techUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CharacterCertModel>>(
      stream: svc.getPendingCerts(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyWidget(
            message: 'No pending character certificate requests.',
            icon: Icons.workspace_premium_outlined,
          );
        }
        return Column(
          children: [
            _TabHeader(
              icon: Icons.workspace_premium,
              color: const Color(0xFFB45309),
              label: '${list.length} character cert request(s) pending',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _CharCertCard(cert: list[i], svc: svc, techUid: techUid),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CharCertCard extends StatelessWidget {
  final CharacterCertModel cert;
  final CharacterCertService svc;
  final String techUid;

  const _CharCertCard({
    required this.cert,
    required this.svc,
    required this.techUid,
  });

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Certificate Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rejecting certificate for ${cert.studentName}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.rejectCert(
      cert.id,
      reason: ctrl.text.trim().isNotEmpty
          ? ctrl.text.trim()
          : 'Rejected by Technical Staff',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate request rejected.'),
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              name: cert.studentName,
              sub: '${cert.branch} • ${cert.year} • ${cert.semester}',
              erpId: cert.erpId,
              color: const Color(0xFFB45309),
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.notes, label: 'Purpose', value: cert.purpose),
            _InfoRow(
              icon: Icons.star_outline,
              label: 'Conduct Remark',
              value: cert.conductRemark,
            ),
            _InfoRow(icon: Icons.cake_outlined, label: 'DOB', value: cert.dob),
            const SizedBox(height: 8),
            _PaidBadge(amount: cert.charges),
            const SizedBox(height: 12),
            _ActionButtons(
              onReject: () => _reject(context),
              onApprove: () async {
                await svc.approveCert(cert.id, techUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Certificate approved. Student can now download it.',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              approveLabel: 'Approve Certificate',
              approveColor: AppTheme.success,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCHOLARSHIP TAB
// ─────────────────────────────────────────────────────────────
class _ScholarshipTab extends StatelessWidget {
  final ScholarshipService svc;
  final UserModel? user;

  const _ScholarshipTab({required this.svc, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarshipModel>>(
      stream: svc.getPendingTechnical(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final list = snap.data!;
        if (list.isEmpty) {
          return const EmptyWidget(
            message: 'No scholarship applications pending review.',
            icon: Icons.school_outlined,
          );
        }
        return Column(
          children: [
            _TabHeader(
              icon: Icons.school,
              color: const Color(0xFF0F766E),
              label: '${list.length} application(s) pending review',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _ScholarshipCard(app: list[i], svc: svc, user: user),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScholarshipCard extends StatelessWidget {
  final ScholarshipModel app;
  final ScholarshipService svc;
  final UserModel? user;

  const _ScholarshipCard({
    required this.app,
    required this.svc,
    required this.user,
  });

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rejecting scholarship for ${app.studentName}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final reason = ctrl.text.trim().isNotEmpty
        ? ctrl.text.trim()
        : 'Rejected by Technical Staff';
    await svc.technicalReject(app.id, reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application rejected.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? 'Technical Staff';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              name: app.studentName,
              sub: '${app.branch} • ${app.year} • ${app.semester}',
              erpId: app.erpId,
              color: const Color(0xFF0F766E),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.card_giftcard_outlined,
              label: 'Scholarship',
              value: app.scholarshipType,
            ),
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Caste Category',
              value: app.casteCategory,
            ),
            // _InfoRow(
            //   icon: Icons.account_balance_outlined,
            //   label: 'Bank',
            //   value: '${app.bankName} — ${app.bankAccount}',
            // ),
            // _InfoRow(
            //   icon: Icons.currency_rupee_outlined,
            //   label: 'Family Income',
            //   value: '₹${app.annualIncome}/yr',
            // ),
            if (app.ccRemarks.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.success,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'CC Remarks: ${app.ccRemarks}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _ActionButtons(
              onReject: () => _reject(context),
              onApprove: () async {
                await svc.technicalApprove(app.id, staffName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${app.studentName}\'s scholarship approved!',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              approveLabel: 'Approve',
              approveColor: const Color(0xFF0F766E),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS  (all top-level)
// ─────────────────────────────────────────────────────────────

class _TabHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _TabHeader({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withOpacity(0.07),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String name;
  final String sub;
  final String erpId;
  final Color color;
  const _CardHeader({
    required this.name,
    required this.sub,
    required this.erpId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              if (erpId.isNotEmpty)
                Text(
                  erpId,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidBadge extends StatelessWidget {
  final double amount;
  const _PaidBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 14),
          const SizedBox(width: 6),
          Text(
            'Payment Received — ₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppTheme.success,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onReject;
  final VoidCallback onApprove;
  final String approveLabel;
  final Color approveColor;

  const _ActionButtons({
    required this.onReject,
    required this.onApprove,
    required this.approveLabel,
    required this.approveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
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
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: Text(approveLabel),
            style: ElevatedButton.styleFrom(backgroundColor: approveColor),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TECHNICAL STAFF DRAWER
// ─────────────────────────────────────────────────────────────
class _TechDrawer extends StatelessWidget {
  final UserModel? user;
  final int selectedIndex;
  final Color color;
  final void Function(int) onItemTap;
  final VoidCallback onLogout;

  const _TechDrawer({
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
      label: 'Bonafide Requests',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
    ),
    _DrawerEntry(
      label: 'TC Requests',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
    ),
    _DrawerEntry(
      label: 'Character Certificates',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium,
    ),
    _DrawerEntry(
      label: 'Scholarship Reviews',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    _DrawerEntry(
      label: 'Exam Forms',
      icon: Icons.edit_document,
      selectedIcon: Icons.edit_document,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? 'Technical Staff';

    return Drawer(
      child: Column(
        children: [
          // Header
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
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Technical Staff',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (user?.erpId.isNotEmpty == true)
                    Text(
                      user!.erpId,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Menu items
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
                    Navigator.pop(context); // close drawer
                    onItemTap(i);
                  },
                );
              },
            ),
          ),

          // Logout
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
