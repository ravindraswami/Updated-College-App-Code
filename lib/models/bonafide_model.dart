class BonafideModel {
  final String id;
  final String studentId;
  final String studentName;
  final String erpId;
  final String branch;
  final String year;
  final String semester;
  final String rollNo;
  final String purpose;
  final String applyDate;
  final String status;
  final bool isPaid;
  final String paymentId;       // Transaction ID entered by student
  final String paymentDate;     // Date of payment entered by student
  final String paymentScreenshotUrl; // Firebase Storage URL of screenshot
  final double charges;
  final String approvedBy;
  final String approvedDate;
  final String pdfUrl;
  final DateTime createdAt;

  BonafideModel({
    required this.id,
    required this.studentId,
    this.studentName = '',
    this.erpId = '',
    this.branch = '',
    this.year = '',
    this.semester = '',
    this.rollNo = '',
    this.purpose = '',
    this.applyDate = '',
    this.status = 'pending_payment',
    this.isPaid = false,
    this.paymentId = '',
    this.paymentDate = '',
    this.paymentScreenshotUrl = '',
    this.charges = 50.0,
    this.approvedBy = '',
    this.approvedDate = '',
    this.pdfUrl = '',
    required this.createdAt,
  });

  factory BonafideModel.fromMap(Map<String, dynamic> map, String id) =>
      BonafideModel(
        id: id,
        studentId: map['studentId'] ?? '',
        studentName: map['studentName'] ?? '',
        erpId: map['erpId'] ?? '',
        branch: map['branch'] ?? '',
        year: map['year'] ?? '',
        semester: map['semester'] ?? '',
        rollNo: map['rollNo'] ?? '',
        purpose: map['purpose'] ?? '',
        applyDate: map['applyDate'] ?? '',
        status: map['status'] ?? 'pending_payment',
        isPaid: map['isPaid'] ?? false,
        paymentId: map['paymentId'] ?? '',
        paymentDate: map['paymentDate'] ?? '',
        paymentScreenshotUrl: map['paymentScreenshotUrl'] ?? '',
        charges: (map['charges'] ?? 50.0).toDouble(),
        approvedBy: map['approvedBy'] ?? '',
        approvedDate: map['approvedDate'] ?? '',
        pdfUrl: map['pdfUrl'] ?? '',
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
    'purpose': purpose,
    'applyDate': applyDate,
    'status': status,
    'isPaid': isPaid,
    'paymentId': paymentId,
    'paymentDate': paymentDate,
    'paymentScreenshotUrl': paymentScreenshotUrl,
    'charges': charges,
    'approvedBy': approvedBy,
    'approvedDate': approvedDate,
    'pdfUrl': pdfUrl,
    'createdAt': createdAt,
  };

  static String statusLabel(String status) {
    switch (status) {
      case 'pending_payment':    return 'Payment Pending';
      case 'payment_done':       return 'Payment Done — Awaiting Approval';
      case 'pending_approval':   return 'Under Review';
      case 'approved':           return 'Approved — Certificate Ready';
      case 'rejected':           return 'Rejected';
      default:                   return status;
    }
  }
}
