class TcModel {
  final String id;
  final String studentId;
  final String studentName;
  final String erpId;
  final String branch;
  final String year;
  final String semester;
  final String rollNo;
  final String registerNo;
  final String dob;
  final String dobInWords;
  final String motherName;
  final String religion;
  final String caste;
  final String casteCategory;
  final String dateOfAdmission;
  final String semesterAdmitted;   // "Semester in which admitted"
  final String lastCollege;        // "Last College attended"
  final String lastExamPassed;
  final String qualifiedForPromotion; // "Yes / No"
  final String reasonForLeaving;
  final String dateOfLeaving;
  final String dateOfApplication;  // "Date of application for T.C."
  final String dues;               // "Dues if any"
  final String conduct;            // "Good / Satisfactory / Poor"
  final String tcRemarks;          // "Remarks"

  final String status;
  final bool isPaid;
  final double charges;
  final String paymentId;
  final String approvedBy;
  final String approvedDate;
  final DateTime createdAt;

  TcModel({
    required this.id,
    required this.studentId,
    this.studentName = '',
    this.erpId = '',
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.rollNo = '',
    this.registerNo = '',
    this.dob = '',
    this.dobInWords = '',
    this.motherName = '',
    this.religion = '',
    this.caste = '',
    this.casteCategory = '',
    this.dateOfAdmission = '',
    this.semesterAdmitted = '',
    this.lastCollege = '',
    this.lastExamPassed = '',
    this.qualifiedForPromotion = 'Yes',
    this.reasonForLeaving = '',
    this.dateOfLeaving = '',
    this.dateOfApplication = '',
    this.dues = 'Nil',
    this.conduct = 'Good',
    this.tcRemarks = '',
    this.status = 'pending_payment',
    this.isPaid = false,
    this.charges = 100.0,
    this.paymentId = '',
    this.approvedBy = '',
    this.approvedDate = '',
    required this.createdAt,
  });

  factory TcModel.fromMap(Map<String, dynamic> map, String id) => TcModel(
    id: id,
    studentId: map['studentId'] ?? '',
    studentName: map['studentName'] ?? '',
    erpId: map['erpId'] ?? '',
    branch: map['branch'] ?? '',
    year: map['year'] ?? '',
    semester: map['semester'] ?? '',
    rollNo: map['rollNo'] ?? '',
    registerNo: map['registerNo'] ?? '',
    dob: map['dob'] ?? '',
    dobInWords: map['dobInWords'] ?? '',
    motherName: map['motherName'] ?? '',
    religion: map['religion'] ?? '',
    caste: map['caste'] ?? '',
    casteCategory: map['casteCategory'] ?? '',
    dateOfAdmission: map['dateOfAdmission'] ?? '',
    semesterAdmitted: map['semesterAdmitted'] ?? '',
    lastCollege: map['lastCollege'] ?? '',
    lastExamPassed: map['lastExamPassed'] ?? '',
    qualifiedForPromotion: map['qualifiedForPromotion'] ?? 'Yes',
    reasonForLeaving: map['reasonForLeaving'] ?? '',
    dateOfLeaving: map['dateOfLeaving'] ?? '',
    dateOfApplication: map['dateOfApplication'] ?? '',
    dues: map['dues'] ?? 'Nil',
    conduct: map['conduct'] ?? 'Good',
    tcRemarks: map['tcRemarks'] ?? '',
    status: map['status'] ?? 'pending_payment',
    isPaid: map['isPaid'] ?? false,
    charges: (map['charges'] ?? 100.0).toDouble(),
    paymentId: map['paymentId'] ?? '',
    approvedBy: map['approvedBy'] ?? '',
    approvedDate: map['approvedDate'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'erpId': erpId,
    'branch': branch,
    'year': year,
    'semester': semester,
    'rollNo': rollNo,
    'registerNo': registerNo,
    'dob': dob,
    'dobInWords': dobInWords,
    'motherName': motherName,
    'religion': religion,
    'caste': caste,
    'casteCategory': casteCategory,
    'dateOfAdmission': dateOfAdmission,
    'semesterAdmitted': semesterAdmitted,
    'lastCollege': lastCollege,
    'lastExamPassed': lastExamPassed,
    'qualifiedForPromotion': qualifiedForPromotion,
    'reasonForLeaving': reasonForLeaving,
    'dateOfLeaving': dateOfLeaving,
    'dateOfApplication': dateOfApplication,
    'dues': dues,
    'conduct': conduct,
    'tcRemarks': tcRemarks,
    'status': status,
    'isPaid': isPaid,
    'charges': charges,
    'paymentId': paymentId,
    'approvedBy': approvedBy,
    'approvedDate': approvedDate,
    'createdAt': createdAt,
  };

  static String statusLabel(String s) {
    switch (s) {
      case 'pending_payment': return 'Payment Pending';
      case 'pending_technical': return 'Under Review by Technical Staff';
      case 'approved': return 'Approved — TC Ready';
      case 'rejected': return 'Rejected';
      default: return s;
    }
  }
}
