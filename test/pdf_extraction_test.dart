import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/ai_service.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> getArunResumePdfBytes() async {
    const fixturePath = 'test/fixtures/NNM23ME008_RESUME.pdf';
    final fixtureFile = File(fixturePath);
    if (fixtureFile.existsSync()) {
      return await fixtureFile.readAsBytes();
    }
    final arunResume = ResumeData(
      fullName: 'ARUN SINGH',
      email: 'arunsinghkatal123@gmail.com',
      phone: '+91 9103506279',
      location: 'Nitte, Karnataka',
      summary: 'Mechanical Engineering undergraduate with hands-on experience in manufacturing, industrial systems, and engineering analysis through technical projects. Skilled in process optimization, root-cause analysis, equipment evaluation, and Industry 4.0 technologies.',
      skills: ['Manufacturing', 'Process Optimization', 'Root Cause Analysis', 'Industrial Systems', 'CAD', 'SolidWorks'],
      education: [
        EducationEntry(
          institution: 'NMAM Institute of Technology, Nitte',
          degree: 'B.Tech in Mechanical Engineering',
          fieldOfStudy: 'Mechanical Engineering',
          startDate: '2020',
          endDate: '2024',
        ),
      ],
      experience: [
        ExperienceEntry(
          company: 'Industrial Automation Plant',
          role: 'Maintenance & Production Intern',
          location: 'Bangalore, India',
          startDate: '2023',
          endDate: '2024',
          description: ['Assisted with root cause analysis of equipment failures and process optimization.'],
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'Pneumatic Sheet Metal Cutting Machine',
          type: 'Mechanical Project',
          descriptionBullets: ['Designed and fabricated a pneumatic sheet metal cutter improving cycle time.'],
        ),
      ],
    );
    return await ResumeExportService.instance.generateAtsPdf(
      arunResume,
      selectedResumeType: ResumeType.experience,
    );
  }

  Future<Uint8List> getNishantResumePdfBytes() async {
    const fixturePath = 'test/fixtures/Nishant_Arya.pdf';
    final fixtureFile = File(fixturePath);
    if (fixtureFile.existsSync()) {
      return await fixtureFile.readAsBytes();
    }
    final nishantResume = ResumeData(
      fullName: 'Nishant Arya',
      email: 'nishaanttx15@gmail.com',
      phone: '+91 8088031526',
      location: 'Nitte, Karkala, Karnataka - 574110',
      linkedin: 'https://linkedin.com/in/nishant-arya',
      github: 'https://github.com/Nishanttxx',
      summary: 'Passionate Artificial Intelligence and Machine Learning engineer with expertise in Flutter, Python, FastAPI, and Cloud architectures.',
      skillGroups: [
        SkillGroupEntry(category: 'Programming Languages', items: ['Python', 'Dart', 'JavaScript', 'SQL']),
        SkillGroupEntry(category: 'Frameworks & Libraries', items: ['Flutter', 'React', 'FastAPI', 'Node.js']),
        SkillGroupEntry(category: 'Databases & Cloud', items: ['PostgreSQL', 'Supabase', 'Docker', 'AWS']),
        SkillGroupEntry(category: 'AI & Machine Learning', items: ['TensorFlow', 'PyTorch', 'Gemini API', 'Scikit-learn']),
      ],
      education: [
        EducationEntry(
          institution: 'NMAM Institute of Technology, Nitte',
          degree: 'B.Tech in Artificial Intelligence & Machine Learning',
          fieldOfStudy: 'AIML',
          startDate: 'Nov 2022',
          endDate: 'June 2026',
          gpa: 'CGPA: 8.7',
        ),
        EducationEntry(
          institution: 'Expert Pre-University College',
          degree: 'Pre-University Course (PCMB)',
          startDate: '2020',
          endDate: '2022',
        ),
        EducationEntry(
          institution: 'St. Aloysius High School',
          degree: 'Secondary School Leaving Certificate (SSLC)',
          startDate: '2019',
          endDate: '2020',
        ),
      ],
      experience: [
        ExperienceEntry(
          company: '3skill',
          role: 'AI / ML Engineer Intern',
          location: 'Remote',
          startDate: 'July 2024',
          endDate: 'Present',
          description: [
            'Engineered a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree.',
            'Developed an AI-based hiring prediction system with automated machine learning pipeline.',
          ],
        ),
        ExperienceEntry(
          company: 'TechCorp Solutions',
          role: 'Software Engineering Intern',
          location: 'Bangalore, India',
          startDate: 'Jan 2024',
          endDate: 'June 2024',
          description: [
            'Built scalable microservices and REST APIs using Python FastAPI and Flutter.',
          ],
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'Nexus Search',
          type: 'AI Search Platform',
          url: 'https://github.com/Nishanttxx/nexus_search',
          descriptionBullets: [
            'Engineered a dynamic AI search engine utilizing Gemini API and Flutter.',
            'Developed an interactive querying interface to handle real-time user interactions.',
          ],
        ),
        ProjectEntry(
          name: 'Vyapar Bandhu',
          type: 'Business Compliance Platform',
          url: 'https://github.com/Nishanttxx/Vyapar_Bandhu',
          descriptionBullets: [
            'Engineered automated tax engine calculating CGST, SGST, and IGST for Indian GST compliance.',
            'Developed integrated compliance tool enabling instant GSTR-1 reports generation.',
          ],
        ),
        ProjectEntry(
          name: 'GST Billing Suite',
          type: 'Fintech Application',
          descriptionBullets: [
            'Architected cross-platform invoicing and billing suite with automated tax calculations.',
          ],
        ),
      ],
      extracurriculars: [
        ExtracurricularEntry(
          activity: 'Core Member, Tantra Club',
          organization: 'NMAMIT',
          role: 'Technical Team',
          description: 'Organized and mentored workshops on emerging technologies.',
        ),
      ],
    );
    return await ResumeExportService.instance.generateAtsPdf(
      nishantResume,
      selectedResumeType: ResumeType.fresher,
    );
  }

  test('Test PDF text extraction on Arun Singh Mechanical Engineering resume', () async {
    final bytes = await getArunResumePdfBytes();
    expect(bytes.isNotEmpty, isTrue);

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'NNM23ME008_RESUME.pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
    expect(text.toUpperCase().contains('ARUN SINGH'), isTrue);
    expect(text.contains('Mechanical Engineering'), isTrue);
  });

  test('Test PDF text extraction on Nishant Arya resume (regex name match)', () async {
    final bytes = await getNishantResumePdfBytes();
    expect(bytes.isNotEmpty, isTrue);

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'NISHANT_ARYA.pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
    expect(RegExp(r'NISHANT\s+ARYA', caseSensitive: false).hasMatch(text), isTrue);
  });

  test('Test PDF text extraction and complete section parsing on Nishant Arya resume', () async {
    final bytes = await getNishantResumePdfBytes();
    expect(bytes.isNotEmpty, isTrue);

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'Nishant_Arya.pdf');

    final rawLines = text.split('\n');
    for (int i = 0; i < rawLines.length; i++) {
      debugPrint('LINE $i: "${rawLines[i]}"');
    }
    final resume = ResumeData.parseFromRawText(text);
    debugPrint('PARSED NAME: "${resume.fullName}"');
    debugPrint('PARSED EMAIL: "${resume.email}"');
    debugPrint('PARSED PHONE: "${resume.phone}"');
    debugPrint('PARSED SUMMARY: "${resume.summary}"');
    debugPrint('PARSED PROJECTS: ${resume.projects.length} -> ${resume.projects.map((p) => p.name).toList()}');
    debugPrint('PARSED EXPERIENCE: ${resume.experience.length} -> ${resume.experience.map((e) => "${e.company} (${e.role})").toList()}');
    debugPrint('PARSED EDUCATION: ${resume.education.length} -> ${resume.education.map((e) => e.degree).toList()}');
    debugPrint('PARSED SKILL GROUPS: ${resume.skillGroups.length} -> ${resume.skillGroups.map((g) => g.category).toList()}');

    expect(resume.fullName.toUpperCase(), contains("NISHANT"));
    expect(resume.email, contains("nishaanttx15@gmail.com"));
    expect(resume.projects.length, equals(3));
    expect(resume.experience.length, equals(2));
    expect(resume.education.length, equals(3));
    expect(resume.skillGroups.length, greaterThanOrEqualTo(3));

    // Assert that EXTRA-CURRICULAR never becomes a project
    for (final p in resume.projects) {
      expect(ResumeData.isKnownSectionHeader(p.name), isFalse);
      expect(p.name.toUpperCase().contains('EXTRA-CURRICULAR'), isFalse);
    }
  });

  test('Test isKnownSectionHeader normalization and alias matching', () {
    expect(ResumeData.isKnownSectionHeader('EXTRA-CURRICULAR'), isTrue);
    expect(ResumeData.isKnownSectionHeader('EXTRA-CURRICULAR ACTIVITIES & ACHIEVEMENTS'), isTrue);
    expect(ResumeData.isKnownSectionHeader('## TECHNICAL SKILLS:'), isTrue);
    expect(ResumeData.isKnownSectionHeader('1. WORK EXPERIENCE'), isTrue);
    expect(ResumeData.isKnownSectionHeader('EDUCATION & QUALIFICATIONS:'), isTrue);
    expect(ResumeData.isKnownSectionHeader('PROJECTS / OPEN SOURCE'), isTrue);
    expect(ResumeData.isKnownSectionHeader('SUMMARY / OBJECTIVE'), isTrue);

    expect(ResumeData.isKnownSectionHeader('Nexus Search'), isFalse);
    expect(ResumeData.isKnownSectionHeader('AI/ML Intern'), isFalse);
    expect(ResumeData.isKnownSectionHeader('B.Tech in Information Science'), isFalse);
  });

  test('Test generic arbitrary resume text parsing', () {
    const genericResume = '''
John Doe
johndoe@example.com | +1234567890 | linkedin.com/in/johndoe | github.com/johndoe

SUMMARY
Experienced Full Stack Engineer specializing in cloud-native applications and microservices.

TECHNICAL SKILLS:
Languages: TypeScript, Python, Go, Dart
Frameworks: Flutter, React, FastAPI, Node.js
Databases & Tools: PostgreSQL, Docker, Kubernetes, AWS

PROFESSIONAL EXPERIENCE:
Senior Software Engineer | Acme Corp | San Francisco, CA | 2021 - Present
- Architected and scaled distributed backend microservices handling 10M daily requests.
- Led migration of legacy monolith to containerized Kubernetes deployment.

Software Engineer | Beta Startup | New York, NY | 2019 - 2021
- Developed real-time analytics dashboard with React and WebSockets.
- Optimized database queries improving p99 response latency by 40%.

KEY PROJECTS:
Cloud Monitor | Real-time Observability Suite | github.com/johndoe/cloud-monitor
- Built high-throughput telemetry collector using Go and Prometheus.
- Implemented real-time anomaly alerting engine.

EDUCATION:
B.S. in Computer Science | Stanford University | 2015 - 2019 | GPA: 3.9

CERTIFICATIONS:
AWS Certified Solutions Architect Associate
''';

    final parsed = ResumeData.parseFromRawText(genericResume);
    expect(parsed.fullName, equals('John Doe'));
    expect(parsed.email, equals('johndoe@example.com'));
    expect(parsed.summary, contains('Experienced Full Stack Engineer'));
    expect(parsed.projects.length, equals(1));
    expect(parsed.projects.first.name, equals('Cloud Monitor'));
    expect(parsed.experience.length, equals(2));
    expect(parsed.experience.first.role, equals('Senior Software Engineer'));
    expect(parsed.experience.first.company, equals('Acme Corp'));
    expect(parsed.education.length, equals(1));
    expect(parsed.education.first.degree, equals('B.S. in Computer Science'));
    expect(parsed.skillGroups.length, greaterThanOrEqualTo(2));
  });
}
