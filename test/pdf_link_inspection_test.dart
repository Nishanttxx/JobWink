import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect raw PDF bytes for /Subtype /Link and URI annotations', () async {
    final resume = ResumeData(
      fullName: 'Test Candidate',
      email: 'candidate@example.com',
      phone: '+1 234 567 8900',
      location: 'San Francisco, CA',
      linkedin: 'https://www.linkedin.com/in/test-user',
      github: 'https://github.com/test-user',
      summary: 'Experienced software engineer. Check my portfolio at https://example.com/portfolio',
      skills: ['Flutter', 'Dart', 'Python'],
      experience: [
        ExperienceEntry(
          company: 'Acme Corp',
          role: 'Lead Engineer',
          startDate: '2022',
          endDate: 'Present',
          description: [
            'Built cloud infrastructure at https://example.com/project-infra using Docker and Python.',
          ],
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'AI Search',
          type: 'Full-Stack Platform',
          url: 'https://github.com/test-user/ai-search',
          descriptionBullets: [
            'Deployed web application on https://ai-search.example.com with Gemini API.',
          ],
          technologies: ['Flutter', 'Python'],
        ),
      ],
      certifications: [
        ExtracurricularEntry(
          activity: 'Cloud Architect',
          organization: 'Google Cloud',
          url: 'https://example.com/certificate/123',
          startDate: '2024',
        ),
      ],
      extracurriculars: [
        ExtracurricularEntry(
          activity: 'Open Source Contributor',
          url: 'https://github.com/test-user/oss-contrib',
          startDate: '2023',
        ),
      ],
      education: [
        EducationEntry(
          institution: 'Stanford University',
          degree: 'B.S.',
          fieldOfStudy: 'Computer Science',
          startDate: '2018',
          endDate: '2022',
        ),
      ],
    );

    final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
      resume,
      selectedResumeType: ResumeType.fresher,
    );

    final pdfString = String.fromCharCodes(pdfBytes);
    final uriMatches = RegExp(r'/URI\s*\(([^)]+)\)').allMatches(pdfString);

    expect(uriMatches.length, greaterThanOrEqualTo(5));
    expect(pdfString.contains('https://www.linkedin.com/in/test-user'), isTrue);
    expect(pdfString.contains('https://github.com/test-user'), isTrue);
    expect(pdfString.contains('https://example.com/portfolio'), isTrue);
    expect(pdfString.contains('https://example.com/certificate/123'), isTrue);
  });
}
