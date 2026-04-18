import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/legal_content.dart';
import 'legal_screen.dart';

/// Returns true if user agreed, false/null if dismissed
Future<bool?> showRegisterAgreementDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _RegisterAgreementDialog(),
  );
}

class _RegisterAgreementDialog extends StatefulWidget {
  const _RegisterAgreementDialog();
  @override
  State<_RegisterAgreementDialog> createState() =>
      _RegisterAgreementDialogState();
}

class _RegisterAgreementDialogState extends State<_RegisterAgreementDialog> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _agreedToAge = false;

  bool get _canProceed => _agreedToTerms && _agreedToPrivacy && _agreedToAge;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_user, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Create Account Agreement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please read and accept before continuing',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Agreement summary
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        LegalContent.registrationAgreement,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checkboxes
                    _CheckItem(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v!),
                      label: 'I have read and agree to the ',
                      linkText: 'Terms & Conditions',
                      onLinkTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            type: LegalType.termsAndConditions,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CheckItem(
                      value: _agreedToPrivacy,
                      onChanged: (v) => setState(() => _agreedToPrivacy = v!),
                      label: 'I have read and agree to the ',
                      linkText: 'Privacy Policy',
                      onLinkTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LegalScreen(type: LegalType.privacyPolicy),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CheckItem(
                      value: _agreedToAge,
                      onChanged: (v) => setState(() => _agreedToAge = v!),
                      label: 'I confirm that I am at least 16 years of age',
                      linkText: '',
                      onLinkTap: null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canProceed
                          ? () => Navigator.pop(context, true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text('I Agree & Register'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String linkText;
  final VoidCallback? onLinkTap;

  const _CheckItem({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: label),
                  if (linkText.isNotEmpty)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onLinkTap,
                        child: Text(
                          linkText,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
