class AppConstants {
  // Roles available in the registration form.
  // Dean is NOT included — pre-configured in system.
  //
  // NOTE ON ROLE KEYS (renamed to match the role names used in the
  // app / Play Store listing):
  //   'professor'   → 'course_teacher'
  //   'coordinator' → 'advisor'
  //   'technical'   → 'education'
  // The OLD keys are kept everywhere as legacy aliases (see
  // roleLabels below and canonicalRole()) so existing Firestore
  // accounts that still have the old value keep working until you
  // run the one-time migration script to update them to the new
  // value. New registrations always get the new canonical key.
  static const List<String> registerRoles = [
    'student',
    'course_teacher',
    'advisor',
    'ug_incharge',
    'pg_incharge',
    'non_technical',
    'education',
    'scholarship',
  ];

  // All CANONICAL roles (used internally; new accounts only ever get
  // one of these — old accounts may still have a legacy key until
  // migrated, see canonicalRole()).
  static const List<String> roles = [
    'student',
    'course_teacher',
    'advisor',
    'ug_incharge',
    'pg_incharge',
    'dean',
    'non_technical',
    'education',
    'scholarship',
  ];

  static const Map<String, String> roleLabels = {
    'student': 'Student',
    'course_teacher': 'Course Teacher',
    'professor': 'Course Teacher', // legacy — old accounts only
    'advisor': 'Advisor',
    'coordinator': 'Advisor', // legacy — old accounts only
    'ug_incharge': 'UG Incharge',
    'pg_incharge': 'PG Incharge',
    'hod': 'UG Incharge / PG Incharge', // legacy — old accounts only
    'principal': 'Dean', // legacy role key — old accounts only
    'dean': 'Dean',
    'non_technical': 'Non-Technical Staff',
    'education': 'Education',
    'technical': 'Education', // legacy — old accounts only
    'scholarship': 'Scholarship',
  };

  static String roleLabel(String role) => roleLabels[role] ?? role;

  /// Maps an old/legacy role key to its new canonical key. Anything
  /// already canonical (or unrecognised) is returned unchanged. Use
  /// this wherever you compare a role read from Firestore against a
  /// single expected value (e.g. `canonicalRole(user.role) ==
  /// 'advisor'`), so accounts not yet migrated still work correctly.
  static String canonicalRole(String role) {
    switch (role) {
      case 'professor':
        return 'course_teacher';
      case 'coordinator':
        return 'advisor';
      case 'technical':
        return 'education';
      case 'principal':
        return 'dean';
      default:
        return role;
    }
  }

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

  // Staff roles that need Incharge/Dean approval (includes legacy
  // keys too, so accounts not yet migrated are still recognised).
  static const List<String> staffRoles = [
    'course_teacher',
    'professor', // legacy
    'advisor',
    'coordinator', // legacy
    'ug_incharge',
    'pg_incharge',
    'hod',
    'non_technical',
    'education',
    'technical', // legacy
    'scholarship',
  ];

  static bool isStaff(String role) => staffRoles.contains(role);
}
