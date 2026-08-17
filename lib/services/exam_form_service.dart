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

  // ══════════════════════════════════════════════════════════
  // REGISTRATION FORM WORKFLOW (new)
  // awaiting_payment → payment_verification → form_open →
  // teacher_review → advisor_review → completed
  // ══════════════════════════════════════════════════════════

  /// Student starts a new registration: pays the flat registration fee
  /// FIRST — subjects aren't chosen yet, the form opens only after
  /// Education verifies the payment.
  Future<String> startRegistration({
    required String studentId,
    required String classId,
    required String name,
    required String erpId,
    required String branch,
    required String year,
    required String semester,
    required String rollNo,
    required String mobile,
    required double registrationFee,
  }) async {
    final ref = await _db.collection(_col).add(ExamFormModel(
      id: '',
      studentId: studentId,
      classId: classId,
      name: name,
      erpId: erpId,
      branch: branch,
      year: year,
      semester: semester,
      rollNo: rollNo,
      mobile: mobile,
      status: 'awaiting_payment',
      startedAsRegistration: true,
      registrationFee: registrationFee,
      submittedAt: DateTime.now(),
    ).toMap());
    return ref.id;
  }

  Future<void> payRegistrationFee(String formId, String paymentId) async {
    await _db.collection(_col).doc(formId).update({
      'registrationPaid': true,
      'registrationPaymentId': paymentId,
      'status': 'payment_verification',
    });
  }

  /// Education: queue of payments waiting to be verified.
  Stream<List<ExamFormModel>> getPendingPaymentVerification() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'payment_verification')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
          return list;
        });
  }

  /// Education verifies payment → the registration form now opens for the
  /// student to fill subject details.
  Future<void> educationVerifyPayment(String formId, String educationName) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'form_open',
      'educationVerifiedBy': educationName,
      'educationVerifiedDate': DateTime.now().toIso8601String(),
    });
  }

  Future<void> educationRejectPayment(String formId, String reason) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'rejected',
      'rejectReason': reason,
      'rejectedBy': 'education',
    });
  }

  /// Student's forms that are open and waiting to be filled.
  Stream<List<ExamFormModel>> getOpenFormsForStudent(String studentId) {
    return _db
        .collection(_col)
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'form_open')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ExamFormModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Student fills and submits the Regular + Backlog subject tables.
  /// Moves the form into the Course Teacher review queue.
  Future<void> submitRegistrationDetails(
    String formId,
    ExamFormModel filled,
  ) async {
    await _db.collection(_col).doc(formId).update({
      ...filled.toMap(),
      'status': 'teacher_review',
    });
  }

  /// Course Teacher: forms where at least one subject assigned to
  /// [teacherId] is still awaiting that teacher's signature.
  Stream<List<ExamFormModel>> getPendingForTeacher(String teacherId) {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'teacher_review')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .where((f) {
                final mySubjects = [
                  ...f.subjectTeacherIds.entries
                      .where((e) => e.value == teacherId)
                      .map((e) => e.key),
                  ...f.backlogSubjectTeacherIds.entries
                      .where((e) => e.value == teacherId)
                      .map((e) => e.key),
                ];
                return mySubjects
                    .any((id) => (f.teacherSignatures[id] ?? '').isEmpty);
              })
              .toList();
          list.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
          return list;
        });
  }

  /// Course Teacher signs off on the ONE subject they teach within this
  /// form — 'RR' (Regular Result), 'OFE' or 'NR' as selected.
  Future<void> teacherSignSubject({
    required String formId,
    required String subjectId,
    required String teacherUid,
    required String signature,
  }) async {
    await _db.collection(_col).doc(formId).update({
      'teacherSignatures.$subjectId': signature,
      'teacherSignedBy.$subjectId': teacherUid,
    });
    // Move to Advisor once every subject on the form has been signed.
    final snap = await _db.collection(_col).doc(formId).get();
    if (!snap.exists) return;
    final form = ExamFormModel.fromMap(snap.data()!, snap.id);
    if (form.allTeachersSigned && form.status == 'teacher_review') {
      await _db.collection(_col).doc(formId).update({
        'status': 'advisor_review',
      });
    }
  }

  /// Advisor: forms assigned to THEM (via the Year+Semester+RegNo range
  /// assignment), ready for final sign-off.
  Stream<List<ExamFormModel>> getPendingForAdvisor(String advisorId) {
    return _db
        .collection(_col)
        .where('advisorId', isEqualTo: advisorId)
        .where('status', isEqualTo: 'advisor_review')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
          return list;
        });
  }

  /// Advisor gives final signature — form is now complete and visible to
  /// Education in the aggregated (sem-wise) view.
  Future<void> advisorApproveForm(
    String formId,
    String advisorName, {
    String signature = 'RR',
    String remark = '',
  }) async {
    await _db.collection(_col).doc(formId).update({
      'status': 'completed',
      'advisorApprovedBy': advisorName,
      'advisorApprovedDate': DateTime.now().toIso8601String(),
      'advisorSignature': signature,
      'advisorRemark': remark,
    });
  }

  /// Education: all completed registration forms, for the aggregated
  /// sem-wise view. Grouped/sorted on the client by semester.
  Stream<List<ExamFormModel>> getCompletedRegistrations() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 'completed')
        .where('startedAsRegistration', isEqualTo: true)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.semester.compareTo(b.semester));
          return list;
        });
  }

  /// Advisor: full history (any status) of registration forms assigned to
  /// THEM — used for the advisor's own per-student summary table.
  Stream<List<ExamFormModel>> getRegistrationsForClass(String advisorId) {
    return _db
        .collection(_col)
        .where('advisorId', isEqualTo: advisorId)
        .where('startedAsRegistration', isEqualTo: true)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ExamFormModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
          return list;
        });
  }
}
