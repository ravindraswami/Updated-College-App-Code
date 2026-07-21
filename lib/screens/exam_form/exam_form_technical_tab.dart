import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../models/user_model.dart';
import '../../services/exam_form_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Exam Form tab inside TechnicalDashboard
/// Fee is already set when Professor adds the subject (regularFee / backlogFee)
/// Technical staff can see the fee breakdown and Approve or Reject — no fee editing here.
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

        if (forms.isEmpty) {
          return const EmptyWidget(
            message: 'No exam forms pending.',
            icon: Icons.inbox_outlined,
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F766E).withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.edit_document,
                      color: Color(0xFF0F766E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${forms.length} exam form(s) pending review',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: forms.length,
                itemBuilder: (_, i) => _TechFormCard(
                  form: forms[i],
                  svc: svc,
                  user: technicalUser,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TechFormCard extends StatelessWidget {
  final ExamFormModel form;
  final ExamFormService svc;
  final UserModel? user;

  const _TechFormCard({required this.form, required this.svc, required this.user});

  Future<void> _approve(BuildContext context) async {
    final staffName = user?.name.isNotEmpty == true
        ? user!.name
        : user?.nameAsPerHsc ?? 'Education Section';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Exam Form'),
        content: Text(
          'Approve exam form for ${form.name}?\n\nTotal Fee: ₹${(form.calculatedTotalFee > 0 ? form.calculatedTotalFee : form.feeAmount).toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.technicalApprove(form.id, staffName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${form.name}\'s exam form approved!'),
        backgroundColor: AppTheme.success,
      ));
    }
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
            Text('Rejecting form for ${form.name}.',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Reason *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
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
      ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'Rejected by Technical Staff',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Form rejected.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRegular = form.totalRegularFee;
    final totalBacklog = form.totalBacklogFee;
    final grandTotal = form.calculatedTotalFee > 0
        ? form.calculatedTotalFee
        : form.feeAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                  child: Text(
                    form.name.isNotEmpty ? form.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                        color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      Text('PRN: ${form.prn}  •  ERP: ${form.erpId}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${form.branch} ${form.year} — ${form.semester}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Regular Subjects ───────────────────────────────
            if (form.subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        const Text('Regular Subjects',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppTheme.primary)),
                        const Spacer(),
                        if (totalRegular > 0)
                          Text('₹${totalRegular.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...form.subjects.asMap().entries.map((e) {
                      final idx = e.key;
                      final name = e.value;
                      double? fee;
                      if (idx < form.subjectIds.length) {
                        fee = form.subjectRegularFees[form.subjectIds[idx]];
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: AppTheme.primary, fontSize: 12)),
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (fee != null && fee > 0)
                              Text('₹${fee.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // ── Backlog Subjects ───────────────────────────────
            if (form.hasBacklog && form.backlogSubjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.warning.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            size: 14, color: AppTheme.warning),
                        const SizedBox(width: 6),
                        const Text('Backlog / ATKT',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppTheme.warning)),
                        const Spacer(),
                        if (totalBacklog > 0)
                          Text('₹${totalBacklog.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.warning)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...form.backlogSubjects.asMap().entries.map((e) {
                      final idx = e.key;
                      final name = e.value;
                      double? fee;
                      if (idx < form.backlogSubjectIds.length) {
                        fee = form.subjectBacklogFees[
                            form.backlogSubjectIds[idx]];
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: AppTheme.warning, fontSize: 12)),
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (fee != null && fee > 0)
                              Text('₹${fee.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // ── Fee summary ────────────────────────────────────
            if (grandTotal > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        color: Colors.teal, size: 16),
                    const SizedBox(width: 6),
                    const Text('Total Exam Fee: ',
                        style: TextStyle(fontSize: 12, color: Colors.teal)),
                    Text(
                      '₹${grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.teal),
                    ),
                    if (totalRegular > 0 && totalBacklog > 0) ...[
                      const Spacer(),
                      Text(
                        'Reg: ₹${totalRegular.toStringAsFixed(0)}  +  BL: ₹${totalBacklog.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (form.ccRemarks.isNotEmpty) ...[
              const SizedBox(height: 6),
              _row(Icons.comment_outlined, 'CC Remarks', form.ccRemarks,
                  color: Colors.teal),
            ],

            // ── Fee paid badge ─────────────────────────────────
            if (form.status == 'fee_paid') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.success, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Fee Paid — ₹${form.feeAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            // ── Actions ────────────────────────────────────────
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
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success),
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
            Text('$label: ',
                style:
                    TextStyle(color: color ?? Colors.grey, fontSize: 12)),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
