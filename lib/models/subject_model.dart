class SubjectModel {
  final String id;
  final String name;
  final String code; // e.g. BT101
  final String branch; // BIO-TECH-UG / BIO-TECH-PG
  final String semester; // SEM-I ... SEM-VI
  final String year; // FY / SY / TY
  final String addedBy; // professor UID
  final String addedByName;
  final DateTime createdAt;

  SubjectModel({
    required this.id,
    required this.name,
    this.code = '',
    required this.branch,
    required this.semester,
    required this.year,
    required this.addedBy,
    this.addedByName = '',
    required this.createdAt,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return SubjectModel(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      branch: map['branch'] ?? '',
      semester: map['semester'] ?? '',
      year: map['year'] ?? '',
      addedBy: map['addedBy'] ?? '',
      addedByName: map['addedByName'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'branch': branch,
    'semester': semester,
    'year': year,
    'addedBy': addedBy,
    'addedByName': addedByName,
    'createdAt': createdAt,
  };

  String get displayName => code.isNotEmpty ? '$code — $name' : name;
}
