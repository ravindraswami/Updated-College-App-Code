import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/scholarship_service.dart';
import '../../services/user_service.dart';
import '../../services/exam_form_service.dart';
import '../../models/user_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/exam_form_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import '../exam_form/registration_pdf.dart';

/// Dashboard for the dedicated "Scholarship" role. Does the review work
/// that Education Section used to do, plus a combined records view
/// (Scholarship + Admission + Registration Form data) with filters.
class ScholarshipDashboard extends StatefulWidget {
  const ScholarshipDashboard({super.key});
  @override
  State<ScholarshipDashboard> createState() => _ScholarshipDashboardState();
}

class _ScholarshipDashboardState extends State<ScholarshipDashboard> {
  final _auth = AuthService();
  final _svc = ScholarshipService();
  UserModel? _user;
  int _tab = 0;

  static const _color = Color(0xFFB45309); // amber-brown

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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ReviewTab(svc: _svc, color: _color),
      const _RecordsTab(),
      _user == null ? const LoadingWidget() : ProfileScreen(user: _user!, onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarship'),
        automaticallyImplyLeading: false,
        backgroundColor: _color,
        actions: [
          if (_user?.erpId.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_user!.erpId, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
        ],
      ),
      body: _user == null ? const LoadingWidget() : pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart),
            label: 'Records',
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

// ══════════════════════════════════════════════════════════════
// TAB 1 — Scholarship review (pending / approved)
// ══════════════════════════════════════════════════════════════
class _ReviewTab extends StatefulWidget {
  final ScholarshipService svc;
  final Color color;
  const _ReviewTab({required this.svc, required this.color});

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> with SingleTickerProviderStateMixin {
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
        TabBar(
          controller: _tabCtrl,
          labelColor: widget.color,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Approved / History')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              StreamBuilder<List<ScholarshipModel>>(
                stream: widget.svc.getPendingTechnical(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(
                      message: 'No scholarship applications pending review.',
                      icon: Icons.school_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _ScholarshipCard(item: list[i], svc: widget.svc),
                  );
                },
              ),
              StreamBuilder<List<ScholarshipModel>>(
                stream: widget.svc.getAllScholarships(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return const EmptyWidget(message: 'No records yet.', icon: Icons.history);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final s = list[i];
                      return Card(
                        child: ListTile(
                          title: Text(s.studentName),
                          subtitle: Text('${s.scholarshipType} · ${s.status}'),
                          trailing: Text(s.year, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      );
                    },
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

class _ScholarshipCard extends StatefulWidget {
  final ScholarshipModel item;
  final ScholarshipService svc;
  const _ScholarshipCard({required this.item, required this.svc});

  @override
  State<_ScholarshipCard> createState() => _ScholarshipCardState();
}

class _ScholarshipCardState extends State<_ScholarshipCard> {
  bool _busy = false;

  Future<void> _act(bool approve) async {
    setState(() => _busy = true);
    try {
      if (approve) {
        await widget.svc.technicalApprove(widget.item.id, 'Scholarship Section');
      } else {
        await widget.svc.technicalReject(widget.item.id, 'Scholarship Section');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${s.scholarshipType} · ${s.branch} · ${s.year} / ${s.semester}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Caste: ${s.caste} (${s.casteCategory})   Gender: ${s.gender}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _act(false),
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.error),
                    label: const Text('Reject', style: TextStyle(color: AppTheme.error)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _act(true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
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

// ══════════════════════════════════════════════════════════════
// TAB 2 — Combined Records: Admission Data + Registration Form Data
// ══════════════════════════════════════════════════════════════
class _RecordsTab extends StatefulWidget {
  const _RecordsTab();
  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab> with SingleTickerProviderStateMixin {
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
        TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          tabs: const [Tab(text: 'Admission Data'), Tab(text: 'Registration Forms')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [_AdmissionDataView(), _RegistrationDataView()],
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? caste;
  final String? gender;
  final String? year;
  final String? semester;
  final List<String> castes;
  final List<String> years;
  final List<String> semesters;
  final ValueChanged<String?> onCaste;
  final ValueChanged<String?> onGender;
  final ValueChanged<String?> onYear;
  final ValueChanged<String?> onSemester;
  const _FilterBar({
    required this.caste,
    required this.gender,
    required this.year,
    required this.semester,
    required this.castes,
    required this.years,
    required this.semesters,
    required this.onCaste,
    required this.onGender,
    required this.onYear,
    required this.onSemester,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _dropdown('Caste', caste, castes, onCaste),
          const SizedBox(width: 8),
          _dropdown('Gender', gender, const ['Male', 'Female', 'Other'], onGender),
          const SizedBox(width: 8),
          _dropdown('Year', year, years, onYear),
          const SizedBox(width: 8),
          _dropdown('Semester', semester, semesters, onSemester),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButton<String?>(
      hint: Text(label, style: const TextStyle(fontSize: 12.5)),
      value: value,
      underline: const SizedBox.shrink(),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All')),
        ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o, style: const TextStyle(fontSize: 12.5)))),
      ],
      onChanged: onChanged,
    );
  }
}

class _AdmissionDataView extends StatefulWidget {
  const _AdmissionDataView();
  @override
  State<_AdmissionDataView> createState() => _AdmissionDataViewState();
}

class _AdmissionDataViewState extends State<_AdmissionDataView> {
  final _userSvc = UserService();
  String? _caste;
  String? _gender;
  String? _year;
  String? _semester;
  bool _sortAsc = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _userSvc.getUsersByRole('student'),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        var list = snap.data!;
        if (_caste != null) list = list.where((s) => s.caste == _caste).toList();
        if (_gender != null) list = list.where((s) => s.gender == _gender).toList();
        if (_year != null) list = list.where((s) => s.year == _year).toList();
        if (_semester != null) list = list.where((s) => s.semester == _semester).toList();
        list.sort((a, b) => _sortAsc ? a.name.compareTo(b.name) : b.name.compareTo(a.name));

        final castes = snap.data!.map((s) => s.caste).where((c) => c.isNotEmpty).toSet().toList()..sort();
        final years = snap.data!.map((s) => s.year).where((c) => c.isNotEmpty).toSet().toList()..sort();
        final sems = snap.data!.map((s) => s.semester).where((c) => c.isNotEmpty).toSet().toList()..sort();

        return Column(
          children: [
            _FilterBar(
              caste: _caste,
              gender: _gender,
              year: _year,
              semester: _semester,
              castes: castes,
              years: years,
              semesters: sems,
              onCaste: (v) => setState(() => _caste = v),
              onGender: (v) => setState(() => _gender = v),
              onYear: (v) => setState(() => _year = v),
              onSemester: (v) => setState(() => _semester = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${list.length} students', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  TextButton.icon(
                    onPressed: () => setState(() => _sortAsc = !_sortAsc),
                    icon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
                    label: const Text('Name', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyWidget(message: 'No students match these filters.', icon: Icons.people_outline)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final s = list[i];
                        return Card(
                          child: ListTile(
                            title: Text(s.name),
                            subtitle: Text('${s.erpId} · ${s.branch} · ${s.year}/${s.semester} · ${s.gender} · ${s.caste}',
                                style: const TextStyle(fontSize: 11.5)),
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

class _RegistrationDataView extends StatefulWidget {
  const _RegistrationDataView();
  @override
  State<_RegistrationDataView> createState() => _RegistrationDataViewState();
}

class _RegistrationDataViewState extends State<_RegistrationDataView> {
  final _formSvc = ExamFormService();
  String? _year;
  String? _semester;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExamFormModel>>(
      stream: _formSvc.getAllForms(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        var list = snap.data!.where((f) => f.startedAsRegistration).toList();
        if (_year != null) list = list.where((f) => f.year == _year).toList();
        if (_semester != null) list = list.where((f) => f.semester == _semester).toList();

        final years = snap.data!.map((f) => f.year).where((c) => c.isNotEmpty).toSet().toList()..sort();
        final sems = snap.data!.map((f) => f.semester).where((c) => c.isNotEmpty).toSet().toList()..sort();

        return Column(
          children: [
            _FilterBar(
              caste: null,
              gender: null,
              year: _year,
              semester: _semester,
              castes: const [],
              years: years,
              semesters: sems,
              onCaste: (_) {},
              onGender: (_) {},
              onYear: (v) => setState(() => _year = v),
              onSemester: (v) => setState(() => _semester = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${list.length} forms', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (list.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => printClassSummaryTable(context, 'Registration Form Records', list),
                      icon: const Icon(Icons.image_outlined, size: 14),
                      label: const Text('Generate', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyWidget(message: 'No registration forms match these filters.', icon: Icons.edit_document)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final f = list[i];
                        return Card(
                          child: ListTile(
                            title: Text(f.name),
                            subtitle: Text(
                              '${f.erpId} · ${f.year}/${f.semester} · ${ExamFormModel.statusLabel(f.status)}',
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.image_outlined, size: 20),
                              onPressed: () => printStudentSubjectTable(context, f),
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
