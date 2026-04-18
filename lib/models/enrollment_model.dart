class EnrollmentModel {
  final String id;
  final String studentId;
  final String examId;
  final bool isPaid;
  final DateTime timestamp;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.examId,
    required this.isPaid,
    required this.timestamp,
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EnrollmentModel(
      id: id,
      studentId: map['studentId'] ?? '',
      examId: map['examId'] ?? '',
      isPaid: map['isPaid'] ?? false,
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'examId': examId,
      'isPaid': isPaid,
      'timestamp': timestamp,
    };
  }
}
