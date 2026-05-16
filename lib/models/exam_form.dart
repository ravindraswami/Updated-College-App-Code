/// Legacy ExamForm class used by FormsListScreen.
/// This wraps ExamFormModel's mutable display fields
/// so the existing FormsListScreen widget works as-is.
class ExamForm {
  final String id;
  final String name;
  final String prn;
  final String year;
  final String semester;
  final String department;
  final bool hasBacklog;
  final List<String> subjects;
  String status; // 'Pending' | 'Approved' | 'Completed' | 'Rejected'
  String paymentStatus; // 'Paid' | 'Not Paid'
  bool feeAdded;
  final DateTime submittedAt;

  ExamForm({
    required this.id,
    required this.name,
    required this.prn,
    required this.year,
    required this.semester,
    required this.department,
    required this.hasBacklog,
    required this.subjects,
    required this.status,
    required this.paymentStatus,
    required this.feeAdded,
    required this.submittedAt,
  });

  /// Convert from ExamFormModel for display in FormsListScreen
  factory ExamForm.fromModel(dynamic m) {
    String displayStatus;
    switch (m.status as String) {
      case 'approved':
        displayStatus = 'Completed';
        break;
      case 'fee_paid':
      case 'fee_pending':
      case 'pending_technical':
      case 'cc_approved':
        displayStatus = 'Approved';
        break;
      case 'rejected':
        displayStatus = 'Rejected';
        break;
      default:
        displayStatus = 'Pending';
    }
    return ExamForm(
      id: m.id,
      name: m.name,
      prn: m.prn,
      year: m.year,
      semester: m.semester,
      department: m.department,
      hasBacklog: m.hasBacklog,
      subjects: List<String>.from(m.subjects),
      status: displayStatus,
      paymentStatus: m.paymentStatus,
      feeAdded: m.feeAdded,
      submittedAt: m.submittedAt,
    );
  }
}
