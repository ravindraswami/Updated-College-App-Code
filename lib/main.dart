import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/professor/professor_dashboard.dart';
import 'screens/coordinator/coordinator_dashboard.dart';
import 'screens/hod/hod_dashboard.dart';
import 'screens/principal/principal_dashboard.dart';
import 'screens/technical/technical_dashboard.dart';
import 'screens/non_technical/non_technical_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed hardcoded Principal accounts (skips if already exists)
  try {
    await AuthService().seedPrincipalAccounts();
  } catch (_) {}

  // Initialize FCM background handler
  await NotificationService().initializeApp();

  runApp(const SmartERPApp());
}

class SmartERPApp extends StatelessWidget {
  const SmartERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart ERP',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      home: const SplashScreen(),
      routes: {
        '/exam_list': (ctx) => const _NotifRoute(screen: 'exam_list'),
        '/notes': (ctx) => const _NotifRoute(screen: 'notes'),
        '/my_results': (ctx) => const _NotifRoute(screen: 'my_results'),
      },
    );
  }
}

// ── Notification deep link handler ───────────────────────────
class _NotifRoute extends StatefulWidget {
  final String screen;
  const _NotifRoute({required this.screen});
  @override
  State<_NotifRoute> createState() => _NotifRouteState();
}

class _NotifRouteState extends State<_NotifRoute> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final user = await AuthService().getCurrentUserModel();
    if (!mounted) return;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    Widget home = _homeForRole(user.role, user);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => home));
  }

  Widget _homeForRole(String role, dynamic user) {
    switch (role) {
      case 'professor':
        return const ProfessorDashboard();
      case 'coordinator':
        return const CoordinatorDashboard();
      case 'hod':
        return const HodDashboard();
      case 'principal':
        return const PrincipalDashboard();
      case 'technical':
        return const TechnicalDashboard();
      case 'non_technical':
        return const NonTechnicalDashboard();
      default:
        int tab = 0;
        if (widget.screen == 'exam_list') tab = 0;
        if (widget.screen == 'my_results') tab = 0;
        if (widget.screen == 'notes') tab = 0;
        return StudentDashboard(initialTab: tab);
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ── Splash screen ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final user = await AuthService().getCurrentUserModel();
    if (!mounted) return;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    // Refresh FCM token
    await NotificationService().initializeForUser(user.id);
    Widget home;
    switch (user.role) {
      case 'professor':
        home = const ProfessorDashboard();
        break;
      case 'coordinator':
        home = const CoordinatorDashboard();
        break;
      case 'hod':
        home = const HodDashboard();
        break;
      case 'principal':
        home = const PrincipalDashboard();
        break;
      case 'technical':
        home = const TechnicalDashboard();
        break;
      case 'non_technical':
        home = const NonTechnicalDashboard();
        break;
      default:
        home = const StudentDashboard();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => home));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                //color: Colors.white.withOpacity(0.2),
                //borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/ic_launcher.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart VDCOAB Latur(M.S)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Learning Management System',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
