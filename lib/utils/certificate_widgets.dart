// certificate_widgets.dart
//
// These used to be `pdf` package (pw.*) widgets rendered into a PDF
// document and printed/shared via the `printing` package. That whole
// PDF/printing pipeline has been removed from the app. Certificates are
// now built as plain Flutter widgets, rendered on-screen, then captured
// as a PNG image (see screens/shared/certificate_preview_screen.dart +
// utils/image_export.dart) so they can only be Saved to Gallery or
// Shared as an image — never as a PDF, never printed.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bonafide_model.dart';
import '../models/tc_model.dart';
import '../models/character_cert_model.dart';

const double kCertWidth = 800;

const String _kMar1 = 'वसंतराव नाईक मराठवाडा कृषी विद्यापीठ, परभणी.';
const String _kEn1 = 'VASANTRAO NAIK MARATHWADA KRISHI VIDYAPEETH, PARBHANI';
const String _kMar2 = 'विलासराव देशमुख कृषी जैवतंत्रज्ञान महाविद्यालय, लातूर';
const String _kEn2 =
    'VILASRAO DESHMUKH COLLEGE OF AGRICULTURAL BIOTECHNOLOGY, LATUR  PIN: 413 512';
const String _kEmail = 'E-mail: coablatur@rediffmail.com';
const String _kSignatory = 'Associate Dean and Principal\nVDCOAB, Latur';
const String _kWatermark = 'VDCOAB LATUR';

// Matches the reference printed-form look you shared: warm off-white
// paper (not stark white) + the certificate/serial number printed in red,
// same as the "998 / 999" red Sr.No. on the sample TC.
const Color kPaperColor = Color(0xFFFFFEFA);
const Color kCertNoColor = Color(0xFFC81E1E);

// Heading line colours — Vasantrao Naik University line in green,
// Vilasrao Deshmukh College line in red.
const Color kNaikLineColor = Color(0xFF1B7A3D);
const Color kDeshmukhLineColor = Color(0xFFC81E1E);

// Title box ("BONAFIDE CERTIFICATE" / "TRANSFER CERTIFICATE" / etc.) —
// green filled box, white text.
const Color kTitleBoxColor = Color(0xFF1B7A3D);

/// Auto-generates a certificate serial number from the Firestore document
/// id, so every certificate gets a stable, unique number with NO manual
/// typing anywhere. This is a placeholder numbering scheme — this is the
/// one function to edit later to change the format app-wide (e.g. to a
/// real office register number).
String buildAutoCertNo(String docId, {String prefix = ''}) {
  final n = (docId.hashCode.abs() % 9000) + 1000; // stable 4-digit number
  return prefix.isEmpty ? '$n' : '$prefix/$n';
}

TextStyle _dev({double size = 11, bool bold = false, Color color = Colors.black}) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
      height: 1.4,
    );

TextStyle _eng({double size = 10, bool bold = false, Color color = Colors.black}) =>
    TextStyle(
      fontFamily: 'Roboto',
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );

