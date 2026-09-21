import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);

  static const Color notAnswered = Color(0xFFE5E7EB);
  static const Color answered = Color(0xFF16A34A);
  static const Color markedReview = Color(0xFFD97706);
  static const Color markedAnswered = Color(0xFF7C3AED);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static Map<String, Color> get roleColors => {
    'student': const Color(0xFF2563EB),
    'course_teacher': const Color(0xFF7C3AED),
    'professor': const Color(0xFF7C3AED), // legacy role key — old accounts only
    'advisor': const Color(0xFF0891B2),
    'coordinator': const Color(0xFF0891B2), // legacy role key — old accounts only
    'ug_incharge': const Color(0xFF059669),
    'pg_incharge': const Color(0xFF0D9488),
    'hod': const Color(0xFF059669),
    'dean': const Color(0xFFDC2626),
    'principal': const Color(0xFFDC2626), // legacy role key — old accounts only
  };

  static Color roleColor(String role) => roleColors[role] ?? primary;

  static Map<String, IconData> get roleIcons => {
    'student': Icons.school,
    'course_teacher': Icons.person_outline,
    'professor': Icons.person_outline, // legacy role key — old accounts only
    'advisor': Icons.people,
    'coordinator': Icons.people, // legacy role key — old accounts only
    'ug_incharge': Icons.manage_accounts,
    'pg_incharge': Icons.manage_accounts,
    'hod': Icons.manage_accounts,
    'dean': Icons.admin_panel_settings,
    'principal': Icons.admin_panel_settings, // legacy role key — old accounts only
  };

  static IconData roleIcon(String role) => roleIcons[role] ?? Icons.person;
}
