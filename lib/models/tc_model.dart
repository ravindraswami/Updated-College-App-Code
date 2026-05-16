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
  final String motherName;
  final String religion;
  final String caste;
  final String casteCategory;
  final String dateOfAdmission;
  final String lastExamPassed;
  final String reasonForLeaving;

  // ── Status flow (NO CC step) ─────────────────────────────────
  // pending_payment → pending_technical → approved / rejected
  final String status;

  final bool isPaid;
  final double charges;
  final String paymentId;
  final String approvedBy; // Technical staff UID
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
    this.motherName = '',
    this.religion = '',
    this.caste = '',
    this.casteCategory = '',
    this.dateOfAdmission = '',
    this.lastExamPassed = '',
    this.reasonForLeaving = '',
    this.status = 'pending_payment',
    this.isPaid = false,
    this.charges = 100.0,
    this.paymentId = '',
    this.approvedBy = '',
    this.approvedDate = '',
    required this.createdAt,
  });

  factory TcModel.fromMap(Map<String, dynamic> map, String id) {
    return TcModel(
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
      motherName: map['motherName'] ?? '',
      religion: map['religion'] ?? '',
      caste: map['caste'] ?? '',
      casteCategory: map['casteCategory'] ?? '',
      dateOfAdmission: map['dateOfAdmission'] ?? '',
      lastExamPassed: map['lastExamPassed'] ?? '',
      reasonForLeaving: map['reasonForLeaving'] ?? '',
      status: map['status'] ?? 'pending_payment',
      isPaid: map['isPaid'] ?? false,
      charges: (map['charges'] ?? 100.0).toDouble(),
      paymentId: map['paymentId'] ?? '',
      approvedBy: map['approvedBy'] ?? '',
      approvedDate: map['approvedDate'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

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
    'motherName': motherName,
    'religion': religion,
    'caste': caste,
    'casteCategory': casteCategory,
    'dateOfAdmission': dateOfAdmission,
    'lastExamPassed': lastExamPassed,
    'reasonForLeaving': reasonForLeaving,
    'status': status,
    'isPaid': isPaid,
    'charges': charges,
    'paymentId': paymentId,
    'approvedBy': approvedBy,
    'approvedDate': approvedDate,
    'createdAt': createdAt,
  };

  // User-friendly status labels
  static String statusLabel(String s) {
    switch (s) {
      case 'pending_payment':
        return 'Payment Pending';
      case 'pending_technical':
        return 'Under Review by Technical Staff';
      case 'approved':
        return 'Approved — TC Ready';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  static String statusDescription(String s) {
    switch (s) {
      case 'pending_payment':
        return 'Please complete payment of ₹100 to submit your TC request.';
      case 'pending_technical':
        return 'Your TC request has been received and is being reviewed by the Technical staff.';
      case 'approved':
        return 'Your Transfer Certificate has been approved. You can now download it.';
      case 'rejected':
        return 'Your TC request was rejected. Please contact the college office.';
      default:
        return '';
    }
  }
}
