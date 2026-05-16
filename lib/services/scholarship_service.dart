import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/scholarship_model.dart';
import '../models/user_model.dart';

class ScholarshipService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Submit scholarship — auto-fills student info, uploads PDF if provided
  Future<String> submitScholarship({
    required UserModel student,
    required String scholarshipType,
    required String formFilledStatus, // 'yes'/'no'
    required String applicationStatus, // 'pending'/'approved'
    List<int>? pdfBytes,
    String pdfFileName = '',
  }) async {
    String pdfUrl = '';

    // Upload PDF if provided
    if (pdfBytes != null && pdfBytes.isNotEmpty && pdfFileName.isNotEmpty) {
      final ref = _storage.ref().child(
        'scholarship_forms/${student.id}_${DateTime.now().millisecondsSinceEpoch}_$pdfFileName',
      );
      await ref.putData(
        Uint8List.fromList(pdfBytes),
        SettableMetadata(contentType: 'application/pdf'),
      );
      pdfUrl = await ref.getDownloadURL();
    }

    final ref = await _db.collection('scholarship_requests').add({
      // Auto-filled from student profile
      'studentId': student.id,
      'studentName': student.nameAsPerHsc.isNotEmpty
          ? student.nameAsPerHsc
          : student.name,
      'erpId': student.erpId,
      'branch': student.branch,
      'year': student.year,
      'semester': student.semester,
      'classId': student.classId,
      'coordinatorId': student.coordinatorId,
      'casteCategory': student.actualCasteCategory,
      'religion': student.religion,
      'caste': student.caste,
      'mobile': student.mobile,
      'address': student.address,
      'state': student.state,
      'district': student.district,
      'motherName': student.motherName,
      'aadharNo': student.aadharNo,
      'dob': student.dob,
      // Student-entered
      'scholarshipType': scholarshipType,
      'formFilledStatus': formFilledStatus,
      'applicationStatus': applicationStatus,
      'pdfUrl': pdfUrl,
      'pdfFileName': pdfFileName,
      // Approval chain initial values
      'status': 'pending_cc',
      'ccApprovedBy': '',
      'ccApprovedDate': '',
      'ccRemarks': '',
      'technicalApprovedBy': '',
      'technicalApprovedDate': '',
      'technicalRemarks': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Student's own scholarship applications
  Stream<List<ScholarshipModel>> getStudentScholarships(String studentId) {
    return _db
        .collection('scholarship_requests')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ScholarshipModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Coordinator: pending from their class
  Stream<List<ScholarshipModel>> getPendingForClass(String classId) {
    return _db
        .collection('scholarship_requests')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'pending_cc')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ScholarshipModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  /// Coordinator approves
  Future<void> ccApprove(String id, String approvedBy, {String remarks = ''}) =>
      _db.collection('scholarship_requests').doc(id).update({
        'status': 'pending_technical',
        'ccApprovedBy': approvedBy,
        'ccApprovedDate': DateTime.now().toIso8601String(),
        'ccRemarks': remarks,
      });

  Future<void> ccReject(String id, String by, {String remarks = ''}) =>
      _db.collection('scholarship_requests').doc(id).update({
        'status': 'cc_rejected',
        'ccApprovedBy': by,
        'ccRemarks': remarks,
      });

  /// Technical: pending_technical
  Stream<List<ScholarshipModel>> getPendingTechnical() {
    return _db
        .collection('scholarship_requests')
        .where('status', isEqualTo: 'pending_technical')
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ScholarshipModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<void> technicalApprove(
    String id,
    String approvedBy, {
    String remarks = '',
  }) => _db.collection('scholarship_requests').doc(id).update({
    'status': 'approved',
    'technicalApprovedBy': approvedBy,
    'technicalApprovedDate': DateTime.now().toIso8601String(),
    'technicalRemarks': remarks,
  });

  Future<void> technicalReject(String id, String by, {String remarks = ''}) =>
      _db.collection('scholarship_requests').doc(id).update({
        'status': 'rejected',
        'technicalApprovedBy': by,
        'technicalRemarks': remarks,
      });

  /// All scholarship requests — for recent activity feeds (newest first)
  Stream<List<ScholarshipModel>> getAllScholarships() {
    return _db
        .collection('scholarship_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ScholarshipModel.fromMap(d.data(), d.id))
            .toList());
  }
}
