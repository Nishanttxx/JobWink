import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Resume Layout Engine by ResumeType', () {
    final testResume = ResumeData(
      fullName: 'Nishant Arya',
      email: 'nishant@example.com',
      phone: '+1 234 567 8900',
      location: 'San Francisco, CA',
      linkedin: 'https://linkedin.com/in/nishant',
      github: 'https://github.com/nishant',
      title: 'Full Stack Engineer',
      summary: 'Experienced full-stack engineer specializing in Dart, Flutter, Python, and cloud microservices.',
      skills: ['Flutter', 'Dart', 'Python', 'FastAPI', 'PostgreSQL', 'Docker', 'AWS'],
      experience: [
        ExperienceEntry(
          company: 'JobWink Technologies',
          role: 'Senior Engineer',
          location: 'San Francisco, CA',
          startDate: '2022',
          endDate: 'Present',
          description: [
            'Architected AI-powered resume tailoring engine with 1-page A4 layout enforcement.',
            'Optimized PDF export latency by 45% using headless rendering pipeline.',
          ],
        ),
        ExperienceEntry(
          company: 'TechCorp',
          role: 'Software Engineer',
          location: 'San Francisco, CA',
          startDate: '2020',
          endDate: '2022',
          description: [
            'Built scalable microservices and APIs.',
          ],
        ),
        ExperienceEntry(
          company: 'CloudStartup',
          role: 'Junior Engineer',
          location: 'San Francisco, CA',
          startDate: '2019',
          endDate: '2020',
          description: [
            'Developed backend components.',
          ],
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'AI Resume Tailorer',
          type: 'Web & Mobile',
          descriptionBullets: ['Multi-provider AI pipeline supporting Gemini, OpenAI, Groq, and Mistral models.'],
          technologies: ['Flutter', 'Python', 'FastAPI'],
        ),
        ProjectEntry(
          name: 'Nexus Search',
          type: 'Search Engine',
          descriptionBullets: ['Engineered AI search platform.'],
          technologies: ['Flutter', 'Gemini API'],
        ),
        ProjectEntry(
          name: 'GST Billing Suite',
          type: 'Fintech App',
          descriptionBullets: ['Cross-platform invoicing suite.'],
          technologies: ['Flutter', 'Dart', 'Supabase'],
        ),
      ],
      education: [
        EducationEntry(
          institution: 'University of Technology',
          degree: 'B.S.',
          fieldOfStudy: 'Computer Science',
          startDate: '2018',
          endDate: '2022',
        ),
      ],
    );

    for (final type in ResumeType.values) {
      test('Generates 1-page PDF for resume type: ${type.displayName}', () async {
        final config = ResumeExportService.instance.optimizeResumeConfig(
          testResume,
          const PdfTemplateConfig(),
        );
        final measurement = ResumeExportService.instance.measureResumeLayout(
          testResume,
          config,
        );

        expect(measurement.pageCount, equals(1));
        expect(measurement.overflow, isFalse);

        final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
          testResume,
          selectedResumeType: type,
        );
        expect(pdfBytes.length, greaterThan(1000));
      });
    }

  });
}
