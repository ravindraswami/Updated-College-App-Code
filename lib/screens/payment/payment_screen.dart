import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/exam_model.dart';
import '../../services/exam_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final ExamModel exam;
  const PaymentScreen({super.key, required this.exam});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Req #6: real SBI payment link (matching the Bonafide/TC/Character/
  // Registration payment flow) instead of a "Payment Successful /
  // Payment Failed" simulation.
  static const _sbiUrl = 'https://www.onlinesbi.sbi/';

  bool _isLoading = false;
  bool _urlOpened = false;
  String _method = 'SBI';
  final _examService = ExamService();
  final _authService = AuthService();
  final _txnCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  @override
  void dispose() {
    _txnCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPaymentLink() async {
    final uri = Uri.parse(_sbiUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        setState(() => _urlOpened = true);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        setState(() => _urlOpened = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser automatically. Visit www.onlinesbi.sbi'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final txnId = _txnCtrl.text.trim();
    final payDate = _dateCtrl.text.trim();
    if (txnId.isEmpty) {
      _snack('Please enter the Transaction ID / Reference No.', isError: true);
      return;
    }
    if (payDate.isEmpty) {
      _snack('Please enter the payment date.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUserModel();
      if (user == null) return;
      await _examService.enrollStudent(
        studentId: user.id,
        examId: widget.exam.id,
        isPaid: true,
        paymentId: '$_method:$txnId',
        paymentDate: payDate,
      );
      if (!mounted) return;
      _showResultDialog(true);
    } catch (e) {
      if (mounted) _snack('Submission failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {required bool isError}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
        ),
      );

  void _showResultDialog(bool success) {
    showDialog(
      context: context,
      barrierDismissible: !success,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (success ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.cancel,
                color: success ? AppTheme.success : AppTheme.error,
                size: 60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Payment Submitted!' : 'Payment Failed!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'You are now enrolled!\n${widget.exam.title}'
                  : 'Payment could not be processed. Try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (success) Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? AppTheme.success : AppTheme.primary,
                ),
                child: Text(success ? 'Access Exam' : 'Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final due = widget.exam.price;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 16),
                        const Text('Order Summary',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    _row('Exam', widget.exam.title),
                    const SizedBox(height: 8),
                    _row('Subject', widget.exam.subject),
                    const SizedBox(height: 8),
                    _row('Duration', '${widget.exam.durationMinutes} mins'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Req #6: label as "amount due" so it reads the
                        // same way as the Bonafide/TC/Registration fee
                        // screens (which show what's still remaining).
                        const Text('Amount Due',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '₹${due.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Step 1: pay via SBI or another bank/UPI app ──────
            _StepCard(
              step: '1',
              title: 'Pay the Fee',
              done: _urlOpened,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('SBI (Online SBI)'),
                          selected: _method == 'SBI',
                          onSelected: (_) => setState(() => _method = 'SBI'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Other Bank / UPI'),
                          selected: _method == 'Other',
                          onSelected: (_) => setState(() => _method = 'Other'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_method == 'SBI') ...[
                    Text(
                      'Pay ₹${due.toStringAsFixed(0)} using the official SBI payment '
                      'portal, then come back and enter the transaction details below.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openPaymentLink,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Pay via SBI (www.onlinesbi.sbi)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3C8F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'You may pay ₹${due.toStringAsFixed(0)} using any other bank '
                      'net-banking app or UPI app (Google Pay, PhonePe, Paytm, etc.), '
                      'then enter the transaction / UTR details below.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _urlOpened = true),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('I have paid via another app'),
                    ),
                  ],
                  if (_urlOpened) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'After paying, fill in the details below.',
                            style: TextStyle(color: AppTheme.success, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Step 2: transaction details ──────────────────────
            _StepCard(
              step: '2',
              title: 'Enter Payment Details',
              done: _txnCtrl.text.isNotEmpty && _dateCtrl.text.isNotEmpty,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.currency_rupee, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Amount due: ₹${due.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'For: ${widget.exam.title}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _txnCtrl,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _method == 'SBI' ? 'Transaction ID *' : 'Transaction / UTR No. *',
                      hintText: 'e.g. SBI123456789',
                      prefixIcon: const Icon(Icons.receipt_long),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onChanged: (_) => setState(() {}),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked));
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Payment Date *',
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Submitting...' : 'Submit Payment Proof',
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}

// ── Step card ─────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final bool done;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.done,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? AppTheme.success.withOpacity(0.5) : AppTheme.primary.withOpacity(0.2),
          width: done ? 1.5 : 1,
        ),
        color: done ? AppTheme.success.withOpacity(0.03) : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done ? AppTheme.success : AppTheme.primary,
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(step,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
