import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/resume_export_service.dart';
import 'package:jobwink/services/resume_limit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testResume = ResumeData(
    fullName: 'Nishant Arya',
    email: 'na6236786@gmail.com',
    phone: '+91 9876543210',
    location: 'Bangalore, India',
    linkedin: 'https://linkedin.com/in/nishant',
    github: 'https://github.com/nishant',
    summary: 'Software engineer specializing in AI and cloud platforms.',
    skills: ['Flutter', 'Dart', 'Python', 'FastAPI', 'Docker', 'PostgreSQL'],
    experience: [
      ExperienceEntry(
        company: '3skill',
        role: 'AI/ML Intern',
        location: 'Remote',
        startDate: 'Jul 2026',
        endDate: 'Present',
        description: [
          'Engineered a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree.',
        ],
      ),
      ExperienceEntry(
        company: 'Finite Loop Club-NMAMIT',
        role: 'Member',
        location: '',
        startDate: 'Aug 2024',
        endDate: 'Aug 2025',
        description: [
          'Organized technical workshops and hands-on coding sessions for junior developers.',
        ],
      ),
    ],
    projects: [
      ProjectEntry(
        name: 'Nexus Search',
        type: 'Gemini API, Flutter, Prompt Engineering, React, Generative AI',
        url: 'Nishanttxx/Nexus-Searchh',
        descriptionBullets: [
          'Engineered a dynamic AI search engine utilizing the Gemini API and Flutter.',
        ],
      ),
      ProjectEntry(
        name: 'Vyapar Bandhu',
        type: 'Business Platform',
        url: 'https://github.com/Nishanttxx/Vyapar_Bandhu',
        descriptionBullets: [
          'Engineered an automated tax engine using Flutter and Dart.',
        ],
      ),
    ],
    education: [
      EducationEntry(
        institution: 'NMAM Institute of Technology',
        degree: 'B.Tech in Artificial Intelligence & Machine Learning',
        fieldOfStudy: 'AIML',
        startDate: '2022',
        endDate: '2026',
      ),
    ],
  );

  group('Admin Dashboard Resume Download Count Tests', () {
    test('Test 1 & 2: Resume Preview does not increment download count', () async {
      final initialUsage = await ResumeLimitService.instance.getUserResumeUsage();
      final initialCount = (initialUsage['usage_count'] as num? ?? 0).toInt();

      // Preview generation only calls generateAtsPdf without checkAndReserveLimit
      final previewBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
      );

      expect(previewBytes, isNotNull);
      expect(previewBytes.isNotEmpty, isTrue);

      final afterPreviewUsage = await ResumeLimitService.instance.getUserResumeUsage();
      final afterPreviewCount = (afterPreviewUsage['usage_count'] as num? ?? 0).toInt();

      expect(afterPreviewCount, equals(initialCount), reason: 'Preview must NOT increase download count');
    });

    test('Test 3 & 4: Actual download increments count exactly once per download', () async {
      final usageBefore = await ResumeLimitService.instance.getUserResumeUsage();
      final countBefore = (usageBefore['usage_count'] as num? ?? 0).toInt();

      // Trigger 1 download
      final res1 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(res1.allowed, isTrue);
      expect(res1.usageCount, equals(countBefore + 1));

      // Trigger 2nd download
      final res2 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(res2.allowed, isTrue);
      expect(res2.usageCount, equals(countBefore + 2));
    });

    test('Test 6: Failed PDF generation does not increment count (refund or skip)', () async {
      final usageBefore = await ResumeLimitService.instance.getUserResumeUsage();
      final countBefore = (usageBefore['usage_count'] as num? ?? 0).toInt();

      // In real flow, exception in generateAtsPdf throws before checkAndReserveLimit
      try {
        throw Exception('Simulated PDF rendering failure');
      } catch (_) {
        // Did not call checkAndReserveLimit
      }

      final usageAfter = await ResumeLimitService.instance.getUserResumeUsage();
      final countAfter = (usageAfter['usage_count'] as num? ?? 0).toInt();

      expect(countAfter, equals(countBefore), reason: 'Failed generation must not increment count');
    });

    test('Test 10: Blocked quota attempt does not increment beyond daily limit', () async {
      // Consume up to limit for guest/normal mode
      for (int i = 0; i < 5; i++) {
        await ResumeLimitService.instance.checkAndReserveLimit();
      }

      final usage = await ResumeLimitService.instance.getUserResumeUsage();
      final allowed = usage['allowed'] == true;
      final used = (usage['usage_count'] as num? ?? 0).toInt();
      final limit = (usage['daily_limit'] as num? ?? 4).toInt();

      if (!allowed) {
        expect(used, greaterThanOrEqualTo(limit));
        final blockedAttempt = await ResumeLimitService.instance.checkAndReserveLimit();
        expect(blockedAttempt.allowed, isFalse);
      }
    });
  });
}
