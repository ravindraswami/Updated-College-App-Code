class AppConstants {
  // Roles available in the registration form
  // Principal is NOT included — pre-configured in system
  static const List<String> registerRoles = [
    'student',
    'professor',
    'coordinator',
    'ug_incharge',
    'pg_incharge',
    'non_technical',
    'technical',
  ];

  // All roles (used internally)
  static const List<String> roles = [
    'student',
    'professor',
    'coordinator',
    'ug_incharge',
    'pg_incharge',
    'principal',
    'non_technical',
    'technical',
  ];

  static const Map<String, String> roleLabels = {
    'student': 'Student',
    'professor': 'Course Teacher',
    'coordinator': 'Advisor',
    'ug_incharge': 'UG Incharge',
    'pg_incharge': 'PG Incharge',
    'hod': 'UG Incharge / PG Incharge', // legacy — old accounts only
    'principal': 'Principal',
    'non_technical': 'Non-Technical Staff',
    'technical': 'Education Section',
  };

  static String roleLabel(String role) => roleLabels[role] ?? role;

  /// The single branch an Incharge role is scoped to, or '' if not scoped
  /// (e.g. legacy 'hod' accounts still see both).
  static String branchForInchargeRole(String role) {
    switch (role) {
      case 'ug_incharge':
        return 'BIO-TECH-UG';
      case 'pg_incharge':
        return 'BIO-TECH-PG';
      default:
        return ''; // legacy 'hod' — unscoped
    }
  }

  // Staff roles that need Incharge/Principal approval
  static const List<String> staffRoles = [
    'professor',
    'coordinator',
    'ug_incharge',
    'pg_incharge',
    'hod',
    'non_technical',
    'technical',
  ];

  static bool isStaff(String role) => staffRoles.contains(role);
}
