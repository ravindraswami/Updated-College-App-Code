class ScholarshipModel {
  final String id;
  final String studentId;
  final String studentName;
  final String erpId;
  final String branch;
  final String year;
  final String semester;
  final String classId;
  final String coordinatorId;

  // Student fills these
  final String scholarshipType; // which scholarship
  final String casteCategory;
  final String religion;
  final String caste;
  final String mobile;
  final String address;
  final String state;
  final String district;
  final String motherName;
  final String aadharNo;
  final String dob;

  // NEW FIELDS
  final String
  formFilledStatus; // 'yes' / 'no'  — has student filled physical form?
  final String
  applicationStatus; // 'pending' / 'approved' — student self-declares
  final String pdfUrl; // uploaded scholarship form PDF URL
  final String pdfFileName; // uploaded file name

  // Approval chain
  final String
  status; // system status: pending_cc, cc_approved, approved, rejected
  final String ccApprovedBy;
  final String ccApprovedDate;
  final String ccRemarks;
  final String technicalApprovedBy;
  final String technicalApprovedDate;
  final String technicalRemarks;
  final DateTime createdAt;

  ScholarshipModel({
    required this.id,
    required this.studentId,
    this.studentName = '',
    this.erpId = '',
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.classId = '',
    this.coordinatorId = '',
    required this.scholarshipType,
    this.casteCategory = '',
    this.religion = '',
    this.caste = '',
    this.mobile = '',
    this.address = '',
    this.state = '',
    this.district = '',
    this.motherName = '',
    this.aadharNo = '',
    this.dob = '',
    this.formFilledStatus = 'no',
    this.applicationStatus = 'pending',
    this.pdfUrl = '',
    this.pdfFileName = '',
    this.status = 'pending_cc',
    this.ccApprovedBy = '',
    this.ccApprovedDate = '',
    this.ccRemarks = '',
    this.technicalApprovedBy = '',
    this.technicalApprovedDate = '',
    this.technicalRemarks = '',
    required this.createdAt,
  });

  factory ScholarshipModel.fromMap(Map<String, dynamic> m, String id) =>
      ScholarshipModel(
        id: id,
        studentId: m['studentId'] ?? '',
        studentName: m['studentName'] ?? '',
        erpId: m['erpId'] ?? '',
        branch: m['branch'] ?? '',
        year: m['year'] ?? '',
        semester: m['semester'] ?? '',
        classId: m['classId'] ?? '',
        coordinatorId: m['coordinatorId'] ?? '',
        scholarshipType: m['scholarshipType'] ?? '',
        casteCategory: m['casteCategory'] ?? '',
        religion: m['religion'] ?? '',
        caste: m['caste'] ?? '',
        mobile: m['mobile'] ?? '',
        address: m['address'] ?? '',
        state: m['state'] ?? '',
        district: m['district'] ?? '',
        motherName: m['motherName'] ?? '',
        aadharNo: m['aadharNo'] ?? '',
        dob: m['dob'] ?? '',
        formFilledStatus: m['formFilledStatus'] ?? 'no',
        applicationStatus: m['applicationStatus'] ?? 'pending',
        pdfUrl: m['pdfUrl'] ?? '',
        pdfFileName: m['pdfFileName'] ?? '',
        status: m['status'] ?? 'pending_cc',
        ccApprovedBy: m['ccApprovedBy'] ?? '',
        ccApprovedDate: m['ccApprovedDate'] ?? '',
        ccRemarks: m['ccRemarks'] ?? '',
        technicalApprovedBy: m['technicalApprovedBy'] ?? '',
        technicalApprovedDate: m['technicalApprovedDate'] ?? '',
        technicalRemarks: m['technicalRemarks'] ?? '',
        createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'erpId': erpId,
    'branch': branch,
    'year': year,
    'semester': semester,
    'classId': classId,
    'coordinatorId': coordinatorId,
    'scholarshipType': scholarshipType,
    'casteCategory': casteCategory,
    'religion': religion,
    'caste': caste,
    'mobile': mobile,
    'address': address,
    'state': state,
    'district': district,
    'motherName': motherName,
    'aadharNo': aadharNo,
    'dob': dob,
    'formFilledStatus': formFilledStatus,
    'applicationStatus': applicationStatus,
    'pdfUrl': pdfUrl,
    'pdfFileName': pdfFileName,
    'status': status,
    'ccApprovedBy': ccApprovedBy,
    'ccApprovedDate': ccApprovedDate,
    'ccRemarks': ccRemarks,
    'technicalApprovedBy': technicalApprovedBy,
    'technicalApprovedDate': technicalApprovedDate,
    'technicalRemarks': technicalRemarks,
    'createdAt': createdAt,
  };
}
