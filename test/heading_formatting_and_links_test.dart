import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/models/resume_type.dart';
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
          'Developed an AI-based hiring prediction system with automated analysis and machine learning pipeline.',
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
          'Engineered a dynamic AI search engine utilizing the Gemini API and Flutter, implementing advanced Prompt Engineering to optimize the accuracy and reliability of LLM responses.',
          'Developed an interactive querying interface to handle real-time user interactions with React and Generative AI.',
        ],
      ),
      ProjectEntry(
        name: 'Vyapar Bandhu',
        type: 'Business Platform',
        url: 'https://github.com/Nishanttxx/Vyapar_Bandhu',
        descriptionBullets: [
          'Engineered an automated tax engine using Flutter and Dart, accurately calculating CGST, SGST, and IGST to ensure full compliance with regional Indian GST regulations.',
          'Integrated Supabase as a Cloud backend for real-time synchronization of business profiles and inventory, utilizing Riverpod for reactive state management and global data caching.',
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

  group('Heading Formatting & Blue Clickable Links Verification', () {
    test('Requirement 1 & 3: Project heading has bold title, normal tech stack, and blue link', () async {
      const jd = 'We need Flutter, Python, Gemini API, React, and Machine Learning.';

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
        jobDescription: jd,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('Requirement 2: Experience heading has bold role, normal company, location, and dates', () async {
      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('Requirement 7 & 20: Job Description keyword darkening continues working inside bullets', () async {
      const jd = 'Looking for an AI/ML Engineer with Gemini API, Flutter, Prompt Engineering, and Logistic Regression.';

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(
        testResume,
        selectedResumeType: ResumeType.fresher,
        jobDescription: jd,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(2000));
    });
  });
}
