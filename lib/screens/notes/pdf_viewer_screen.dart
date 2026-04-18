
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../utils/app_theme.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;
  const PdfViewerScreen({super.key, required this.title, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: pdfUrl.isEmpty
          ? const Center(child: Text('PDF URL not available'))
          : SfPdfViewer.network(
              pdfUrl,
              onDocumentLoadFailed: (details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load PDF: ${details.description}'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              },
            ),
    );
  }
}
