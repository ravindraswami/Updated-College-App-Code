import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/bonafide_model.dart';
import '../../models/tc_model.dart';
import '../../models/character_cert_model.dart';

// ══════════════════════════════════════════════════════════════
// FONT LOADER
// ══════════════════════════════════════════════════════════════
pw.Font? _devRegular;
pw.Font? _devBold;

Future<void> _loadFonts() async {
  if (_devRegular != null) return; // already loaded
  final regData = await rootBundle.load(
    'assets/fonts/NotoSansDevanagari-Regular.ttf',
  );
  final boldData = await rootBundle.load(
    'assets/fonts/NotoSansDevanagari-Bold.ttf',
  );
  _devRegular = pw.Font.ttf(regData);
  _devBold = pw.Font.ttf(boldData);
}

// ── Text style helpers ────────────────────────────────────────
pw.TextStyle _dev({
  double size = 10,
  bool bold = false,
  PdfColor color = PdfColors.black,
}) => pw.TextStyle(
  font: bold ? _devBold : _devRegular,
  fontBold: _devBold,
  fontSize: size,
  color: color,
);

// ══════════════════════════════════════════════════════════════
// SHARED CONSTANTS — Marathi + English
// ══════════════════════════════════════════════════════════════
const _kMar1 = 'वसंतराव नाईक मराठवाडा कृषी विद्यापीठ, परभणी.';
const _kEn1 = 'VASANTRAO NAIK MARATHWADA KRISHI VIDYAPEETH, PARBHANI';
const _kMar2 =
    'वी'
    'लासराव देशमुख कृषी जैवतंत्रज्ञान महाविद्यालय, लातूर';
const _kEn2 =
    'VILASRAO DESHMUKH COLLEGE OF AGRICULTURAL BIOTECHNOLOGY, LATUR  PIN: 413 512';
const _kEmail = 'E-mail: coablatur@rediffmail.com';
const _kSignatory = 'Associate Dean and Principal\nVDCOAB, Latur';

// ══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════

// ── Horizontal rule ───────────────────────────────────────────
pw.Widget _rule() => pw.Container(
  height: 1.2,
  color: PdfColors.black,
  margin: const pw.EdgeInsets.symmetric(vertical: 2),
);

// ── College header ────────────────────────────────────────────
pw.Widget _collegeHeader({
  String? noLabel, // e.g. 'No.'
  String? noValue, // e.g. 'VDCOAB/   /'
  bool isTc = false, // uses 'Sr.No.'
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      // Marathi line 1
      pw.Text(
        _kMar1,
        style: _dev(size: 11, bold: true),
        textAlign: pw.TextAlign.center,
      ),
      // English line 1
      pw.Text(
        _kEn1,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 2),
      // Marathi line 2 (larger)
      pw.Text(
        _kMar2,
        style: _dev(size: 13, bold: true),
        textAlign: pw.TextAlign.center,
      ),
      // English line 2
      pw.Text(
        _kEn2,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
      // Email
      pw.Text(
        _kEmail,
        style: pw.TextStyle(fontSize: 8, color: PdfColors.blue700),
        textAlign: pw.TextAlign.center,
      ),
      pw.SizedBox(height: 4),
      _rule(),
      pw.SizedBox(height: 4),
      // No. / Sr.No. + Date row
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isTc
                ? 'Sr.No.'
                : noValue != null
                ? '${noLabel ?? 'No.'}  $noValue'
                : (noLabel ?? 'No.'),
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text('Date:   /   /', style: pw.TextStyle(fontSize: 9)),
        ],
      ),
      pw.SizedBox(height: 8),
    ],
  );
}

// ── Certificate title box ─────────────────────────────────────
pw.Widget _titleBox(String title) => pw.Center(
  child: pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    ),
  ),
);

// ── Signature block (right-aligned) ──────────────────────────
pw.Widget _signatureBlock() => pw.Align(
  alignment: pw.Alignment.centerRight,
  child: pw.Text(
    _kSignatory,
    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
    textAlign: pw.TextAlign.right,
  ),
);

// ── TC numbered row ───────────────────────────────────────────
pw.Widget _tcRow(
  int n,
  String label,
  String value, {
  String? subLabel,
  String? regNo,
}) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 7),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Serial number
      pw.SizedBox(
        width: 24,
        child: pw.Text('$n.', style: pw.TextStyle(fontSize: 10)),
      ),
      // Label (optionally with sub-label)
      pw.Expanded(
        flex: 5,
        child: subLabel != null
            ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(label, style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    subLabel,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              )
            : pw.Text(label, style: pw.TextStyle(fontSize: 10)),
      ),
      // Colon
      pw.Text(' : ', style: pw.TextStyle(fontSize: 10)),
      // Value + optional Reg. No. on same line, right side
      pw.Expanded(
        flex: 5,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(value, style: pw.TextStyle(fontSize: 10)),
            ),
            if (regNo != null) ...[
              pw.SizedBox(width: 6),
              pw.Text(
                'Reg. No. : $regNo',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  ),
);

