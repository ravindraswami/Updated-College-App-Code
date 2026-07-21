import 'package:cloud_firestore/cloud_firestore.dart';

/// ID Strategy:
///   Student  → NO auto ERP ID. Their college registerNo is their ID.
///              If FY Sem I (comparative), registerNo may be empty initially.
///   Staff    → Auto-generated: [rolePrefix][DEPT][YEAR][3-digit]
///              Professor:    P-BIO-TECH-2026-001
///              Coordinator:  CC-BIO-TECH-2026-001
///              HOD:          HOD-BIO-TECH-2026-001
///              Technical:    TECH-2026-001
///              Non-Technical:NT-2026-001
///              Principal:    PRIN-2026-001
class IdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _prefix(String role) {
    switch (role) {
      case 'professor':
        return 'PROF';
      case 'coordinator':
        return 'CC';
      case 'ug_incharge':
        return 'UGI';
      case 'pg_incharge':
        return 'PGI';
      case 'hod':
        return 'HOD';
      case 'principal':
        return 'PRIN';
      case 'technical':
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

    // Technical/Non-Technical don't use dept in their ID
    final counterKey =
        (role == 'technical' || role == 'non_technical' || role == 'principal')
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
    if (role == 'technical' || role == 'non_technical' || role == 'principal') {
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
