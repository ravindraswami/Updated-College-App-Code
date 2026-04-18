import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/scholarship_service.dart';
import '../../services/bonafide_service.dart';
import '../../models/user_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/bonafide_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';

class TechnicalDashboard extends StatefulWidget {
  const TechnicalDashboard({super.key});
  @override
  State<TechnicalDashboard> createState() => _TechnicalDashboardState();
}

class _TechnicalDashboardState extends State<TechnicalDashboard> {
  final _auth = AuthService();
  final _scholarshipSvc = ScholarshipService();
  final _bonafideSvc = BonafideService();
  UserModel? _user;
  int _selectedIndex =
      0; // bottom nav: 0=Home, 1=Scholarship, 2=Bonafide, 3=Profile

  static const _techColor = Color(0xFF0F766E);

  // Public method so child widgets can switch tabs without touching protected setState
  void setTab(int index) => setState(() => _selectedIndex = index);

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        scholarshipSvc: _scholarshipSvc,
        bonafideSvc: _bonafideSvc,
        user: _user,
      ),
      _ScholarshipTab(svc: _scholarshipSvc, user: _user),
      _BonafideTab(svc: _bonafideSvc, user: _user),
      _user == null
          ? const LoadingWidget()
          : ProfileScreen(user: _user!, onLogout: _logout),
    ];

    final titles = [
      'Home',
      'Scholarship Reviews',
      'Bonafide Requests',
      'My Profile',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: _techColor,
        automaticallyImplyLeading: false,
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
            label: 'Scholarship',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Bonafide',
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

// ═══════════════════════════════════════════════════════════════
// HOME TAB — shows live counts of pending requests
// ═══════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final ScholarshipService scholarshipSvc;
  final BonafideService bonafideSvc;
  final UserModel? user;
  const _HomeTab({
    required this.scholarshipSvc,
    required this.bonafideSvc,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
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
                  user?.name.isNotEmpty == true
                      ? user!.name
                      : user?.nameAsPerHsc ?? '',
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

          // ── Live counts from Firestore ──────────────────────
          const Text(
            'Pending Requests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Scholarship pending count
              Expanded(
                child: StreamBuilder<List<ScholarshipModel>>(
                  stream: scholarshipSvc.getPendingTechnical(),
                  builder: (_, snap) {
                    final count = snap.data?.length ?? 0;
                    return _CountCard(
                      title: 'Scholarship',
                      subtitle: 'Awaiting your review',
                      count: count,
                      icon: Icons.school,
                      color: const Color(0xFF0F766E),
                      onTap: () {
                        context
                            .findAncestorStateOfType<_TechnicalDashboardState>()
                            ?.setTab(1);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Bonafide pending count
              Expanded(
                child: StreamBuilder<List<BonafideModel>>(
                  stream: bonafideSvc.getPendingBonafides(),
                  builder: (_, snap) {
                    final count = snap.data?.length ?? 0;
                    return _CountCard(
                      title: 'Bonafide',
                      subtitle: 'Awaiting approval',
                      count: count,
                      icon: Icons.badge,
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        context
                            .findAncestorStateOfType<_TechnicalDashboardState>()
                            ?.setTab(2);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

}

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
        padding: const EdgeInsets.all(16),
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


// ═══════════════════════════════════════════════════════════════
// SCHOLARSHIP TAB — pending_technical requests
// ═══════════════════════════════════════════════════════════════
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F766E).withOpacity(0.07),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF0F766E), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length} application(s) pending review',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
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

  Future<void> _showRejectDialog(BuildContext context) async {
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
    await svc.technicalReject(app.id, 'Technical Staff', remarks: reason);
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
                    app.studentName.isNotEmpty
                        ? app.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
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
                        app.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${app.branch} • ${app.year} • ${app.semester}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        app.erpId,
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Scholarship type
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
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
                      final staffName = user?.name.isNotEmpty == true
                          ? user!.name
                          : user?.nameAsPerHsc ?? 'Technical Staff';
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
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
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

// ═══════════════════════════════════════════════════════════════
// BONAFIDE TAB — pending_approval bonafide requests
// ═══════════════════════════════════════════════════════════════
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF7C3AED).withOpacity(0.07),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Color(0xFF7C3AED), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length} bonafide request(s) pending',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
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

  Future<void> _showRejectDialog(BuildContext context) async {
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
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                  child: Text(
                    request.studentName.isNotEmpty
                        ? request.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
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
                        request.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${request.branch} • ${request.year} • ${request.semester}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        request.erpId,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

            // Payment status badge
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.success.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Payment Received — ₹${request.charges.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
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
                      final staffName = user?.name.isNotEmpty == true
                          ? user!.name
                          : user?.nameAsPerHsc ?? 'Technical Staff';
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
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
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

// ── Shared info row widget ────────────────────────────────────
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
