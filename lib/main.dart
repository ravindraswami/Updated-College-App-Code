import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/course_teacher/course_teacher_dashboard.dart';
import 'screens/advisor/advisor_dashboard.dart';
import 'screens/incharge/incharge_dashboard.dart';
import 'screens/dean/dean_dashboard.dart';
import 'screens/education/education_dashboard.dart';
import 'screens/non_technical/non_technical_dashboard.dart';
import 'screens/scholarship/scholarship_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed hardcoded Dean account (skips if already exists) — self-heals
  // if you wiped the Firestore "users" collection but the Firebase Auth
  // account still exists.
  //
  // IMPORTANT: only do this when NO ONE is currently signed in.
  // seedPrincipalAccounts() internally calls signInWithEmailAndPassword
  // for the Dean account and then signOut()s again once done. If a
  // student/staff session was already persisted from a previous app
  // run, running this unconditionally on every launch would silently
  // swap Firebase Auth's active session to Dean and then sign out of
  // THAT — wiping the real logged-in user's session every single time
  // the app is restarted (this was the "login doesn't stay, I get
  // logged out again" bug). Since seeding only ever needs to happen
  // once (or when signed out), skipping it while someone is already
  // signed in fixes that without losing the self-heal behaviour.
  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await AuthService().seedPrincipalAccounts();
    } catch (e) {
      debugPrint('[seedPrincipalAccounts] top-level failure: $e');
    }
  }

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
      case 'course_teacher':
      case 'professor': // legacy role key — old accounts only
        return const CourseTeacherDashboard();
      case 'advisor':
      case 'coordinator': // legacy role key — old accounts only
        return const AdvisorDashboard();
      case 'ug_incharge':
      case 'pg_incharge':
      case 'hod':
        return const InchargeDashboard();
      case 'dean':
      case 'principal': // legacy role key — old accounts only
        return const DeanDashboard();
      case 'education':
      case 'technical': // legacy role key — old accounts only
        return const EducationDashboard();
      case 'non_technical':
        return const NonTechnicalDashboard();
      case 'scholarship':
        return const ScholarshipDashboard();
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
      case 'course_teacher':
      case 'professor': // legacy role key — old accounts only
        home = const CourseTeacherDashboard();
        break;
      case 'advisor':
      case 'coordinator': // legacy role key — old accounts only
        home = const AdvisorDashboard();
        break;
      case 'ug_incharge':
      case 'pg_incharge':
      case 'hod':
        home = const InchargeDashboard();
        break;
      case 'dean':
      case 'principal': // legacy role key — old accounts only
        home = const DeanDashboard();
        break;
      case 'education':
      case 'technical': // legacy role key — old accounts only
        home = const EducationDashboard();
        break;
      case 'non_technical':
        home = const NonTechnicalDashboard();
        break;
      case 'scholarship':
        home = const ScholarshipDashboard();
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
