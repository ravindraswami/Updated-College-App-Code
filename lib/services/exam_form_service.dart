import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_form_model.dart';

class ExamFormService {
  final _db = FirebaseFirestore.instance;
  final _col = 'exam_forms';

  // ── Student ────────────────────────────────────────────────
  Future<String> submitForm(ExamFormModel form) async {
    final ref = await _db.collection(_col).add(form.toMap());
    return ref.id;
  }

  Stream<List<ExamFormModel>> getStudentForms(String studentId) {
    return _db
        .collection(_col)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  // Student pays fee
  Future<void> payFee(String formId) async {
    await _db.collection(_col).doc(formId).update({
      'paymentStatus': 'Paid',
      'status': 'fee_paid',
      'paymentId': 'PAY_EF_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  // ── CC (Class Coordinator) ─────────────────────────────────
  Stream<List<ExamFormModel>> getPendingForCC(String classId) {
    return _db
        .collection(_col)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .where((f) => f.status == 'pending_cc')
              .toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  Future<void> ccApprove(String formId, String ccName, {String remarks = ''}) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'pending_technical',
      'ccApprovedBy': ccName,
      'ccApprovedDate': DateTime.now().toIso8601String(),
      'ccRemarks': remarks,
    });
  }

  Future<void> ccReject(String formId, String reason) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'rejected',
      'rejectReason': reason,
      'rejectedBy': 'cc',
    });
  }

  // ── Technical Staff ────────────────────────────────────────
  Stream<List<ExamFormModel>> getPendingForTechnical() {
    return _db.collection(_col).snapshots().map((s) {
      final list = s.docs
          .map((d) => ExamFormModel.fromMap(d.data(), d.id))
          .where((f) =>
              f.status == 'pending_technical' || f.status == 'fee_paid')
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  // Technical sets fee (old simple method — kept for compatibility)
  Future<void> addFee(String formId, double amount) async {
    await _db.collection(_col).doc(formId).update({
      'feeAdded': true,
      'feeAmount': amount,
      'status': 'fee_pending',
    });
  }

  // Technical sets per-subject fees with breakdown stored in the form doc
  Future<void> addFeeWithBreakdown(
    String formId,
    double totalAmount,
    Map<String, double> regularFees,
    Map<String, double> backlogFees,
  ) async {
    await _db.collection(_col).doc(formId).update({
      'feeAdded': true,
      'feeAmount': totalAmount,
      'subjectRegularFees': regularFees,
      'subjectBacklogFees': backlogFees,
      'status': 'fee_pending',
    });
  }

  // Technical final approval
  Future<void> technicalApprove(String formId, String staffName) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'approved',
      'technicalApprovedBy': staffName,
      'technicalApprovedDate': DateTime.now().toIso8601String(),
    });
  }

  Future<void> technicalReject(String formId, String reason) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'rejected',
      'rejectReason': reason,
      'rejectedBy': 'technical',
    });
  }

  // All approved forms (principal / hall tickets)
  Stream<List<ExamFormModel>> getApprovedForms() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }

  Stream<List<ExamFormModel>> getAllForms() {
    return _db.collection(_col).snapshots().map((s) {
      final list = s.docs
          .map((d) => ExamFormModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }
}
