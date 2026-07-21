class ExamModel {
  final String id;
  final String title;
  final String subject;
  final DateTime examDate;
  final int durationMinutes;
  final double price;
  final String professorId;
  final String status;
  final int totalQuestions;
  final bool isResultPublished;
  final bool isReExamAllowed;

  // Fix 2: sem-wise + all-student targeting
  final String targetBranch;   // e.g. 'BIO-TECH-UG' or '' for all
  final String targetYear;     // e.g. 'SY' or ''
  final String targetSemester; // e.g. 'SEM-III' or ''
  final bool targetAllStudents; // true = all branches/sems

  ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.examDate,
    required this.durationMinutes,
    required this.price,
    required this.professorId,
    required this.status,
    required this.totalQuestions,
    this.isResultPublished = false,
    this.isReExamAllowed = false,
    this.targetBranch = '',
    this.targetYear = '',
    this.targetSemester = '',
    this.targetAllStudents = false,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      examDate: (map['examDate'] as dynamic)?.toDate() ?? DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 60,
      price: (map['price'] ?? 0).toDouble(),
      professorId: map['professorId'] ?? '',
      status: map['status'] ?? 'upcoming',
      totalQuestions: map['totalQuestions'] ?? 0,
      isResultPublished: map['isResultPublished'] ?? false,
      isReExamAllowed: map['isReExamAllowed'] ?? false,
      targetBranch: map['targetBranch'] ?? '',
      targetYear: map['targetYear'] ?? '',
      targetSemester: map['targetSemester'] ?? '',
      targetAllStudents: map['targetAllStudents'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'examDate': examDate,
      'durationMinutes': durationMinutes,
      'price': price,
      'professorId': professorId,
      'status': status,
      'totalQuestions': totalQuestions,
      'isResultPublished': isResultPublished,
      'isReExamAllowed': isReExamAllowed,
      'targetBranch': targetBranch,
      'targetYear': targetYear,
      'targetSemester': targetSemester,
      'targetAllStudents': targetAllStudents,
    };
  }

  ExamModel copyWith({
    bool? isResultPublished,
    bool? isReExamAllowed,
    String? targetBranch,
    String? targetYear,
    String? targetSemester,
    bool? targetAllStudents,
  }) {
    return ExamModel(
      id: id,
      title: title,
      subject: subject,
      examDate: examDate,
      durationMinutes: durationMinutes,
      price: price,
      professorId: professorId,
      status: status,
      totalQuestions: totalQuestions,
      isResultPublished: isResultPublished ?? this.isResultPublished,
      isReExamAllowed: isReExamAllowed ?? this.isReExamAllowed,
      targetBranch: targetBranch ?? this.targetBranch,
      targetYear: targetYear ?? this.targetYear,
      targetSemester: targetSemester ?? this.targetSemester,
      targetAllStudents: targetAllStudents ?? this.targetAllStudents,
    );
  }

  /// Human-readable target string for display
  String get targetLabel {
    if (targetAllStudents) return 'All Students';
    final parts = [
      if (targetBranch.isNotEmpty) targetBranch,
      if (targetYear.isNotEmpty) targetYear,
      if (targetSemester.isNotEmpty) targetSemester,
    ];
    return parts.isEmpty ? 'All Students' : parts.join(' • ');
  }
}
