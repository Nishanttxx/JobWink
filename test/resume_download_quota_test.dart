import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/resume_export_service.dart';
import 'package:jobwink/services/resume_limit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testResume = ResumeData(
    fullName: 'Jane Doe',
    email: 'jane@example.com',
    phone: '+1 555 123 4567',
    location: 'New York, NY',
    linkedin: 'https://linkedin.com/in/janedoe',
    github: 'https://github.com/janedoe',
    summary: 'Full stack engineer with 3+ years experience building cloud web apps.',
    skills: ['Flutter', 'Dart', 'Python', 'FastAPI'],
    experience: [
      ExperienceEntry(
        company: 'Tech Solutions',
        role: 'Software Engineer',
        startDate: '2022',
        endDate: 'Present',
        description: ['Built scalable microservices and Flutter web applications.'],
      ),
    ],
    projects: [
      ProjectEntry(
        name: 'AI Chat',
        type: 'Mobile App',
        descriptionBullets: ['Developed conversational AI assistant using Flutter and LLMs.'],
        technologies: ['Flutter', 'Python'],
      ),
    ],
    education: [
      EducationEntry(
        institution: 'NYU',
        degree: 'B.S.',
        fieldOfStudy: 'Computer Science',
        startDate: '2018',
        endDate: '2022',
      ),
    ],
  );

  group('Resume Download Quota Enforcement Matrix', () {
    test('TEST 1: Fresh user has 4 quota; successful download consumes exactly 1 unit', () async {
      // Get initial usage
      final initial = await ResumeLimitService.instance.getUserResumeUsage();
      expect(initial['daily_limit'], 4);
      expect(initial['allowed'], true);

      // Generate ATS PDF
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
      );
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);

      // Reserve quota on successful download
      final result1 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(result1.allowed, true);
      expect(result1.usageCount, 1);
      expect(result1.remaining, 3);
    });

    test('TEST 2: Generating PDF Preview 10 times does NOT consume quota', () async {
      final before = await ResumeLimitService.instance.getUserResumeUsage();
      final usedBefore = before['usage_count'];

      // Simulate 10 preview renders
      for (int i = 0; i < 10; i++) {
        final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
          testResume,
          selectedResumeType: ResumeType.fresher,
        );
        expect(pdfBytes.isNotEmpty, isTrue);
      }

      final after = await ResumeLimitService.instance.getUserResumeUsage();
      expect(after['usage_count'], usedBefore);
    });

    test('TEST 3: Editing and saving resume does NOT consume quota', () async {
      final before = await ResumeLimitService.instance.getUserResumeUsage();
      final usedBefore = before['usage_count'];

      // Modify resume data in memory
      final updatedResume = testResume.copyWith(
        summary: 'Updated summary without consuming download quota.',
      );
      expect(updatedResume.summary, contains('Updated summary'));

      final after = await ResumeLimitService.instance.getUserResumeUsage();
      expect(after['usage_count'], usedBefore);
    });

    test('TEST 4 & 5: Download 4 times consumes all quota; 5th download is blocked', () async {
      // User is currently at used: 1, remaining: 3
      // Download 2
      final r2 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(r2.allowed, true);
      expect(r2.usageCount, 2);
      expect(r2.remaining, 2);

      // Download 3
      final r3 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(r3.allowed, true);
      expect(r3.usageCount, 3);
      expect(r3.remaining, 1);

      // Download 4
      final r4 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(r4.allowed, true);
      expect(r4.usageCount, 4);
      expect(r4.remaining, 0);

      // Attempt 5th download -> MUST BE BLOCKED
      final r5 = await ResumeLimitService.instance.checkAndReserveLimit();
      expect(r5.allowed, false);
      expect(r5.usageCount, 4);
      expect(r5.remaining, 0);
      expect(r5.message, contains('Daily resume limit reached'));
    });

    test('TEST 6: Failed generation does not consume quota (refunded if pre-reserved)', () async {
      final before = await ResumeLimitService.instance.getUserResumeUsage();
      expect(before['allowed'], false); // Already exhausted at 4/4

      // Verify refunding restores one slot
      await ResumeLimitService.instance.refundLimit();
      final afterRefund = await ResumeLimitService.instance.getUserResumeUsage();
      expect(afterRefund['usage_count'], 3);
      expect(afterRefund['remaining'], 1);
      expect(afterRefund['allowed'], true);
    });
  });
}
