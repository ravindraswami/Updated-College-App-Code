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
  final String advisorId;
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

  // Status flow (legacy exam-form path):
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

  // ── Registration Form workflow (new) ──────────────────────
  // New status flow (used when startedAsRegistration == true):
  // awaiting_payment → payment_verification → form_open →
  // teacher_review → advisor_review → completed
  final bool startedAsRegistration;
  final double registrationFee;
  final bool registrationPaid;
  final String registrationPaymentId;
  final String educationVerifiedBy;
  final String educationVerifiedDate;

  // Teacher assignment per subject (regular + backlog), keyed by subjectId
  final Map<String, String> subjectTeacherIds;
  final Map<String, String> subjectTeacherNames;
  final Map<String, String> backlogSubjectTeacherIds;
  final Map<String, String> backlogSubjectTeacherNames;

  // Student's choice per backlog subject: 'OFE' or 'RR'
  final Map<String, String> backlogSelections;

  // Per-subject teacher sign-off, keyed by subjectId (regular + backlog
  // combined): value is 'RR' / 'OFE' / 'NR' once the assigned Course
  // Teacher has signed. Empty/absent = not yet signed.
  final Map<String, String> teacherSignatures;
  final Map<String, String> teacherSignedBy; // subjectId -> teacher UID
  final String teacherRemark;

  // Advisor final sign-off (per student, after all teachers have signed)
  final String advisorApprovedBy;
  final String advisorApprovedDate;
  final String advisorSignature; // 'RR' typically
  final String advisorRemark;

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
    this.advisorId = '',
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
    this.startedAsRegistration = false,
    this.registrationFee = 0,
    this.registrationPaid = false,
    this.registrationPaymentId = '',
    this.educationVerifiedBy = '',
    this.educationVerifiedDate = '',
    this.subjectTeacherIds = const {},
    this.subjectTeacherNames = const {},
    this.backlogSubjectTeacherIds = const {},
    this.backlogSubjectTeacherNames = const {},
    this.backlogSelections = const {},
    this.teacherSignatures = const {},
    this.teacherSignedBy = const {},
    this.teacherRemark = '',
    this.advisorApprovedBy = '',
    this.advisorApprovedDate = '',
    this.advisorSignature = '',
    this.advisorRemark = '',
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

  /// All subject IDs (regular + backlog) that need a Course Teacher signature.
  List<String> get allSignableSubjectIds => [...subjectIds, ...backlogSubjectIds];

  /// True once every regular + backlog subject has a teacher signature.
  bool get allTeachersSigned {
    if (allSignableSubjectIds.isEmpty) return false;
    return allSignableSubjectIds
        .every((id) => (teacherSignatures[id] ?? '').isNotEmpty);
  }

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
      advisorId: m['advisorId'] ?? '',
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
      startedAsRegistration: m['startedAsRegistration'] ?? false,
      registrationFee: (m['registrationFee'] ?? 0).toDouble(),
      registrationPaid: m['registrationPaid'] ?? false,
      registrationPaymentId: m['registrationPaymentId'] ?? '',
      educationVerifiedBy: m['educationVerifiedBy'] ?? '',
      educationVerifiedDate: m['educationVerifiedDate'] ?? '',
      subjectTeacherIds: _toStringMap(m['subjectTeacherIds']),
      subjectTeacherNames: _toStringMap(m['subjectTeacherNames']),
      backlogSubjectTeacherIds: _toStringMap(m['backlogSubjectTeacherIds']),
      backlogSubjectTeacherNames:
          _toStringMap(m['backlogSubjectTeacherNames']),
      backlogSelections: _toStringMap(m['backlogSelections']),
      teacherSignatures: _toStringMap(m['teacherSignatures']),
      teacherSignedBy: _toStringMap(m['teacherSignedBy']),
      teacherRemark: m['teacherRemark'] ?? '',
      advisorApprovedBy: m['advisorApprovedBy'] ?? '',
      advisorApprovedDate: m['advisorApprovedDate'] ?? '',
      advisorSignature: m['advisorSignature'] ?? '',
      advisorRemark: m['advisorRemark'] ?? '',
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
    'advisorId': advisorId,
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
    'startedAsRegistration': startedAsRegistration,
    'registrationFee': registrationFee,
    'registrationPaid': registrationPaid,
    'registrationPaymentId': registrationPaymentId,
    'educationVerifiedBy': educationVerifiedBy,
    'educationVerifiedDate': educationVerifiedDate,
    'subjectTeacherIds': subjectTeacherIds,
    'subjectTeacherNames': subjectTeacherNames,
    'backlogSubjectTeacherIds': backlogSubjectTeacherIds,
    'backlogSubjectTeacherNames': backlogSubjectTeacherNames,
    'backlogSelections': backlogSelections,
    'teacherSignatures': teacherSignatures,
    'teacherSignedBy': teacherSignedBy,
    'teacherRemark': teacherRemark,
    'advisorApprovedBy': advisorApprovedBy,
    'advisorApprovedDate': advisorApprovedDate,
    'advisorSignature': advisorSignature,
    'advisorRemark': advisorRemark,
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
      // Registration Form workflow
      case 'awaiting_payment':
        return 'Awaiting Fee Payment';
      case 'payment_verification':
        return 'Payment Under Verification';
      case 'form_open':
        return 'Form Open — Fill Now';
      case 'submitted':
        return 'Submitted — Awaiting Course Teacher';
      case 'teacher_review':
        return 'Under Course Teacher Review';
      case 'advisor_review':
        return 'Under Advisor Review';
      case 'completed':
        return 'Completed ✓';
      default:
        return s;
    }
  }

  ExamFormModel copyWith({
    String? status,
    bool? registrationPaid,
    String? registrationPaymentId,
    String? educationVerifiedBy,
    String? educationVerifiedDate,
    List<String>? subjects,
    List<String>? subjectIds,
    bool? hasBacklog,
    List<String>? backlogSubjects,
    List<String>? backlogSubjectIds,
    Map<String, double>? subjectCredits,
    Map<String, double>? backlogSubjectCredits,
    Map<String, String>? subjectCodes,
    Map<String, String>? subjectTitles,
    Map<String, String>? backlogSubjectCodes,
    Map<String, String>? backlogSubjectTitles,
    Map<String, String>? subjectTeacherIds,
    Map<String, String>? subjectTeacherNames,
    Map<String, String>? backlogSubjectTeacherIds,
    Map<String, String>? backlogSubjectTeacherNames,
    Map<String, String>? backlogSelections,
    Map<String, String>? teacherSignatures,
    Map<String, String>? teacherSignedBy,
    String? teacherRemark,
    String? advisorApprovedBy,
    String? advisorApprovedDate,
    String? advisorSignature,
    String? advisorRemark,
    String? advisorName,
    String? advisorId,
  }) {
    return ExamFormModel(
      id: id,
      studentId: studentId,
      classId: classId,
      name: name,
      prn: prn,
      erpId: erpId,
      branch: branch,
      year: year,
      semester: semester,
      department: department,
      rollNo: rollNo,
      dob: dob,
      mobile: mobile,
      email: email,
      subjects: subjects ?? this.subjects,
      subjectIds: subjectIds ?? this.subjectIds,
      hasBacklog: hasBacklog ?? this.hasBacklog,
      backlogSubjects: backlogSubjects ?? this.backlogSubjects,
      backlogSubjectIds: backlogSubjectIds ?? this.backlogSubjectIds,
      examYear: examYear,
      examMonth: examMonth,
      center: center,
      session: session,
      advisorId: advisorId ?? this.advisorId,
      advisorName: advisorName ?? this.advisorName,
      advisorDesignation: advisorDesignation,
      subjectRegularFees: subjectRegularFees,
      subjectBacklogFees: subjectBacklogFees,
      subjectCredits: subjectCredits ?? this.subjectCredits,
      backlogSubjectCredits: backlogSubjectCredits ?? this.backlogSubjectCredits,
      subjectCodes: subjectCodes ?? this.subjectCodes,
      subjectTitles: subjectTitles ?? this.subjectTitles,
      backlogSubjectCodes: backlogSubjectCodes ?? this.backlogSubjectCodes,
      backlogSubjectTitles: backlogSubjectTitles ?? this.backlogSubjectTitles,
      status: status ?? this.status,
      ccApprovedBy: ccApprovedBy,
      ccApprovedDate: ccApprovedDate,
      ccRemarks: ccRemarks,
      feeAdded: feeAdded,
      feeAmount: feeAmount,
      paymentStatus: paymentStatus,
      paymentId: paymentId,
      technicalApprovedBy: technicalApprovedBy,
      technicalApprovedDate: technicalApprovedDate,
      rejectReason: rejectReason,
      rejectedBy: rejectedBy,
      startedAsRegistration: startedAsRegistration,
      registrationFee: registrationFee,
      registrationPaid: registrationPaid ?? this.registrationPaid,
      registrationPaymentId:
          registrationPaymentId ?? this.registrationPaymentId,
      educationVerifiedBy: educationVerifiedBy ?? this.educationVerifiedBy,
      educationVerifiedDate:
          educationVerifiedDate ?? this.educationVerifiedDate,
      subjectTeacherIds: subjectTeacherIds ?? this.subjectTeacherIds,
      subjectTeacherNames: subjectTeacherNames ?? this.subjectTeacherNames,
      backlogSubjectTeacherIds:
          backlogSubjectTeacherIds ?? this.backlogSubjectTeacherIds,
      backlogSubjectTeacherNames:
          backlogSubjectTeacherNames ?? this.backlogSubjectTeacherNames,
      backlogSelections: backlogSelections ?? this.backlogSelections,
      teacherSignatures: teacherSignatures ?? this.teacherSignatures,
      teacherSignedBy: teacherSignedBy ?? this.teacherSignedBy,
      teacherRemark: teacherRemark ?? this.teacherRemark,
      advisorApprovedBy: advisorApprovedBy ?? this.advisorApprovedBy,
      advisorApprovedDate: advisorApprovedDate ?? this.advisorApprovedDate,
      advisorSignature: advisorSignature ?? this.advisorSignature,
      advisorRemark: advisorRemark ?? this.advisorRemark,
      submittedAt: submittedAt,
    );
  }
}
