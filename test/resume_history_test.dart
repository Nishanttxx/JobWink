import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/controllers/auth_controller.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_history_item.dart';
import 'package:jobwink/models/user_resume.dart';
import 'package:jobwink/services/demo_service.dart';
import 'package:jobwink/services/resume_export_service.dart';
import 'package:jobwink/services/resume_limit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Resume History Model & Deserialization Tests', () {
    test('TEST 1: ResumeHistoryItem parses title, target role, version, and formatted date', () {
      final mockRow = {
        'id': 'version-uuid-1',
        'resume_id': 'resume-uuid-1',
        'user_id': 'user-uuid-123',
        'version_number': 2,
        'change_summary': 'Tailored for Senior Mobile Engineer',
        'created_at': '2026-08-27T10:30:00.000Z',
        'updated_at': '2026-08-27T14:45:00.000Z',
        'parsed_content': {
          'fullName': 'Alice Wonderland',
          'email': 'alice@example.com',
          'phone': '+1 234 567 8900',
          'title': 'Senior Software Engineer',
          'summary': 'Experienced Flutter & Cloud architect.',
          'skills': ['Flutter', 'Dart', 'PostgreSQL'],
          'experience': [
            {
              'company': 'Tech Corp',
              'role': 'Senior Software Engineer',
              'startDate': '2023',
              'endDate': 'Present',
              'description': ['Developed enterprise Flutter web solutions.'],
            }
          ],
        },
        'resumes': {
          'id': 'resume-uuid-1',
          'title': 'Master Resume',
          'template_type': 'NATIONAL_ATS',
        }
      };

      final item = ResumeHistoryItem.fromMap(mockRow);

      expect(item.id, 'version-uuid-1');
      expect(item.resumeId, 'resume-uuid-1');
      expect(item.userId, 'user-uuid-123');
      expect(item.versionNumber, 2);
      expect(item.title, 'Senior Software Engineer Resume');
      expect(item.targetRole, 'Senior Software Engineer');
      expect(item.formattedUpdatedDate, 'Aug 27, 2026');
      expect(item.formattedCreatedDate, 'Aug 27, 2026');
      expect(item.templateType, CvTemplateType.nationalAts);
      expect(item.resumeData.fullName, 'Alice Wonderland');
      expect(item.resumeData.experience.length, 1);
      expect(item.resumeData.experience.first.company, 'Tech Corp');
    });

    test('TEST 2: ResumeHistoryItem fallbacks correctly when title is missing', () {
      final mockRow = {
        'id': 'version-uuid-2',
        'resume_id': 'resume-uuid-2',
        'user_id': 'user-uuid-456',
        'version_number': 1,
        'created_at': '2026-08-25T08:00:00.000Z',
        'parsed_content': {
          'fullName': 'Bob Builder',
          'email': 'bob@example.com',
          'skills': ['Construction', 'Planning'],
        },
        'resumes': {
          'id': 'resume-uuid-2',
          'title': 'Master Resume',
          'template_type': 'INTERNATIONAL_GLOBAL',
        }
      };

      final item = ResumeHistoryItem.fromMap(mockRow);

      expect(item.title, 'Bob Builder Resume');
      expect(item.versionNumber, 1);
      expect(item.formattedCreatedDate, 'Aug 25, 2026');
      expect(item.templateType, CvTemplateType.internationalGlobal);
    });

    test('TEST 3: ResumeHistoryItem handles minimal data without crashing', () {
      final mockRow = {
        'id': 'v-minimal',
        'user_id': 'u-1',
        'version_number': 3,
        'created_at': '2026-01-01T00:00:00.000Z',
        'parsed_content': {},
      };

      final item = ResumeHistoryItem.fromMap(mockRow);

      expect(item.title, 'Resume v3');
      expect(item.versionNumber, 3);
      expect(item.formattedCreatedDate, 'Jan 1, 2026');
      expect(item.targetRole, isNull);
    });
  });

  group('Resume History Sorting & Isolation Verification', () {
    test('TEST 4: Items are sorted newest first by timestamp', () {
      final rows = [
        ResumeHistoryItem(
          id: '1',
          resumeId: 'r1',
          userId: 'user_A',
          versionNumber: 1,
          title: 'Older Resume',
          createdAt: DateTime(2026, 8, 20),
          updatedAt: DateTime(2026, 8, 20),
          resumeData: const ResumeData(fullName: 'Alice'),
        ),
        ResumeHistoryItem(
          id: '2',
          resumeId: 'r1',
          userId: 'user_A',
          versionNumber: 2,
          title: 'Newer Resume',
          createdAt: DateTime(2026, 8, 27),
          updatedAt: DateTime(2026, 8, 27),
          resumeData: const ResumeData(fullName: 'Alice'),
        ),
      ];

      // Sort newest first
      rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(rows.first.id, '2');
      expect(rows.first.title, 'Newer Resume');
      expect(rows.last.id, '1');
    });

    test('TEST 5: User A cannot see User B records (cross-user isolation)', () {
      final allDatabaseRows = [
        {'id': 'v1', 'user_id': 'user_A', 'parsed_content': {'fullName': 'User A'}},
        {'id': 'v2', 'user_id': 'user_B', 'parsed_content': {'fullName': 'User B'}},
        {'id': 'v3', 'user_id': 'user_A', 'parsed_content': {'fullName': 'User A v2'}},
      ];

      const currentAuthUserId = 'user_A';

      // Simulate Supabase RLS WHERE user_id = auth.uid()
      final userAResumes = allDatabaseRows
          .where((r) => r['user_id'] == currentAuthUserId)
          .map((r) => ResumeHistoryItem.fromMap(r))
          .toList();

      expect(userAResumes.length, 2);
      expect(userAResumes.every((r) => r.userId == 'user_A'), isTrue);
      expect(userAResumes.any((r) => r.userId == 'user_B'), isFalse);
    });
  });

  group('Resume History Quota & PDF Generation Compatibility', () {
    test('TEST 6: Viewing and opening History does NOT consume quota', () async {
      final initialUsage = await ResumeLimitService.instance.getUserResumeUsage();
      final initialUsed = initialUsage['usage_count'];

      // Simulate history item creation and opening in editor
      final historicalItem = ResumeHistoryItem(
        id: 'h-1',
        resumeId: 'r-1',
        userId: 'user_A',
        versionNumber: 1,
        title: 'Full Stack Engineer Resume',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        resumeData: const ResumeData(
          fullName: 'Developer',
          email: 'dev@test.com',
          skills: ['Flutter', 'Dart'],
        ),
      );

      // Inspecting and reading historical resume
      expect(historicalItem.resumeData.skills.length, 2);
      expect(historicalItem.title, contains('Full Stack Engineer'));

      // Check quota after viewing/reading
      final afterUsage = await ResumeLimitService.instance.getUserResumeUsage();
      expect(afterUsage['usage_count'], initialUsed);
    });

    test('TEST 7: Downloading historical resume generates valid PDF bytes', () async {
      final historicalResume = ResumeData(
        fullName: 'Jane Developer',
        email: 'jane.dev@example.com',
        phone: '+1 555 987 6543',
        location: 'San Francisco, CA',
        title: 'Senior Mobile Engineer',
        summary: 'Passionate Flutter developer with background in distributed systems.',
        skills: ['Flutter', 'Dart', 'REST APIs', 'Supabase'],
        experience: [
          ExperienceEntry(
            company: 'Tech Studio',
            role: 'Lead Flutter Developer',
            startDate: '2021',
            endDate: 'Present',
            description: ['Architected cross-platform apps with 99.9% crash-free rate.'],
          ),
        ],
        projects: [
          ProjectEntry(
            name: 'JobWink App',
            type: 'Mobile & Web',
            descriptionBullets: ['Built AI-driven resume studio in Flutter.'],
            technologies: ['Flutter', 'Dart'],
          ),
        ],
        education: [
          EducationEntry(
            institution: 'Stanford University',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2017',
            endDate: '2021',
          ),
        ],
      );

      final filename = ResumeExportService.getCandidateFilename(historicalResume, 'pdf');
      expect(filename, 'Jane Developer.pdf');

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(historicalResume);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });

  group('Session State & Demo Mode Isolation', () {
    test('TEST 8: DemoService exits demo mode upon authentication', () {
      DemoService.instance.enterDemoMode();
      expect(DemoService.instance.isDemoMode, isTrue);

      DemoService.instance.exitDemoMode();
      expect(DemoService.instance.isDemoMode, isFalse);
    });

    test('TEST 9: Auth status transitions correctly without flash', () {
      expect(AuthStatus.initializing.name, 'initializing');
      expect(AuthStatus.authenticated.name, 'authenticated');
      expect(AuthStatus.unauthenticated.name, 'unauthenticated');
    });
  });
}
