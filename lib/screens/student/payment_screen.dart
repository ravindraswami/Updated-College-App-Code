import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/bonafide_service.dart';
import '../../services/tc_service.dart';
import '../../services/character_cert_service.dart';
import '../../services/scholarship_service.dart';
import '../../utils/app_theme.dart';

enum PaymentFor { bonafide, tc, character, scholarship }

class PaymentScreen extends StatefulWidget {
  final String requestId;
  final double amount;
  final String studentName;
  final PaymentFor paymentFor;

  const PaymentScreen({
    super.key,
    required this.requestId,
    required this.amount,
    required this.studentName,
    required this.paymentFor,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _paymentUrl = 'https://www.onlinesbi.sbi/';

  final _txnCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  bool _submitting = false;
  bool _urlOpened = false;

  @override
  void dispose() {
    _txnCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ── Open SBI link ─────────────────────────────────────────
  Future<void> _openPaymentLink() async {
    final uri = Uri.parse(_paymentUrl);
    try {
      // Use LaunchMode.externalApplication — most reliable for https
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        setState(() => _urlOpened = true);
      } else {
        // Fallback: try platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        setState(() => _urlOpened = true);
      }
    } catch (e) {
      // Last resort: try without canLaunchUrl check
      try {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        setState(() => _urlOpened = true);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Could not open browser automatically.'),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      await launchUrl(
                        Uri.parse(_paymentUrl),
                        mode: LaunchMode.platformDefault,
                      );
                    },
                    child: const Text(
                      'Tap here: www.onlinesbi.sbi',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────
  Future<void> _submit() async {
    final txnId = _txnCtrl.text.trim();
    final payDate = _dateCtrl.text.trim();

    if (txnId.isEmpty) {
      _snack('Please enter the Transaction ID.', isError: true);
      return;
    }
    if (payDate.isEmpty) {
      _snack('Please enter the payment date.', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      switch (widget.paymentFor) {
        case PaymentFor.bonafide:
          await BonafideService().markPaymentDone(
            widget.requestId,
            txnId,
            paymentDate: payDate,
          );
          break;
        case PaymentFor.tc:
          await TcService().markPaymentDone(
            widget.requestId,
            txnId,
            paymentDate: payDate,
          );
          break;
        case PaymentFor.character:
          await CharacterCertService().markPaymentDone(
            widget.requestId,
            txnId,
            paymentDate: payDate,
          );
          break;
        case PaymentFor.scholarship:
          await ScholarshipService().markPaymentDone(
            widget.requestId,
            txnId,
            paymentDate: payDate,
          );
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment submitted! Technical Staff will verify and approve.',
          ),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Submission failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {required bool isError}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppTheme.error : AppTheme.success,
          duration: Duration(seconds: isError ? 3 : 5),
        ),
      );

  String get _title {
    switch (widget.paymentFor) {
      case PaymentFor.bonafide:
        return 'Bonafide';
      case PaymentFor.tc:
        return 'Transfer Certificate';
      case PaymentFor.character:
        return 'Character Certificate';
      case PaymentFor.scholarship:
        return 'Scholarship';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_title — Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount card ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _title,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'For: ${widget.studentName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Step 1: Open payment link ──────────────────
            _StepCard(
              step: '1',
              title: 'Pay via SBI Online Banking',
              done: _urlOpened,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Click the button below to open the SBI payment portal. '
                    'Complete the payment of the amount shown above.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openPaymentLink,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open SBI Payment Portal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3C8F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Manual link as backup
                  GestureDetector(
                    onTap: _openPaymentLink,
                    child: const Text(
                      'www.onlinesbi.sbi',
                      style: TextStyle(
                        color: Color(0xFF1A3C8F),
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_urlOpened) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.success,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Payment portal opened. After paying, fill in the details below.',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Step 2: Transaction details ────────────────
            _StepCard(
              step: '2',
              title: 'Enter Payment Details',
              done: _txnCtrl.text.isNotEmpty && _dateCtrl.text.isNotEmpty,
              child: Column(
                children: [
                  TextField(
                    controller: _txnCtrl,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID *',
                      hintText: 'e.g. SBI123456789',
                      prefixIcon: Icon(Icons.receipt_long),
                      border: OutlineInputBorder(),
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
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateCtrl.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(picked);
                        });
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
            const SizedBox(height: 16),

            const SizedBox(height: 28),

            // ── Submit ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _submitting ? 'Submitting...' : 'Submit Payment Proof',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Your request will be reviewed after Technical Staff verifies the payment.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
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
          color: done
              ? AppTheme.success.withOpacity(0.5)
              : AppTheme.primary.withOpacity(0.2),
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
                      : Text(
                          step,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
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
