class UserModel {
  final String id;
  final String erpId;
  final String role;
  final bool isApproved;
  final DateTime createdAt;
  final String fcmToken;

  // ── Class assignment ──────────────────────────────────────
  final String classId; // e.g. "FY-A"
  final String classLabel; // e.g. "First Year - Division A"
  final String coordinatorId; // for students: their coordinator's UID

  // For coordinators: which student slot they manage
  // HOD sets: slotStart=1, slotEnd=20 for CC-1; slotStart=21, slotEnd=40 for CC-2
  // -1 means no limit (all students in class)
  final int slotStart; // inclusive, 1-based
  final int slotEnd; // inclusive

  // ── Academic Info ─────────────────────────────────────────
  final String branch;
  final String year;
  final String semester;
  final String registerNo;

  // ── Personal Info ─────────────────────────────────────────
  final String nameAsPerHsc;
  final String nameAsPerAadhar;
  final String motherName;
  final String abcId;
  final String aadharNo;
  final String dob;
  final String mobile;
  final String email;
  final String maritalStatus;

  // ── Address ───────────────────────────────────────────────
  final String address;
  final String state;
  final String district;
  final String taluka;
  final String village;

  // ── Family ────────────────────────────────────────────────
  final String fatherOrHusbandName;
  final String guardianOccupation;

  // ── Category ─────────────────────────────────────────────
  final String religion;
  final String caste;
  final String actualCasteCategory;
  final String admittedCasteCategory;
  final String otherCategory;
  final String hostelFacility;

  // ── Staff fields ──────────────────────────────────────────
  final String name;
  final String department;
  final String phone;
  final String photoUrl;

  UserModel({
    required this.id,
    this.erpId = '',
    required this.role,
    this.isApproved = false,
    required this.createdAt,
    this.fcmToken = '',
    this.classId = '',
    this.classLabel = '',
    this.coordinatorId = '',
    this.slotStart = -1,
    this.slotEnd = -1,
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.registerNo = '',
    this.nameAsPerHsc = '',
    this.nameAsPerAadhar = '',
    this.motherName = '',
    this.abcId = '',
    this.aadharNo = '',
    this.dob = '',
    this.mobile = '',
    this.email = '',
    this.maritalStatus = '',
    this.address = '',
    this.state = '',
    this.district = '',
    this.taluka = '',
    this.village = '',
    this.fatherOrHusbandName = '',
    this.guardianOccupation = '',
    this.religion = '',
    this.caste = '',
    this.actualCasteCategory = '',
    this.admittedCasteCategory = '',
    this.otherCategory = 'None',
    this.hostelFacility = 'No',
    this.name = '',
    this.department = '',
    this.phone = '',
    this.photoUrl = '',
  });

  String get displayName => nameAsPerHsc.isNotEmpty ? nameAsPerHsc : name;

  bool get hasSlot => slotStart > 0 && slotEnd > 0;

  String get slotLabel =>
      hasSlot ? 'Students $slotStart–$slotEnd' : 'All Students';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      erpId: map['erpId'] ?? '',
      role: map['role'] ?? 'student',
      isApproved: map['isApproved'] ?? false,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      fcmToken: map['fcmToken'] ?? '',
      classId: map['classId'] ?? '',
      classLabel: map['classLabel'] ?? '',
      coordinatorId: map['coordinatorId'] ?? '',
      slotStart: (map['slotStart'] ?? -1) as int,
      slotEnd: (map['slotEnd'] ?? -1) as int,
      branch: map['branch'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      registerNo: map['registerNo'] ?? '',
      nameAsPerHsc: map['nameAsPerHsc'] ?? '',
      nameAsPerAadhar: map['nameAsPerAadhar'] ?? '',
      motherName: map['motherName'] ?? '',
      abcId: map['abcId'] ?? '',
      aadharNo: map['aadharNo'] ?? '',
      dob: map['dob'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      maritalStatus: map['maritalStatus'] ?? '',
      address: map['address'] ?? '',
      state: map['state'] ?? '',
      district: map['district'] ?? '',
      taluka: map['taluka'] ?? '',
      village: map['village'] ?? '',
      fatherOrHusbandName: map['fatherOrHusbandName'] ?? '',
      guardianOccupation: map['guardianOccupation'] ?? '',
      religion: map['religion'] ?? '',
      caste: map['caste'] ?? '',
      actualCasteCategory: map['actualCasteCategory'] ?? '',
      admittedCasteCategory: map['admittedCasteCategory'] ?? '',
      otherCategory: map['otherCategory'] ?? 'None',
      hostelFacility: map['hostelFacility'] ?? 'No',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'erpId': erpId,
    'role': role,
    'isApproved': isApproved,
    'createdAt': createdAt,
    'fcmToken': fcmToken,
    'classId': classId,
    'classLabel': classLabel,
    'coordinatorId': coordinatorId,
    'slotStart': slotStart,
    'slotEnd': slotEnd,
    'branch': branch,
    'year': year,
    'semester': semester,
    'registerNo': registerNo,
    'nameAsPerHsc': nameAsPerHsc,
    'nameAsPerAadhar': nameAsPerAadhar,
    'motherName': motherName,
    'abcId': abcId,
    'aadharNo': aadharNo,
    'dob': dob,
    'mobile': mobile,
    'email': email,
    'maritalStatus': maritalStatus,
    'address': address,
    'state': state,
    'district': district,
    'taluka': taluka,
    'village': village,
    'fatherOrHusbandName': fatherOrHusbandName,
    'guardianOccupation': guardianOccupation,
    'religion': religion,
    'caste': caste,
    'actualCasteCategory': actualCasteCategory,
    'admittedCasteCategory': admittedCasteCategory,
    'otherCategory': otherCategory,
    'hostelFacility': hostelFacility,
    'name': name,
    'department': department,
    'phone': phone,
    'photoUrl': photoUrl,
  };
}
