import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/config/supabase_config.dart';
import 'package:jobwink/controllers/auth_controller.dart';
import 'package:jobwink/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase OAuth & Authentication Tests', () {
    test('1. SupabaseConfig sanitizes input and detects valid configuration', () {
      expect(SupabaseConfig.url, isA<String>());
      expect(SupabaseConfig.anonKey, isA<String>());

      // Test sanitization rules
      expect(SupabaseConfig.url.contains('"'), isFalse);
      expect(SupabaseConfig.url.contains("'"), isFalse);
      expect(SupabaseConfig.url, isNot(equals('null')));
      expect(SupabaseConfig.url, isNot(equals('undefined')));
    });

    test('2. Uninitialized Supabase produces clear non-silent error when OAuth is clicked', () async {
      // Supabase is not initialized in this local test environment
      expect(SupabaseService.instance.isInitialized, isFalse);

      final googleResult = await SupabaseService.instance.signInWithOAuth(OAuthProvider.google);
      expect(googleResult, isFalse);

      final githubResult = await SupabaseService.instance.signInWithOAuth(OAuthProvider.github);
      expect(githubResult, isFalse);
    });

    test('3. AuthController sets error status and helpful message on uninitialized OAuth attempt', () async {
      final controller = AuthController();
      final success = await controller.signInWithGoogle();

      expect(success, isFalse);
      expect(controller.status, equals(AuthStatus.error));
      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage!.contains('Supabase'), isTrue);

      final githubSuccess = await controller.signInWithGithub();
      expect(githubSuccess, isFalse);
      expect(controller.status, equals(AuthStatus.error));
    });

    test('4. Email authentication methods preserve error handling when uninitialized', () async {
      final controller = AuthController();
      final signInResult = await controller.signIn(email: 'test@example.com', password: 'password123');

      expect(signInResult, isFalse);
      expect(controller.status, equals(AuthStatus.error));
    });

    test('5. Dynamic OAuth redirect origin is environment-independent', () {
      // Localhost with port 65457
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'http://localhost:65457'),
        equals('http://localhost:65457/'),
      );

      // Localhost with another arbitrary dynamic port (e.g. 52143)
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'http://localhost:52143'),
        equals('http://localhost:52143/'),
      );

      // Localhost with trailing slash already present
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'http://localhost:65457/'),
        equals('http://localhost:65457/'),
      );

      // 127.0.0.1 IP origin
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'http://127.0.0.1:8080'),
        equals('http://127.0.0.1:8080/'),
      );

      // Production origin (Cloudflare Pages)
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'https://jobwink.pages.dev'),
        equals('https://jobwink.pages.dev/'),
      );

      // Cloudflare Pages branch / preview deployment origin
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'https://preview-123.jobwink.pages.dev'),
        equals('https://preview-123.jobwink.pages.dev/'),
      );

      // Null / empty / fallback origin
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: ''),
        equals('https://jobwink.pages.dev/'),
      );
      expect(
        SupabaseService.resolveOAuthRedirectUrl(customOrigin: 'null'),
        equals('https://jobwink.pages.dev/'),
      );
    });

    test('6. SupabaseConfig validation correctly checks URL and key criteria', () {
      final url = SupabaseConfig.url;
      final anonKey = SupabaseConfig.anonKey;

      if (url.isNotEmpty && anonKey.isNotEmpty) {
        expect(SupabaseConfig.isConfigured, isTrue);
        expect(url.startsWith('http://') || url.startsWith('https://'), isTrue);
        expect(url.endsWith('/'), isFalse);
        expect(anonKey.length, greaterThanOrEqualTo(20));
      } else {
        expect(SupabaseConfig.isConfigured, isFalse);
      }
    });
  });
}