// ══════════════════════════════════════════════════════════════
// 1. BONAFIDE CERTIFICATE
// ══════════════════════════════════════════════════════════════
Future<pw.Document> buildBonafidePdf(BonafideModel b) async {
  await _loadFonts();

  final doc = pw.Document();
  final today = DateTime.now();
  final acYear =
      '${today.year - 1}-${(today.year % 100).toString().padLeft(2, '0')}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 44, 56, 44),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _collegeHeader(noLabel: 'No.'),
          pw.SizedBox(height: 14),

          _titleBox('BONAFIDE CERTIFICATE'),
          pw.SizedBox(height: 28),

          // Body paragraph
          pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(
                font: _devRegular,
                fontBold: _devBold,
                fontSize: 11,
                lineSpacing: 5,
              ),
              children: [
                const pw.TextSpan(
                  text: '\t\tThis is to certify that Shri./Kum. ',
                ),
                pw.TextSpan(
                  text: b.studentName,
                  style: pw.TextStyle(
                    font: _devBold,
                    fontBold: _devBold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                const pw.TextSpan(text: ', Registration No. '),
                pw.TextSpan(
                  text: b.erpId,
                  style: pw.TextStyle(
                    font: _devBold,
                    fontBold: _devBold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                const pw.TextSpan(
                  text: ' is / was a Bonafide student of this college for ',
                ),
                pw.TextSpan(
                  text: 'B.Tech.',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const pw.TextSpan(text: '(Biotechnology)/ '),
                pw.TextSpan(
                  text: 'M.Sc. Agri.',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const pw.TextSpan(
                  text:
                      ' (Molecular Biology and Biotechnology) degree'
                      ' Programme during the academic year ',
                ),
                pw.TextSpan(
                  text: acYear,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const pw.TextSpan(text: ' (Monsoon / Summer) session.'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          pw.Text(
            '\t\tHence certified.',
            style: pw.TextStyle(
              font: _devRegular,
              fontBold: _devBold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 26),

          pw.Text(
            'Place: Latur',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Date:     /     /',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 52),

          _signatureBlock(),
        ],
      ),
    ),
  );

  return doc;
}

// ══════════════════════════════════════════════════════════════
// 2. CHARACTER CERTIFICATE
// ══════════════════════════════════════════════════════════════
Future<pw.Document> buildCharacterCertPdf(CharacterCertModel c) async {
  await _loadFonts();

  final doc = pw.Document();
  final today = DateTime.now();
  final acYear =
      '${today.year - 1}-${(today.year % 100).toString().padLeft(2, '0')}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 44, 56, 44),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _collegeHeader(noLabel: 'No.', noValue: 'VDCOAB/   /'),
          pw.SizedBox(height: 14),

          _titleBox('CHARACTER CERTIFICATE'),
          pw.SizedBox(height: 28),

          // Body
          pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(
                font: _devRegular,
                fontBold: _devBold,
                fontSize: 11,
                lineSpacing: 5,
              ),
              children: [
                const pw.TextSpan(
                  text: '\t\tThis is to certify that Shri./Kum. ',
                ),
                pw.TextSpan(
                  text: c.studentName,
                  style: pw.TextStyle(
                    font: _devBold,
                    fontBold: _devBold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                const pw.TextSpan(text: ', Registration No. '),
                pw.TextSpan(
                  text: c.erpId,
                  style: pw.TextStyle(
                    font: _devBold,
                    fontBold: _devBold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                const pw.TextSpan(text: ' is/was a student of '),
                pw.TextSpan(
                  text: 'B.Tech.',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const pw.TextSpan(text: '(Biotechnology)/ '),
                pw.TextSpan(
                  text: 'M.Sc. Agri.',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const pw.TextSpan(
                  text:
                      ' (Molecular Biology and Biotechnology) this'
                      ' college during the Year ',
                ),
                pw.TextSpan(
                  text: acYear,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const pw.TextSpan(text: '.'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          pw.Text(
            '\t\tTo the best of my knowledge, He / She bears a good moral character.',
            style: pw.TextStyle(
              font: _devRegular,
              fontBold: _devBold,
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 28),

          pw.Text(
            'Date:     /     /',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Place: Latur',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 52),

          _signatureBlock(),
        ],
      ),
    ),
  );

  return doc;
}

// ══════════════════════════════════════════════════════════════
// 3. TRANSFER CERTIFICATE (Original + Duplicate — 2 pages)
// ══════════════════════════════════════════════════════════════
Future<pw.Document> buildTransferCertPdf(TcModel tc) async {
  await _loadFonts();

  final doc = pw.Document();

  pw.Widget _tcPage(String copyLabel) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _collegeHeader(isTc: true),

      pw.Center(
        child: pw.Text(
          copyLabel,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 6),

      _titleBox('Transfer Certificate'),
      pw.SizedBox(height: 12),

      // 15 numbered fields
      _tcRow(
        1,
        'Name of the student (full)',
        tc.studentName.toUpperCase(),
        subLabel: '(In block letter beginning with surname)',
      ),
      _tcRow(2, 'Mother\'s Name', tc.motherName),

      // 3a + 3b
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 24,
              child: pw.Text('3.', style: pw.TextStyle(fontSize: 10)),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'a. Date of Birth (In figure)',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('b. In words', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Text(' : ', style: pw.TextStyle(fontSize: 10)),
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(tc.dob, style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Text(tc.dobInWords, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),

      _tcRow(4, 'Caste', tc.caste),

      // 5: two-line label
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 24,
              child: pw.Text('5.', style: pw.TextStyle(fontSize: 10)),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Semester at the time of leaving',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text('the college', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Text(' : ', style: pw.TextStyle(fontSize: 10)),
            pw.Expanded(
              flex: 5,
              child: pw.Text(tc.semester, style: pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),

      _tcRow(6, 'Date of admission in the college', tc.dateOfAdmission),
      _tcRow(
        7,
        'Semester in which admitted',
        tc.semesterAdmitted,
        regNo: tc.registerNo,
      ),
      _tcRow(8, 'Last College attended', tc.lastCollege),

      // 9: two-line label
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 24,
              child: pw.Text('9.', style: pw.TextStyle(fontSize: 10)),
            ),
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Whether qualified for promotion to',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text('higher class', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.Text(' : ', style: pw.TextStyle(fontSize: 10)),
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                tc.qualifiedForPromotion,
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),

      _tcRow(10, 'Reason for leaving the college', tc.reasonForLeaving),
      _tcRow(11, 'Date of leaving the college', tc.dateOfLeaving),
      _tcRow(12, 'Date of application for T.C.', tc.dateOfApplication),
      _tcRow(13, 'Dues if any', tc.dues),
      _tcRow(14, 'Conduct', tc.conduct),
      _tcRow(15, 'Remarks', tc.tcRemarks),

      pw.SizedBox(height: 6),
      _rule(),
      pw.SizedBox(height: 5),

      pw.Text(
        'Certified that the above information is in accordance with the college office record.',
        style: pw.TextStyle(fontSize: 9),
      ),
      pw.Text('Date :     /     /', style: pw.TextStyle(fontSize: 9)),
      pw.SizedBox(height: 18),

      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Clerk', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(
                'Principal',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Associate Dean and',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Principal',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 44, 56, 44),
      build: (_) => _tcPage('Original'),
    ),
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 44, 56, 44),
      build: (_) => _tcPage('Duplicate'),
    ),
  );

  return doc;
}

// ══════════════════════════════════════════════════════════════
// PRINT + SAVE helpers
// ══════════════════════════════════════════════════════════════
Future<void> printBonafide(BonafideModel b) async {
  final doc = await buildBonafidePdf(b);
  await Printing.layoutPdf(
    onLayout: (_) async => await doc.save(),
    name: 'Bonafide_${b.studentName.replaceAll(' ', '_')}.pdf',
  );
}

Future<void> saveBonafide(BonafideModel b) async {
  final doc = await buildBonafidePdf(b);
  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'Bonafide_${b.studentName.replaceAll(' ', '_')}.pdf',
  );
}

Future<void> printCharacterCert(CharacterCertModel c) async {
  final doc = await buildCharacterCertPdf(c);
  await Printing.layoutPdf(
    onLayout: (_) async => await doc.save(),
    name: 'CharacterCert_${c.studentName.replaceAll(' ', '_')}.pdf',
  );
}

Future<void> saveCharacterCert(CharacterCertModel c) async {
  final doc = await buildCharacterCertPdf(c);
  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'CharacterCert_${c.studentName.replaceAll(' ', '_')}.pdf',
  );
}

Future<void> printTransferCert(TcModel tc) async {
  final doc = await buildTransferCertPdf(tc);
  await Printing.layoutPdf(
    onLayout: (_) async => await doc.save(),
    name: 'TransferCert_${tc.studentName.replaceAll(' ', '_')}.pdf',
  );
}

Future<void> saveTransferCert(TcModel tc) async {
  final doc = await buildTransferCertPdf(tc);
  await Printing.sharePdf(
    bytes: await doc.save(),
    filename: 'TransferCert_${tc.studentName.replaceAll(' ', '_')}.pdf',
  );
}
