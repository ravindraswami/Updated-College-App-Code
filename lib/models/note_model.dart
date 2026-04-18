class NoteModel {
  final String id;
  final String title;
  final String subject;
  final String pdfUrl;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String
  classId; // which class this note belongs to (empty = all classes)

  NoteModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.pdfUrl,
    required this.uploadedBy,
    required this.uploadedAt,
    this.classId = '',
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      pdfUrl: map['pdfUrl'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: (map['uploadedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      classId: map['classId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'pdfUrl': pdfUrl,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt,
      'classId': classId,
    };
  }
}
