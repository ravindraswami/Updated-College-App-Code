import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

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

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // All approved students in a class (for HOD / Professor view)
  Stream<List<UserModel>> getStudentsByClass(String classId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classId', isEqualTo: classId)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ── Slot-based: students for a coordinator (by coordinatorId) ──
  // Student's coordinatorId field is set at registration to match
  // the coordinator whose slot had room.
  Stream<List<UserModel>> getStudentsForCoordinator(String coordinatorId) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('coordinatorId', isEqualTo: coordinatorId)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // Pending students for a coordinator (waiting approval)
  Stream<List<UserModel>> getPendingStudentsForCoordinator(
    String coordinatorId,
  ) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('coordinatorId', isEqualTo: coordinatorId)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> approveUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isApproved': true});
  }

  Future<void> rejectUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isApproved': false});
  }

  // HOD: assign class + slot to a coordinator
  Future<void> assignClassToCoordinator({
    required String coordinatorId,
    required String classId,
    required String classLabel,
    required int slotStart,
    required int slotEnd,
  }) async {
    await _db.collection('users').doc(coordinatorId).update({
      'classId': classId,
      'classLabel': classLabel,
      'slotStart': slotStart,
      'slotEnd': slotEnd,
    });
  }

  // HOD: remove class from coordinator
  Future<void> removeClassFromCoordinator(String coordinatorId) async {
    await _db.collection('users').doc(coordinatorId).update({
      'classId': '',
      'classLabel': '',
      'slotStart': -1,
      'slotEnd': -1,
    });
  }

  // ── Find which coordinator a new student should go to ─────
  // Returns the coordinator whose slot still has room in the given class.
  // Called during student registration.
  Future<String?> findCoordinatorForStudent(String classId) async {
    // Get all coordinators for this class
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'coordinator')
        .where('classId', isEqualTo: classId)
        .where('isApproved', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return null;

    final coordinators =
        snap.docs
            .map((d) => UserModel.fromMap(d.data(), d.id))
            .where((c) => c.hasSlot)
            .toList()
          ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

    // Count students already assigned to each coordinator
    for (final cc in coordinators) {
      final studentCount = await _db
          .collection('users')
          .where('coordinatorId', isEqualTo: cc.id)
          .where('role', isEqualTo: 'student')
          .count()
          .get();
      final count = studentCount.count ?? 0;
      final capacity = cc.slotEnd - cc.slotStart + 1;
      if (count < capacity) return cc.id;
    }

    // If all slots full, fall back to first coordinator
    return coordinators.isNotEmpty ? coordinators.first.id : null;
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
