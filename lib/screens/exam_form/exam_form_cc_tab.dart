import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../models/user_model.dart';
import '../../services/exam_form_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ExamFormCcTab extends StatelessWidget {
  final UserModel coordinator;
  const ExamFormCcTab({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final svc = ExamFormService();

    if (coordinator.classId.isEmpty) {
      return const EmptyWidget(
        message: 'No class assigned to you yet.\nAsk your Incharge to assign a class first.',
        icon: Icons.class_outlined,
      );
    }

    return StreamBuilder<List<ExamFormModel>>(
      stream: svc.getPendingForCC(coordinator.classId),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
        if (!snap.hasData) return const LoadingWidget();

        final forms = snap.data!;
        if (forms.isEmpty) {
          return EmptyWidget(
            message: 'No exam forms pending your review for class:\n${coordinator.classId}\n\nStudents from your class will appear here after they submit.',
            icon: Icons.inbox_outlined,
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primary.withOpacity(0.06),
              child: Row(
                children: [
                  const Icon(Icons.edit_document, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${forms.length} exam form(s) pending — ${coordinator.classId}',
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
                itemBuilder: (_, i) => _CcFormCard(
                  form: forms[i],
                  svc: svc,
                  coordinator: coordinator,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CcFormCard extends StatelessWidget {
  final ExamFormModel form;
  final ExamFormService svc;
  final UserModel coordinator;
  const _CcFormCard({required this.form, required this.svc, required this.coordinator});

  Future<void> _approve(BuildContext context) async {
    final remarksCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Exam Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approving form for ${form.name}.',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
                hintText: 'e.g. Documents verified...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.ccApprove(
      form.id,
      coordinator.name.isNotEmpty ? coordinator.name : coordinator.erpId,
      remarks: remarksCtrl.text.trim(),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${form.name}\'s exam form approved and sent to Technical Staff.'),
        backgroundColor: AppTheme.success,
      ));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                labelText: 'Reason for Rejection *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await svc.ccReject(
      form.id,
      ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'Rejected by Coordinator',
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
    // Calculate total fee from stored per-subject fees
    final totalRegular = form.totalRegularFee;
    final totalBacklog = form.totalBacklogFee;
    final grandTotal = form.calculatedTotalFee;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    form.name.isNotEmpty ? form.name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      Text('PRN: ${form.prn}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${form.branch} ${form.year} — ${form.semester}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Regular Subjects list ──────────────────────────
            if (form.subjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 14, color: AppTheme.primary),
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
                      final subName = e.value;
                      // Get fee if stored (by index using subjectIds)
                      double? fee;
                      if (idx < form.subjectIds.length) {
                        fee = form.subjectRegularFees[form.subjectIds[idx]];
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Expanded(
                              child: Text(subName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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

            // ── Backlog Subjects list ──────────────────────────
            if (form.hasBacklog && form.backlogSubjects.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 14, color: AppTheme.warning),
                        const SizedBox(width: 6),
                        const Text('Backlog / ATKT Subjects',
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
                      final subName = e.value;
                      double? fee;
                      if (idx < form.backlogSubjectIds.length) {
                        fee = form.subjectBacklogFees[form.backlogSubjectIds[idx]];
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.warning, fontSize: 12)),
                            Expanded(
                              child: Text(subName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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

            // ── Fee summary ───────────────────────────────────
            if (grandTotal > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee, color: Colors.teal, size: 14),
                    const SizedBox(width: 4),
                    const Text('Total Estimated Fee: ',
                        style: TextStyle(fontSize: 12, color: Colors.teal)),
                    Text('₹${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.teal)),
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
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
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

  Widget _row(IconData icon, String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: color ?? Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
