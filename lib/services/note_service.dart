import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note_model.dart';

class NoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadNoteFromBytes({
    required String title,
    required String subject,
    required String uploadedBy,
    required PlatformFile platformFile,
    String classId = '', // empty = visible to all students
  }) async {
    final bytes = platformFile.bytes;
    if (bytes == null) {
      throw Exception('Could not read file. Please try again.');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';
    final ref = _storage.ref().child('notes/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    final url = await ref.getDownloadURL();

    await _db.collection('notes').add({
      'title': title,
      'subject': subject,
      'pdfUrl': url,
      'uploadedBy': uploadedBy,
      'uploadedAt': FieldValue.serverTimestamp(),
      'classId': classId,
    });
  }

  // All notes (for professors / Incharge / Principal)
  Stream<List<NoteModel>> getNotes() {
    return _db
        .collection('notes')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => NoteModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  // Notes for a specific class OR notes shared with all (classId == '')
  Stream<List<NoteModel>> getNotesForClass(String classId) {
    return _db
        .collection('notes')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) {
          return s.docs
              .map((d) => NoteModel.fromMap(d.data(), d.id))
              .where((n) => n.classId.isEmpty || n.classId == classId)
              .toList();
        });
  }

  Future<void> deleteNote(String noteId, String pdfUrl) async {
    await _db.collection('notes').doc(noteId).delete();
    try {
      await _storage.refFromURL(pdfUrl).delete();
    } catch (_) {}
  }
}
