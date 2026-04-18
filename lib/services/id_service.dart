import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates ERP IDs like:
///   Student:     CSC2026001, CSC2026002 ...
///   Professor:   PCSC2026001
///   Coordinator: CCSC2026001
///   HOD:         HCSC2026001
///   Principal:   PRIN2026001
class IdService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Prefix map per role
  static String _prefix(String role) {
    switch (role) {
      case 'professor':
        return 'P';
      case 'coordinator':
        return 'C';
      case 'hod':
        return 'H';
      case 'principal':
        return 'PRIN';
      default:
        return ''; // students have no prefix
    }
  }

  /// Generate next ERP ID and atomically increment counter.
  /// Format: [rolePrefix][DEPT][YEAR][3-digit-number]
  /// e.g. CSC2026001, PCSC2026001
  Future<String> generateErpId({
    required String role,
    required String department,
    required String year,
  }) async {
    final dept = department.toUpperCase().replaceAll(' ', '');
    final yr = year.isNotEmpty ? year : DateTime.now().year.toString();
    final prefix = _prefix(role);
    final counterKey = '$prefix$dept$yr';

    // Use a Firestore transaction so two users registering at same time
    // never get the same number
    final counterRef = _db.collection('id_counters').doc(counterKey);

    int nextNum = 1;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      if (snap.exists) {
        nextNum = (snap.data()!['count'] as int) + 1;
      }
      tx.set(counterRef, {'count': nextNum});
    });

    final num = nextNum.toString().padLeft(3, '0');
    return '$prefix$dept$yr$num';
  }

  /// Call when a student/staff is REMOVED — decrements counter
  /// so future IDs fill the gap... actually we just log it.
  /// (In real ERP, IDs are never reused; we only track count for next new ID)
  Future<void> onUserRemoved(String erpId) async {
    // IDs are permanent — we don't reuse them.
    // But we store removed IDs for audit trail.
    await _db.collection('removed_ids').add({
      'erpId': erpId,
      'removedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get current count for a dept/year combo
  Future<int> getCurrentCount({
    required String role,
    required String department,
    required String year,
  }) async {
    final dept = department.toUpperCase().replaceAll(' ', '');
    final prefix = _prefix(role);
    final counterKey = '$prefix$dept$year';
    final snap = await _db.collection('id_counters').doc(counterKey).get();
    if (!snap.exists) return 0;
    return snap.data()!['count'] as int;
  }
}
