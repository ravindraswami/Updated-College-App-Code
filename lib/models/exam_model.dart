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
  final bool isReExamAllowed; // ← Professor controls re-exam permission

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
    };
  }

  ExamModel copyWith({bool? isResultPublished, bool? isReExamAllowed}) {
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
    );
  }
}
