/// Hardcoded Principal accounts.
/// These are seeded into Firebase on first app launch.
/// Share these credentials with your Principal privately.
///
/// To add/change: edit this list and re-run seedPrincipalAccounts()
/// from main.dart once, then remove the call.
class PrincipalConfig {

  static const List<Map<String, String>> principals = [
    {
      'name':       'Dr. Suraj Mole',
      'email':      'principal@smarterp.app',
      'password':   'Principal@2026',   // share this privately
      'department': 'Administration',
      'phone':      '9800000001',
      'erpId':      'PRINADMIN2026001',
    },
    // Add more principals here if needed:
    // {
    //   'name':  'Dr. Sunita Patil',
    //   'email': 'principal2@smarterp.app',
    //   'password': 'Principal@2026B',
    //   ...
    // },
  ];
}