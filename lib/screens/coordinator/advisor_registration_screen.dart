import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../models/user_model.dart';
import '../../services/exam_form_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../exam_form/registration_pdf.dart';

/// Advisor: final sign-off on each student's Registration Form (once every
/// assigned Course Teacher has signed), plus a class-wide summary table.
class AdvisorRegistrationScreen extends StatefulWidget {
  final UserModel coordinator;
  const AdvisorRegistrationScreen({super.key, required this.coordinator});

  @override
  State<AdvisorRegistrationScreen> createState() => _AdvisorRegistrationScreenState();
}

class _AdvisorRegistrationScreenState extends State<AdvisorRegistrationScreen>
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
    final advisorId = widget.coordinator.id;
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Class Summary'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              StreamBuilder<List<ExamFormModel>>(
                stream: _svc.getPendingForAdvisor(advisorId),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final forms = snap.data!;
                  if (forms.isEmpty) {
                    return const EmptyWidget(
                      message: 'No registration forms pending your approval.',
                      icon: Icons.verified_outlined,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: forms.length,
                    itemBuilder: (ctx, i) => _PendingCard(
                      form: forms[i],
                      advisorName: widget.coordinator.name,
                    ),
                  );
                },
              ),
              StreamBuilder<List<ExamFormModel>>(
                stream: _svc.getRegistrationsForClass(advisorId),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LoadingWidget();
                  final forms = snap.data!;
                  if (forms.isEmpty) {
                    return const EmptyWidget(
                      message: 'No registration forms yet for your class.',
                      icon: Icons.table_chart_outlined,
                    );
                  }
                  final grouped = <String, List<ExamFormModel>>{};
                  for (final f in forms) {
                    final key = '${f.year.isNotEmpty ? f.year : 'Unspecified'} — ${f.semester.isNotEmpty ? f.semester : 'Unspecified'}';
                    grouped.putIfAbsent(key, () => []).add(f);
                  }
                  final groupKeys = grouped.keys.toList()..sort();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: groupKeys.map((key) {
                      final list = grouped[key]!;
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
                                    child: Text(key,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ),
                                  Text('${list.length} students',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const Divider(),
                              ...list.map((f) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(f.name, style: const TextStyle(fontSize: 13)),
                                    subtitle: Text(
                                      ExamFormModel.statusLabel(f.status),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.image_outlined, size: 20),
                                      onPressed: () => printStudentSubjectTable(context, f),
                                    ),
                                  )),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => printClassSummaryTable(
                                    context,
                                    'Class Registration Summary — $key',
                                    list,
                                  ),
                                  icon: const Icon(Icons.image_outlined, size: 16),
                                  label: Text('Generate $key Table'),
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

class _PendingCard extends StatefulWidget {
  final ExamFormModel form;
  final String advisorName;
  const _PendingCard({required this.form, required this.advisorName});

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  String _signature = 'RR';
  bool _approving = false;

  Future<void> _approve() async {
    setState(() => _approving = true);
    try {
      await ExamFormService().advisorApproveForm(
        widget.form.id,
        widget.advisorName,
        signature: _signature,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved.'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _approving = false);
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
            Text('${f.erpId} · ${f.year} / ${f.semester}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              'Regular: ${f.subjectIds.length} subjects (${f.totalCreditSum.toStringAsFixed(1)} cr)   '
              'Backlog: ${f.backlogSubjectIds.length} subjects (${f.totalBacklogCreditSum.toStringAsFixed(1)} cr)',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Signature:', style: TextStyle(fontSize: 12.5)),
                const SizedBox(width: 8),
                ...['RR', 'OFE', 'NR'].map((opt) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(opt),
                        selected: _signature == opt,
                        onSelected: (_) => setState(() => _signature = opt),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => printStudentSubjectTable(context, f),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View / Print'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approving ? null : _approve,
                    icon: _approving
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
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
}
