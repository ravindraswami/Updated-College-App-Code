// registration_pdf.dart
//
// NOTE: kept this filename so existing imports across the app don't need
// renaming, but this is no longer PDF-based. Registration tables are now
// built as Flutter widgets and shown via CertificatePreviewScreen, where
// the user can only Save as Image (gallery) or Share as Image — no PDF,
// no print, anywhere.
import 'package:flutter/material.dart';
import '../../models/exam_form_model.dart';
import '../../utils/certificate_widgets.dart' as certw;
import '../shared/certificate_preview_screen.dart';

Widget _letterhead(String title) => Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        certw.buildLetterheadBlock(),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
      ],
    );

Widget _signatureFooter({required String leftLabel, required String rightLabel}) => Padding(
      padding: const EdgeInsets.only(top: 34, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(leftLabel, style: const TextStyle(fontSize: 11)),
          Text(rightLabel, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );

TableRow _headerRow(List<String> headers) => TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: headers
          .map((h) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );

TableRow _dataRow(List<String> cells) => TableRow(
      children: cells
          .map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(c, style: const TextStyle(fontSize: 9.5)),
              ))
          .toList(),
    );

Widget _bordered(Table table) => Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black45, width: 0.7)),
      child: table,
    );

// Uses the SAME letterhead + watermark sheet as every certificate, so
// every generated report looks visually identical to every certificate.
Widget _sheet({required Widget child, double width = 1050}) =>
    certw.reportSheet(width: width, child: child);

