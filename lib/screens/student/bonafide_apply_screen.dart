import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/bonafide_model.dart';
import '../../services/bonafide_service.dart';
import '../../services/fee_config_service.dart';
import '../../utils/app_theme.dart';
import 'payment_screen.dart';

class BonafideApplyScreen extends StatefulWidget {
  final UserModel student;
  const BonafideApplyScreen({super.key, required this.student});
  @override
  State<BonafideApplyScreen> createState() => _BonafideApplyScreenState();
}

class _BonafideApplyScreenState extends State<BonafideApplyScreen> {
  final _svc = BonafideService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BonafideModel>>(
      stream: _svc.getStudentBonafides(widget.student.id),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        // Student only sees pending/processing requests, NOT approved certs
        // (approved certificates are managed and printed by Technical Staff only)
        final pending = requests.where((r) => r.status != 'approved').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Apply new button ──────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _BonafideFormScreen(student: widget.student),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Apply for New Bonafide Certificate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Info banner — tell student where to get approved cert
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.success,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Once approved, collect your bonafide certificate from the Technical Department.',
                        style: TextStyle(color: AppTheme.success, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pending / other requests ──────────────────
              if (pending.isNotEmpty) ...[
                const _SectionHeader(
                  icon: Icons.pending,
                  label: 'Request Status',
                  color: AppTheme.warning,
                ),
                const SizedBox(height: 8),
                ...pending.map(
                  (r) => _BonafideStatusCard(request: r, svc: _svc),
                ),
              ],

              if (requests.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.badge_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No bonafide requests yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap the button above to apply.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Card for pending/processing request ──────────────────────
class _BonafideStatusCard extends StatelessWidget {
  final BonafideModel request;
  final BonafideService svc;
  const _BonafideStatusCard({required this.request, required this.svc});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(request.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.$1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.$2, color: statusInfo.$1, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        statusInfo.$3,
                        style: TextStyle(
                          color: statusInfo.$1,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  request.applyDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Purpose: ${request.purpose}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Charges: ₹${request.charges.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            // Pay now button if pending payment
            if (request.status == 'pending_payment') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        requestId: request.id,
                        amount: request.charges,
                        studentName: request.studentName,
                        paymentFor: PaymentFor.bonafide,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Complete Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                  ),
                ),
              ),
            ],

            if (request.status == 'rejected') ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Reason: Your request was rejected.',
                  style: TextStyle(color: AppTheme.error, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, IconData, String) _statusInfo(String status) {
    switch (status) {
      case 'pending_payment':
        return (AppTheme.warning, Icons.payment, 'Payment Pending');
      case 'pending_approval':
        return (AppTheme.primary, Icons.hourglass_top, 'Awaiting Approval');
      case 'rejected':
        return (AppTheme.error, Icons.cancel, 'Rejected');
      default:
        return (Colors.grey, Icons.help_outline, status);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: color,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// FORM SCREEN — separate screen for applying
// ─────────────────────────────────────────────────────────────
class _BonafideFormScreen extends StatefulWidget {
  final UserModel student;
  const _BonafideFormScreen({required this.student});
  @override
  State<_BonafideFormScreen> createState() => _BonafideFormScreenState();
}

class _BonafideFormScreenState extends State<_BonafideFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController();
  final _svc = BonafideService();
  final _feeSvc = FeeConfigService();
  bool _isLoading = false;
  double _charges = FeeConfigService.defaultBonafideFee;

  @override
  void initState() {
    super.initState();
    _feeSvc.getFees().then((fees) {
      if (mounted) setState(() => _charges = fees['bonafideFee']!);
    });
  }

  String get _todayDate => DateFormat('dd/MM/yyyy').format(DateTime.now());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final id = await _svc.applyBonafide(
        studentId: widget.student.id,
        studentName: widget.student.nameAsPerHsc.isNotEmpty
            ? widget.student.nameAsPerHsc
            : widget.student.name,
        erpId: widget.student.erpId,
        branch: widget.student.branch,
        year: widget.student.year,
        semester: widget.student.semester,
        rollNo: widget.student.registerNo,
        purpose: _purposeCtrl.text.trim(),
        charges: _charges,
      );
      if (!mounted) return;
      // Navigate to PaymentScreen with real SBI link
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            requestId: id,
            amount: _charges,
            studentName: widget.student.nameAsPerHsc.isNotEmpty
                ? widget.student.nameAsPerHsc
                : widget.student.name,
            paymentFor: PaymentFor.bonafide,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Bonafide Certificate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-filled info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Auto-filled from your profile',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _infoRow(
                      'Name',
                      s.nameAsPerHsc.isNotEmpty ? s.nameAsPerHsc : s.name,
                    ),
                    _infoRow('ERP ID', s.erpId),
                    _infoRow('Branch', s.branch),
                    _infoRow('Year', s.year),
                    _infoRow('Semester', s.semester),
                    _infoRow(
                      'Roll No.',
                      s.registerNo.isNotEmpty ? s.registerNo : '—',
                    ),
                    _infoRow('Date', _todayDate),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Purpose',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Bank account opening, Passport application, Loan purpose...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.edit_note),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Please enter the purpose.' : null,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Certificate Charges — paid in next step',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '₹${_charges.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.navigate_next),
                  label: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            l,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            v.isNotEmpty ? v : '—',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// PAYMENT SCREEN
// ─────────────────────────────────────────────────────────────
class BonafidePaymentScreen extends StatefulWidget {
  final String bonafideId;
  final double charges;

  const BonafidePaymentScreen({
    super.key,
    required this.bonafideId,
    required this.charges,
  });

  @override
  State<BonafidePaymentScreen> createState() => _BonafidePaymentScreenState();
}

class _BonafidePaymentScreenState extends State<BonafidePaymentScreen> {
  bool _processing = false;
  final _svc = BonafideService();

  Future<void> _pay(bool success) async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (success) {
      final payId = 'BON${DateTime.now().millisecondsSinceEpoch}';
      await _svc.markPaymentDone(widget.bonafideId, payId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment successful! Your request has been sent for approval.',
          ),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 4),
        ),
      );
      // ✅ FIX: pop back to form screen, then form screen pops to list
      // This avoids going to root/login
      Navigator.pop(context); // payment → form
      Navigator.pop(context); // form → bonafide list
    } else {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bonafide — Payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payment, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Bonafide Certificate Charges',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.charges.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Text(
                    '(Simulation — no real payment)',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 28),
                  if (_processing)
                    const CircularProgressIndicator()
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _pay(true),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('✅ Simulate Successful Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _pay(false),
                        icon: const Icon(Icons.cancel, color: AppTheme.error),
                        label: const Text(
                          '❌ Simulate Failed Payment',
                          style: TextStyle(color: AppTheme.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
