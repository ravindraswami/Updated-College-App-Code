import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/class_constants.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<UserModel>> getUsersByRole(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ── Students by classId (branch|semester) ─────────────────
  Stream<List<UserModel>> getStudentsByClass(String classId) {
    if (classId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ── Pending students for coordinator's class ───────────────
  Stream<List<UserModel>> getPendingStudentsForClass(String classId) {
    if (classId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classId', isEqualTo: classId)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ── Get coordinator for a classId ─────────────────────────
  Future<UserModel?> getCoordinatorForClass(String classId) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'coordinator')
        .where('classId', isEqualTo: classId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<void> approveUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isApproved': true});
  }

  Future<void> rejectUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isApproved': false});
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // ── HOD assigns branch+semester class to coordinator ──────
  Future<void> assignClassToCoordinator({
    required String coordinatorId,
    required String classId, // e.g. "BIO-TECH-UG|SEM-I"
    required String classLabel, // e.g. "BIO-TECH UG — Semester I"
  }) async {
    await _db.collection('users').doc(coordinatorId).update({
      'classId': classId,
      'classLabel': classLabel,
    });
  }

  Future<void> removeClassFromCoordinator(String coordinatorId) async {
    await _db.collection('users').doc(coordinatorId).update({
      'classId': '',
      'classLabel': '',
    });
  }

  Future<void> deleteUser(String userId, String erpId) async {
    await _db.collection('users').doc(userId).delete();
    await _db.collection('removed_ids').add({
      'erpId': erpId,
      'userId': userId,
      'removedAt': FieldValue.serverTimestamp(),
    });
  }
}