// ══════════════════════════════════════════════════════════════
// 1) PER-STUDENT SUBJECT TABLE
// ══════════════════════════════════════════════════════════════
Future<void> printStudentSubjectTable(BuildContext context, ExamFormModel f) async {
  final rows = <List<String>>[];
  int sr = 1;
  double totalCredits = 0;
  for (final id in f.subjectIds) {
    final credit = f.subjectCredits[id] ?? 0;
    totalCredits += credit;
    rows.add([
      '${sr++}',
      f.subjectCodes[id] ?? '',
      f.subjectTitles[id] ?? '',
      credit.toStringAsFixed(1),
      f.teacherSignatures[id] ?? '-',
      f.subjectTeacherNames[id] ?? '',
      '',
    ]);
  }
  for (final id in f.backlogSubjectIds) {
    final credit = f.backlogSubjectCredits[id] ?? 0;
    totalCredits += credit;
    final selection = f.backlogSelections[id] ?? '';
    rows.add([
      '${sr++}',
      f.backlogSubjectCodes[id] ?? '',
      '${f.backlogSubjectTitles[id] ?? ''} ($selection)',
      credit.toStringAsFixed(1),
      f.teacherSignatures[id] ?? '-',
      f.backlogSubjectTeacherNames[id] ?? '',
      '',
    ]);
  }
  final totalSubjects = f.subjectIds.length + f.backlogSubjectIds.length;
  final regNo = f.rollNo.isNotEmpty ? f.rollNo : f.erpId;

  final widget = _sheet(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _letterhead('Registration Form — Subject Details'),
        Text('Student Name: ${f.name}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text('Year: ${f.year}     Semester: ${f.semester}     Registration No: $regNo',
            style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 12),
        _bordered(
          Table(
            border: TableBorder.all(color: Colors.black45, width: 0.7),
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(80),
              2: FlexColumnWidth(2.4),
              3: FixedColumnWidth(60),
              4: FlexColumnWidth(1.3),
              5: FlexColumnWidth(1.5),
              6: FlexColumnWidth(1),
            },
            children: [
              _headerRow(['Sr No', 'Course No', 'Course Title', 'Credits', 'Sign of Advisor (RR)', 'Sign of Course Teacher', 'Remark']),
              ...rows.map(_dataRow),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Total Subjects: $totalSubjects      Total Credits: ${totalCredits.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        _signatureFooter(leftLabel: 'Signature of Student', rightLabel: 'Signature of Advisor'),
      ],
    ),
  );

  await openCertificatePreview(
    context,
    title: 'Registration Form',
    fileName: 'RegistrationForm_${f.erpId}',
    certificate: widget,
  );
}

// ══════════════════════════════════════════════════════════════
// 2) CLASS / SEM SUMMARY TABLE
// ══════════════════════════════════════════════════════════════
Future<void> printClassSummaryTable(
  BuildContext context,
  String title,
  List<ExamFormModel> forms,
) async {
  final rows = <List<String>>[];
  int sr = 1;
  double grandCredits = 0;
  for (final f in forms) {
    final totalSubjects = f.subjectIds.length + f.backlogSubjectIds.length;
    final credits = f.totalCreditSum + f.totalBacklogCreditSum;
    grandCredits += credits;
    final teacherSigs = {
      for (final id in f.subjectIds) f.teacherSignatures[id] ?? '',
      for (final id in f.backlogSubjectIds) f.teacherSignatures[id] ?? '',
    }..removeWhere((s) => s.isEmpty);
    final teacherSigDisplay =
        teacherSigs.isEmpty ? '-' : (teacherSigs.length == 1 ? teacherSigs.first : 'Multiple');

    rows.add([
      '${sr++}',
      f.name,
      '$totalSubjects',
      '${f.backlogSubjectIds.length}',
      credits.toStringAsFixed(1),
      f.advisorSignature.isNotEmpty ? f.advisorSignature : '-',
      teacherSigDisplay,
      '',
    ]);
  }

  final widget = _sheet(
    width: 1200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _letterhead(title),
        _bordered(
          Table(
            border: TableBorder.all(color: Colors.black45, width: 0.7),
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(2),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(90),
              4: FixedColumnWidth(70),
              5: FlexColumnWidth(1.3),
              6: FlexColumnWidth(1.5),
              7: FlexColumnWidth(1),
            },
            children: [
              _headerRow(['Sr No', 'Student Name', 'Total Subject', 'Backlog Subject', 'Credits', 'Sign of Advisor (RR)', 'Sign of Course Teacher', 'Remark']),
              ...rows.map(_dataRow),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Total Students: ${forms.length}      Total Credits: ${grandCredits.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        _signatureFooter(leftLabel: 'Signature of Advisor', rightLabel: 'Signature of Education Section'),
      ],
    ),
  );

  await openCertificatePreview(
    context,
    title: title,
    fileName: title.replaceAll(' ', '_'),
    certificate: widget,
  );
}

// ══════════════════════════════════════════════════════════════
// 3) COURSE TEACHER TABLE
// ══════════════════════════════════════════════════════════════
class CourseTeacherRow {
  final ExamFormModel form;
  final String subjectId;
  final bool isBacklog;
  CourseTeacherRow({required this.form, required this.subjectId, required this.isBacklog});
}

Future<void> printCourseTeacherTable(
  BuildContext context,
  String subjectCode,
  String subjectTitle,
  List<CourseTeacherRow> entries,
) async {
  final rows = <List<String>>[];
  int sr = 1;
  for (final e in entries) {
    final f = e.form;
    final credit = e.isBacklog
        ? (f.backlogSubjectCredits[e.subjectId] ?? 0)
        : (f.subjectCredits[e.subjectId] ?? 0);
    rows.add([
      '${sr++}',
      subjectCode,
      subjectTitle,
      f.name,
      credit.toStringAsFixed(1),
      f.advisorSignature.isNotEmpty ? f.advisorSignature : '-',
      f.teacherSignatures[e.subjectId] ?? '-',
      '',
    ]);
  }

  final widget = _sheet(
    width: 1200,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _letterhead('Registration — $subjectTitle'),
        _bordered(
          Table(
            border: TableBorder.all(color: Colors.black45, width: 0.7),
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FixedColumnWidth(80),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FixedColumnWidth(70),
              5: FlexColumnWidth(1.3),
              6: FlexColumnWidth(1.5),
              7: FlexColumnWidth(1),
            },
            children: [
              _headerRow(['Sr No', 'Course No', 'Course Title', 'Student Name', 'Credits', 'Sign of Advisor (RR)', 'Sign of Course Teacher', 'Remark']),
              ...rows.map(_dataRow),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Total Students: ${entries.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        _signatureFooter(leftLabel: 'Signature of Advisor', rightLabel: 'Signature of Course Teacher'),
      ],
    ),
  );

  await openCertificatePreview(
    context,
    title: 'Registration — $subjectTitle',
    fileName: 'CourseTeacher_${subjectTitle.replaceAll(' ', '_')}',
    certificate: widget,
  );
}
