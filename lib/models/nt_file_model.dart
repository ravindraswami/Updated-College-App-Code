class NtFileModel {
  final String id;
  final String uploadedBy; // non-technical staff UID
  final String uploaderName;
  final String uploaderErpId;
  final String title; // short title / label for the file
  final String description; // optional notes
  final String fileUrl; // Firebase Storage URL
  final String fileName;
  final String fileType; // pdf / image / doc / etc
  final DateTime uploadedAt;

  NtFileModel({
    required this.id,
    required this.uploadedBy,
    this.uploaderName = '',
    this.uploaderErpId = '',
    required this.title,
    this.description = '',
    required this.fileUrl,
    required this.fileName,
    this.fileType = '',
    required this.uploadedAt,
  });

  factory NtFileModel.fromMap(Map<String, dynamic> map, String id) {
    return NtFileModel(
      id: id,
      uploadedBy: map['uploadedBy'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      uploaderErpId: map['uploaderErpId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
      uploadedAt: (map['uploadedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uploadedBy': uploadedBy,
    'uploaderName': uploaderName,
    'uploaderErpId': uploaderErpId,
    'title': title,
    'description': description,
    'fileUrl': fileUrl,
    'fileName': fileName,
    'fileType': fileType,
    'uploadedAt': uploadedAt,
  };
}
