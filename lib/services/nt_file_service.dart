import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/nt_file_model.dart';

class NtFileService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _col = 'nt_files';

  /// Upload file — only non-technical staff can call this
  Future<void> uploadFile({
    required String uploadedBy,
    required String uploaderName,
    required String uploaderErpId,
    required String title,
    required String description,
    required PlatformFile file,
  }) async {
    final bytes = file.bytes;
    if (bytes == null)
      throw Exception('Could not read file. Please try again.');

    final ext = file.name.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('nt_files/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: _mimeType(ext)));
    final url = await ref.getDownloadURL();

    await _db
        .collection(_col)
        .add(
          NtFileModel(
            id: '',
            uploadedBy: uploadedBy,
            uploaderName: uploaderName,
            uploaderErpId: uploaderErpId,
            title: title,
            description: description,
            fileUrl: url,
            fileName: file.name,
            fileType: ext,
            uploadedAt: DateTime.now(),
          ).toMap()..addAll({'uploadedAt': FieldValue.serverTimestamp()}),
        );
  }

  /// Get all NT files — for Principal only
  Stream<List<NtFileModel>> getAllFiles() {
    return _db
        .collection(_col)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => NtFileModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Get files uploaded by a specific NT staff member
  Stream<List<NtFileModel>> getMyFiles(String staffId) {
    return _db
        .collection(_col)
        .where('uploadedBy', isEqualTo: staffId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => NtFileModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<void> deleteFile(String fileId, String fileUrl) async {
    await _db.collection(_col).doc(fileId).delete();
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (_) {}
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
}
