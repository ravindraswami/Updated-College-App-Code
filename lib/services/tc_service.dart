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

  // Education Section: edit any field on a TC request (name, id, dates,
  // reason, etc.) before/while approving, then save.
  Future<void> updateTc(TcModel tc) async {
    await _db.collection(_col).doc(tc.id).update(tc.toMap());
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

  // Payment done → status = pending_technical
  Future<void> makePayment(String tcId) => markPaymentDone(tcId, '');

  Future<void> markPaymentDone(
    String tcId,
    String transactionId, {
    String paymentDate = '',
    String screenshotUrl = '',
  }) async {
    await _db.collection(_col).doc(tcId).update({
      'isPaid': true,
      'status': 'pending_technical',
      'paymentId': transactionId.isNotEmpty
          ? transactionId
          : 'PAY_TC_\${DateTime.now().millisecondsSinceEpoch}',
      'paymentDate': paymentDate,
      'paymentScreenshotUrl': screenshotUrl,
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

  // Technical: get approved TCs (for history / print list)
  Stream<List<TcModel>> getApprovedTcs() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'approved')
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