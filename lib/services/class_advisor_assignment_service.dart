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

  /// Finds the advisor assigned to a given branch + year + regNo, if any.
  Future<ClassAdvisorAssignmentModel?> findAdvisorFor(
    String branch,
    String year,
    String regNo,
  ) async {
    final snap = await _db
        .collection(_col)
        .where('branch', isEqualTo: branch)
        .where('year', isEqualTo: year)
        .get();
    for (final d in snap.docs) {
      final a = ClassAdvisorAssignmentModel.fromMap(d.data(), d.id);
      if (a.matchesRegNo(regNo)) return a;
    }
    return null;
  }
}
