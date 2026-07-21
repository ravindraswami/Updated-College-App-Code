import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/result_model.dart';

class ExamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── EXAMS ───────────────────────────────────────────────
  Future<String> createExam(ExamModel exam) async {
    final doc = await _db.collection('exams').add(exam.toMap());
    return doc.id;
  }

  Future<void> updateExam(ExamModel exam) async {
    await _db.collection('exams').doc(exam.id).update(exam.toMap());
  }

  Future<void> deleteExam(String examId) async {
    await _db.collection('exams').doc(examId).delete();
    final qs = await _db
        .collection('questions')
        .where('examId', isEqualTo: examId)
        .get();
    for (final doc in qs.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<ExamModel>> getExams() {
    return _db
        .collection('exams')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ExamModel.fromMap(d.data(), d.id)).toList()
                ..sort((a, b) => a.examDate.compareTo(b.examDate)),
        );
  }

  /// Fix 2: Returns exams that target this student's branch/semester (or targetAllStudents).
  Stream<List<ExamModel>> getExamsForStudent({
    required String branch,
    required String semester,
  }) {
    return _db.collection('exams').snapshots().map((s) {
      final all = s.docs.map((d) => ExamModel.fromMap(d.data(), d.id)).toList();
      return all.where((e) {
        if (e.targetAllStudents || e.targetBranch.isEmpty) return true;
        if (e.targetBranch != branch) return false;
        if (e.targetSemester.isEmpty) return true; // branch match, any sem
        return e.targetSemester == semester;
      }).toList()..sort((a, b) => a.examDate.compareTo(b.examDate));
    });
  }

  Stream<List<ExamModel>> getExamsByProfessor(String professorId) {
    return _db
        .collection('exams')
        .where('professorId', isEqualTo: professorId)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ExamModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<ExamModel?> getExam(String examId) async {
    final doc = await _db.collection('exams').doc(examId).get();
    if (!doc.exists) return null;
    return ExamModel.fromMap(doc.data()!, doc.id);
  }

  // ─── QUESTIONS ───────────────────────────────────────────
  Future<List<QuestionModel>> getQuestions(String examId) async {
    try {
      final snap = await _db
          .collection('questions')
          .where('examId', isEqualTo: examId)
          .get();
      final list = snap.docs
          .map((d) => QuestionModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.questionNumber.compareTo(b.questionNumber));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Live count of questions actually saved for an exam. Used instead of
  /// the exam's stored `totalQuestions` field so the count shown to the
  /// professor/student is always correct, even if that field ever drifts
  /// out of sync (e.g. a partially-failed save).
  Stream<int> watchQuestionCount(String examId) {
    return _db
        .collection('questions')
        .where('examId', isEqualTo: examId)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> addQuestion(QuestionModel question) async {
    await _db.collection('questions').add(question.toMap());
  }

  Future<void> updateQuestion(QuestionModel question) async {
    await _db.collection('questions').doc(question.id).update(question.toMap());
  }

  Future<void> updateQuestionImage(String questionId, String imageUrl) async {
    await _db.collection('questions').doc(questionId).update({
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteQuestion(String questionId) async {
    await _db.collection('questions').doc(questionId).delete();
  }

  // ─── ENROLLMENTS ─────────────────────────────────────────
  Future<void> enrollStudent({
    required String studentId,
    required String examId,
    required bool isPaid,
  }) async {
    final existing = await _db
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .where('examId', isEqualTo: examId)
        .get();
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({'isPaid': isPaid});
    } else {
      await _db.collection('enrollments').add({
        'studentId': studentId,
        'examId': examId,
        'isPaid': isPaid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isEnrolled(String studentId, String examId) async {
    try {
      final snap = await _db
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('examId', isEqualTo: examId)
          .where('isPaid', isEqualTo: true)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─── RESULTS ─────────────────────────────────────────────
  Future<void> saveResult(ResultModel result) async {
    try {
      final existing = await _db
          .collection('results')
          .where('studentId', isEqualTo: result.studentId)
          .where('examId', isEqualTo: result.examId)
          .get();
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(result.toMap());
      } else {
        await _db.collection('results').add(result.toMap());
      }
    } catch (e) {
      await _db.collection('results').add(result.toMap());
    }
  }

  Future<ResultModel?> getResult(String studentId, String examId) async {
    try {
      final snap = await _db
          .collection('results')
          .where('studentId', isEqualTo: studentId)
          .where('examId', isEqualTo: examId)
          .get();
      if (snap.docs.isEmpty) return null;
      return ResultModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<ResultModel>> getResultsByExam(String examId) {
    return _db
        .collection('results')
        .where('examId', isEqualTo: examId)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ResultModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<ResultModel>> getResultsByStudent(String studentId) {
    return _db
        .collection('results')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ResultModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<ResultModel>> getAllResults() {
    return _db
        .collection('results')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ResultModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // ─── RESULT PUBLISHING ───────────────────────────────────
  // ✅ These are INSIDE the class — they can access _db
  Future<void> publishResult(String examId) async {
    await _db.collection('exams').doc(examId).update({
      'isResultPublished': true,
    });
  }

  Future<void> unpublishResult(String examId) async {
    await _db.collection('exams').doc(examId).update({
      'isResultPublished': false,
    });
  }

  // ─── RE-EXAM CONTROL ─────────────────────────────────────
  Future<void> allowReExam(String examId) async {
    await _db.collection('exams').doc(examId).update({'isReExamAllowed': true});
  }

  Future<void> disallowReExam(String examId) async {
    await _db.collection('exams').doc(examId).update({
      'isReExamAllowed': false,
    });
  }

  /// Reset a specific student's attempt so they can re-take
  Future<void> resetStudentAttempt({
    required String studentId,
    required String examId,
  }) async {
    final results = await _db
        .collection('results')
        .where('studentId', isEqualTo: studentId)
        .where('examId', isEqualTo: examId)
        .get();
    for (final doc in results.docs) {
      await doc.reference.delete();
    }

    final enrollments = await _db
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .where('examId', isEqualTo: examId)
        .get();
    for (final doc in enrollments.docs) {
      await doc.reference.update({'reExamGranted': true});
    }
  }
}
