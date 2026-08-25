import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Clickable Hyperlinks Tests', () {
    test('1. LinkedIn, GitHub, and Project URLs are real clickable hyperlinks in PDF', () async {
      final resume = ResumeData(
        fullName: 'Nishant Arya',
        email: 'nishant@example.com',
        phone: '+91 8102908376',
        linkedin: 'linkedin.com/in/nishant-arya-838168321',
        github: 'github.com/Nishanttxx',
        summary: 'Software Engineer skilled in Flutter and Python. Portfolio at https://nishant.dev.',
        education: [
          EducationEntry(
            degree: 'B.Tech',
            fieldOfStudy: 'Computer Science',
            institution: 'NMAMIT',
            startDate: '2021',
            endDate: '2025',
          ),
        ],
        skills: ['Flutter', 'Dart', 'Python'],
        projects: [
          ProjectEntry(
            name: 'JobWink Platform',
            technologies: ['Flutter', 'Supabase'],
            url: 'https://github.com/Nishanttxx/jobwink',
            description: 'AI resume tailoring system available at https://jobwink.app.',
          ),
        ],
        experience: [
          ExperienceEntry(
            role: 'Software Engineer Intern',
            company: 'Tech Corp',
            startDate: '2024',
            endDate: 'Present',
            description: ['Contributed to open source at github.com/flutter/flutter.'],
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);

      final pdfString = String.fromCharCodes(pdfBytes);

      // Verify that all URLs have been embedded as PDF URI annotations
      expect(pdfString.contains('https://linkedin.com/in/nishant-arya-838168321'), isTrue,
          reason: 'LinkedIn URL must be converted to full https URI target in PDF');
      expect(pdfString.contains('https://github.com/Nishanttxx'), isTrue,
          reason: 'GitHub URL must be converted to full https URI target in PDF');
      expect(pdfString.contains('https://github.com/Nishanttxx/jobwink'), isTrue,
          reason: 'Project repository URL must be clickable in PDF');
      expect(pdfString.contains('https://nishant.dev'), isTrue,
          reason: 'Summary portfolio URL must be clickable in PDF');
      expect(pdfString.contains('https://jobwink.app'), isTrue,
          reason: 'Project description URL must be clickable in PDF');
      expect(pdfString.contains('https://github.com/flutter/flutter'), isTrue,
          reason: 'Experience bullet URL must be clickable in PDF');

      // Verify visible text does not modify user model
      expect(resume.linkedin, 'linkedin.com/in/nishant-arya-838168321');
      expect(resume.github, 'github.com/Nishanttxx');
    });

    test('2. Normal text is not turned into a hyperlink', () async {
      const resume = ResumeData(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        summary: 'Computer Science and Engineering graduate.',
        skills: ['Dart', 'Flutter'],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      final pdfString = String.fromCharCodes(pdfBytes);

      expect(pdfString.contains('/URI (Computer Science and Engineering)'), isFalse);
    });
  });
}
