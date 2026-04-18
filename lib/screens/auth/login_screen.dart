import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../auth/register_screen.dart';
import '../student/student_dashboard.dart';
import '../professor/professor_dashboard.dart';
import '../coordinator/coordinator_dashboard.dart';
import '../hod/hod_dashboard.dart';
import '../principal/principal_dashboard.dart';
import '../technical/technical_dashboard.dart';
import '../non_technical/non_technical_dashboard.dart';
import '../legal/legal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  final _auth = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await _auth.loginUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      if (user == null) {
        _showMessage('No account found. Please register first.', isError: true);
        return;
      }
      if (!user.isApproved) {
        // User-friendly message based on role
        String pendingMsg;
        if (user.role == 'student') {
          pendingMsg = user.coordinatorId.isNotEmpty
              ? 'Your registration is pending approval from your class coordinator. Please wait.'
              : 'Your registration is pending approval. Please wait for your coordinator to assign a class.';
        } else {
          pendingMsg =
              'Your account is awaiting approval from the HOD or Principal. You will be notified once approved.';
        }
        _showMessage(pendingMsg, isError: false);
        await _auth.logout();
        return;
      }
      // Save FCM token after successful login
      await NotificationService().initializeForUser(user.id);
      _showMessage('Welcome back, ${user.name}!', isError: false);
      _navigateByRole(user.role);
    } catch (e) {
      // Errors from auth service are already user-friendly
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateByRole(String role) {
    Widget screen;
    switch (role) {
      case 'professor':
        screen = const ProfessorDashboard();
        break;
      case 'coordinator':
        screen = const CoordinatorDashboard();
        break;
      case 'hod':
        screen = const HodDashboard();
        break;
      case 'principal':
        screen = const PrincipalDashboard();
        break;
      case 'technical':
        screen = const TechnicalDashboard();
        break;
      case 'non_technical':
        screen = const NonTechnicalDashboard();
        break;
      default:
        screen = const StudentDashboard();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  // child: Container(
                  //   width: 80,
                  //   height: 80,
                  //   decoration: BoxDecoration(
                  //     gradient: const LinearGradient(
                  //       colors: [AppTheme.primary, AppTheme.secondary],
                  //     ),
                  //     borderRadius: BorderRadius.circular(20),
                  //   ),
                  child: Image.asset(
                    'assets/ic_launcher.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                // ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Smart VDCOAB Latur(M.S)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    'Learning Management System',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Sign in to your account',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v!.trim().isEmpty)
                      return 'Please enter your email address.';
                    if (!v.contains('@'))
                      return 'Please enter a valid email address.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'Please enter your password.' : null,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LegalScreen(type: LegalType.privacyPolicy),
                        ),
                      ),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            type: LegalType.termsAndConditions,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
