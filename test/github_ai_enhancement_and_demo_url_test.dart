import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/services/ai_service.dart';
import 'package:jobwink/services/resume_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHub README Analysis & Max 3 Bullets Tests', () {
    test('1. Extracts at most 3 rich, detailed bullet points from README without repetition', () async {
      const readme = '''
# JobWink
JobWink is an AI-powered job search platform built with Flutter. It features an intelligent resume builder with ATS scoring, Tinder-style job matching, salary prediction, and application tracking — all powered by a multi-provider AI backend and Python FastAPI server.

## Features
- Intelligent resume builder with ATS scoring and real-time formatting
- Interactive swipe-to-apply job matching based on skills vector embeddings
- Comprehensive application tracker with interview pipeline analytics

## Architecture
Built with Flutter frontend, Supabase database, and FastAPI microservices.
''';

      final entry = await AIService.instance.analyzeGithubRepo(
        repoName: 'Jobwink',
        repoDescription: 'JobWink is an AI-powered job search platform built with Flutter.',
        language: 'Dart',
        topics: ['flutter', 'fastapi', 'resume-builder'],
        readmeContent: readme,
        githubUrl: 'https://github.com/Nishanttxx/Jobwink',
        owner: 'Nishanttxx',
        repo: 'Jobwink',
      );

      expect(entry.name, equals('Jobwink'));
      expect(entry.descriptionBullets.length, inInclusiveRange(1, 3));
      expect(entry.descriptionBullets.length, lessThanOrEqualTo(3));

      // Assert no awkward "Developed Jobwink, JobWink is an..." repetitions
      for (final bullet in entry.descriptionBullets) {
        expect(bullet.toLowerCase().contains('jobwink, jobwink is'), isFalse);
        expect(bullet.startsWith('•'), isFalse);
        expect(bullet.startsWith('-'), isFalse);
      }

      // Assert README is retained
      expect(entry.readmeContent, isNotNull);
      expect(entry.readmeContent!.isNotEmpty, isTrue);
    });

    test('2. Missing README produces clean factual fallback without crashing or inventing features', () async {
      final entry = await AIService.instance.analyzeGithubRepo(
        repoName: 'nexus-vector-search',
        repoDescription: 'Semantic vector search engine with cosine similarity ranking',
        language: 'Python',
        topics: ['vector-search', 'embeddings'],
        readmeContent: '',
        githubUrl: 'https://github.com/Nishanttxx/nexus-vector-search',
        owner: 'Nishanttxx',
        repo: 'nexus-vector-search',
      );

      expect(entry.name, equals('Nexus Vector Search'));
      expect(entry.descriptionBullets.length, inInclusiveRange(1, 3));
      expect(entry.technologies, contains('Python'));
      expect(entry.githubUrl, equals('https://github.com/Nishanttxx/nexus-vector-search'));
    });
  });

  group('Improve with AI & Anti-Duplication Tests', () {
    test('3. Anti-duplication comparison detects identical or near-identical bullets', () {
      final original = [
        'Developed an AI-powered job search platform with Flutter and FastAPI.',
        'Implemented resume builder with ATS scoring and real-time formatting.'
      ];
      final identical = [
        '• Developed an AI-powered job search platform with Flutter and FastAPI.',
        '- Implemented resume builder with ATS scoring and real-time formatting.'
      ];

      expect(AIService.areBulletsNearlyIdentical(original, identical), isTrue);

      final different = [
        'Architected an AI-driven career acceleration ecosystem leveraging Flutter and FastAPI.',
        'Engineered ATS scoring pipeline with dynamic keyword optimization algorithms.'
      ];

      expect(AIService.areBulletsNearlyIdentical(original, different), isFalse);
    });

    test('4. improveProjectDescription returns materially enhanced bullets distinct from original', () async {
      final originalBullets = [
        'Built a shopping app with Flutter',
        'Implemented cart functionality and state management'
      ];

      final enhanced = await AIService.instance.improveProjectDescription(
        name: 'Shopping App',
        type: 'Mobile Application',
        technologies: ['Flutter', 'Dart', 'Provider'],
        bullets: originalBullets,
        readmeContent: '# Shopping App\nE-commerce mobile app with product browsing and cart checkout.',
        githubUrl: 'https://github.com/test/shopping-app',
      );

      expect(enhanced.isNotEmpty, isTrue);
      expect(enhanced.length, lessThanOrEqualTo(3));
      expect(AIService.areBulletsNearlyIdentical(originalBullets, enhanced), isFalse);

      // Verify enhanced bullet uses strong action verbs
      final firstEnhanced = enhanced.first;
      expect(firstEnhanced.startsWith('Built a shopping app'), isFalse);
    });
  });

  group('Live Demo URL Persistence & Normalization Tests', () {
    test('5. ProjectEntry correctly parses demoUrl from various JSON key variations', () {
      final json1 = {
        'name': 'JobWink',
        'demoUrl': 'jobwink.vercel.app',
        'githubUrl': 'https://github.com/Nishanttxx/jobwink',
      };
      final p1 = ProjectEntry.fromJson(json1);
      expect(p1.demoUrl, equals('jobwink.vercel.app'));
      expect(p1.effectiveDemoUrl, equals('jobwink.vercel.app'));

      final json2 = {
        'name': 'JobWink',
        'liveDemoUrl': 'https://jobwink.app',
        'github_url': 'https://github.com/Nishanttxx/jobwink',
      };
      final p2 = ProjectEntry.fromJson(json2);
      expect(p2.demoUrl, equals('https://jobwink.app'));
      expect(p2.effectiveDemoUrl, equals('https://jobwink.app'));

      final json3 = {
        'name': 'JobWink',
        'live_demo': 'https://jobwink.dev',
      };
      final p3 = ProjectEntry.fromJson(json3);
      expect(p3.demoUrl, equals('https://jobwink.dev'));
    });

    test('6. ProjectEntry ignores null or undefined string literals for demoUrl', () {
      final jsonNull = {
        'name': 'JobWink',
        'demoUrl': 'null',
        'githubUrl': 'undefined',
      };
      final p = ProjectEntry.fromJson(jsonNull);
      expect(p.demoUrl, isEmpty);
      expect(p.effectiveDemoUrl, isEmpty);
      expect(p.effectiveGithubUrl, isEmpty);
    });

    test('7. ProjectEntry serializes demoUrl and readmeContent in toJson', () {
      final p = ProjectEntry(
        name: 'Nexus Search',
        type: 'Search Engine',
        technologies: ['Dart', 'Redis'],
        descriptionBullets: ['Engineered vector search index'],
        githubUrl: 'https://github.com/example/nexus',
        demoUrl: 'https://nexus.demo.com',
        readmeContent: '# Nexus\nFast vector search engine.',
      );

      final json = p.toJson();
      expect(json['demoUrl'], equals('https://nexus.demo.com'));
      expect(json['githubUrl'], equals('https://github.com/example/nexus'));
      expect(json['readmeContent'], equals('# Nexus\nFast vector search engine.'));

      final restored = ProjectEntry.fromJson(json);
      expect(restored.demoUrl, equals('https://nexus.demo.com'));
      expect(restored.readmeContent, equals('# Nexus\nFast vector search engine.'));
    });
  });

  group('PDF Generation & Clickable Live Demo Hyperlink Tests', () {
    test('8. Live Demo URL appears as a dedicated clickable hyperlink in the generated PDF', () async {
      final resume = ResumeData(
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1 555-0199',
        summary: 'Full Stack Engineer skilled in Flutter and Cloud architectures.',
        skills: ['Flutter', 'Dart', 'FastAPI'],
        projects: [
          ProjectEntry(
            name: 'JobWink Resume Studio',
            type: 'Web Application',
            technologies: ['Flutter', 'FastAPI', 'Supabase'],
            githubUrl: 'https://github.com/Nishanttxx/jobwink',
            demoUrl: 'https://jobwink.vercel.app',
            descriptionBullets: [
              'Developed an AI-powered resume builder and ATS optimization platform.',
              'Implemented real-time scoring and PDF layout calculation engine.'
            ],
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      expect(pdfBytes.isNotEmpty, isTrue);

      final pdfString = String.fromCharCodes(pdfBytes);

      // Verify that Live Demo URL and GitHub URL annotations are embedded in the PDF
      expect(pdfString.contains('https://jobwink.vercel.app'), isTrue,
          reason: 'Live Demo URL must be embedded as a clickable URI annotation in the PDF');
      expect(pdfString.contains('https://github.com/Nishanttxx/jobwink'), isTrue,
          reason: 'GitHub repository URL must also be embedded as a clickable URI annotation in the PDF');
    });

    test('9. Project without Live Demo URL does not render "Live Demo:" or null/undefined in PDF', () async {
      final resume = ResumeData(
        fullName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 555-0188',
        skills: ['Flutter'],
        projects: [
          ProjectEntry(
            name: 'Offline CLI Tool',
            technologies: ['Dart'],
            descriptionBullets: ['Engineered command line utility for log parsing.'],
            githubUrl: 'https://github.com/example/cli-tool',
            demoUrl: '',
          ),
        ],
      );

      final pdfBytes = await ResumeExportService.instance.generateAtsPdf(resume);
      final pdfString = String.fromCharCodes(pdfBytes);

      expect(pdfString.contains('Live Demo:'), isFalse,
          reason: 'Live Demo label must NOT appear when demoUrl is empty');
      expect(pdfString.contains('Live Demo: null'), isFalse);
      expect(pdfString.contains('Live Demo: undefined'), isFalse);
    });
  });
}
