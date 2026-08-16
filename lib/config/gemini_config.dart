/// Configuration constants for the Google Gemini AI API.
class GeminiConfig {
  static const String apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String projectNumber = 'REDACTED_GCP_PROJECT_NUMBER';

  /// The Gemini model to use for resume analysis.
  static const String modelId = 'gemini-1.5-flash';
}
