import 'package:flutter/material.dart';
import '../../services/fee_config_service.dart';
import '../../utils/app_theme.dart';

/// Education Section screen to set the fee amount for Bonafide,
/// Character Certificate and Transfer Certificate applications.
/// Whatever is saved here is what every student sees and pays.
class FeeSettingsScreen extends StatefulWidget {
  const FeeSettingsScreen({super.key});

  @override
  State<FeeSettingsScreen> createState() => _FeeSettingsScreenState();
}

class _FeeSettingsScreenState extends State<FeeSettingsScreen> {
  final _feeSvc = FeeConfigService();
  final _bonafideCtrl = TextEditingController();
  final _characterCtrl = TextEditingController();
  final _tcCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fees = await _feeSvc.getFees();
    _bonafideCtrl.text = fees['bonafideFee']!.toStringAsFixed(0);
    _characterCtrl.text = fees['characterFee']!.toStringAsFixed(0);
    _tcCtrl.text = fees['tcFee']!.toStringAsFixed(0);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final bonafide = double.tryParse(_bonafideCtrl.text.trim());
    final character = double.tryParse(_characterCtrl.text.trim());
    final tc = double.tryParse(_tcCtrl.text.trim());
    if (bonafide == null || character == null || tc == null ||
        bonafide < 0 || character < 0 || tc < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid, non-negative fee amounts.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _feeSvc.setFees(
        bonafideFee: bonafide,
        characterFee: character,
        tcFee: tc,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fees updated. New applications will use these amounts.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _bonafideCtrl.dispose();
    _characterCtrl.dispose();
    _tcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Set the fee for each certificate type. Every student will '
                    'see and pay exactly this amount when they apply.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _FeeField(
            label: 'Bonafide Certificate Fee',
            icon: Icons.badge_outlined,
            controller: _bonafideCtrl,
          ),
          const SizedBox(height: 16),
          _FeeField(
            label: 'Character Certificate Fee',
            icon: Icons.workspace_premium_outlined,
            controller: _characterCtrl,
          ),
          const SizedBox(height: 16),
          _FeeField(
            label: 'Transfer Certificate (TC) Fee',
            icon: Icons.article_outlined,
            controller: _tcCtrl,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Fees'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  const _FeeField({
    required this.label,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
