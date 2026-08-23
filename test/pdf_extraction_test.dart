import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/ai_service.dart';

void main() {
  test('Test PDF text extraction on NNM23ME008_RESUME.pdf', () async {
    final file = File(r'C:\Users\na623\Downloads\NNM23ME008_RESUME.pdf');
    expect(file.existsSync(), isTrue);
    final bytes = await file.readAsBytes();

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'NNM23ME008_RESUME.pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
    expect(text.contains('ARUN SINGH'), isTrue);
    expect(text.contains('Mechanical Engineering'), isTrue);
  });

  test('Test PDF text extraction on NISHANT ARYA (4).pdf', () async {
    final file = File(r'C:\Users\na623\Downloads\NISHANT ARYA (4).pdf');
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'NISHANT ARYA (4).pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
    expect(RegExp(r'NISHANT\s+ARYA', caseSensitive: false).hasMatch(text), isTrue);
  });

  test('Test PDF text extraction on Nishant Arya.pdf', () async {
    final file = File(r'C:\Users\na623\Downloads\Nishant Arya.pdf');
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'Nishant Arya.pdf');

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

    expect(resume.fullName, contains("NISHANT"));
    expect(resume.email, contains("nishaanttx15@gmail.com"));
    expect(resume.projects.length, equals(3));
    expect(resume.experience.length, equals(2));
    expect(resume.education.length, equals(3));
    expect(resume.skillGroups.length, equals(4));

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
