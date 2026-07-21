class ExamFormModel {
  final String id;
  final String studentId;
  final String classId;

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
  final List<String> subjects;        // subject display names
  final List<String> subjectIds;      // subject Firestore IDs
  final bool hasBacklog;
  final List<String> backlogSubjects; // backlog display names
  final List<String> backlogSubjectIds;
  final String examYear;
  final String examMonth;
  final String center;
  final String session; // Summer / Winter
  final String advisorName;
  final String advisorDesignation;

  // Per-subject fees stored at submission time (map: subjectId -> fee)
  final Map<String, double> subjectRegularFees;  // regularFee per subject
  final Map<String, double> subjectBacklogFees;  // backlogFee per subject
  final Map<String, double> subjectCredits;      // credit per regular subject
  final Map<String, double> backlogSubjectCredits; // credit per backlog subject
  final Map<String, String> subjectCodes;        // course code per subject
  final Map<String, String> subjectTitles;       // course title per subject
  final Map<String, String> backlogSubjectCodes;
  final Map<String, String> backlogSubjectTitles;

  // Status flow:
  // pending_cc → pending_technical → fee_pending → fee_paid → approved
  final String status;

  // CC fields
  final String ccApprovedBy;
  final String ccApprovedDate;
  final String ccRemarks;

  // Technical fields
  final bool feeAdded;
  final double feeAmount;
  final String paymentStatus;
  final String paymentId;
  final String technicalApprovedBy;
  final String technicalApprovedDate;

  // Rejection
  final String rejectReason;
  final String rejectedBy;

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
    this.subjectIds = const [],
    this.hasBacklog = false,
    this.backlogSubjects = const [],
    this.backlogSubjectIds = const [],
    this.examYear = '',
    this.examMonth = '',
    this.center = '',
    this.session = '',
    this.advisorName = '',
    this.advisorDesignation = '',
    this.subjectRegularFees = const {},
    this.subjectBacklogFees = const {},
    this.subjectCredits = const {},
    this.backlogSubjectCredits = const {},
    this.subjectCodes = const {},
    this.subjectTitles = const {},
    this.backlogSubjectCodes = const {},
    this.backlogSubjectTitles = const {},
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

  /// Total regular fee = sum of regularFee for all regular subjects
  double get totalRegularFee =>
      subjectRegularFees.values.fold(0, (a, b) => a + b);

  /// Total backlog fee = sum of backlogFee for all backlog subjects
  double get totalBacklogFee =>
      subjectBacklogFees.values.fold(0, (a, b) => a + b);

  /// Grand total fee (before technical override)
  double get calculatedTotalFee => totalRegularFee + totalBacklogFee;

  /// Total course count (regular)
  int get totalCourseCount => subjects.length;

  /// Total credit sum (regular)
  double get totalCreditSum =>
      subjectCredits.values.fold(0, (a, b) => a + b);

  /// Total course count (backlog)
  int get totalBacklogCourseCount => backlogSubjects.length;

  /// Total credit sum (backlog)
  double get totalBacklogCreditSum =>
      backlogSubjectCredits.values.fold(0, (a, b) => a + b);

  factory ExamFormModel.fromMap(Map<String, dynamic> m, String id) {
    Map<String, double> _toDoubleMap(dynamic raw) {
      if (raw == null) return {};
      final map = raw as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v ?? 0).toDouble()));
    }

    Map<String, String> _toStringMap(dynamic raw) {
      if (raw == null) return {};
      final map = raw as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v ?? '').toString()));
    }

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
      subjectIds: List<String>.from(m['subjectIds'] ?? []),
      hasBacklog: m['hasBacklog'] ?? false,
      backlogSubjects: List<String>.from(m['backlogSubjects'] ?? []),
      backlogSubjectIds: List<String>.from(m['backlogSubjectIds'] ?? []),
      examYear: m['examYear'] ?? '',
      examMonth: m['examMonth'] ?? '',
      center: m['center'] ?? '',
      session: m['session'] ?? '',
      advisorName: m['advisorName'] ?? '',
      advisorDesignation: m['advisorDesignation'] ?? '',
      subjectRegularFees: _toDoubleMap(m['subjectRegularFees']),
      subjectBacklogFees: _toDoubleMap(m['subjectBacklogFees']),
      subjectCredits: _toDoubleMap(m['subjectCredits']),
      backlogSubjectCredits: _toDoubleMap(m['backlogSubjectCredits']),
      subjectCodes: _toStringMap(m['subjectCodes']),
      subjectTitles: _toStringMap(m['subjectTitles']),
      backlogSubjectCodes: _toStringMap(m['backlogSubjectCodes']),
      backlogSubjectTitles: _toStringMap(m['backlogSubjectTitles']),
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
    'subjectIds': subjectIds,
    'hasBacklog': hasBacklog,
    'backlogSubjects': backlogSubjects,
    'backlogSubjectIds': backlogSubjectIds,
    'examYear': examYear,
    'examMonth': examMonth,
    'center': center,
    'session': session,
    'advisorName': advisorName,
    'advisorDesignation': advisorDesignation,
    'subjectRegularFees': subjectRegularFees,
    'subjectBacklogFees': subjectBacklogFees,
    'subjectCredits': subjectCredits,
    'backlogSubjectCredits': backlogSubjectCredits,
    'subjectCodes': subjectCodes,
    'subjectTitles': subjectTitles,
    'backlogSubjectCodes': backlogSubjectCodes,
    'backlogSubjectTitles': backlogSubjectTitles,
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
