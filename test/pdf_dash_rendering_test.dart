import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test Dash characters rendering in PDF with Tinos TTF font', () async {
    final regBytes = File('assets/fonts/Tinos-Regular.ttf').readAsBytesSync();
    final boldBytes = File('assets/fonts/Tinos-Bold.ttf').readAsBytesSync();
    final italicBytes = File('assets/fonts/Tinos-Italic.ttf').readAsBytesSync();
    final boldItalicBytes = File('assets/fonts/Tinos-BoldItalic.ttf').readAsBytesSync();

    final ttfBase = pw.Font.ttf(Uint8List.fromList(regBytes).buffer.asByteData());
    final ttfBold = pw.Font.ttf(Uint8List.fromList(boldBytes).buffer.asByteData());
    final ttfItalic = pw.Font.ttf(Uint8List.fromList(italicBytes).buffer.asByteData());
    final ttfBoldItalic = pw.Font.ttf(Uint8List.fromList(boldItalicBytes).buffer.asByteData());

    final fontTheme = pw.ThemeData.withFont(
      base: ttfBase,
      bold: ttfBold,
      italic: ttfItalic,
      boldItalic: ttfBoldItalic,
    );

    final testStrings = [
      'Aug 2023 - Aug 2027 | GPA: 7.84', // ASCII hyphen U+002D
      'Aug 2023 – Aug 2027 | GPA: 7.84', // En dash U+2013
      'Aug 2023 — Aug 2027 | GPA: 7.84', // Em dash U+2014
      'Aug 2023 − Aug 2027 | GPA: 7.84', // Minus U+2212
      '₹ • © ™ é ü — – “ ” → -',
    ];

    for (final str in testStrings) {
      debugPrint('\n--- Testing String: $str ---');
      for (int i = 0; i < str.length; i++) {
        final char = str[i];
        final code = char.codeUnitAt(0);
        final hex = code.toRadixString(16).toUpperCase().padLeft(4, '0');
        debugPrint('[PDF TEXT DEBUG] Character: "$char" | Code point: U+$hex');
      }

      final doc = pw.Document(theme: fontTheme);
      doc.addPage(pw.Page(
        build: (pw.Context ctx) => pw.Column(
          children: [
            pw.Text(str, style: pw.TextStyle(fontSize: 12)),
            pw.RichText(
              text: pw.TextSpan(
                text: str,
                style: pw.TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ));

      final bytes = await doc.save();
      expect(bytes.length, greaterThan(0));
      debugPrint('Generated PDF length: ${bytes.length} bytes for string "$str"');
    }

    final resume = ResumeData(
      fullName: 'John Doe',
      education: [
        const EducationEntry(
          institution: 'State University',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Computer Science',
          startDate: 'Aug 2023',
          endDate: 'Aug 2027',
          gpa: '7.84',
        ),
      ],
    );

    final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
    expect(pdfBytes.length, greaterThan(0));
    debugPrint('Successfully generated ATS PDF of size ${pdfBytes.length} bytes');
  });
}
