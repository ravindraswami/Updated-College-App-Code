import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../services/exam_form_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../exam_form/registration_pdf.dart';

/// Education Section: verifies registration-fee payments (before the form
/// opens for students), and views every COMPLETED registration form,
/// grouped semester-by-semester, exactly as the Advisor sees it.
class RegistrationEducationScreen extends StatefulWidget {
  final String educationName;
  const RegistrationEducationScreen({super.key, required this.educationName});

  @override
  State<RegistrationEducationScreen> createState() => _RegistrationEducationScreenState();
}

class _RegistrationEducationScreenState extends State<RegistrationEducationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _svc = ExamFormService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Payment Verification'),
            Tab(text: 'Sem-wise Records'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              StreamBuilder<List<ExamFormModel>>(
                stream: _svc.getPendingPaymentVerification(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final forms = snap.data!;
                  if (forms.isEmpty) {
                    return const EmptyWidget(
                      message: 'No payments waiting for verification.',
                      icon: Icons.payments_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: forms.length,
                    itemBuilder: (ctx, i) => _PaymentCard(
                      form: forms[i],
                      educationName: widget.educationName,
                    ),
                  );
                },
              ),
              StreamBuilder<List<ExamFormModel>>(
                stream: _svc.getCompletedRegistrations(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final forms = snap.data!;
                  if (forms.isEmpty) {
                    return const EmptyWidget(
                      message: 'No completed registration forms yet.',
                      icon: Icons.table_chart_outlined,
                    );
                  }
                  final bySem = <String, List<ExamFormModel>>{};
                  for (final f in forms) {
                    final year = f.year.isNotEmpty ? f.year : 'Unspecified';
                    final sem = f.semester.isNotEmpty ? f.semester : 'Unspecified';
                    bySem.putIfAbsent('$year — $sem', () => []).add(f);
                  }
                  final sems = bySem.keys.toList()..sort();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: sems.map((sem) {
                      final list = bySem[sem]!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(sem,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                  Text('${list.length} students',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const Divider(),
                              ...list.take(5).map((f) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(f.name, style: const TextStyle(fontSize: 13)),
                                    subtitle: Text(
                                      'Advisor: ${f.advisorName}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.image_outlined, size: 20),
                                      onPressed: () => printStudentSubjectTable(context, f),
                                    ),
                                  )),
                              if (list.length > 5)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('+ ${list.length - 5} more...',
                                      style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                                ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => printClassSummaryTable(context, '$sem — All Students', list),
                                  icon: const Icon(Icons.image_outlined, size: 16),
                                  label: Text('Generate $sem Table'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatefulWidget {
  final ExamFormModel form;
  final String educationName;
  const _PaymentCard({required this.form, required this.educationName});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _busy = false;

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      await ExamFormService().educationVerifyPayment(widget.form.id, widget.educationName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verified. Form is now open for the student.'), backgroundColor: AppTheme.success),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(hintText: 'Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ExamFormService().educationRejectPayment(widget.form.id, reason);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.form;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${f.erpId} · ${f.branch} · ${f.year} / ${f.semester}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text('Fee Paid: ₹${f.registrationFee.toStringAsFixed(0)}   Txn: ${f.registrationPaymentId}',
                style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _reject,
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.error),
                    label: const Text('Reject', style: TextStyle(color: AppTheme.error)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _verify,
                    icon: _busy
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: const Text('Verify & Open Form'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
