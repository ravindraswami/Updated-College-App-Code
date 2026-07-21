import 'package:cloud_firestore/cloud_firestore.dart';

/// Central certificate-fee configuration.
///
/// The Education Section (technical role) sets these amounts once from
/// [FeeSettingsScreen]; every student's Bonafide / Character Certificate /
/// Transfer Certificate application picks up whatever is currently set
/// here, instead of a hardcoded amount.
class FeeConfigService {
  final _db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> get _docRef =>
      _db.collection('settings').doc('certificate_fees');

  static const double defaultBonafideFee = 50.0;
  static const double defaultCharacterFee = 50.0;
  static const double defaultTcFee = 100.0;

  Map<String, double> _fromDoc(Map<String, dynamic>? data) {
    final d = data ?? {};
    return {
      'bonafideFee': (d['bonafideFee'] ?? defaultBonafideFee).toDouble(),
      'characterFee': (d['characterFee'] ?? defaultCharacterFee).toDouble(),
      'tcFee': (d['tcFee'] ?? defaultTcFee).toDouble(),
    };
  }

  /// One-time read — used by student apply screens before they submit.
  Future<Map<String, double>> getFees() async {
    try {
      final doc = await _docRef.get();
      return _fromDoc(doc.data());
    } catch (_) {
      return _fromDoc(null);
    }
  }

  /// Live stream — used by the Education Section settings screen.
  Stream<Map<String, double>> watchFees() {
    return _docRef.snapshots().map((doc) => _fromDoc(doc.data()));
  }

  Future<void> setFees({
    required double bonafideFee,
    required double characterFee,
    required double tcFee,
  }) async {
    await _docRef.set({
      'bonafideFee': bonafideFee,
      'characterFee': characterFee,
      'tcFee': tcFee,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
