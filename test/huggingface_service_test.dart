import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/config/ai_config.dart';
import 'package:jobwink/services/huggingface_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HuggingFaceService Integration Tests', () {
    test('HuggingFaceService initializes with HF_TOKEN correctly', () {
      final service = HuggingFaceService.instance;
      expect(service.isInitialized, isFalse);

      service.initialize('hf_dummy_token_12345');
      expect(service.isInitialized, isTrue);
    });

    test('AIConfig includes Hugging Face Router configurations', () {
      expect(AIConfig.huggingFaceBaseUrl, equals('https://router.huggingface.co/v1'));
      expect(AIConfig.huggingFaceModel, equals('Qwen/Qwen3.8-27B:featherless-ai'));
    });
  });
}
