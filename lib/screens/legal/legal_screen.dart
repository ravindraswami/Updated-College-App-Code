import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/legal_content.dart';

enum LegalType { privacyPolicy, termsAndConditions }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalType.privacyPolicy;
    final title = isPrivacy ? 'Privacy Policy' : 'Terms & Conditions';
    final content = isPrivacy
        ? LegalContent.privacyPolicy
        : LegalContent.termsAndConditions;

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: AppTheme.primary),
      body: Column(
        children: [
          // Header bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primary.withOpacity(0.07),
            child: Row(
              children: [
                Icon(
                  isPrivacy ? Icons.privacy_tip_outlined : Icons.gavel,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last Updated: ${LegalContent.lastUpdated}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