// ── Diagonal text watermark (drawn once behind the whole certificate) ──
Widget _watermark() => IgnorePointer(
      child: Opacity(
        opacity: 0.08,
        child: Transform.rotate(
          angle: -0.5, // ~ -28 degrees, diagonal like the old PDF watermark
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 40,
            spacing: 40,
            children: List.generate(
              18,
              (_) => Text(
                _kWatermark,
                style: _eng(size: 26, bold: true, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );

Widget _rule() => Container(height: 1.2, color: Colors.black, margin: const EdgeInsets.symmetric(vertical: 4));

/// Path to the college seal/logo shown at the top of every certificate
/// and report. Put the actual logo PNG at this exact path in the Flutter
/// project (create the folders if they don't exist yet):
///
///   assets/images/college_logo.png
///
/// ...and declare it in pubspec.yaml under:
///
///   flutter:
///     assets:
///       - assets/images/
///
/// Until the real file is added, a plain placeholder circle is shown
/// instead so the app doesn't crash — once you drop the PNG in, it will
/// show up automatically everywhere, no code changes needed.
const String kCollegeLogoAsset = 'assets/images/college_logo.png';

Widget _collegeLogo({double size = 64}) => ClipOval(
      child: Image.asset(
        kCollegeLogoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Icon(Icons.school, color: Colors.grey.shade500, size: size * 0.5),
        ),
      ),
    );

/// Shared identity block — college name (Marathi + English), address line,
/// e-mail — used at the top of EVERY generated certificate and EVERY
/// generated report so the letterhead looks identical everywhere in the
/// app (per user requirement: "same college header on all reports too,
/// not just certificates").
Widget buildLetterheadBlock({bool withRule = true}) => Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _collegeLogo(),
        const SizedBox(height: 6),
        Text(_kMar1, style: _dev(size: 15, bold: true, color: kNaikLineColor), textAlign: TextAlign.center),
        Text(_kEn1, style: _eng(size: 10, bold: true, color: kNaikLineColor), textAlign: TextAlign.center),
        const SizedBox(height: 3),
        Text(_kMar2, style: _dev(size: 17, bold: true, color: kDeshmukhLineColor), textAlign: TextAlign.center),
        Text(_kEn2, style: _eng(size: 9.5, bold: true, color: kDeshmukhLineColor), textAlign: TextAlign.center),
        Text(_kEmail, style: _eng(size: 10, color: Colors.black), textAlign: TextAlign.center),
        if (withRule) ...[
          const SizedBox(height: 6),
          _rule(),
        ],
      ],
    );

/// Same diagonal watermark used behind every certificate — exposed so
/// reports can use it too and everything looks visually consistent.
Widget buildWatermark() => _watermark();

/// Generic page wrapper (white sheet + watermark) for REPORTS (registration
/// tables, monthly reports, history reports, receipts). Mirrors `_frame`
/// (used for certificates) so both share the exact same look.
Widget reportSheet({required Widget child, double width = 850}) => Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
      color: kPaperColor,
      child: Stack(
        children: [
          Positioned.fill(child: _watermark()),
          child,
        ],
      ),
    );

/// [noValue] is normally the output of buildAutoCertNo(...) — shown in
/// red, exactly like the printed Sr.No./No. on the reference form.
/// The label itself ("Cr.No.") stays black.
Widget _collegeHeader({String noLabel = 'Cr.No.', String? noValue}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      buildLetterheadBlock(),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: _eng(size: 11, color: Colors.black),
              children: [
                TextSpan(text: '$noLabel  '),
                TextSpan(
                  text: noValue ?? '',
                  style: _eng(size: 13, bold: true, color: kCertNoColor),
                ),
              ],
            ),
          ),
          Text('Date:   /   /', style: _eng(size: 11, color: Colors.black)),
        ],
      ),
      const SizedBox(height: 10),
    ],
  );
}

Widget _titleBox(String title) => Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: kTitleBoxColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          style: _eng(size: 17, bold: true, color: Colors.white),
        ),
      ),
    );

Widget _signatureBlock() => Align(
      alignment: Alignment.centerRight,
      child: Text(_kSignatory, style: _eng(size: 12, bold: true), textAlign: TextAlign.right),
    );

Widget _tcRow(int n, String label, String value, {String? subLabel, String? regNo}) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 26, child: Text('$n.', style: _eng(size: 11))),
          Expanded(
            flex: 5,
            child: subLabel != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: _eng(size: 11)),
                      Text(subLabel, style: _eng(size: 10, color: Colors.grey.shade700)),
                    ],
                  )
                : Text(label, style: _eng(size: 11)),
          ),
          Text(' : ', style: _eng(size: 11)),
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(value, style: _eng(size: 11))),
                if (regNo != null) ...[
                  const SizedBox(width: 8),
                  Text('Reg. No. : $regNo', style: _eng(size: 10, bold: true)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

Widget _twoLineRow(int n, List<String> labelLines, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 26, child: Text('$n.', style: _eng(size: 11))),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: labelLines.map((l) => Text(l, style: _eng(size: 11))).toList(),
            ),
          ),
          Text(' : ', style: _eng(size: 11)),
          Expanded(flex: 5, child: Text(value, style: _eng(size: 11))),
        ],
      ),
    );

