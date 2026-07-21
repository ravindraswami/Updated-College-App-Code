import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/tc_model.dart';
import '../../services/tc_service.dart';
import '../../services/fee_config_service.dart';
import '../../utils/app_theme.dart';
import 'payment_screen.dart';

class TcScreen extends StatelessWidget {
  final UserModel student;
  const TcScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final svc = TcService();
    return StreamBuilder<List<TcModel>>(
      stream: svc.getStudentTcs(student.id),
      builder: (context, snap) {
        final all = snap.data ?? [];
        // Student sees only pending/processing — approved TCs are printed by Technical
        final others = all.where((r) => r.status != 'approved').toList();
        final hasApproved = all.any((r) => r.status == 'approved');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // How it works
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How TC works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _Step(n: '1', text: 'Fill the form and pay ₹100 fee'),
                    _Step(
                      n: '2',
                      text: 'Request goes directly to Technical Staff',
                    ),
                    _Step(n: '3', text: 'Technical Staff reviews and approves'),
                    _Step(
                      n: '4',
                      text:
                          'Collect your Transfer Certificate from Technical Department',
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _TcFormScreen(student: student, svc: svc),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Apply for Transfer Certificate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Collect banner — shown when TC is approved
              if (hasApproved)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.success.withOpacity(0.25),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.success, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your Transfer Certificate has been approved!\nPlease collect it from the Technical Department.',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.success.withOpacity(0.15),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.success,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Once approved, collect your Transfer Certificate from the Technical Department.',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (others.isNotEmpty) ...[
                _Label(
                  icon: Icons.receipt_long,
                  label: 'My Requests',
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                ...others.map((r) => _StatusCard(tc: r, svc: svc)),
              ],

              if (all.isEmpty) ...[
                const SizedBox(height: 48),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No TC requests yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        'Tap above to apply.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── TC Form — fill details then pay directly ─────────────────
class _TcFormScreen extends StatefulWidget {
  final UserModel student;
  final TcService svc;
  const _TcFormScreen({required this.student, required this.svc});
  @override
  State<_TcFormScreen> createState() => _TcFormScreenState();
}

class _TcFormScreenState extends State<_TcFormScreen> {
  final _lastExamCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _feeSvc = FeeConfigService();
  bool _paying = false;
  double _charges = FeeConfigService.defaultTcFee;

  @override
  void initState() {
    super.initState();
    _feeSvc.getFees().then((fees) {
      if (mounted) setState(() => _charges = fees['tcFee']!);
    });
  }

  @override
  void dispose() {
    _lastExamCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  // Validate form then show payment dialog
  void _proceedToPayment() {
    if (_lastExamCtrl.text.trim().isEmpty || _reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    // Show payment dialog
    _showPaymentDialog();
  }

  Future<void> _showPaymentDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('TC Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 56, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text(
              'TC Charges',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              '₹${_charges.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'After payment your request will go directly\nto the Technical Staff for review.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: Text('Pay ₹${_charges.toStringAsFixed(0)}'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitAndPay();
            },
          ),
        ],
      ),
    );
  }

  // Create TC record → navigate to PaymentScreen
  Future<void> _submitAndPay() async {
    setState(() => _paying = true);
    final s = widget.student;
    try {
      // 1. Create record (status = pending_payment)
      final docRef = await widget.svc.applyTcReturnRef(
        TcModel(
          id: '',
          studentId: s.id,
          studentName: s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
          erpId: s.erpId,
          branch: s.branch,
          year: s.year,
          semester: s.semester,
          rollNo: s.registerNo,
          registerNo: s.registerNo,
          dob: s.dob,
          motherName: s.motherName,
          religion: s.religion,
          caste: s.caste,
          casteCategory: s.actualCasteCategory,
          dateOfAdmission: DateFormat('dd/MM/yyyy').format(s.createdAt),
          lastExamPassed: _lastExamCtrl.text.trim(),
          reasonForLeaving: _reasonCtrl.text.trim(),
          charges: _charges,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      // 2. Navigate to PaymentScreen with real SBI link
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            requestId: docRef,
            amount: _charges,
            studentName: s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
            paymentFor: PaymentFor.tc,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for TC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-filled card
            Card(
              color: AppTheme.primary.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-filled from your profile',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      'Name',
                      s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
                    ),
                    _InfoRow('ERP / Roll No.', s.erpId),
                    _InfoRow('Branch', '${s.branch} — ${s.year} ${s.semester}'),
                    _InfoRow('Date of Birth', s.dob),
                    _InfoRow("Mother's Name", s.motherName),
                    _InfoRow('Religion/Caste', '${s.religion} / ${s.caste}'),
                    _InfoRow('Category', s.actualCasteCategory),
                    _InfoRow(
                      'Date of Admission',
                      DateFormat('dd/MM/yyyy').format(s.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Additional Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lastExamCtrl,
              decoration: const InputDecoration(
                labelText: 'Last Exam Passed *',
                prefixIcon: Icon(Icons.school_outlined),
                hintText: 'e.g. SEM II (2024-25)',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for Leaving *',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
                hintText:
                    'e.g. Admission in another college, Personal reason...',
              ),
            ),
            const SizedBox(height: 20),

            // Pay button — no separate submit step
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _paying ? null : _proceedToPayment,
                icon: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(_paying ? 'Processing...' : 'Pay ₹${_charges.toStringAsFixed(0)} & Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Payment required to submit request to Technical Staff.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final TcModel tc;
  final TcService svc;
  const _StatusCard({required this.tc, required this.svc});

  Color get _color {
    switch (tc.status) {
      case 'pending_technical':
        return AppTheme.primary;
      case 'rejected':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top, color: _color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    TcModel.statusLabel(tc.status),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _color,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(tc.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              TcModel.statusLabel(tc.status),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (tc.reasonForLeaving.isNotEmpty)
              Text(
                'Reason: ${tc.reasonForLeaving}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Label({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 14,
        ),
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              n,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
