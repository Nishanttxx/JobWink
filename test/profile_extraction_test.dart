import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/widgets/resume_editor/identity_contact_card.dart';
import 'package:jobwink/widgets/resume_editor/professional_summary_card.dart';

void main() {
  group('Profile Extraction Agent - Unit & Widget Tests', () {
    test('1. Full Profile Extraction from Raw Text with Standard and Edge Case Formats', () {
      const rawText = '''
Nishant Arya
Senior Software Engineer
nishaanttx15@gmail.com | (617) 555-0182 | San Francisco, CA
https://linkedin.com/in/nishant-arya | https://github.com/Nishanttxx

SUMMARY
Experienced Full Stack and AI Engineer specializing in Flutter, Dart, and generative AI systems with a proven track record of architecting scalable applications.

EXPERIENCE
Tech Corp | Senior Engineer | Jan 2022 – Present
• Spearheaded mobile and web app development using Flutter.
''';

      final resume = ResumeData.parseFromRawText(rawText);

      expect(resume.fullName, equals('Nishant Arya'));
      expect(resume.email, equals('nishaanttx15@gmail.com'));
      expect(resume.phone, equals('(617) 555-0182'));
      expect(resume.location, equals('San Francisco, CA'));
      expect(resume.title, contains('Senior Software Engineer'));
      expect(resume.linkedin, contains('linkedin.com/in/nishant-arya'));
      expect(resume.github, contains('github.com/Nishanttxx'));
      expect(resume.summary, contains('Experienced Full Stack and AI Engineer'));
    });

    test('2. Phone Extraction Preserves Diverse International and US Parenthetical Formats', () {
      const textWithUsParen = "John Doe\n(617) 555-0182\njohn@example.com";
      final resumeUs = ResumeData.parseFromRawText(textWithUsParen);
      expect(resumeUs.phone, equals('(617) 555-0182'));

      const textWithIntlPlus = "Jane Smith\n+91 8088031526\njane@example.com";
      final resumeIntl = ResumeData.parseFromRawText(textWithIntlPlus);
      expect(resumeIntl.phone, contains('8088031526'));

      const textWithHyphen = "Bob Martin\n+1-555-019-2834\nbob@example.com";
      final resumeHyphen = ResumeData.parseFromRawText(textWithHyphen);
      expect(resumeHyphen.phone, contains('555-019-2834'));
    });

    test('3. Unwraps Nested JSON Maps for Location and Phone in ResumeData.fromJson', () {
      final nestedJson = {
        "fullName": "Alex Morgan",
        "email": "alex.morgan@example.com",
        "phone": {
          "number": "+1 (555) 234-5678",
          "type": "mobile"
        },
        "location": {
          "city": "Seattle",
          "state": "WA",
          "country": "USA",
          "postalCode": "98101"
        },
        "title": "Staff AI Researcher",
        "summary": "AI researcher specializing in LLM optimization and multi-agent orchestration.",
        "linkedin": "https://linkedin.com/in/alexmorgan",
        "github": "https://github.com/alexmorgan"
      };

      final resume = ResumeData.fromJson(nestedJson);

      expect(resume.fullName, equals("Alex Morgan"));
      expect(resume.email, equals("alex.morgan@example.com"));
      expect(resume.phone, equals("+1 (555) 234-5678"));
      expect(resume.location, equals("Seattle, WA, 98101, USA"));
      expect(resume.title, equals("Staff AI Researcher"));
      expect(resume.summary, contains("AI researcher specializing in LLM optimization"));
      expect(resume.linkedin, equals("https://linkedin.com/in/alexmorgan"));
      expect(resume.github, equals("https://github.com/alexmorgan"));
    });

    test('4. Gracefully Handles Missing Phone and Location without Placeholders', () {
      final partialJson = {
        "fullName": "Devon Lane",
        "email": "devon.lane@example.com",
        "phone": "Not specified",
        "location": "[Not provided]",
        "title": "Product Designer",
        "summary": "Design systems lead creating intuitive digital experiences."
      };

      final resume = ResumeData.fromJson(partialJson);

      expect(resume.fullName, equals("Devon Lane"));
      expect(resume.email, equals("devon.lane@example.com"));
      expect(resume.phone, isEmpty);
      expect(resume.location, isEmpty);
      expect(resume.title, equals("Product Designer"));
      expect(resume.summary, equals("Design systems lead creating intuitive digital experiences."));
    });

    testWidgets('5. IdentityContactCard Renders All Profile Fields Including Email', (WidgetTester tester) async {
      final nameController = TextEditingController(text: 'Nishant Arya');
      final emailController = TextEditingController(text: 'nishaanttx15@gmail.com');
      final roleController = TextEditingController(text: 'Senior Software Engineer');
      final phoneController = TextEditingController(text: '+91 8088031526');
      final locationController = TextEditingController(text: 'Bengaluru, India');
      final linkedinController = TextEditingController(text: 'https://linkedin.com/in/nishant-arya');
      final githubController = TextEditingController(text: 'https://github.com/Nishanttxx');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: IdentityContactCard(
                nameController: nameController,
                emailController: emailController,
                roleController: roleController,
                phoneController: phoneController,
                locationController: locationController,
                linkedinController: linkedinController,
                githubController: githubController,
              ),
            ),
          ),
        ),
      );

      // Verify text presence in read mode
      expect(find.text('Identity & Contact'), findsOneWidget);
      expect(find.text('Nishant Arya'), findsOneWidget);
      expect(find.text('nishaanttx15@gmail.com'), findsOneWidget);
      expect(find.text('Senior Software Engineer'), findsOneWidget);
      expect(find.text('+91 8088031526'), findsOneWidget);
      expect(find.text('Bengaluru, India'), findsOneWidget);
      expect(find.text('https://linkedin.com/in/nishant-arya'), findsOneWidget);
      expect(find.text('https://github.com/Nishanttxx'), findsOneWidget);

      // Switch to edit mode
      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      // Verify text fields are editable and populated
      expect(find.byType(TextField), findsNWidgets(7));
    });

    testWidgets('6. ProfessionalSummaryCard Renders Title and Summary with AI Enhance Button', (WidgetTester tester) async {
      final titleController = TextEditingController(text: 'AI Solutions Architect');
      final summaryController = TextEditingController(text: 'Experienced engineer with expertise in LLMs.');
      bool enhanceCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfessionalSummaryCard(
                titleController: titleController,
                summaryController: summaryController,
                onAiEnhance: () => enhanceCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Professional Summary'), findsOneWidget);
      expect(find.text('AI Enhance Summary'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.tap(find.text('AI Enhance Summary'));
      expect(enhanceCalled, isTrue);
    });
  });
}
