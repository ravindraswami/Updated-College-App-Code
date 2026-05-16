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

    // If CC has no class assigned yet, show message
    if (coordinator.classId.isEmpty) {
      return const EmptyWidget(
        message:
            'No class assigned to you yet.\n'
            'Ask your HOD to assign a class first.',
        icon: Icons.class_outlined,
      );
    }

    return StreamBuilder<List<ExamFormModel>>(
      // Use classId — same format in both student and CC profiles
      stream: svc.getPendingForCC(coordinator.classId),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snap.hasData) return const LoadingWidget();

        final forms = snap.data!;
        if (forms.isEmpty) {
          return EmptyWidget(
            message:
                'No exam forms pending your review for class:\n'
                '${coordinator.classId}\n\n'
                'Students from your class will appear here after they submit.',
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
                  const Icon(
                    Icons.edit_document,
                    color: AppTheme.primary,
                    size: 18,
                  ),
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
  const _CcFormCard({
    required this.form,
    required this.svc,
    required this.coordinator,
  });

  Future<void> _approve(BuildContext context) async {
    final remarksCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Exam Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Approving form for ${form.name}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${form.name}\'s exam form approved and sent to Technical Staff.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
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
            Text(
              'Rejecting form for ${form.name}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
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
      ctrl.text.trim().isNotEmpty
          ? ctrl.text.trim()
          : 'Rejected by Coordinator',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form rejected.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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
            // Student header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    form.name.isNotEmpty ? form.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: AppTheme.primary,
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
                        'PRN: ${form.prn}',
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
              Icons.event,
              'Exam Period',
              '${form.examMonth} (${form.examYear})',
            ),
            _row(
              Icons.menu_book_outlined,
              'Subjects',
              form.subjects.join(', '),
            ),
            if (form.hasBacklog && form.backlogSubjects.isNotEmpty)
              _row(
                Icons.warning_amber,
                'Backlog / ATKT',
                form.backlogSubjects.join(', '),
                color: AppTheme.warning,
              ),
            if (form.center.isNotEmpty)
              _row(Icons.location_on_outlined, 'Preferred Center', form.center),

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
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
        padding: const EdgeInsets.only(bottom: 5),
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
