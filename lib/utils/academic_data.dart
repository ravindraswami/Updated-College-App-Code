/// All academic branch / year / semester data
/// Maharashtra state - India specific data
class AcademicData {
  // ── Branches ─────────────────────────────────────────────
  static const List<Map<String, dynamic>> branches = [
    {
      'id': 'BIO-TECH-UG',
      'label': 'B.Tech (Biotechnology)',
      'years': [
        {
          'id': 'FY', 'label': 'First Year (FY)',
          'sems': [
            {'id': 'SEM-I', 'label': 'Semester I'},
            {'id': 'SEM-II', 'label': 'Semester II'},
          ],
          'regNoRequired': false, // FY SEM I → optional
        },
        {
          'id': 'SY',
          'label': 'Second Year (SY)',
          'sems': [
            {'id': 'SEM-III', 'label': 'Semester III'},
            {'id': 'SEM-IV', 'label': 'Semester IV'},
          ],
          'regNoRequired': true,
        },
        {
          'id': 'TY',
          'label': 'Third Year (TY)',
          'sems': [
            {'id': 'SEM-V', 'label': 'Semester V'},
            {'id': 'SEM-VI', 'label': 'Semester VI'},
          ],
          'regNoRequired': true,
        },
        {
          'id': 'LY',
          'label': 'Fourth Year (LY)',
          'sems': [
            {'id': 'SEM-VII', 'label': 'Semester VII'},
            {'id': 'SEM-VIII', 'label': 'Semester VIII'},
          ],
          'regNoRequired': true,
        },
      ],
    },
    {
      'id': 'BIO-TECH-PG',
      'label': 'M.Sc (Molecular Biology & Biotechnology)',
      'years': [
        {
          'id': 'FY',
          'label': 'First Year (FY)',
          'sems': [
            {'id': 'SEM-I', 'label': 'Semester I'},
            {'id': 'SEM-II', 'label': 'Semester II'},
          ],
          'regNoRequired': false,
        },
        {
          'id': 'SY',
          'label': 'Second Year (SY)',
          'sems': [
            {'id': 'SEM-III', 'label': 'Semester III'},
            {'id': 'SEM-IV', 'label': 'Semester IV'},
          ],
          'regNoRequired': true,
        },
      ],
    },
  ];

  /// Full, non-abbreviated display name for a branch
  /// e.g. BIO-TECH-UG -> "Biotechnology Undergraduate"
  /// e.g. BIO-TECH-PG -> "Biotechnology Postgraduate"
  static String branchFullLabel(String branchId) {
    switch (branchId) {
      case 'BIO-TECH-UG':
        return 'Biotechnology Undergraduate';
      case 'BIO-TECH-PG':
        return 'Biotechnology Postgraduate';
      default:
        final branch = branches.firstWhere(
          (b) => b['id'] == branchId,
          orElse: () => {},
        );
        return branch.isEmpty ? branchId : (branch['label'] as String);
    }
  }

  /// Full, non-abbreviated display name for a year
  /// e.g. FY -> "First Year", SY -> "Second Year", TY -> "Third Year", LY -> "Final Year"
  static String yearFullLabel(String yearId) {
    switch (yearId) {
      case 'FY':
        return 'First Year';
      case 'SY':
        return 'Second Year';
      case 'TY':
        return 'Third Year';
      case 'LY':
        return 'Final Year';
      default:
        return yearId;
    }
  }

  static List<Map<String, dynamic>> yearsForBranch(String branchId) {
    final branch = branches.firstWhere(
      (b) => b['id'] == branchId,
      orElse: () => {},
    );
    if (branch.isEmpty) return [];
    return List<Map<String, dynamic>>.from(branch['years'] as List);
  }

  static List<Map<String, dynamic>> semsForYear(
    String branchId,
    String yearId,
  ) {
    final years = yearsForBranch(branchId);
    final year = years.firstWhere((y) => y['id'] == yearId, orElse: () => {});
    if (year.isEmpty) return [];
    return List<Map<String, dynamic>>.from(year['sems'] as List);
  }

  /// Returns true if registration number is REQUIRED for this branch+year+sem combo
  static bool isRegNoRequired(String branchId, String yearId, String semId) {
    // FY SEM I → optional (comparative registration, not finalised)
    if (yearId == 'FY' && semId == 'SEM-I') return false;
    // All others → required
    return true;
  }

  // ── Religion + Caste ─────────────────────────────────────
  static const Map<String, List<String>> religionCastes = {
    'Hindu': [
      'Brahmin',
      'Kshatriya',
      'Vaishya',
      'Shudra',
      'Maratha',
      'Kunbi',
      'Mali',
      'Dhangar',
      'Koli',
      'Chambhar',
      'Mahar',
      'Mang',
      'Banjara',
      'Teli',
      'Sonar',
      'Lohar',
      'Sutar',
      'Kumbhar',
      'Shimpi',
      'Nhavi',
      'Parit',
      'Gurav',
      'Gondhali',
      'Other Hindu',
    ],
    'Muslim': [
      'Sunni',
      'Shia',
      'Sufi',
      'Ansari',
      'Siddiqui',
      'Khan',
      'Sheikh',
      'Pathan',
      'Momin',
      'Other Muslim',
    ],
    'Christian': [
      'Roman Catholic',
      'Protestant',
      'Baptist',
      'Church of North India',
      'Other Christian',
    ],
    'Buddhist': [
      'Navayana (Neo-Buddhist)',
      'Theravada',
      'Mahayana',
      'Vajrayana',
      'Other Buddhist',
    ],
    'Jain': ['Digambara', 'Shwetambara', 'Other Jain'],
    'Sikh': ['Jat Sikh', 'Ramgarhia', 'Khatri', 'Other Sikh'],
    'Parsi': ['Parsi'],
    'Jewish': ['Jewish'],
    'Other': ['Other'],
  };

  static List<String> castesForReligion(String religion) {
    return religionCastes[religion] ?? [];
  }

  // ── Caste Categories ─────────────────────────────────────
  static const List<String> actualCasteCategories = [
    'SC',
    'ST',
    'VJ/DT(A)',
    'NT(B)',
    'NT(C)',
    'NT(D)',
    'OBC',
    'SBC',
    'OPEN',
    'EWS',
    'SEBC',
  ];

  static const List<String> admittedCasteCategories = [
    'SC',
    'ST',
    'VJ/DT(A)',
    'NT(B)',
    'NT(C)',
    'NT(D)',
    'OBC',
    'SBC',
    'OPEN',
    'EWS',
    'SEBC',
    'CR',
    'CO',
  ];

  static const List<String> otherCategories = [
    'None',
    'FF',
    'DP',
    'PH',
    'PD',
    'AG',
    'OS',
    'PAP',
    'Spot Round',
  ];

  // ── Occupation list ───────────────────────────────────────
  static const List<String> occupations = [
    'Farmer',
    'Government Employee',
    'Private Employee',
    'Business',
    'Self Employed',
    'Doctor',
    'Engineer',
    'Teacher / Professor',
    'Lawyer',
    'Police / Military',
    'Labour / Daily Wages',
    'Retired',
    'Deceased',
    'Other',
  ];

  // ── Marital Status ────────────────────────────────────────
  static const List<String> maritalStatuses = [
    'Unmarried',
    'Married',
    'Divorced',
    'Widowed',
  ];
}
