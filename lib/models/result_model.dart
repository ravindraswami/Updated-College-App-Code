class ResultModel {
  final String id;
  final String studentId;
  final String examId;
  final Map<String, int> answers; // questionId -> selectedOptionIndex
  final int score;
  final double percentage;
  final int totalQuestions;
  final DateTime timestamp;

  ResultModel({
    required this.id,
    required this.studentId,
    required this.examId,
    required this.answers,
    required this.score,
    required this.percentage,
    required this.totalQuestions,
    required this.timestamp,
  });

  factory ResultModel.fromMap(Map<String, dynamic> map, String id) {
    return ResultModel(
      id: id,
      studentId: map['studentId'] ?? '',
      examId: map['examId'] ?? '',
      answers: Map<String, int>.from(map['answers'] ?? {}),
      score: map['score'] ?? 0,
      percentage: (map['percentage'] ?? 0).toDouble(),
      totalQuestions: map['totalQuestions'] ?? 0,
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'examId': examId,
      'answers': answers,
      'score': score,
      'percentage': percentage,
      'totalQuestions': totalQuestions,
      'timestamp': timestamp,
    };
  }
}
