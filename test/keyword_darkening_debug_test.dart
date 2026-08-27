import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
import 'package:jobwink/services/ai_service.dart';
import 'package:jobwink/services/jd_keyword_engine.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testResume = ResumeData(
    fullName: 'Nishant Arya',
    email: 'na6236786@gmail.com',
    phone: '+91 9876543210',
    location: 'Bangalore, India',
    linkedin: 'https://linkedin.com/in/nishant',
    github: 'https://github.com/nishant',
    summary: 'Full-stack software engineer specializing in AI and cloud platforms.',
    skills: ['Flutter', 'Dart', 'Python', 'FastAPI', 'Docker', 'PostgreSQL'],
    experience: [
      ExperienceEntry(
        company: '3skill',
        role: 'AI / ML Engineer',
        location: 'Remote',
        startDate: '2023',
        endDate: 'Present',
        description: [
          'Engineered a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree.',
          'Developed an AI-based hiring prediction system with Python, Docker, and REST APIs.',
        ],
      ),
    ],
    projects: [
      ProjectEntry(
        name: 'Nexus Search',
        type: 'AI Platform',
        descriptionBullets: [
          'Engineered a dynamic AI search engine utilizing the Gemini API and Flutter, implementing advanced Prompt Engineering to optimize the accuracy and reliability of LLM responses.',
          'Developed an interactive querying interface to handle real-time user interactions with React and Generative AI.',
        ],
        technologies: ['Flutter', 'Python', 'Gemini API'],
      ),
    ],
    education: [
      EducationEntry(
        institution: 'NMAM Institute of Technology',
        degree: 'B.Tech',
        fieldOfStudy: 'Computer Science',
        startDate: '2020',
        endDate: '2024',
      ),
    ],
  );

  group('Keyword Darkening Debug & Verification Matrix', () {
    test('Step 3: Critical Hardcode Test - "Flutter" isolated darkening in PDF renderer', () async {
      const hardcodedKeywords = ['Flutter'];

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
        highlightKeywords: hardcodedKeywords,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Step 12: Manual Keyword Test without AI - "Gemini API", "Flutter", "Prompt Engineering", "LLM"', () async {
      const manualKeywords = ['Flutter', 'Gemini API', 'Prompt Engineering', 'LLM'];

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
        highlightKeywords: manualKeywords,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Step 19: Full End-to-End Pipeline with Section 38 Job Description', () async {
      const targetJd = 'We are looking for an AI/ML Software Engineer with experience in Python, Machine Learning, REST APIs, Docker, Git, NLP, Generative AI, LLMs and model deployment.';

      // 1. Analyze JD keywords & weightage
      final analysis = await AIService.instance.analyzeJobKeywords(
        jobDescription: targetJd,
        currentResume: testResume,
        targetJobTitle: 'AI/ML Software Engineer',
      );

      expect(analysis.extractedJobKeywords, isNotEmpty);
      expect(analysis.projectAndExperienceKeywords, isNotEmpty);

      // Verify that matched keywords contain core terms
      expect(analysis.projectAndExperienceKeywords, anyOf([
        contains('Python'),
        contains('Docker'),
        contains('REST APIs'),
        contains('Machine Learning'),
        contains('ML'),
        contains('AI'),
        contains('Generative AI'),
        contains('LLMs'),
        contains('LLM'),
      ]));

      // Verify strict exclusion of Skills and Summary from darkening set
      expect(analysis.projectAndExperienceKeywords, isNot(contains('PostgreSQL'))); // PostgreSQL is only in skills, not in projects/exp of testResume!

      // 2. Generate PDF with extracted keywords
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
        highlightKeywords: analysis.projectAndExperienceKeywords,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Step 20: Contextual Bullet Extraction matches exact reference phrases', () {
      // Reference bullet 1: Gemini API, Flutter, Prompt Engineering, LLM
      const bullet1 = 'Engineered a dynamic AI search engine utilizing the Gemini API and Flutter, implementing advanced Prompt Engineering to optimize the accuracy and reliability of LLM responses.';
      final kws1 = JdKeywordEngine.instance.extractBulletKeywords(bulletText: bullet1);
      expect(kws1, contains('Gemini API'));
      expect(kws1, contains('Flutter'));
      expect(kws1, contains('Prompt Engineering'));
      expect(kws1, contains('LLM'));

      // Reference bullet 2: Generative AI, React
      const bullet2 = 'Developed an interactive querying interface to handle real-time user interactions, focusing on the seamless integration of Generative AI components into a high-performance React frontend.';
      final kws2 = JdKeywordEngine.instance.extractBulletKeywords(bulletText: bullet2);
      expect(kws2, contains('Generative AI'));
      expect(kws2, contains('React'));

      // Reference bullet 3: Logistic Regression, KNN, Decision Tree, GridSearchCV
      const expBullet1 = 'Engineered a predictive ML model for quality classification using Logistic Regression, KNN, and Decision Tree, optimizing hyperparameters via GridSearchCV to boost accuracy.';
      final expKws1 = JdKeywordEngine.instance.extractBulletKeywords(bulletText: expBullet1);
      expect(expKws1, contains('Logistic Regression'));
      expect(expKws1, contains('KNN'));
      expect(expKws1, contains('Decision Tree'));
      expect(expKws1, contains('GridSearchCV'));

      // Reference bullet 4: Supabase, Cloud, Riverpod, real-time synchronization
      const bullet4 = 'Integrated Supabase as a Cloud backend for real-time synchronization of business profiles and inventory, utilizing Riverpod for reactive state management and global data caching.';
      final kws4 = JdKeywordEngine.instance.extractBulletKeywords(bulletText: bullet4);
      expect(kws4, contains('Supabase'));
      expect(kws4, contains('Riverpod'));
      expect(kws4, anyOf(contains('Real-time Synchronization'), contains('Reactive State Management'), contains('Cloud')));
    });

    test('Step 21: Non-technical generic words are never darkened', () {
      const genericText = 'Worked with team to develop application solution using advanced technologies and tools for good systems.';
      final kws = JdKeywordEngine.instance.extractBulletKeywords(bulletText: genericText);
      expect(kws, isEmpty);
    });
  });
}
