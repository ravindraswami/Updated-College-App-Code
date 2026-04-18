class UserModel {
  final String id;
  final String erpId;
  final String role;
  final bool isApproved;
  final DateTime createdAt;
  final String fcmToken;
  final String classId;
  final String classLabel;
  final String coordinatorId;

  // ── Academic Info ─────────────────────────────────────────
  final String branch; // BIO-TECH-UG / BIO-TECH-PG
  final String year; // FY / SY / TY
  final String semester; // SEM-I ... SEM-VI
  final String registerNo; // College registration number

  // ── Personal Info ─────────────────────────────────────────
  final String nameAsPerHsc; // As per HSC Marklist
  final String nameAsPerAadhar; // As per Aadhar card
  final String motherName; // Mother's name (before marriage)
  final String abcId; // ABC ID
  final String aadharNo; // Aadhar card number
  final String dob; // Date of birth (dd/MM/yyyy)
  final String mobile;
  final String email;
  final String maritalStatus;

  // ── Address ───────────────────────────────────────────────
  final String address;
  final String state;
  final String district;
  final String taluka;
  final String village;

  // ── Family Info ───────────────────────────────────────────
  final String fatherOrHusbandName;
  final String guardianOccupation;

  // ── Category / Religion ───────────────────────────────────
  final String religion;
  final String caste;
  final String actualCasteCategory;
  final String admittedCasteCategory;
  final String otherCategory;
  final String hostelFacility; // 'Yes' / 'No'

  // ── Legacy / Staff fields ─────────────────────────────────
  final String name; // for staff (professor / coordinator / hod / principal)
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
    // Academic
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.registerNo = '',
    // Personal
    this.nameAsPerHsc = '',
    this.nameAsPerAadhar = '',
    this.motherName = '',
    this.abcId = '',
    this.aadharNo = '',
    this.dob = '',
    this.mobile = '',
    this.email = '',
    this.maritalStatus = '',
    // Address
    this.address = '',
    this.state = '',
    this.district = '',
    this.taluka = '',
    this.village = '',
    // Family
    this.fatherOrHusbandName = '',
    this.guardianOccupation = '',
    // Category
    this.religion = '',
    this.caste = '',
    this.actualCasteCategory = '',
    this.admittedCasteCategory = '',
    this.otherCategory = '',
    this.hostelFacility = 'No',
    // Staff fields
    this.name = '',
    this.department = '',
    this.phone = '',
    this.photoUrl = '',
  });

  /// Display name — uses nameAsPerHsc for students, name for staff
  String get displayName => nameAsPerHsc.isNotEmpty ? nameAsPerHsc : name;

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

  Map<String, dynamic> toMap() {
    return {
      'erpId': erpId,
      'role': role,
      'isApproved': isApproved,
      'createdAt': createdAt,
      'fcmToken': fcmToken,
      'classId': classId,
      'classLabel': classLabel,
      'coordinatorId': coordinatorId,
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
}
