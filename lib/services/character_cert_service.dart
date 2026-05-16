import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character_cert_model.dart';

class CharacterCertService {
  final _db = FirebaseFirestore.instance;
  final _col = 'character_cert_requests';

  // Returns doc ID so payment can be marked immediately
  Future<String> applyCertReturnRef(CharacterCertModel cert) async {
    final ref = await _db.collection(_col).add(cert.toMap());
    return ref.id;
  }

  // Student: get own requests — sort in Dart (no composite index needed)
  Stream<List<CharacterCertModel>> getStudentCerts(String studentId) {
    return _db
        .collection(_col)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => CharacterCertModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Payment done → status = pending_technical
  Future<void> makePayment(String certId) async {
    await _db.collection(_col).doc(certId).update({
      'isPaid': true,
      'status': 'pending_technical',
      'paymentId': 'PAY_CC_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  // Technical: get pending requests — sort in Dart
  Stream<List<CharacterCertModel>> getPendingCerts() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'pending_technical')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => CharacterCertModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Technical: approve
  Future<void> approveCert(String certId, String approverUid) async {
    await _db.collection(_col).doc(certId).update({
      'status': 'approved',
      'approvedBy': approverUid,
      'approvedDate': DateTime.now().toIso8601String(),
    });
  }

  // Technical: reject
  Future<void> rejectCert(String certId, {String reason = ''}) async {
    await _db.collection(_col).doc(certId).update({
      'status': 'rejected',
      'rejectReason': reason,
    });
  }
}
