class QuestionModel {
  final String id;
  final String examId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final int questionNumber;

  QuestionModel({
    required this.id,
    required this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.questionNumber,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      examId: map['examId'] ?? '',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      questionNumber: map['questionNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'questionNumber': questionNumber,
    };
  }
}
