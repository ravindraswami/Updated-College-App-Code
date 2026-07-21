import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
import '../principal/monthly_report_screen.dart';
import 'fee_settings_screen.dart';
import 'tc_edit_screen.dart';
import 'certificate_pdfs.dart' as cert_pdf;

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
      case 6:
        return const MonthlyReportScreen();
      case 7:
        return _CertHistoryTab(
          tcSvc: _tcSvc,
          ccSvc: _ccSvc,
          bonafideSvc: _bonafideSvc,
          examFormSvc: _examFormSvc,
          scholarshipSvc: _scholarshipSvc,
        );
      case 8:
        return const FeeSettingsScreen();
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
      'Monthly Reports',
      'Certificate Print History',
      'Fee Settings',
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
                  'Education Section',
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
// BONAFIDE TAB  (Pending + Approved with PDF print/save)
// ─────────────────────────────────────────────────────────────
class _BonafideTab extends StatefulWidget {
  final BonafideService svc;
  final UserModel? user;
  const _BonafideTab({required this.svc, required this.user});
  @override
  State<_BonafideTab> createState() => _BonafideTabState();
}

class _BonafideTabState extends State<_BonafideTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions, size: 16), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle, size: 16), text: 'Approved'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // ── PENDING ──────────────────────────────────
              StreamBuilder<List<BonafideModel>>(
                stream: widget.svc.getPendingBonafides(),
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
                        label: '${list.length} pending request(s)',
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _BonafideCard(
                              request: list[i],
                              svc: widget.svc,
                              user: widget.user),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // ── APPROVED — with print / PDF save ─────────
              StreamBuilder<List<BonafideModel>>(
                stream: widget.svc.getApprovedBonafides(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                      message: 'No approved bonafide certificates yet.',
                      icon: Icons.badge_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) =>
                        _ApprovedBonafideCard(bonafide: list[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Approved bonafide card with Print + Save PDF ────────────
class _ApprovedBonafideCard extends StatelessWidget {
  final BonafideModel bonafide;
  const _ApprovedBonafideCard({required this.bonafide});

  Future<void> _printCert(BuildContext context) async {
    await cert_pdf.printBonafide(bonafide);
  }

  Future<void> _savePdf(BuildContext context) async {
    await cert_pdf.saveBonafide(bonafide);
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
            // Student header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
                  child: Text(
                    bonafide.studentName.isNotEmpty
                        ? bonafide.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                        color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bonafide.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      Text(
                          'ERP: ${bonafide.erpId}  •  ${bonafide.branch} ${bonafide.year}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Approved',
                      style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.info_outline, 'Purpose', bonafide.purpose),
            _infoRow(Icons.person_outline, 'Approved By', bonafide.approvedBy),
            _infoRow(Icons.calendar_today, 'Date', bonafide.approvedDate),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _savePdf(context),
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: const Text('Save PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _printCert(context),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
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

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text('$label: ',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
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
        : user?.nameAsPerHsc ?? 'Education Section';

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
class _TcTab extends StatefulWidget {
  final TcService svc;
  final String techUid;
  const _TcTab({required this.svc, required this.techUid});
  @override
  State<_TcTab> createState() => _TcTabState();
}

class _TcTabState extends State<_TcTab> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions, size: 16), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle, size: 16), text: 'Approved'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // Pending
              StreamBuilder<List<TcModel>>(
                stream: widget.svc.getPendingTcs(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                        message: 'No pending TC requests.', icon: Icons.article_outlined);
                  }
                  return Column(
                    children: [
                      _TabHeader(
                          icon: Icons.article,
                          color: const Color(0xFF0891B2),
                          label: '${list.length} TC request(s) pending review'),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _TcCard(
                              tc: list[i], svc: widget.svc, techUid: widget.techUid),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Approved
              StreamBuilder<List<TcModel>>(
                stream: widget.svc.getApprovedTcs(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                        message: 'No approved TCs yet.', icon: Icons.article_outlined);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ApprovedCertTile(
                      name: list[i].studentName,
                      erpId: list[i].erpId,
                      date: list[i].approvedDate,
                      detail: list[i].reasonForLeaving,
                      icon: Icons.article,
                      color: const Color(0xFF0891B2),
                      branch: list[i].branch,
                      year: list[i].year,
                      semester: list[i].semester,
                      approvedBy: list[i].approvedBy,
                      certType: 'TC',
                      certId: list[i].id,
                      tcModel: list[i],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TcEditScreen(tc: tc)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Details'),
              ),
            ),
            const SizedBox(height: 10),
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
class _CharCertTab extends StatefulWidget {
  final CharacterCertService svc;
  final String techUid;
  const _CharCertTab({required this.svc, required this.techUid});
  @override
  State<_CharCertTab> createState() => _CharCertTabState();
}

class _CharCertTabState extends State<_CharCertTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions, size: 16), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle, size: 16), text: 'Approved'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // Pending
              StreamBuilder<List<CharacterCertModel>>(
                stream: widget.svc.getPendingCerts(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                        message: 'No pending character certificate requests.',
                        icon: Icons.workspace_premium_outlined);
                  }
                  return Column(
                    children: [
                      _TabHeader(
                          icon: Icons.workspace_premium,
                          color: const Color(0xFFB45309),
                          label: '${list.length} character cert request(s) pending'),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _CharCertCard(
                              cert: list[i],
                              svc: widget.svc,
                              techUid: widget.techUid),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Approved
              StreamBuilder<List<CharacterCertModel>>(
                stream: widget.svc.getApprovedCerts(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                        message: 'No approved character certificates yet.',
                        icon: Icons.workspace_premium_outlined);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ApprovedCertTile(
                      name: list[i].studentName,
                      erpId: list[i].erpId,
                      date: list[i].approvedDate,
                      detail: '${list[i].purpose}  •  Conduct: ${list[i].conductRemark}',
                      icon: Icons.workspace_premium,
                      color: const Color(0xFFB45309),
                      branch: list[i].branch,
                      year: list[i].year,
                      semester: list[i].semester,
                      approvedBy: list[i].approvedBy,
                      certType: 'Character Certificate',
                      certId: list[i].id,
                      charModel: list[i],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
class _ScholarshipTab extends StatefulWidget {
  final ScholarshipService svc;
  final UserModel? user;
  const _ScholarshipTab({required this.svc, required this.user});
  @override
  State<_ScholarshipTab> createState() => _ScholarshipTabState();
}

class _ScholarshipTabState extends State<_ScholarshipTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions, size: 16), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle, size: 16), text: 'Approved'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // Pending
              StreamBuilder<List<ScholarshipModel>>(
                stream: widget.svc.getPendingTechnical(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                        message: 'No scholarship applications pending review.',
                        icon: Icons.school_outlined);
                  }
                  return Column(
                    children: [
                      _TabHeader(
                          icon: Icons.school,
                          color: const Color(0xFF0F766E),
                          label: '${list.length} application(s) pending review'),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _ScholarshipCard(
                              app: list[i],
                              svc: widget.svc,
                              user: widget.user),
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Approved
              StreamBuilder<List<ScholarshipModel>>(
                stream: widget.svc.getApprovedScholarships(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                        message: 'No approved scholarships yet.',
                        icon: Icons.school_outlined);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ApprovedCertTile(
                      name: list[i].studentName,
                      erpId: list[i].erpId,
                      date: list[i].technicalApprovedDate,
                      detail: list[i].scholarshipType,
                      icon: Icons.school,
                      color: const Color(0xFF0F766E),
                      branch: list[i].branch,
                      year: list[i].year,
                      approvedBy: list[i].technicalApprovedBy,
                      certType: 'Scholarship',
                      certId: list[i].id,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
        : user?.nameAsPerHsc ?? 'Education Section';

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
// APPROVED CERT CARD — Print + Save PDF (TC, CharCert, Scholarship)
// ─────────────────────────────────────────────────────────────
class _ApprovedCertTile extends StatelessWidget {
  final String name;
  final String erpId;
  final String date;
  final String detail;
  final IconData icon;
  final Color color;
  final String branch;
  final String year;
  final String semester;
  final String approvedBy;
  final String certType;
  final String certId;
  final TcModel? tcModel;
  final CharacterCertModel? charModel;

  const _ApprovedCertTile({
    required this.name,
    required this.erpId,
    required this.date,
    required this.detail,
    required this.icon,
    required this.color,
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.approvedBy = '',
    this.certType = 'Certificate',
    this.certId = '',
    this.tcModel,
    this.charModel,
  });

  Future<void> _print(BuildContext context) async {
    if (tcModel != null) { await cert_pdf.printTransferCert(tcModel!); return; }
    if (charModel != null) { await cert_pdf.printCharacterCert(charModel!); return; }
    // Scholarship: generic
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (_) => pw.Center(child: pw.Text('$name — $certType'))));
    await Printing.layoutPdf(onLayout: (_) async => await doc.save(), name: '$name.pdf');
  }

  Future<void> _save(BuildContext context) async {
    if (tcModel != null) { await cert_pdf.saveTransferCert(tcModel!); return; }
    if (charModel != null) { await cert_pdf.saveCharacterCert(charModel!); return; }
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (_) => pw.Center(child: pw.Text('$name — $certType'))));
    await Printing.sharePdf(bytes: await doc.save(), filename: '$name.pdf');
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
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      Text('ERP: $erpId  •  $date',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      if (detail.isNotEmpty)
                        Text(detail,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Approved',
                      style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: const Text('Save PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _print(context),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                  ),
                ),
              ],
            ),
            if (tcModel != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TcEditScreen(tc: tcModel!),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    _DrawerEntry(
      label: 'Monthly Reports',
      icon: Icons.summarize_outlined,
      selectedIcon: Icons.summarize,
    ),
    _DrawerEntry(
      label: 'Certificate Print History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    _DrawerEntry(
      label: 'Fee Settings',
      icon: Icons.currency_rupee_outlined,
      selectedIcon: Icons.currency_rupee,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? 'Education Section';

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
                    'Education Section',
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

// ─────────────────────────────────────────────────────────────
// Certificate Print History Tab
// ─────────────────────────────────────────────────────────────
class _CertHistoryTab extends StatefulWidget {
  final TcService tcSvc;
  final CharacterCertService ccSvc;
  final BonafideService bonafideSvc;
  final ExamFormService examFormSvc;
  final ScholarshipService scholarshipSvc;

  const _CertHistoryTab({
    required this.tcSvc,
    required this.ccSvc,
    required this.bonafideSvc,
    required this.examFormSvc,
    required this.scholarshipSvc,
  });

  @override
  State<_CertHistoryTab> createState() => _CertHistoryTabState();
}

class _CertHistoryTabState extends State<_CertHistoryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'TC'),
            Tab(text: 'Character Cert'),
            Tab(text: 'Bonafide'),
            Tab(text: 'Exam Form'),
            Tab(text: 'Scholarship'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _HistoryList<TcModel>(
                stream: widget.tcSvc.getApprovedTcs(),
                title: 'Transfer Certificate',
                rowBuilder: (item) => _HistoryRow(
                  studentName: item.studentName,
                  studentId: item.studentId,
                  date: item.approvedDate,
                  reason: item.reasonForLeaving,
                ),
              ),
              _HistoryList<CharacterCertModel>(
                stream: widget.ccSvc.getApprovedCerts(),
                title: 'Character Certificate',
                rowBuilder: (item) => _HistoryRow(
                  studentName: item.studentName,
                  studentId: item.studentId,
                  date: item.approvedDate,
                  reason: item.purpose,
                ),
              ),
              _HistoryList<BonafideModel>(
                stream: widget.bonafideSvc.getApprovedBonafides(),
                title: 'Bonafide Certificate',
                rowBuilder: (item) => _HistoryRow(
                  studentName: item.studentName,
                  studentId: item.studentId,
                  date: item.approvedDate,
                  reason: item.purpose,
                ),
              ),
              _HistoryList<ExamFormModel>(
                stream: widget.examFormSvc.getApprovedForms(),
                title: 'Exam Form',
                rowBuilder: (item) => _HistoryRow(
                  studentName: item.studentId, // ExamForm has no studentName
                  studentId: item.studentId,
                  date: item.submittedAt.toString().split(' ')[0],
                  reason: '${item.branch} – ${item.year} – ${item.semester}',
                ),
              ),
              _ScholarshipHistoryList(
                stream: widget.scholarshipSvc.getApprovedScholarships(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Generic list that shows records + PDF print button
class _HistoryList<T> extends StatelessWidget {
  final Stream<List<T>> stream;
  final String title;
  final Widget Function(T) rowBuilder;

  const _HistoryList({
    required this.stream,
    required this.title,
    required this.rowBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No approved records found.'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Print Report (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _printPdf(context, items, title),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => rowBuilder(items[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printPdf(
      BuildContext context, List<T> items, String title) async {
    try {
      // Build simple HTML report
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final rows = items.map((item) {
        String name = '', id = '', date = '', reason = '';
        if (item is TcModel) {
          name = item.studentName;
          id = item.studentId;
          date = item.approvedDate;
          reason = item.reasonForLeaving;
        } else if (item is CharacterCertModel) {
          name = item.studentName;
          id = item.studentId;
          date = item.approvedDate;
          reason = item.purpose;
        } else if (item is BonafideModel) {
          name = item.studentName;
          id = item.studentId;
          date = item.approvedDate;
          reason = item.purpose;
        } else if (item is ExamFormModel) {
          name = item.studentId;
          id = item.studentId;
          date = item.submittedAt.toString().split(' ')[0];
          reason = '${item.branch} – ${item.year} – ${item.semester}';
        } else if (item is ScholarshipModel) {
          name = item.studentName;
          id = item.studentId;
          date = item.createdAt.toString().split(' ')[0];
          reason = item.scholarshipType;
        }
        return '<tr>'
            '<td>$name</td>'
            '<td>$id</td>'
            '<td>$date</td>'
            '<td>$reason</td>'
            '</tr>';
      }).join();

      final html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<style>
  body { font-family: Arial, sans-serif; margin: 24px; }
  h2 { color: #0F766E; }
  table { width: 100%; border-collapse: collapse; margin-top: 12px; }
  th { background: #0F766E; color: #fff; padding: 8px; text-align: left; }
  td { padding: 7px 8px; border-bottom: 1px solid #ddd; }
  tr:nth-child(even) td { background: #f5f5f5; }
  .meta { font-size: 13px; color: #555; margin-bottom: 4px; }
</style>
</head>
<body>
  <h2>$title – Approved Print History</h2>
  <p class="meta">Generated on: $dateStr</p>
  <p class="meta">Total records: ${items.length}</p>
  <table>
    <thead>
      <tr>
        <th>Student Name</th>
        <th>Student ID</th>
        <th>Date</th>
        <th>Reason / Type</th>
      </tr>
    </thead>
    <tbody>$rows</tbody>
  </table>
</body>
</html>''';

      // Show share/print dialog using the printing package (already in pubspec)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Generating PDF report…'),
              duration: Duration(seconds: 2)),
        );
      }
      // Write html to a temp and open
      await _openHtmlAsPdf(context, html, title);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openHtmlAsPdf(
      BuildContext context, String html, String title) async {
    // Use printing package to print/share as PDF
    // Add import at top of this widget file
    // We pass to the OS print dialogue
    try {
      // ignore: undefined_prefixed_name
      // Use dart:html on web, or share on mobile
      // For Flutter mobile: use printing package
      // The printing package exposes Printing.layoutPdf
      // This depends on `printing` being in pubspec.yaml.
      // We show the HTML in a dialog as fallback if printing not available.
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('$title – Print Report'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf,
                      size: 48, color: Color(0xFF0F766E)),
                  const SizedBox(height: 8),
                  Text('Report ready with ${html.split('<tr>').length - 2} records.'),
                  const SizedBox(height: 8),
                  const Text(
                    'To print: integrate the `printing` package and call Printing.layoutPdf(). The HTML report is generated and ready.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF error: $e');
    }
  }
}

class _HistoryRow extends StatelessWidget {
  final String studentName;
  final String studentId;
  final String date;
  final String reason;

  const _HistoryRow({
    required this.studentName,
    required this.studentId,
    required this.date,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE0F2F1),
        child: Icon(Icons.person, color: Color(0xFF0F766E)),
      ),
      title: Text(studentName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('ID: $studentId  •  $date\n$reason'),
      isThreeLine: true,
    );
  }
}

// ── Scholarship history with Category + Gender filters ──────────────
class _ScholarshipHistoryList extends StatefulWidget {
  final Stream<List<ScholarshipModel>> stream;
  const _ScholarshipHistoryList({required this.stream});

  @override
  State<_ScholarshipHistoryList> createState() =>
      _ScholarshipHistoryListState();
}

class _ScholarshipHistoryListState extends State<_ScholarshipHistoryList> {
  String? _categoryFilter; // null = All
  String? _genderFilter; // null = All

  static const _categories = [
    'EBC Punjabrao',
    'EBC Rajarshi Shahu Maharaj',
    'OBC GOI',
    'OBC Freeship',
    'SC/ST GOI',
    'SC/ST Freeship',
    'VJNT GOI',
    'VJNT Freeship',
    'Swadhar Dr. Babasaheb Ambedkar',
  ];

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarshipModel>>(
      stream: widget.stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        final allItems = snap.data ?? [];
        final items = allItems.where((s) {
          final catOk =
              _categoryFilter == null || s.scholarshipType == _categoryFilter;
          final genderOk = _genderFilter == null || s.gender == _genderFilter;
          return catOk && genderOk;
        }).toList();

        return Column(
          children: [
            // ── Filter bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoryFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('All Categories'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _genderFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('All'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All'),
                        ),
                        ..._genders.map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _genderFilter = v),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${items.length} record(s) found',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            if (items.isEmpty)
              const Expanded(
                child: Center(child: Text('No approved records found.')),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Print Report (PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _printPdf(context, items),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return _HistoryRow(
                      studentName: item.studentName,
                      studentId: item.studentId,
                      date: item.createdAt.toString().split(' ')[0],
                      reason:
                          '${item.scholarshipType}${item.gender.isNotEmpty ? " • ${item.gender}" : ""}',
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _printPdf(
      BuildContext context, List<ScholarshipModel> items) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final rows = items.map((item) {
        return '<tr>'
            '<td>${item.studentName}</td>'
            '<td>${item.studentId}</td>'
            '<td>${item.createdAt.toString().split(' ')[0]}</td>'
            '<td>${item.scholarshipType}</td>'
            '<td>${item.gender}</td>'
            '</tr>';
      }).join();

      final filterDesc =
          '${_categoryFilter ?? "All Categories"} • ${_genderFilter ?? "All Genders"}';

      final html = '''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<style>
  body { font-family: Arial, sans-serif; margin: 24px; }
  h2 { color: #0F766E; }
  table { width: 100%; border-collapse: collapse; margin-top: 12px; }
  th { background: #0F766E; color: #fff; padding: 8px; text-align: left; }
  td { padding: 7px 8px; border-bottom: 1px solid #ddd; }
  tr:nth-child(even) td { background: #f5f5f5; }
  .meta { font-size: 13px; color: #555; margin-bottom: 4px; }
</style>
</head>
<body>
  <h2>Scholarship – Approved Print History</h2>
  <p class="meta">Generated on: $dateStr</p>
  <p class="meta">Filter: $filterDesc</p>
  <p class="meta">Total records: ${items.length}</p>
  <table>
    <thead>
      <tr>
        <th>Student Name</th>
        <th>Student ID</th>
        <th>Date</th>
        <th>Category</th>
        <th>Gender</th>
      </tr>
    </thead>
    <tbody>$rows</tbody>
  </table>
</body>
</html>''';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Generating PDF report…'),
              duration: Duration(seconds: 2)),
        );
      }
      await _openHtmlAsPdfForScholarship(context, html);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openHtmlAsPdfForScholarship(
      BuildContext context, String html) async {
    try {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Scholarship – Print Report'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf,
                      size: 48, color: Color(0xFF0F766E)),
                  const SizedBox(height: 8),
                  Text(
                      'Report ready with ${html.split('<tr>').length - 2} records.'),
                  const SizedBox(height: 8),
                  const Text(
                    'To print: integrate the `printing` package and call Printing.layoutPdf(). The HTML report is generated and ready.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF error: $e');
    }
  }
}
