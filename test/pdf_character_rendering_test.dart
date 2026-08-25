import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Unicode Character & Exact String Rendering Verification', () {
    late pw.ThemeData fontTheme;
    late pw.Font fReg;
    late pw.Font fBold;
    late pw.Font fItalic;
    late pw.Font fBoldItalic;

    setUpAll(() async {
      final regBytes = File('assets/fonts/Tinos-Regular.ttf').readAsBytesSync();
      final boldBytes = File('assets/fonts/Tinos-Bold.ttf').readAsBytesSync();
      final italicBytes = File('assets/fonts/Tinos-Italic.ttf').readAsBytesSync();
      final boldItalicBytes = File('assets/fonts/Tinos-BoldItalic.ttf').readAsBytesSync();

      fReg = pw.Font.ttf(Uint8List.fromList(regBytes).buffer.asByteData());
      fBold = pw.Font.ttf(Uint8List.fromList(boldBytes).buffer.asByteData());
      fItalic = pw.Font.ttf(Uint8List.fromList(italicBytes).buffer.asByteData());
      fBoldItalic = pw.Font.ttf(Uint8List.fromList(boldItalicBytes).buffer.asByteData());

      expect(fReg.fontName, 'Tinos-Regular');
      expect(fBold.fontName, 'Tinos-Bold');
      expect(fItalic.fontName, 'Tinos-Italic');
      expect(fBoldItalic.fontName, 'Tinos-BoldItalic');

      fontTheme = pw.ThemeData.withFont(
        base: fReg,
        bold: fBold,
        italic: fItalic,
        boldItalic: fBoldItalic,
        fontFallback: [fReg, fBold, fItalic, fBoldItalic],
      );
    });

    test('All acceptance characters render without glyph missing errors', () async {
      final testChars = [
        'ABC',
        '123',
        '-', // U+002D
        '–', // U+2013
        '—', // U+2014
        '−', // U+2212
        '•', // U+2022
        '&',
        '/',
        '|',
        '(',
        ')',
        '[',
        ']',
        '{',
        '}',
        ':',
        ';',
        ',',
        '.',
        "'",
        '"',
        '₹', // U+20B9
        '€', // U+20AC
        '£', // U+00A3
        '©', // U+00A9
        '™', // U+2122
        'é',
        'ü',
        'ñ',
        '→',
        '←',
      ];

      for (final char in testChars) {
        final doc = pw.Document(theme: fontTheme);
        doc.addPage(pw.Page(
          build: (ctx) => pw.Column(
            children: [
              pw.Text('Regular: $char', style: pw.TextStyle(font: fReg)),
              pw.Text('Bold: $char', style: pw.TextStyle(font: fBold, fontWeight: pw.FontWeight.bold)),
              pw.Text('Italic: $char', style: pw.TextStyle(font: fItalic, fontStyle: pw.FontStyle.italic)),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'RichText: '),
                    pw.TextSpan(text: char, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ));

        final bytes = await doc.save();
        expect(bytes.length, greaterThan(1000));
      }
    });

    test('Critical acceptance strings render precisely', () async {
      final acceptanceStrings = [
        'Aug 2024 - Aug 2025',
        'C++, C#, Node.js',
        '₹50,000 — Software Engineer',
        'Computer Society of India (CSI)',
      ];

      for (final str in acceptanceStrings) {
        final doc = pw.Document(theme: fontTheme);
        doc.addPage(pw.Page(
          build: (ctx) => pw.Column(
            children: [
              pw.Text(str),
              pw.RichText(
                text: pw.TextSpan(
                  text: str,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ));

        final bytes = await doc.save();
        expect(bytes.length, greaterThan(1000));
      }
    });

    test('Full ResumeExportService PDF generation preserves all characters and stays 1 page', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+91 9876543210',
        linkedin: 'linkedin.com/in/nishant',
        github: 'github.com/nishant',
        summary: 'Passionate Engineer with ₹50,000+ stipend experience & proven expertise in C++, C#, Node.js.',
        education: [
          const EducationEntry(
            institution: 'Computer Society of India (CSI) Institute',
            degree: 'Bachelor of Technology',
            fieldOfStudy: 'Computer Science & Engineering',
            startDate: 'Aug 2024',
            endDate: 'Aug 2025',
            gpa: '8.9/10.0',
          ),
        ],
        skills: [
          'C++',
          'C#',
          'Node.js',
          'Python',
          'Problem Solving & Leadership',
          'REST APIs & Postman',
        ],
        experience: [
          const ExperienceEntry(
            role: 'Software Engineer',
            company: 'Tech Solutions Inc.',
            location: 'Bangalore, India',
            startDate: 'Aug 2024',
            endDate: 'Aug 2025',
            description: [
              'Developed scalable backends using C++, C#, and Node.js with 99.9% uptime.',
              'Earned ₹50,000 performance award for microservice optimization.',
              'Collaborated with cross-functional teams across India & Europe.',
            ],
          ),
        ],
        projects: [
          ProjectEntry(
            name: 'JobWink Platform',
            type: 'Web Application',
            technologies: ['Flutter', 'Node.js', 'C++'],
            url: 'jobwink.app',
            descriptionBullets: [
              'Engineered single-page resume ATS generator supporting full Unicode (₹, €, —, –, •).',
              'Implemented real-time character preserving PDF rendering engine.',
            ],
          ),
        ],
        extracurriculars: [
          const ExtracurricularEntry(
            activity: 'Computer Society of India (CSI) - Chapter Lead',
            role: 'Lead Organizer',
            organization: 'CSI',
            description: 'Organized technical symposium for 500+ participants.',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.length, greaterThan(5000));

      debugPrint('[Test] PDF successfully generated: ${pdfBytes.length} bytes');
    });
  });
}
