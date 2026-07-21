class SubjectModel {
  final String id;
  final String name;
  final String code; // e.g. BT101
  final String branch; // BIO-TECH-UG / BIO-TECH-PG
  final String semester; // SEM-I ... SEM-VIII
  final String year; // FY / SY / TY / LY
  final String scheme; // Old / New / NEP
  final double theoryCredit;
  final double practicalCredit;
  final String addedBy; // UID of the person who added this subject
  final String addedByName;
  final DateTime createdAt;
  final double regularFee; // exam fee for regular students
  final double backlogFee; // exam fee for backlog/ATKT students
  final String teacherId; // assigned Course Teacher UID
  final String teacherName; // assigned Course Teacher name

  SubjectModel({
    required this.id,
    required this.name,
    this.code = '',
    required this.branch,
    required this.semester,
    required this.year,
    this.scheme = 'New',
    this.theoryCredit = 0,
    this.practicalCredit = 0,
    required this.addedBy,
    this.addedByName = '',
    required this.createdAt,
    this.regularFee = 0,
    this.backlogFee = 0,
    this.teacherId = '',
    this.teacherName = '',
  });

  double get totalCredit => theoryCredit + practicalCredit;

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return SubjectModel(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      branch: map['branch'] ?? '',
      semester: map['semester'] ?? '',
      year: map['year'] ?? '',
      scheme: map['scheme'] ?? 'New',
      theoryCredit: (map['theoryCredit'] ?? 0).toDouble(),
      practicalCredit: (map['practicalCredit'] ?? 0).toDouble(),
      addedBy: map['addedBy'] ?? '',
      addedByName: map['addedByName'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      regularFee: (map['regularFee'] ?? 0).toDouble(),
      backlogFee: (map['backlogFee'] ?? 0).toDouble(),
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'branch': branch,
    'semester': semester,
    'year': year,
    'scheme': scheme,
    'theoryCredit': theoryCredit,
    'practicalCredit': practicalCredit,
    'addedBy': addedBy,
    'addedByName': addedByName,
    'createdAt': createdAt,
    'regularFee': regularFee,
    'backlogFee': backlogFee,
    'teacherId': teacherId,
    'teacherName': teacherName,
  };

  SubjectModel copyWith({
    double? regularFee,
    double? backlogFee,
    String? teacherId,
    String? teacherName,
  }) => SubjectModel(
    id: id, name: name, code: code, branch: branch, semester: semester,
    year: year, scheme: scheme, theoryCredit: theoryCredit,
    practicalCredit: practicalCredit, addedBy: addedBy,
    addedByName: addedByName, createdAt: createdAt,
    regularFee: regularFee ?? this.regularFee,
    backlogFee: backlogFee ?? this.backlogFee,
    teacherId: teacherId ?? this.teacherId,
    teacherName: teacherName ?? this.teacherName,
  );

  String get displayName => code.isNotEmpty ? '$code — $name' : name;
}
