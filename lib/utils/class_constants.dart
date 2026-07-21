/// Class system — based on Branch + Semester (matches student registration)
/// classId format: "BIO-TECH-UG|SEM-I"  (branch|semester)
class ClassConstants {
  // All possible branch+semester combinations
  static const Map<String, ClassInfo> classes = {
    // B.Tech (Biotechnology) — 8 semesters (FY→SY→TY→LY)
    'BIO-TECH-UG|SEM-I': ClassInfo(
      'BIO-TECH-UG|SEM-I',
      'B.Tech (Biotechnology)',
      'Sem I',
      'B.Tech (Biotechnology) — Semester I',
    ),
    'BIO-TECH-UG|SEM-II': ClassInfo(
      'BIO-TECH-UG|SEM-II',
      'B.Tech (Biotechnology)',
      'Sem II',
      'B.Tech (Biotechnology) — Semester II',
    ),
    'BIO-TECH-UG|SEM-III': ClassInfo(
      'BIO-TECH-UG|SEM-III',
      'B.Tech (Biotechnology)',
      'Sem III',
      'B.Tech (Biotechnology) — Semester III',
    ),
    'BIO-TECH-UG|SEM-IV': ClassInfo(
      'BIO-TECH-UG|SEM-IV',
      'B.Tech (Biotechnology)',
      'Sem IV',
      'B.Tech (Biotechnology) — Semester IV',
    ),
    'BIO-TECH-UG|SEM-V': ClassInfo(
      'BIO-TECH-UG|SEM-V',
      'B.Tech (Biotechnology)',
      'Sem V',
      'B.Tech (Biotechnology) — Semester V',
    ),
    'BIO-TECH-UG|SEM-VI': ClassInfo(
      'BIO-TECH-UG|SEM-VI',
      'B.Tech (Biotechnology)',
      'Sem VI',
      'B.Tech (Biotechnology) — Semester VI',
    ),
    'BIO-TECH-UG|SEM-VII': ClassInfo(
      'BIO-TECH-UG|SEM-VII',
      'B.Tech (Biotechnology)',
      'Sem VII',
      'B.Tech (Biotechnology) — Semester VII',
    ),
    'BIO-TECH-UG|SEM-VIII': ClassInfo(
      'BIO-TECH-UG|SEM-VIII',
      'B.Tech (Biotechnology)',
      'Sem VIII',
      'B.Tech (Biotechnology) — Semester VIII',
    ),
    // M.Sc (Molecular Biology & Biotechnology) — 4 semesters
    'BIO-TECH-PG|SEM-I': ClassInfo(
      'BIO-TECH-PG|SEM-I',
      'M.Sc (Molecular Biology & Biotechnology)',
      'Sem I',
      'M.Sc (Molecular Biology & Biotechnology) — Semester I',
    ),
    'BIO-TECH-PG|SEM-II': ClassInfo(
      'BIO-TECH-PG|SEM-II',
      'M.Sc (Molecular Biology & Biotechnology)',
      'Sem II',
      'M.Sc (Molecular Biology & Biotechnology) — Semester II',
    ),
    'BIO-TECH-PG|SEM-III': ClassInfo(
      'BIO-TECH-PG|SEM-III',
      'M.Sc (Molecular Biology & Biotechnology)',
      'Sem III',
      'M.Sc (Molecular Biology & Biotechnology) — Semester III',
    ),
    'BIO-TECH-PG|SEM-IV': ClassInfo(
      'BIO-TECH-PG|SEM-IV',
      'M.Sc (Molecular Biology & Biotechnology)',
      'Sem IV',
      'M.Sc (Molecular Biology & Biotechnology) — Semester IV',
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

  /// Unique branch ids (e.g. 'BIO-TECH-UG', 'BIO-TECH-PG')
  static List<String> get allBranchIds {
    final seen = <String>{};
    return allClassIds.map((id) => branchFrom(id)).where(seen.add).toList();
  }

  /// Human-readable label for a branch id
  static String branchLabel(String branchId) {
    final entry = classes.entries.firstWhere(
      (e) => e.value.id.startsWith(branchId),
      orElse: () => MapEntry('', ClassInfo('', branchId, '', branchId)),
    );
    return entry.value.branchLabel;
  }

  /// Year ids available for a given branch
  /// Returns distinct year portions derived from the classId semesters,
  /// using AcademicData ordering (FY→SY→TY→LY).
  static List<YearEntry> yearsForBranch(String branchId) {
    // Build from classes map — group sems under year labels
    // We infer year from semester number:
    // SEM-I,II → FY; SEM-III,IV → SY; SEM-V,VI → TY; SEM-VII,VIII → LY
    const semToYear = {
      'SEM-I': YearEntry('FY', 'First Year (FY)'),
      'SEM-II': YearEntry('FY', 'First Year (FY)'),
      'SEM-III': YearEntry('SY', 'Second Year (SY)'),
      'SEM-IV': YearEntry('SY', 'Second Year (SY)'),
      'SEM-V': YearEntry('TY', 'Third Year (TY)'),
      'SEM-VI': YearEntry('TY', 'Third Year (TY)'),
      'SEM-VII': YearEntry('LY', 'Fourth Year (LY)'),
      'SEM-VIII': YearEntry('LY', 'Fourth Year (LY)'),
    };
    final seen = <String>{};
    final result = <YearEntry>[];
    for (final classId in allClassIds) {
      if (!classId.startsWith('$branchId|')) continue;
      final sem = semesterFrom(classId);
      final ye = semToYear[sem];
      if (ye != null && seen.add(ye.id)) result.add(ye);
    }
    return result;
  }

  /// Semester classIds for a given branch + year
  static List<String> semsForBranchYear(String branchId, String yearId) {
    const yearToSems = {
      'FY': ['SEM-I', 'SEM-II'],
      'SY': ['SEM-III', 'SEM-IV'],
      'TY': ['SEM-V', 'SEM-VI'],
      'LY': ['SEM-VII', 'SEM-VIII'],
    };
    final sems = yearToSems[yearId] ?? [];
    return sems
        .map((s) => '$branchId|$s')
        .where((id) => classes.containsKey(id))
        .toList();
  }
}

class ClassInfo {
  final String id;
  final String branchLabel;
  final String semLabel;
  final String fullLabel;

  const ClassInfo(this.id, this.branchLabel, this.semLabel, this.fullLabel);

  String get shortLabel => '$branchLabel · $semLabel';
}

class YearEntry {
  final String id;
  final String label;
  const YearEntry(this.id, this.label);
}
