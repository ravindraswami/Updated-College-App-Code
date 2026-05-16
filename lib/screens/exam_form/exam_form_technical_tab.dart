import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../models/user_model.dart';
import '../../services/exam_form_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Add this as a tab inside TechnicalDashboard
class ExamFormTechnicalTab extends StatelessWidget {
  final UserModel? technicalUser;
  const ExamFormTechnicalTab({super.key, required this.technicalUser});

  @override
  Widget build(BuildContext context) {
    final svc = ExamFormService();
    return StreamBuilder<List<ExamFormModel>>(
      stream: svc.getPendingForTechnical(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final forms = snap.data!;

        // Split into two lists: need fee added vs fee paid (ready for final approval)
        final needFee = forms
            .where((f) => f.status == 'pending_technical')
            .toList();
        final feePaid = forms.where((f) => f.status == 'fee_paid').toList();

        if (forms.isEmpty) {
          return const EmptyWidget(
            message: 'No exam forms pending.',
            icon: Icons.inbox_outlined,
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (feePaid.isNotEmpty) ...[
              _header(
                Icons.check_circle,
                AppTheme.success,
                '${feePaid.length} form(s) — Fee Paid — Ready to Approve',
              ),
              ...feePaid.map(
                (f) => _TechFormCard(
                  form: f,
                  svc: svc,
                  user: technicalUser,
                  isFeeStage: false,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (needFee.isNotEmpty) ...[
              _header(
                Icons.currency_rupee,
                AppTheme.warning,
                '${needFee.length} form(s) — Add Fee Amount',
              ),
              ...needFee.map(
                (f) => _TechFormCard(
                  form: f,
                  svc: svc,
                  user: technicalUser,
                  isFeeStage: true,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _header(IconData icon, Color color, String text) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TechFormCard extends StatelessWidget {
  final ExamFormModel form;
  final ExamFormService svc;
  final UserModel? user;
  final bool isFeeStage; // true = add fee, false = final approve

  const _TechFormCard({
    required this.form,
    required this.svc,
    required this.user,
    required this.isFeeStage,
  });

  Future<void> _addFeeDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: '1000');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Exam Fee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Setting fee for ${form.name}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fee Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Set Fee'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final amount = double.tryParse(ctrl.text.trim()) ?? 1000;
    await svc.addFee(form.id, amount);
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fee of ₹${amount.toStringAsFixed(0)} set for ${form.name}. Student will be notified to pay.',
          ),
          backgroundColor: AppTheme.warning,
        ),
      );
  }

  Future<void> _finalApprove(BuildContext context) async {
    final staffName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? 'Technical Staff';
    await svc.technicalApprove(form.id, staffName);
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${form.name}\'s exam form approved! Hall ticket is ready.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
  }

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Exam Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rejecting form for ${form.name}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.technicalReject(
      form.id,
      ctrl.text.trim().isNotEmpty
          ? ctrl.text.trim()
          : 'Rejected by Technical Staff',
    );
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form rejected.'),
          backgroundColor: AppTheme.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                  child: Text(
                    form.name.isNotEmpty ? form.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'PRN: ${form.prn}  •  ERP: ${form.erpId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${form.branch} ${form.year} — ${form.semester}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _row(
              Icons.menu_book_outlined,
              'Subjects',
              form.subjects.join(', '),
            ),
            _row(Icons.event, 'Exam', '${form.examMonth} (${form.examYear})'),
            if (form.hasBacklog && form.backlogSubjects.isNotEmpty)
              _row(
                Icons.warning_amber,
                'Backlog',
                form.backlogSubjects.join(', '),
                color: AppTheme.warning,
              ),
            if (form.ccRemarks.isNotEmpty)
              _row(
                Icons.comment_outlined,
                'CC Remarks',
                form.ccRemarks,
                color: Colors.teal,
              ),

            // Fee paid badge
            if (!isFeeStage) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fee Paid — ₹${form.feeAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => isFeeStage
                        ? _addFeeDialog(context)
                        : _finalApprove(context),
                    icon: Icon(
                      isFeeStage ? Icons.currency_rupee : Icons.check,
                      size: 16,
                    ),
                    label: Text(isFeeStage ? 'Set Fee' : 'Final Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFeeStage
                          ? AppTheme.warning
                          : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(color: color ?? Colors.grey, fontSize: 12),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
