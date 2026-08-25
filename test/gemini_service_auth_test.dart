import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/services/gemini_service.dart';

void main() {
  group('GeminiService Authentication & Initialization Tests', () {
    test('Empty API key does not initialize GeminiService or create unauthenticated model', () {
      final service = GeminiService.instance;
      service.initialize('');
      expect(service.isInitialized, isFalse);
    });

    test('generatePrompt safely returns null without throwing when uninitialized', () async {
      final service = GeminiService.instance;
      final result = await service.generatePrompt('Hello');
      expect(result, isNull);
    });

    test('GeminiService initializes cleanly when valid key is provided', () {
      final service = GeminiService.instance;
      service.initialize('AIzaSyDummyTestKeyForUnitTestsOnly123456');
      expect(service.isInitialized, isTrue);
    });
  });
}
