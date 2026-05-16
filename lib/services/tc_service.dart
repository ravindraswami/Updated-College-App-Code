import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tc_model.dart';

class TcService {
  final _db = FirebaseFirestore.instance;
  final _col = 'tc_requests';

  // Returns doc ID so payment can be marked immediately
  Future<String> applyTcReturnRef(TcModel tc) async {
    final ref = await _db.collection(_col).add(tc.toMap());
    return ref.id;
  }

  // Student: get own TC requests — sort in Dart (no composite index needed)
  Stream<List<TcModel>> getStudentTcs(String studentId) {
    return _db
        .collection(_col)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => TcModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Payment done → status = pending_technical (goes to Technical Staff directly)
  Future<void> makePayment(String tcId) async {
    await _db.collection(_col).doc(tcId).update({
      'isPaid':    true,
      'status':    'pending_technical',
      'paymentId': 'PAY_TC_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  // Technical: get pending requests — sort in Dart
  Stream<List<TcModel>> getPendingTcs() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'pending_technical')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => TcModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Technical: approve TC
  Future<void> approveTc(String tcId, String approverUid) async {
    await _db.collection(_col).doc(tcId).update({
      'status':       'approved',
      'approvedBy':   approverUid,
      'approvedDate': DateTime.now().toIso8601String(),
    });
  }

  // Technical: reject TC
  Future<void> rejectTc(String tcId, {String reason = ''}) async {
    await _db.collection(_col).doc(tcId).update({
      'status':       'rejected',
      'rejectReason': reason,
    });
  }
}