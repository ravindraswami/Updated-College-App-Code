import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';

class SubjectService {
  final _db = FirebaseFirestore.instance;
  final _col = 'subjects';

  // Professor: add a subject
  Future<void> addSubject(SubjectModel subject) async {
    await _db.collection(_col).add(subject.toMap());
  }

  // Professor: delete a subject
  Future<void> deleteSubject(String subjectId) async {
    await _db.collection(_col).doc(subjectId).delete();
  }

  // Get all subjects (for HOD, Principal, all staff)
  Stream<List<SubjectModel>> getAllSubjects() {
    return _db
        .collection(_col)
        .orderBy('semester')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => SubjectModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // Get subjects for a specific branch+semester (for exam form)
  Stream<List<SubjectModel>> getSubjectsBySemester(
    String branch,
    String semester,
  ) {
    return _db
        .collection(_col)
        .where('branch', isEqualTo: branch)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => SubjectModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // Get subjects for a specific branch+year (backlog: show all past sems)
  Future<List<SubjectModel>> getBacklogSubjects(
    String branch,
    String year,
  ) async {
    // For backlog, return all subjects for the branch in earlier semesters
    final semMap = {
      'FY': ['SEM-I', 'SEM-II'],
      'SY': ['SEM-I', 'SEM-II', 'SEM-III', 'SEM-IV'],
      'TY': ['SEM-I', 'SEM-II', 'SEM-III', 'SEM-IV', 'SEM-V', 'SEM-VI'],
    };
    final allSems = semMap[year] ?? [];
    if (allSems.isEmpty) return [];

    final snap = await _db
        .collection(_col)
        .where('branch', isEqualTo: branch)
        .where('semester', whereIn: allSems.take(10).toList())
        .get();
    return snap.docs.map((d) => SubjectModel.fromMap(d.data(), d.id)).toList();
  }
}
