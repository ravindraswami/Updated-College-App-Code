import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bonafide_model.dart';

class BonafideService {
  final _db = FirebaseFirestore.instance;

  Future<String> applyBonafide({
    required String studentId,
    required String studentName,
    required String erpId,
    required String branch,
    required String year,
    required String semester,
    required String rollNo,
    required String purpose,
    double charges = 50.0,
  }) async {
    final ref = await _db.collection('bonafide_requests').add({
      'studentId': studentId,
      'studentName': studentName,
      'erpId': erpId,
      'branch': branch,
      'year': year,
      'semester': semester,
      'rollNo': rollNo,
      'purpose': purpose,
      'applyDate': DateTime.now().toString().split(' ')[0],
      'status': 'pending_payment',
      'isPaid': false,
      'paymentId': '',
      'charges': charges,
      'approvedBy': '',
      'approvedDate': '',
      'pdfUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> markPaymentDone(
    String bonafideId,
    String transactionId, {
    String paymentDate = '',
    String screenshotUrl = '',
  }) async {
    await _db.collection('bonafide_requests').doc(bonafideId).update({
      'isPaid': true,
      'paymentId': transactionId,
      'paymentDate': paymentDate,
      'paymentScreenshotUrl': screenshotUrl,
      'status': 'pending_approval',
    });
  }

  Future<void> approveBonafide({
    required String bonafideId,
    required String approvedBy,
    String pdfUrl = '',
  }) async {
    await _db.collection('bonafide_requests').doc(bonafideId).update({
      'status': 'approved',
      'approvedBy': approvedBy,
      'approvedDate': DateTime.now().toString().split(' ')[0],
      'pdfUrl': pdfUrl,
    });
  }

  Future<void> rejectBonafide(String bonafideId, String reason) async {
    await _db.collection('bonafide_requests').doc(bonafideId).update({
      'status': 'rejected',
      'ccRemarks': reason,
    });
  }

  // ── FIX: removed orderBy to avoid Firestore composite index error ──
  // Sort in Dart instead

  Stream<List<BonafideModel>> getStudentBonafides(String studentId) {
    return _db
        .collection('bonafide_requests')
        .where('studentId', isEqualTo: studentId)
        // NO orderBy here — sort in Dart
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => BonafideModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BonafideModel>> getPendingBonafides() {
    return _db
        .collection('bonafide_requests')
        .where('status', isEqualTo: 'pending_approval')
        // NO orderBy — sort in Dart
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => BonafideModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Stream<List<BonafideModel>> getApprovedBonafides() {
    return _db
        .collection('bonafide_requests')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => BonafideModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BonafideModel>> getAllBonafides() {
    return _db.collection('bonafide_requests').snapshots().map((s) {
      final list = s.docs
          .map((d) => BonafideModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<BonafideModel?> getBonafide(String id) async {
    final doc = await _db.collection('bonafide_requests').doc(id).get();
    if (!doc.exists) return null;
    return BonafideModel.fromMap(doc.data()!, doc.id);
  }
}
