class AppConstants {
  // Roles available in the registration form
  // Principal is NOT included — pre-configured in system
  static const List<String> registerRoles = [
    'student',
    'professor',
    'coordinator',
    'hod',
    'non_technical',
    'technical',
  ];

  // All roles (used internally)
  static const List<String> roles = [
    'student',
    'professor',
    'coordinator',
    'hod',
    'principal',
    'non_technical',
    'technical',
  ];

  static const Map<String, String> roleLabels = {
    'student': 'Student',
    'professor': 'Professor',
    'coordinator': 'Class Coordinator',
    'hod': 'HOD',
    'principal': 'Principal',
    'non_technical': 'Non-Technical Staff',
    'technical': 'Technical Staff (Admin)',
  };

  static String roleLabel(String role) => roleLabels[role] ?? role;

  // Staff roles that need HOD/Principal approval
  static const List<String> staffRoles = [
    'professor',
    'coordinator',
    'hod',
    'non_technical',
    'technical',
  ];

  static bool isStaff(String role) => staffRoles.contains(role);
}
