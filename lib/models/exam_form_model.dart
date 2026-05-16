class ExamFormModel {
  final String id;
  final String studentId;
  final String
  classId; // same format as coordinator.classId — used for filtering

  // Student info (auto-filled)
  final String name;
  final String prn;
  final String erpId;
  final String branch;
  final String year;
  final String semester;
  final String department;
  final String rollNo;
  final String dob;
  final String mobile;
  final String email;

  // Exam details (student fills)
  final List<String> subjects;
  final bool hasBacklog;
  final List<String> backlogSubjects;
  final String examYear;
  final String examMonth;
  final String center;

  // Status flow:
  // pending_cc → pending_technical → fee_pending → fee_paid → approved
  // any stage → rejected
  final String status;

  // CC fields
  final String ccApprovedBy;
  final String ccApprovedDate;
  final String ccRemarks;

  // Technical fields
  final bool feeAdded;
  final double feeAmount;
  final String paymentStatus; // 'Not Paid' | 'Paid'
  final String paymentId;
  final String technicalApprovedBy;
  final String technicalApprovedDate;

  // Rejection
  final String rejectReason;
  final String rejectedBy; // 'cc' | 'technical'

  final DateTime submittedAt;

  ExamFormModel({
    required this.id,
    required this.studentId,
    this.classId = '',
    this.name = '',
    this.prn = '',
    this.erpId = '',
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.department = '',
    this.rollNo = '',
    this.dob = '',
    this.mobile = '',
    this.email = '',
    this.subjects = const [],
    this.hasBacklog = false,
    this.backlogSubjects = const [],
    this.examYear = '',
    this.examMonth = '',
    this.center = '',
    this.status = 'pending_cc',
    this.ccApprovedBy = '',
    this.ccApprovedDate = '',
    this.ccRemarks = '',
    this.feeAdded = false,
    this.feeAmount = 0,
    this.paymentStatus = 'Not Paid',
    this.paymentId = '',
    this.technicalApprovedBy = '',
    this.technicalApprovedDate = '',
    this.rejectReason = '',
    this.rejectedBy = '',
    required this.submittedAt,
  });

  factory ExamFormModel.fromMap(Map<String, dynamic> m, String id) {
    return ExamFormModel(
      id: id,
      studentId: m['studentId'] ?? '',
      classId: m['classId'] ?? '',
      name: m['name'] ?? '',
      prn: m['prn'] ?? '',
      erpId: m['erpId'] ?? '',
      branch: m['branch'] ?? '',
      year: m['year'] ?? '',
      semester: m['semester'] ?? '',
      department: m['department'] ?? '',
      rollNo: m['rollNo'] ?? '',
      dob: m['dob'] ?? '',
      mobile: m['mobile'] ?? '',
      email: m['email'] ?? '',
      subjects: List<String>.from(m['subjects'] ?? []),
      hasBacklog: m['hasBacklog'] ?? false,
      backlogSubjects: List<String>.from(m['backlogSubjects'] ?? []),
      examYear: m['examYear'] ?? '',
      examMonth: m['examMonth'] ?? '',
      center: m['center'] ?? '',
      status: m['status'] ?? 'pending_cc',
      ccApprovedBy: m['ccApprovedBy'] ?? '',
      ccApprovedDate: m['ccApprovedDate'] ?? '',
      ccRemarks: m['ccRemarks'] ?? '',
      feeAdded: m['feeAdded'] ?? false,
      feeAmount: (m['feeAmount'] ?? 0).toDouble(),
      paymentStatus: m['paymentStatus'] ?? 'Not Paid',
      paymentId: m['paymentId'] ?? '',
      technicalApprovedBy: m['technicalApprovedBy'] ?? '',
      technicalApprovedDate: m['technicalApprovedDate'] ?? '',
      rejectReason: m['rejectReason'] ?? '',
      rejectedBy: m['rejectedBy'] ?? '',
      submittedAt: (m['submittedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'classId': classId,
    'name': name,
    'prn': prn,
    'erpId': erpId,
    'branch': branch,
    'year': year,
    'semester': semester,
    'department': department,
    'rollNo': rollNo,
    'dob': dob,
    'mobile': mobile,
    'email': email,
    'subjects': subjects,
    'hasBacklog': hasBacklog,
    'backlogSubjects': backlogSubjects,
    'examYear': examYear,
    'examMonth': examMonth,
    'center': center,
    'status': status,
    'ccApprovedBy': ccApprovedBy,
    'ccApprovedDate': ccApprovedDate,
    'ccRemarks': ccRemarks,
    'feeAdded': feeAdded,
    'feeAmount': feeAmount,
    'paymentStatus': paymentStatus,
    'paymentId': paymentId,
    'technicalApprovedBy': technicalApprovedBy,
    'technicalApprovedDate': technicalApprovedDate,
    'rejectReason': rejectReason,
    'rejectedBy': rejectedBy,
    'submittedAt': submittedAt,
  };

  static String statusLabel(String s) {
    switch (s) {
      case 'pending_cc':
        return 'Pending CC Approval';
      case 'pending_technical':
        return 'Under Technical Review';
      case 'fee_pending':
        return 'Fee Added — Pay Now';
      case 'fee_paid':
        return 'Fee Paid — Awaiting Approval';
      case 'approved':
        return 'Approved ✓';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }
}
