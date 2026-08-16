import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/services/github_service.dart';

void main() {
  group('GitHubService Parsing Tests', () {
    final service = GitHubService.instance;

    test('1. Full HTTPS GitHub URL', () {
      final res = service.parseGithubUrl('https://github.com/Nishanttxx/Shopping-App');
      expect(res, isNotNull);
      expect(res!.key, equals('Nishanttxx'));
      expect(res.value, equals('Shopping-App'));
    });

    test('2. Full HTTPS GitHub URL with .git extension', () {
      final res = service.parseGithubUrl('https://github.com/Nishanttxx/Shopping-App.git');
      expect(res, isNotNull);
      expect(res!.key, equals('Nishanttxx'));
      expect(res.value, equals('Shopping-App'));
    });

    test('3. github.com shortcut format', () {
      final res = service.parseGithubUrl('github.com/Nishanttxx/Shopping-App');
      expect(res, isNotNull);
      expect(res!.key, equals('Nishanttxx'));
      expect(res.value, equals('Shopping-App'));
    });

    test('4. Short-form owner/repository', () {
      final res = service.parseGithubUrl('Nishanttxx/Shopping-App');
      expect(res, isNotNull);
      expect(res!.key, equals('Nishanttxx'));
      expect(res.value, equals('Shopping-App'));
    });

    test('5. www.github.com prefix', () {
      final res = service.parseGithubUrl('www.github.com/Nishanttxx/Shopping-App');
      expect(res, isNotNull);
      expect(res!.key, equals('Nishanttxx'));
      expect(res.value, equals('Shopping-App'));
    });

    test('6. Trailing slashes and whitespace around valid URL', () {
      final res = service.parseGithubUrl('   https://github.com/Nishanttxx/Shopping-App.git/   ');
      expect(res, isNotNull);
      expect(res!.key, equals('Nishanttxx'));
      expect(res.value, equals('Shopping-App'));
    });

    test('7. Non-GitHub domain (google.com/test)', () {
      final res = service.parseGithubUrl('https://google.com/Nishanttxx/Shopping-App');
      expect(res, isNull);
    });

    test('8. Empty input and whitespace-only input', () {
      expect(service.parseGithubUrl(''), isNull);
      expect(service.parseGithubUrl('    '), isNull);
    });

    test('9. Single username input ("Nishanttxx")', () {
      final repoRes = service.parseGithubUrl('Nishanttxx');
      expect(repoRes, isNull);

      final userRes = service.parseGithubUsername('Nishanttxx');
      expect(userRes, equals('Nishanttxx'));
    });

    test('10. Username with @ symbol ("@Nishanttxx")', () {
      final userRes = service.parseGithubUsername('@Nishanttxx');
      expect(userRes, equals('Nishanttxx'));
    });
  });
}
