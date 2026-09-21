import 'package:cloud_firestore/cloud_firestore.dart';

/// ID Strategy:
///   Student       → NO auto ERP ID. Their college registerNo is their ID.
///                   If FY Sem I (comparative), registerNo may be empty initially.
///   Staff         → Auto-generated: [rolePrefix][DEPT][YEAR][3-digit]
///              Course Teacher: PROF-BIO-TECH-2026-001
///              Advisor:        CC-BIO-TECH-2026-001
///              HOD:            HOD-BIO-TECH-2026-001
///              Education:      TECH-2026-001
///              Non-Technical:  NT-2026-001
///              Dean:           DEAN-2026-001
class IdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _prefix(String role) {
    switch (role) {
      case 'course_teacher':
      case 'professor': // legacy role key — old accounts only
        return 'PROF';
      case 'advisor':
      case 'coordinator': // legacy role key — old accounts only
        return 'CC';
      case 'ug_incharge':
        return 'UGI';
      case 'pg_incharge':
        return 'PGI';
      case 'hod':
        return 'HOD';
      case 'dean':
      case 'principal': // legacy role key — old accounts only
        return 'DEAN';
      case 'education':
      case 'technical': // legacy role key — old accounts only
        return 'TECH';
      case 'non_technical':
        return 'NT';
      default:
        return '';
    }
  }

  /// Generate ID for STAFF only.
  /// Students use their college registerNo — no auto ID.
  Future<String> generateStaffId({
    required String role,
    required String department,
    required String year,
  }) async {
    // Students do not get auto ERP IDs
    if (role == 'student') return '';

    final dept = department
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('-', '');
    final yr = year.isNotEmpty ? year : DateTime.now().year.toString();
    final prefix = _prefix(role);

    // Education/Non-Technical/Dean don't use dept in their ID
    final counterKey =
        (role == 'education' || role == 'technical' || role == 'non_technical' || role == 'dean' || role == 'principal')
        ? '$prefix$yr'
        : '$prefix$dept$yr';

    final counterRef = _db.collection('id_counters').doc(counterKey);
    int nextNum = 1;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      if (snap.exists) nextNum = (snap.data()!['count'] as int) + 1;
      tx.set(counterRef, {'count': nextNum});
    });

    final num = nextNum.toString().padLeft(3, '0');

    // Format: PROF-BIOTECH-2026-001 / CC-BIOTECH-2026-001 / TECH-2026-001
    if (role == 'education' || role == 'technical' || role == 'non_technical' || role == 'dean' || role == 'principal') {
      return '$prefix-$yr-$num';
    }
    return '$prefix-$dept-$yr-$num';
  }

  Future<void> onUserRemoved(String erpId) async {
    await _db.collection('removed_ids').add({
      'erpId': erpId,
      'removedAt': FieldValue.serverTimestamp(),
    });
  }
}
