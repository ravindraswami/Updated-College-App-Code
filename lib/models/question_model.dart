class QuestionModel {
  final String id;
  final String examId;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final int questionNumber;
  final String imageUrl; // optional image for this question

  QuestionModel({
    required this.id,
    required this.examId,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.questionNumber,
    this.imageUrl = '',
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      examId: map['examId'] ?? '',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      questionNumber: map['questionNumber'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'questionNumber': questionNumber,
      'imageUrl': imageUrl,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? examId,
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    int? questionNumber,
    String? imageUrl,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      questionNumber: questionNumber ?? this.questionNumber,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
