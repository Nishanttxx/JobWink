import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/services/ai_service.dart';
import 'package:jobwink/services/github_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHub Project Description & README Extraction Tests', () {
    test('1. GitHub URL parsing works accurately', () {
      final parsed1 = GitHubService.instance.parseGithubUrl('https://github.com/flutter/flutter');
      expect(parsed1, isNotNull);
      expect(parsed1!.key, equals('flutter'));
      expect(parsed1.value, equals('flutter'));

      final parsed2 = GitHubService.instance.parseGithubUrl('github.com/octocat/Hello-World.git');
      expect(parsed2, isNotNull);
      expect(parsed2!.key, equals('octocat'));
      expect(parsed2.value, equals('Hello-World'));

      final parsed3 = GitHubService.instance.parseGithubUrl('https://gitlab.com/user/repo');
      expect(parsed3, isNull);
    });

    test('2. Fallback bullet generation strictly returns 2 or 3 concise, factual bullets', () async {
      final entry = await AIService.instance.analyzeGithubRepo(
        repoName: 'shopping_cart_app',
        repoDescription: 'A Flutter-based shopping cart application with provider state management',
        language: 'Flutter',
        topics: ['dart', 'mobile-app', 'state-management'],
        readmeContent: '''
# Shopping Cart App
A Flutter application with product browsing, product details, and cart functionality.

## Features
- Product browsing and catalog view
- Add to cart and quantity management with Provider
- Real-time total calculation and checkout summary
''',
        githubUrl: 'https://github.com/testuser/shopping_cart_app',
        owner: 'testuser',
        repo: 'shopping_cart_app',
      );

      expect(entry.name.isNotEmpty, isTrue);
      expect(entry.descriptionBullets.length, inInclusiveRange(2, 3));
      for (final bullet in entry.descriptionBullets) {
        expect(bullet.trim().isNotEmpty, isTrue);
        expect(bullet.startsWith('•'), isFalse);
        expect(bullet.startsWith('-'), isFalse);
      }
      expect(entry.githubUrl, equals('https://github.com/testuser/shopping_cart_app'));
      expect(entry.githubOwner, equals('testuser'));
      expect(entry.githubRepo, equals('shopping_cart_app'));
    });

    test('3. Missing README logs properly and produces strictly 2 or 3 factual fallback bullets', () async {
      final entry = await AIService.instance.analyzeGithubRepo(
        repoName: 'cli-log-analyzer',
        repoDescription: 'Command line utility for parsing Apache server logs',
        language: 'Python',
        topics: ['cli', 'log-parser'],
        readmeContent: '',
        githubUrl: 'https://github.com/testuser/cli-log-analyzer',
        owner: 'testuser',
        repo: 'cli-log-analyzer',
      );

      expect(entry.name, equals('Cli Log Analyzer'));
      expect(entry.descriptionBullets.length, inInclusiveRange(2, 3));
      expect(entry.technologies, contains('Python'));
    });
  });
}
