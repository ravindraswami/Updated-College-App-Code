import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../models/bonafide_model.dart';
import '../../utils/app_theme.dart';

/// Bonafide Certificate Screen
/// - Shows a rendered certificate with institute stamp + sign area
/// - Student can download as PDF (screenshot capture)
/// - Technical staff can approve from here
class BonafidePdfScreen extends StatefulWidget {
  final BonafideModel bonafide;
  final String approverName;
  const BonafidePdfScreen({
    super.key,
    required this.bonafide,
    required this.approverName,
  });
  @override
  State<BonafidePdfScreen> createState() => _BonafidePdfScreenState();
}

class _BonafidePdfScreenState extends State<BonafidePdfScreen> {
  final GlobalKey _certKey = GlobalKey();
  bool _capturing = false;

  Future<void> _captureAndDownload() async {
    setState(() => _capturing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final boundary =
          _certKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      // In real app: use path_provider + share_plus to save/share
      // For now: show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Certificate captured! In production, this saves as PDF to your device.',
          ),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not capture. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonafide Certificate'),
        actions: [
          TextButton.icon(
            onPressed: _capturing ? null : _captureAndDownload,
            icon: _capturing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'Download PDF',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Preview — Bonafide Certificate',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            // Certificate
            RepaintBoundary(
              key: _certKey,
              child: _CertificateWidget(
                bonafide: widget.bonafide,
                approverName: widget.approverName,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _capturing ? null : _captureAndDownload,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  'Download as PDF',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Certificate Widget (the actual certificate layout) ────────
class _CertificateWidget extends StatelessWidget {
  final BonafideModel bonafide;
  final String approverName;
  const _CertificateWidget({
    required this.bonafide,
    required this.approverName,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final b = bonafide;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
            ),
            child: Column(
              children: [
                // Institute logo placeholder
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/ic_launcher.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vasantrao Naik Marathwada Krishi Vidyapeeth, Parbhani              विलासराव देशमुख कृषी जैवतंत्रज्ञान महाविद्यालय, लातूर                       Vilasrao Deshmukh College of Agricultural Biotechnology, Latur LATUR – 413 512 (MS)',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                // const Text(
                //   'Affiliated to University | NAAC Accredited',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(fontSize: 11, color: Colors.grey),
                // ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BONAFIDE CERTIFICATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Certificate No + Date ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cert. No: BON/${DateTime.now().year}/${b.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  'Date: ${b.approvedDate.isNotEmpty ? b.approvedDate : today}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text(
                //   'To Whomsoever It May Concern,',
                //   style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                // ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black,
                      height: 1.8,
                    ),
                    children: [
                      const TextSpan(text: 'This is to certify that '),
                      TextSpan(
                        text: b.studentName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ', Registration No '),
                      TextSpan(
                        text: b.erpId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ', is/was a bonafide student of this college, currently enrolled in the ',
                      ),
                      TextSpan(
                        text: '${b.branch} program',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ', in '),
                      TextSpan(
                        text: '${b.year} Year, ${b.semester}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' (Agril. Biotechnology)/M.Sc(MBB) degree course during the year 2025-26 (Monsoon / Summer) session..',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black,
                      height: 1.8,
                    ),
                    children: [
                      const TextSpan(
                        text: 'This certificate is issued for the purpose of ',
                      ),
                      TextSpan(
                        text: b.purpose,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Place of Issue: Latur',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  'Date of Application: ${b.applyDate}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 28),

                // ── Signatures ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Stamp
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E3A5F),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF1E3A5F),
                                  size: 24,
                                ),
                                const Text(
                                  'OFFICIAL',
                                  style: TextStyle(
                                    fontSize: 7,
                                    color: Color(0xFF1E3A5F),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const Text(
                                  'STAMP',
                                  style: TextStyle(
                                    fontSize: 7,
                                    color: Color(0xFF1E3A5F),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Signature
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(width: 120, height: 1, color: Colors.black),
                        const SizedBox(height: 4),
                        Text(
                          approverName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'Associate Dean and Principal',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          today,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Note: This certificate is valid for 6 months from the date of issue. '
                    'It is issued on request and bears no responsibility of the institute '
                    'beyond certification of student enrollment.',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
