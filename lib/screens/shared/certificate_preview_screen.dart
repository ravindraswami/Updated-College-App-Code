import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/image_export.dart';

/// Generic preview screen for every generated certificate / report in the
/// app (Bonafide, TC, Character Certificate, Registration receipt, etc.)
///
/// It shows the certificate as it will look, then lets the user either
/// SAVE it as an image to their phone's Gallery, or SHARE it as an image
/// (WhatsApp / Drive / etc.) — there is no PDF export and no print option
/// anywhere in this screen, by design.
class CertificatePreviewScreen extends StatefulWidget {
  final String title;
  final String fileName;
  final Widget certificate;

  const CertificatePreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.certificate,
  });

  @override
  State<CertificatePreviewScreen> createState() =>
      _CertificatePreviewScreenState();
}

class _CertificatePreviewScreenState extends State<CertificatePreviewScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;
  String? _busyLabel;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _busyLabel = 'Saving…';
    });
    final bytes = await ImageExportUtils.captureBoundary(_boundaryKey);
    GalSaveResult result = const GalSaveResult(false, 'Could not render the image.');
    if (bytes != null) {
      result = await ImageExportUtils.saveToGallery(bytes, widget.fileName);
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _busyLabel = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Saved to "Smart ERP" album in your gallery.'
                : (result.error ?? 'Could not save image. Please try again.'),
          ),
          backgroundColor: result.success ? AppTheme.success : AppTheme.error,
          duration: Duration(seconds: result.success ? 3 : 8),
        ),
      );
    }
  }

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _busyLabel = 'Preparing…';
    });
    final bytes = await ImageExportUtils.captureBoundary(_boundaryKey);
    bool ok = false;
    if (bytes != null) {
      ok = await ImageExportUtils.shareImage(
        bytes,
        widget.fileName,
        text: widget.title,
      );
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _busyLabel = null;
      });
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share image. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                // IMPORTANT: constrained defaults to true, which force-fits
                // the child into the visible viewport height — since every
                // certificate/report is taller than one screen, that was
                // squeezing the content and causing the
                // "BOTTOM OVERFLOWED BY n PIXELS" errors you saw.
                // constrained: false lets the content be its natural
                // (taller) size; the user pans/zooms to see all of it.
                constrained: false,
                minScale: 0.4,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(80),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: Material(
                      color: Colors.white,
                      elevation: 4,
                      child: widget.certificate,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Save Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 18),
                      label: Text(_busy ? (_busyLabel ?? '…') : 'Share Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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

/// Convenience navigation helper used across the app.
Future<void> openCertificatePreview(
  BuildContext context, {
  required String title,
  required String fileName,
  required Widget certificate,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CertificatePreviewScreen(
        title: title,
        fileName: fileName,
        certificate: certificate,
      ),
    ),
  );
}
