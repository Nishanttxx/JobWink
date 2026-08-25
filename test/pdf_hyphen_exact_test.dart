import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Hyphen & Dash Character Rendering Tests', () {
    test('1. Education date range with exact ASCII hyphen renders accurately', () async {
      const resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'na6236786@gmail.com',
        phone: '+91 9876543210',
        education: [
          EducationEntry(
            institution: 'Indian Institute of Technology',
            degree: 'Bachelor of Technology',
            fieldOfStudy: 'Computer Science',
            startDate: 'Aug 2023',
            endDate: 'Aug 2027',
            gpa: '7.84',
          ),
        ],
        experience: [
          ExperienceEntry(
            company: 'Tech Corp',
            role: 'Software Engineer Intern',
            startDate: 'May 2024',
            endDate: 'Jul 2024',
            description: [
              'Developed backend APIs using Dart and Python - optimized query response by 35%.',
            ],
          ),
        ],
        summary: 'Passionate software engineer specializing in mobile and cloud systems.',
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('2. Custom date string containing ASCII hyphen, en-dash, em-dash, and minus renders cleanly', () async {
      const resume = ResumeData(
        fullName: 'Nishant Arya',
        summary: 'Specializing in high-performance computing (2020 - 2024). Range: Jan – Dec. Dash: Alpha — Beta. Minus: −5.',
        education: [
          EducationEntry(
            institution: 'University',
            degree: 'B.Tech',
            startDate: 'Aug 2023 - Aug 2027',
            gpa: '7.84',
          ),
        ],
        skills: [
          'Dart', 'Flutter', 'Python', 'C++', 'SQL', 'Git - Version Control'
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('3. Unicode special glyphs and punctuation render without warnings or missing glyphs', () async {
      const resume = ResumeData(
        fullName: 'Nishant Arya',
        summary: 'Revenue: ₹50,000 • Copyright © 2026 ™ • Café & Zürich (é, ü) • Direction: Left → Right • “Quotes” and dashes: — – -',
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('4. Extracted/Word PUA hyphens (e.g. Club-NMAMIT Aug 2024 [PUA hyphen] Aug 2025) render cleanly as ASCII hyphen', () async {
      const resume = ResumeData(
        fullName: 'Nishant Arya',
        extracurriculars: [
          ExtracurricularEntry(
            activity: 'club-NMAMIT Aug 2024 \uF02D Aug 2025',
            organization: 'NMAMIT',
            description: 'Technical community to research emerging technologies and software development.\nSystems and automation tools.\nEngineering principles to solve complex problems through peer-led projects, focusing on design patterns.',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
