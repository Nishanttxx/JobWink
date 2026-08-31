import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/user_resume.dart';
import 'package:jobwink/providers/auth_provider.dart';
import 'package:jobwink/screens/resume_editor_screen.dart';
import 'package:jobwink/widgets/resume_preview_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  ResumeData createCompleteResumeData() {
    return ResumeData(
      fullName: 'Alex Candidate',
      email: 'alex@example.com',
      phone: '+1 (555) 019-2834',
      location: 'San Francisco, CA',
      title: 'Senior Flutter Developer',
      summary: 'Experienced cross-platform mobile engineer specialized in Flutter and Dart architectures with 6+ years of building production applications.',
      skills: const ['Flutter', 'Dart', 'State Management', 'REST API', 'Git', 'CI/CD', 'Unit Testing'],
      experience: const [
        ExperienceEntry(
          role: 'Senior Flutter Engineer',
          company: 'Tech Innovations Inc',
          location: 'San Francisco, CA',
          startDate: '2022',
          endDate: 'Present',
          description: ['Architected and scaled Flutter mobile apps serving 500k+ monthly active users with high performance.'],
        ),
        ExperienceEntry(
          role: 'Mobile Software Engineer',
          company: 'AppWorks Studio',
          location: 'San Jose, CA',
          startDate: '2020',
          endDate: '2022',
          description: ['Developed stateful client applications using provider and bloc architecture.'],
        ),
        ExperienceEntry(
          role: 'Junior Dart Developer',
          company: 'InnoTech Solutions',
          location: 'Oakland, CA',
          startDate: '2019',
          endDate: '2020',
          description: ['Built and tested reusable UI widget components.'],
        ),
      ],
      education: const [
        EducationEntry(
          institution: 'University of California, Berkeley',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Computer Science',
          startDate: '2015',
          endDate: '2019',
        ),
      ],
      projects: [
        ProjectEntry(
          name: 'JobWink Mobile App',
          technologies: const ['Flutter', 'Dart', 'Supabase'],
          descriptionBullets: const ['Production AI-powered career platform with sub-second page rendering and ATS tailoring.'],
        ),
        ProjectEntry(
          name: 'OpenSource Widget Suite',
          technologies: const ['Dart', 'Flutter'],
          descriptionBullets: const ['Custom animated components library with 1.2k GitHub stars.'],
        ),
      ],
      extracurriculars: const [
        ExtracurricularEntry(
          activity: 'Bay Area Flutter Meetup',
          role: 'Lead Organizer',
          organization: 'Bay Area Flutter Meetup',
          description: 'Organized monthly tech talks and developer workshops.',
        ),
      ],
    );
  }

  Widget buildTestTree({
    Key? key,
    int initialTab = 0,
    CvTemplateType? template,
    GlobalKey<ResumeEditorScreenState>? editorKey,
  }) {
    return AuthProviderScope(
      authProvider: AuthController(),
      child: MaterialApp(
        home: Scaffold(
          body: ResumeEditorScreen(
            key: editorKey ?? key,
            initialTab: initialTab,
            initialTemplate: template,
          ),
        ),
      ),
    );
  }

  group('Mandatory Job Description Before Export Guard Tests', () {
    testWidgets('1. Empty Job Description blocks navigation to Step 8 (Export) and displays validation SnackBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();

      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      // Populate complete resume data meeting 3 experiences and 2 projects criteria
      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      // Ensure Job Description is completely empty
      expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));

      // Attempt navigation to Step 8 (Export)
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pump(const Duration(milliseconds: 300));

      // Navigation MUST be blocked
      expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));
      expect(find.text('Job Description is required before exporting your resume.'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('2. Whitespace-only Job Description ("   ", "\\n", "\\t") blocks navigation to Step 8 and download', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();

      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      final whitespaceCases = ['   ', '\n', '\t', '  \n\t  \r\n'];

      for (final ws in whitespaceCases) {
        // Navigate to Target Job tab to enter whitespace
        editorKey.currentState!.handleSubSectionSelected(6);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.last, ws);
          await tester.pumpAndSettle();
        }

        // Attempt opening full preview with whitespace
        editorKey.currentState!.openFullPreviewDialog();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Job Description is required before exporting your resume.'), findsOneWidget);
        expect(find.byType(ResumePreviewDialog), findsNothing);

        // Attempt step selection with whitespace
        editorKey.currentState!.handleSubSectionSelected(8);
        await tester.pump(const Duration(milliseconds: 300));

        expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));
      }

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('3. Valid Job Description allows proceeding to Step 8 and opening preview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();

      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      // Navigate to Step 7 (Target Job)
      editorKey.currentState!.handleSubSectionSelected(6);
      await tester.pumpAndSettle();

      // Find Job Description TextField and enter valid text
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      await tester.enterText(
        textFields.last,
        'Seeking a Senior Flutter Developer with experience in state management, cross-platform UI, and REST API integration.',
      );
      await tester.pumpAndSettle();

      // Now proceed to Step 8
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pumpAndSettle();

      // Step 8 is now accessible
      expect(editorKey.currentState!.activeSubSectionIndex, 8);
      expect(find.text('Preview & Export'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('4. Direct instantiation with initialTab = 8 redirects/clamps to Tab 6 when Job Description is empty', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();

      // Attempt direct URL/route entry to tab 8 with no job description
      await tester.pumpWidget(buildTestTree(editorKey: editorKey, initialTab: 8));
      await tester.pumpAndSettle();

      // Must be safely redirected to Tab 6 (Target Job)
      expect(editorKey.currentState!.activeSubSectionIndex, 6);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('5a. Mobile 375px viewport consistently enforces Job Description guard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375 * 2, 812 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();
      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      // Attempt entering export without Job Description
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pump(const Duration(milliseconds: 300));

      expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));
      expect(find.text('Job Description is required before exporting your resume.'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('5b. Mobile 412px viewport consistently enforces Job Description guard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412 * 2, 915 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();
      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      // Attempt entering export without Job Description
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pump(const Duration(milliseconds: 300));

      expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));
      expect(find.text('Job Description is required before exporting your resume.'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('5c. Mobile 430px viewport consistently enforces Job Description guard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430 * 2, 932 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();
      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      // Attempt entering export without Job Description
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pump(const Duration(milliseconds: 300));

      expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));
      expect(find.text('Job Description is required before exporting your resume.'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('6. Existing user: removing/clearing Job Description immediately blocks export again', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;

      final editorKey = GlobalKey<ResumeEditorScreenState>();

      await tester.pumpWidget(buildTestTree(editorKey: editorKey));
      await tester.pumpAndSettle();

      editorKey.currentState!.populateFormFromResume(createCompleteResumeData());
      await tester.pumpAndSettle();

      // 1. Enter valid Job Description
      editorKey.currentState!.handleSubSectionSelected(6);
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      await tester.enterText(
        textFields.last,
        'Full-stack Mobile Engineer proficient in Flutter and Cloud backends.',
      );
      await tester.pumpAndSettle();

      // Proceed to Step 8 -> Allowed
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pumpAndSettle();
      expect(editorKey.currentState!.activeSubSectionIndex, 8);

      // 2. User goes back to Step 7 and clears the Job Description
      editorKey.currentState!.handleSubSectionSelected(6);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, '');
      await tester.pumpAndSettle();

      // 3. Attempt to proceed to Step 8 again -> MUST be blocked
      editorKey.currentState!.handleSubSectionSelected(8);
      await tester.pump(const Duration(milliseconds: 300));

      expect(editorKey.currentState!.activeSubSectionIndex, isNot(8));
      expect(find.text('Job Description is required before exporting your resume.'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