Widget _frame({required Widget child}) => Container(
      width: kCertWidth,
      padding: const EdgeInsets.fromLTRB(56, 44, 56, 44),
      color: kPaperColor,
      child: Stack(
        children: [
          Positioned.fill(child: _watermark()),
          child,
        ],
      ),
    );

// ══════════════════════════════════════════════════════════════
// 1. BONAFIDE CERTIFICATE
// ══════════════════════════════════════════════════════════════

/// Fallback "YYYY-YY" academic year string, used only when a request was
/// created before the academicYear field existed (Req #5).
String _fallbackAcademicYear() {
  final today = DateTime.now();
  return '${today.year - 1}-${(today.year % 100).toString().padLeft(2, '0')}';
}

Widget buildBonafideCertificate(BonafideModel b) {
  final acYear = b.academicYear.isNotEmpty ? b.academicYear : _fallbackAcademicYear();

  return _frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _collegeHeader(noLabel: 'Cr.No.', noValue: buildAutoCertNo(b.id, prefix: 'BC')),
        const SizedBox(height: 16),
        _titleBox('BONAFIDE CERTIFICATE'),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            style: _dev(size: 12),
            children: [
              const TextSpan(text: '\t\tThis is to certify that Shri./Kum. '),
              TextSpan(text: b.studentName, style: _dev(size: 12, bold: true)),
              const TextSpan(text: ', Registration No. '),
              TextSpan(text: b.erpId, style: _dev(size: 12, bold: true)),
              const TextSpan(text: ' is / was a Bonafide student of this college for '),
              TextSpan(text: 'B.Tech.', style: _eng(size: 12, bold: true)),
              const TextSpan(text: '(Biotechnology)/ '),
              TextSpan(text: 'M.Sc. Agri.', style: _eng(size: 12, bold: true)),
              const TextSpan(
                text: ' (Molecular Biology and Biotechnology) degree Programme during the academic year ',
              ),
              TextSpan(text: acYear, style: _eng(size: 12, bold: true)),
              const TextSpan(text: ' (Monsoon / Summer) session.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('\t\tHence certified.', style: _dev(size: 12)),
        const SizedBox(height: 30),
        Text('Place: Latur', style: _eng(size: 11, bold: true)),
        const SizedBox(height: 4),
        Text('Date:     /     /', style: _eng(size: 11, bold: true)),
        const SizedBox(height: 56),
        _signatureBlock(),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 2. CHARACTER CERTIFICATE
// ══════════════════════════════════════════════════════════════
Widget buildCharacterCertCertificate(CharacterCertModel c) {
  final acYear = c.academicYear.isNotEmpty ? c.academicYear : _fallbackAcademicYear();

  return _frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _collegeHeader(noLabel: 'Cr.No.', noValue: buildAutoCertNo(c.id, prefix: 'CC')),
        const SizedBox(height: 16),
        _titleBox('CHARACTER CERTIFICATE'),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            style: _dev(size: 12),
            children: [
              const TextSpan(text: '\t\tThis is to certify that Shri./Kum. '),
              TextSpan(text: c.studentName, style: _dev(size: 12, bold: true)),
              const TextSpan(text: ', Registration No. '),
              TextSpan(text: c.erpId, style: _dev(size: 12, bold: true)),
              const TextSpan(text: ' is/was a student of '),
              TextSpan(text: 'B.Tech.', style: _eng(size: 12, bold: true)),
              const TextSpan(text: '(Biotechnology)/ '),
              TextSpan(text: 'M.Sc. Agri.', style: _eng(size: 12, bold: true)),
              const TextSpan(
                text: ' (Molecular Biology and Biotechnology) this college during the Year ',
              ),
              TextSpan(text: acYear, style: _eng(size: 12, bold: true)),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '\t\tTo the best of my knowledge, He / She bears a good moral character.',
          style: _dev(size: 12),
        ),
        const SizedBox(height: 30),
        Text('Date:     /     /', style: _eng(size: 11, bold: true)),
        const SizedBox(height: 4),
        Text('Place: Latur', style: _eng(size: 11, bold: true)),
        const SizedBox(height: 56),
        _signatureBlock(),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// 3. TRANSFER CERTIFICATE (Original + Duplicate, both in one image)
// ══════════════════════════════════════════════════════════════
Widget _tcCopy(TcModel tc, String copyLabel) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _collegeHeader(noLabel: 'Cr.No.', noValue: buildAutoCertNo(tc.id, prefix: 'TC')),
        Center(child: Text(copyLabel, style: _eng(size: 12, bold: true))),
        const SizedBox(height: 8),
        _titleBox('Transfer Certificate'),
        const SizedBox(height: 14),
        _tcRow(1, 'Name of the student (full)', tc.studentName.toUpperCase(),
            subLabel: '(In block letter beginning with surname)'),
        _tcRow(2, "Mother's Name", tc.motherName),
        _twoLineRow(3, ['a. Date of Birth (In figure)', 'b. In words'], '${tc.dob}\n${tc.dobInWords}'),
        _tcRow(4, 'Caste', tc.caste),
        _twoLineRow(5, ['Semester at the time of leaving', 'the college'], tc.semester),
        _tcRow(6, 'Date of admission in the college', tc.dateOfAdmission),
        _tcRow(7, 'Semester in which admitted', tc.semesterAdmitted, regNo: tc.registerNo),
        _tcRow(8, 'Last College attended', tc.lastCollege),
        _twoLineRow(9, ['Whether qualified for promotion to', 'higher class'], tc.qualifiedForPromotion),
        _tcRow(10, 'Reason for leaving the college', tc.reasonForLeaving),
        _tcRow(11, 'Date of leaving the college', tc.dateOfLeaving),
        _tcRow(12, 'Date of application for T.C.', tc.dateOfApplication),
        _tcRow(13, 'Dues if any', tc.dues),
        _tcRow(14, 'Conduct', tc.conduct),
        _tcRow(15, 'Remarks', tc.tcRemarks),
        const SizedBox(height: 8),
        _rule(),
        const SizedBox(height: 6),
        Text(
          'Certified that the above information is in accordance with the college office record.',
          style: _eng(size: 10),
        ),
        Text('Date :     /     /', style: _eng(size: 10)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Clerk', style: _eng(size: 11, bold: true)),
            Text('Section Officer', style: _eng(size: 11, bold: true)),
            Text(
              'Associate Dean and\nPrincipal',
              style: _eng(size: 11, bold: true),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ],
    );

Widget buildTransferCertCertificate(TcModel tc) => _frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tcCopy(tc, 'Original'),
          const SizedBox(height: 28),
          Container(height: 2, color: Colors.black26),
          const SizedBox(height: 28),
          _tcCopy(tc, 'Duplicate'),
        ],
      ),
    );

// ══════════════════════════════════════════════════════════════
// Generic fallback (e.g. scholarship sanction letter placeholder)
// ══════════════════════════════════════════════════════════════
Widget buildGenericCertificate({
  required String name,
  required String certType,
  String detail = '',
  String docId = '',
}) =>
    _frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _collegeHeader(
            noLabel: 'Cr.No.',
            noValue: docId.isNotEmpty ? buildAutoCertNo(docId) : null,
          ),
          const SizedBox(height: 16),
          _titleBox(certType.toUpperCase()),
          const SizedBox(height: 30),
          Text(name, style: _eng(size: 13, bold: true)),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(detail, style: _eng(size: 11)),
          ],
          const SizedBox(height: 56),
          _signatureBlock(),
        ],
      ),
    );
