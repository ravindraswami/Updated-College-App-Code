import 'package:flutter/material.dart';
import '../../services/note_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/class_constants.dart';
import '../../widgets/common_widgets.dart';
import 'pdf_viewer_screen.dart';

class NotesScreen extends StatelessWidget {
  // classId = '' means show all notes (for professors/Incharge/Principal)
  // classId = 'FY-A' means show only notes for FY-A + global notes
  final String classId;
  const NotesScreen({super.key, this.classId = ''});

  @override
  Widget build(BuildContext context) {
    final stream = classId.isNotEmpty
        ? NoteService().getNotesForClass(classId)
        : NoteService().getNotes();

    return StreamBuilder(
      stream: stream,
      builder: (ctx, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final notes = snap.data!;
        if (notes.isEmpty) {
          return EmptyWidget(
            message: classId.isNotEmpty
                ? 'No study materials uploaded for ${ClassConstants.shortLabel(classId)} yet.'
                : 'No study materials available.',
            icon: Icons.book_outlined,
          );
        }
        return Column(
          children: [
            if (classId.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppTheme.primary.withOpacity(0.06),
                child: Row(
                  children: [
                    const Icon(Icons.book, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${notes.length} material(s) for ${ClassConstants.shortLabel(classId)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (_, i) {
                  final note = notes[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: AppTheme.error,
                        ),
                      ),
                      title: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.subject,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (note.classId.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ClassConstants.shortLabel(note.classId),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'All Classes',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const Icon(
                        Icons.open_in_new,
                        color: AppTheme.primary,
                      ),
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            title: note.title,
                            pdfUrl: note.pdfUrl,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
