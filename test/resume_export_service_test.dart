import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  test('generateAtsPdf generates valid PDF bytes without throwing', () async {
    final resume = ResumeData(
      fullName: 'Nishant Arya',
      email: 'nishant@example.com',
      phone: '+1 234 567 8900',
      location: 'San Francisco, CA',
      linkedin: 'https://linkedin.com/in/nishant',
      github: 'https://github.com/nishant',
      title: 'Senior Software Engineer',
      summary: 'Experienced software engineer specializing in mobile and cloud architectures.',
      skills: ['Flutter', 'Dart', 'Python', 'FastAPI', 'PostgreSQL', 'Docker'],
      experience: [
        ExperienceEntry(
          company: 'Tech Corp',
          role: 'Senior Engineer',
          location: 'San Francisco, CA',
          startDate: '2022',
          endDate: 'Present',
          description: [
            'Led development of core features using Flutter and Dart.',
            'Optimized application performance reducing latency by 40%.',
          ],
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'JobWink',
          type: 'Mobile App',
          descriptionBullets: ['Built AI job prediction engine using Flutter and Python.'],
          technologies: ['Flutter', 'Python', 'FastAPI'],
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

    final bytes = await ResumeExportService.instance.generateAtsPdf(resume);
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(0));
  });
}
