/// Class system — based on Branch + Semester (matches student registration)
/// classId format: "BIO-TECH-UG|SEM-I"  (branch|semester)
/// This replaces the old FY-A / SY-B system
class ClassConstants {
  // All possible branch+semester combinations
  static const Map<String, ClassInfo> classes = {
    // BIO-TECH (UG) — 6 semesters
    'BIO-TECH-UG|SEM-I': ClassInfo(
      'BIO-TECH-UG|SEM-I',
      'BIO-TECH (UG)',
      'Sem I',
      'BIO-TECH UG — Semester I',
    ),
    'BIO-TECH-UG|SEM-II': ClassInfo(
      'BIO-TECH-UG|SEM-II',
      'BIO-TECH (UG)',
      'Sem II',
      'BIO-TECH UG — Semester II',
    ),
    'BIO-TECH-UG|SEM-III': ClassInfo(
      'BIO-TECH-UG|SEM-III',
      'BIO-TECH (UG)',
      'Sem III',
      'BIO-TECH UG — Semester III',
    ),
    'BIO-TECH-UG|SEM-IV': ClassInfo(
      'BIO-TECH-UG|SEM-IV',
      'BIO-TECH (UG)',
      'Sem IV',
      'BIO-TECH UG — Semester IV',
    ),
    'BIO-TECH-UG|SEM-V': ClassInfo(
      'BIO-TECH-UG|SEM-V',
      'BIO-TECH (UG)',
      'Sem V',
      'BIO-TECH UG — Semester V',
    ),
    'BIO-TECH-UG|SEM-VI': ClassInfo(
      'BIO-TECH-UG|SEM-VI',
      'BIO-TECH (UG)',
      'Sem VI',
      'BIO-TECH UG — Semester VI',
    ),
    // BIO-TECH (PG) — 4 semesters
    'BIO-TECH-PG|SEM-I': ClassInfo(
      'BIO-TECH-PG|SEM-I',
      'BIO-TECH (PG)',
      'Sem I',
      'BIO-TECH PG — Semester I',
    ),
    'BIO-TECH-PG|SEM-II': ClassInfo(
      'BIO-TECH-PG|SEM-II',
      'BIO-TECH (PG)',
      'Sem II',
      'BIO-TECH PG — Semester II',
    ),
    'BIO-TECH-PG|SEM-III': ClassInfo(
      'BIO-TECH-PG|SEM-III',
      'BIO-TECH (PG)',
      'Sem III',
      'BIO-TECH PG — Semester III',
    ),
    'BIO-TECH-PG|SEM-IV': ClassInfo(
      'BIO-TECH-PG|SEM-IV',
      'BIO-TECH (PG)',
      'Sem IV',
      'BIO-TECH PG — Semester IV',
    ),
  };

  static List<String> get allClassIds => classes.keys.toList();

  static String labelFor(String classId) =>
      classes[classId]?.fullLabel ?? classId;

  static String shortLabel(String classId) =>
      classes[classId]?.shortLabel ?? classId;

  /// Build classId from branch + semester strings
  static String buildClassId(String branch, String semester) {
    if (branch.isEmpty || semester.isEmpty) return '';
    return '$branch|$semester';
  }

  /// Get branch from classId
  static String branchFrom(String classId) {
    if (!classId.contains('|')) return classId;
    return classId.split('|')[0];
  }

  /// Get semester from classId
  static String semesterFrom(String classId) {
    if (!classId.contains('|')) return '';
    return classId.split('|')[1];
  }

  /// All classes grouped by branch for UI display
  static Map<String, List<String>> get classesByBranch {
    final result = <String, List<String>>{};
    for (final entry in classes.entries) {
      final branch = entry.value.branchLabel;
      result.putIfAbsent(branch, () => []).add(entry.key);
    }
    return result;
  }
}

class ClassInfo {
  final String id;
  final String branchLabel; // 'BIO-TECH (UG)'
  final String semLabel; // 'Sem I'
  final String fullLabel; // 'BIO-TECH UG — Semester I'

  const ClassInfo(this.id, this.branchLabel, this.semLabel, this.fullLabel);

  String get shortLabel => '$branchLabel · $semLabel';
}
