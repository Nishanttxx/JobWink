import 'gemini_config.dart';

/// Configuration for AI providers and automatic fallback manager.
class AIConfig {
  /// Gemini API Key
  static String geminiApiKey = GeminiConfig.apiKey;

  /// OpenAI API Key (Set manually or via env)
  static String openAiApiKey =
      const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  /// xAI (Grok) API Key
  static String xAiApiKey =
      const String.fromEnvironment('XAI_API_KEY', defaultValue: '');

  /// Groq API Key
  static String groqApiKey =
      const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  /// NVIDIA (Nemotron) API Key
  static String nvidiaApiKey =
      const String.fromEnvironment('NVIDIA_API_KEY', defaultValue: '');

  /// NVIDIA API Base URL
  static String nvidiaBaseUrl = 'https://integrate.api.nvidia.com/v1';

  /// Primary AI provider ('gemini')
  static String primaryProvider = 'gemini';

  /// Fallback AI provider 1 ('openai')
  static String fallbackProvider = 'openai';

  /// Fallback AI provider 2 ('cerebras')
  static String secondaryFallbackProvider = 'cerebras';

  /// Fallback AI provider 3 ('mistral')
  static String tertiaryFallbackProvider = 'mistral';

  /// Forced AI provider for testing ('none', 'gemini', 'openai', 'cerebras', 'mistral')
  static String forceProvider = 'none';

  /// OpenAI model to use for fallback operations
  static String openAiModel = 'gpt-4o-mini';

  /// Gemini model to use for primary operations
  static String geminiModel = GeminiConfig.modelId;

  /// xAI (Grok) model to use for operations
  static String xAiModel = 'grok-2-latest';

  /// Groq model to use for ultra-fast operations
  static String groqModel = 'llama-3.3-70b-versatile';

  /// NVIDIA model to use for operations
  static String nvidiaModel = 'nvidia/nemotron-3-ultra-550b-a55b';

  /// Mistral API Key
  static String mistralApiKey =
      const String.fromEnvironment('MISTRAL_API_KEY', defaultValue: '');
  /// Mistral API Base URL
  static String mistralBaseUrl = 'https://api.mistral.ai/v1';
  /// Mistral model
  static String mistralModel = 'mistral-small-latest';

  /// Cerebras API Key
  static String cerebrasApiKey =
      const String.fromEnvironment('CEREBRAS_API_KEY', defaultValue: '');
  /// Cerebras API Base URL
  static String cerebrasBaseUrl = 'https://api.cerebras.ai/v1';
  /// Cerebras model
  static String cerebrasModel = 'llama-3.3-70b';

  /// HuggingFace Token
  static String huggingFaceToken = '';
  /// HuggingFace Base URL
  static String huggingFaceBaseUrl = 'https://router.huggingface.co/v1';
  /// HuggingFace model
  static String huggingFaceModel = 'Qwen/Qwen3.8-27B:featherless-ai';
}
