class ClassAdvisorAssignmentModel {
  final String id;
  final String branch; // BIO-TECH-UG / BIO-TECH-PG
  final String year; // FY / SY / TY / LY
  final String regNoStart; // e.g. "001"
  final String regNoEnd; // e.g. "025"
  final String advisorId;
  final String advisorName;
  final DateTime createdAt;

  ClassAdvisorAssignmentModel({
    required this.id,
    required this.branch,
    required this.year,
    required this.regNoStart,
    required this.regNoEnd,
    required this.advisorId,
    required this.advisorName,
    required this.createdAt,
  });

  factory ClassAdvisorAssignmentModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return ClassAdvisorAssignmentModel(
      id: id,
      branch: map['branch'] ?? '',
      year: map['year'] ?? '',
      regNoStart: map['regNoStart'] ?? '',
      regNoEnd: map['regNoEnd'] ?? '',
      advisorId: map['advisorId'] ?? '',
      advisorName: map['advisorName'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'branch': branch,
    'year': year,
    'regNoStart': regNoStart,
    'regNoEnd': regNoEnd,
    'advisorId': advisorId,
    'advisorName': advisorName,
    'createdAt': createdAt,
  };

  String get rangeLabel => '$regNoStart – $regNoEnd';

  /// Checks whether a given registration number (numeric part) falls
  /// within this assignment's range. Handles simple numeric suffix
  /// comparisons e.g. "VDCOAB2026001" -> 001.
  bool matchesRegNo(String regNo) {
    final digits = RegExp(r'\d+$').stringMatch(regNo.trim());
    final startDigits = RegExp(r'\d+$').stringMatch(regNoStart.trim());
    final endDigits = RegExp(r'\d+$').stringMatch(regNoEnd.trim());
    if (digits == null || startDigits == null || endDigits == null) {
      return false;
    }
    final n = int.tryParse(digits);
    final s = int.tryParse(startDigits);
    final e = int.tryParse(endDigits);
    if (n == null || s == null || e == null) return false;
    return n >= s && n <= e;
  }
}
