// image_export.dart
//
// Shared helper used by every certificate / report screen in the app.
// Captures a widget (wrapped in a RepaintBoundary) as a PNG image and
// either saves it to the phone's Gallery/Photos, or shares it as an
// image file. There is intentionally NO pdf/print option anywhere here —
// PDF generation and printing have been removed from the app per the
// updated requirement: certificates & reports are now delivered only as
// images (save to gallery / share as image).
//
// Requires these packages in pubspec.yaml:
//   gal: ^2.3.0
//   share_plus: ^10.0.0
//   path_provider: ^2.1.0
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class GalSaveResult {
  final bool success;
  final String? error;
  const GalSaveResult(this.success, this.error);
}

/// Album every certificate/report image is saved into — makes it easy to
/// find them as one group in Photos/Gallery instead of mixed in with
/// camera photos.
const String kSaveAlbum = 'Smart ERP';

class ImageExportUtils {
  ImageExportUtils._();

  /// Renders whatever is wrapped by [key]'s RepaintBoundary into PNG bytes.
  /// Use a higher [pixelRatio] for crisper, print-quality-looking images.
  static Future<Uint8List?> captureBoundary(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // Let one frame settle before capturing (avoids blank captures).
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 60));
      }
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static String _safeName(String name) =>
      name.trim().replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_');

  /// Saves PNG bytes straight to the device Gallery / Photos app, into a
  /// dedicated "Smart ERP" album.
  ///
  /// IMPORTANT — this can only actually write to storage if ALL of these
  /// are true in the native project (this Flutter code can't fix these
  /// three by itself, they're outside the `lib/` folder):
  ///   1. `gal: ^2.3.0` is listed in pubspec.yaml under dependencies, and
  ///      you've run `flutter pub get` + a full rebuild (hot reload is
  ///      NOT enough after adding a new native plugin).
  ///   2. Android: `android/app/src/main/AndroidManifest.xml` has
  ///        <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
  ///          android:maxSdkVersion="28" />
  ///      (only needed for Android 9 and below; harmless to add anyway).
  ///   3. iOS: `ios/Runner/Info.plist` has
  ///        <key>NSPhotoLibraryAddUsageDescription</key>
  ///        <string>Needed to save certificates and reports to your Photos.</string>
  ///
  /// If any of those are missing, saving fails SILENTLY on some devices
  /// (no crash, no obvious error) — that's almost certainly why you were
  /// seeing a "saved" message with no file actually appearing. This
  /// method now returns the REAL underlying error instead of swallowing
  /// it, so the SnackBar tells you exactly what's wrong.
  static Future<GalSaveResult> saveToGallery(
      Uint8List bytes, String fileName) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          return const GalSaveResult(
            false,
            'Photo/storage permission was not granted. Please allow it '
            'from phone Settings → Apps → this app → Permissions → '
            'Photos/Storage, then try again.',
          );
        }
      }
      await Gal.putImageBytes(
        bytes,
        name: _safeName(fileName),
        album: kSaveAlbum,
      );
      // Re-check access as a sanity confirmation the write path is live.
      final stillHasAccess = await Gal.hasAccess(toAlbum: true);
      if (!stillHasAccess) {
        return const GalSaveResult(
          false,
          'Storage access was lost right after saving — check app '
          'permissions in phone Settings.',
        );
      }
      return const GalSaveResult(true, null);
    } on GalException catch (e) {
      return GalSaveResult(false, e.type.message);
    } catch (e) {
      // Most common real cause here: the `gal` plugin isn't actually
      // wired up yet (missing from pubspec.yaml, or app wasn't fully
      // rebuilt after adding it) — this shows up as
      // "MissingPluginException".
      final msg = e.toString();
      if (msg.contains('MissingPluginException')) {
        return const GalSaveResult(
          false,
          'The "gal" plugin isn\'t active in this build. Add gal to '
          'pubspec.yaml, run flutter pub get, then fully rebuild the app '
          '(stop and restart, not hot reload).',
        );
      }
      return GalSaveResult(false, msg);
    }
  }

  /// Shares the PNG as an image file (share sheet → WhatsApp, Drive, etc.)
  static Future<bool> shareImage(
    Uint8List bytes,
    String fileName, {
    String? text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_safeName(fileName)}.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')],
          text: text);
      return true;
    } catch (_) {
      return false;
    }
  }
}
