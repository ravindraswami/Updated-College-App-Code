/// Hardcoded Dean account(s).
/// These are seeded into Firebase automatically every time the app
/// launches (see AuthService.seedPrincipalAccounts, called from
/// main.dart) — safe to run every time, it checks first and only
/// creates what's missing. It also self-heals if you ever clear the
/// Firestore "users" collection but the Firebase Auth account survives.
/// Share these credentials with your Dean privately.
///
/// To add/change an account: just edit this list — no need to remove
/// the seeding call afterwards, it's safe to leave it running forever.
class PrincipalConfig {

  static const List<Map<String, String>> principals = [
    {
      'name':       'Dr. Suraj Mole',
      'email':      'dean@smarterp.app',
      'password':   'Dean@2026',   // share this privately
      'department': 'Administration',
      'phone':      '9800000001',
      'erpId':      'DEANADMIN2026001',
    },
    // Add more Dean accounts here if needed:
    // {
    //   'name':  'Dr. Sunita Patil',
    //   'email': 'dean2@smarterp.app',
    //   'password': 'Dean@2026B',
    //   ...
    // },
  ];
}