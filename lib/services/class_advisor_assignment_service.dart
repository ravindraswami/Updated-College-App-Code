import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_advisor_assignment_model.dart';

class ClassAdvisorAssignmentService {
  final _db = FirebaseFirestore.instance;
  final _col = 'class_advisor_assignments';

  Future<void> addAssignment(ClassAdvisorAssignmentModel a) async {
    await _db.collection(_col).add(a.toMap());
  }

  Future<void> deleteAssignment(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  Stream<List<ClassAdvisorAssignmentModel>> getAssignments(String branch) {
    return _db
        .collection(_col)
        .where('branch', isEqualTo: branch)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) =>
                    ClassAdvisorAssignmentModel.fromMap(d.data(), d.id),
              )
              .toList(),
        );
  }

  Stream<List<ClassAdvisorAssignmentModel>> getAssignmentsForAdvisor(
    String advisorId,
  ) {
    return _db
        .collection(_col)
        .where('advisorId', isEqualTo: advisorId)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) =>
                    ClassAdvisorAssignmentModel.fromMap(d.data(), d.id),
              )
              .toList(),
        );
  }

  Stream<List<ClassAdvisorAssignmentModel>> getAllAssignments() {
    return _db
        .collection(_col)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) =>
                    ClassAdvisorAssignmentModel.fromMap(d.data(), d.id),
              )
              .toList(),
        );
  }

  /// Finds the advisor assigned to a given branch + year + semester + regNo,
  /// if any. Falls back to a year-only match (semester blank on the
  /// assignment) for backward compatibility with older assignments.
  Future<ClassAdvisorAssignmentModel?> findAdvisorFor(
    String branch,
    String year,
    String regNo, {
    String semester = '',
  }) async {
    final snap = await _db
        .collection(_col)
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();
    ClassAdvisorAssignmentModel? fallback;
    for (final d in snap.docs) {
      final a = ClassAdvisorAssignmentModel.fromMap(d.data(), d.id);
      if (!a.matchesRegNo(regNo)) continue;
      if (semester.isNotEmpty && a.semester == semester) return a;
      if (a.semester.isEmpty) fallback = a;
    }
    return fallback;
  }
}
