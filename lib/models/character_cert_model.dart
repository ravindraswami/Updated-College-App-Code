class CharacterCertModel {
  final String id;
  final String studentId;
  final String studentName;
  final String erpId;
  final String branch;
  final String year;
  final String semester;
  final String rollNo;
  final String dob;
  final String conductRemark;
  final String purpose;

  // ── Status flow (NO CC step) ─────────────────────────────────
  // pending_payment → pending_technical → approved / rejected
  final String status;

  final bool isPaid;
  final double charges;
  final String paymentId;
  final String approvedBy; // Technical staff UID
  final String approvedDate;
  final DateTime createdAt;

  CharacterCertModel({
    required this.id,
    required this.studentId,
    this.studentName = '',
    this.erpId = '',
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.rollNo = '',
    this.dob = '',
    this.conductRemark = 'Good',
    this.purpose = '',
    this.status = 'pending_payment',
    this.isPaid = false,
    this.charges = 50.0,
    this.paymentId = '',
    this.approvedBy = '',
    this.approvedDate = '',
    required this.createdAt,
  });

  factory CharacterCertModel.fromMap(Map<String, dynamic> map, String id) {
    return CharacterCertModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      erpId: map['erpId'] ?? '',
      branch: map['branch'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      rollNo: map['rollNo'] ?? '',
      dob: map['dob'] ?? '',
      conductRemark: map['conductRemark'] ?? 'Good',
      purpose: map['purpose'] ?? '',
      status: map['status'] ?? 'pending_payment',
      isPaid: map['isPaid'] ?? false,
      charges: (map['charges'] ?? 50.0).toDouble(),
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
    'dob': dob,
    'conductRemark': conductRemark,
    'purpose': purpose,
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
      case 'pending_payment':
        return 'Payment Pending';
      case 'pending_technical':
        return 'Under Review by Technical Staff';
      case 'approved':
        return 'Approved — Certificate Ready';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  static String statusDescription(String s) {
    switch (s) {
      case 'pending_payment':
        return 'Please complete payment of ₹50 to submit your request.';
      case 'pending_technical':
        return 'Your request has been received and is being reviewed by the Technical staff.';
      case 'approved':
        return 'Your Character Certificate has been approved. You can now download it.';
      case 'rejected':
        return 'Your request was rejected. Please contact the college office.';
      default:
        return '';
    }
  }
}
