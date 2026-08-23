import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import '../models/resume_data.dart';
import 'ai_service.dart';

/// Exception thrown when Gemini API quota or rate limit is exceeded.
class GeminiQuotaExceededException implements Exception {
  final String message;
  GeminiQuotaExceededException([this.message = 'Gemini quota or rate limit exceeded']);
  @override
  String toString() => 'GeminiQuotaExceededException: $message';
}

/// Singleton service wrapping the Google Gemini Generative AI SDK.
class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialises the Gemini model. Call once at app startup.
  void initialize(String apiKey, {String modelId = GeminiConfig.modelId}) {
    if (_isInitialized && _model != null) return;
    _model = GenerativeModel(
      model: modelId,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topP: 0.95,
        responseMimeType: 'application/json',
      ),
    );
    _isInitialized = true;
    debugPrint('[GeminiService] Initialized with model: $modelId');
  }

  /// Public method to execute a text prompt and return raw text response.
  Future<String?> generatePrompt(String promptText) async {
    if (_model == null) {
      initialize(GeminiConfig.apiKey, modelId: GeminiConfig.modelId);
    }
    try {
      final res = await _generateContentWithRetry([Content.text(promptText)]);
      return res.text;
    } catch (e) {
      debugPrint('[GeminiService] generatePrompt error: $e');
      return null;
    }
  }

  /// Public helper to extract JSON map from text response.
  Map<String, dynamic>? extractJson(String responseText) {
    var raw = responseText.trim();
    if (raw.startsWith('```json')) {
      raw = raw.substring(7);
    } else if (raw.startsWith('```')) {
      raw = raw.substring(3);
    }
    if (raw.endsWith('```')) {
      raw = raw.substring(0, raw.length - 3);
    }
    raw = raw.trim();

    final jsonStart = raw.indexOf('{');
    final jsonEnd = raw.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      raw = raw.substring(jsonStart, jsonEnd + 1);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      debugPrint('[GeminiService] JSON parse error: $e');
    }
    return null;
  }

  /// Helper method that calls Gemini with automatic exponential backoff retry and model fallback when encountering 503 high demand or timeouts.
  Future<GenerateContentResponse> _generateContentWithRetry(
    List<Content> contents, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (_model == null) {
          initialize(GeminiConfig.apiKey, modelId: GeminiConfig.modelId);
        }
        return await _model!.generateContent(contents).timeout(timeout);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        final isQuota = errStr.contains('429') ||
            errStr.contains('resource_exhausted') ||
            errStr.contains('quota') ||
            errStr.contains('rate limit') ||
            errStr.contains('limit exceeded') ||
            errStr.contains('over_quota');

        if (isQuota) {
          debugPrint('[GeminiService] Gemini quota exceeded detected');
          throw GeminiQuotaExceededException(e.toString());
        }

        final is503 = errStr.contains('503') || errStr.contains('unavailable') || errStr.contains('high demand');
        final isTimeout = e is TimeoutException || errStr.contains('timeoutexception');

        if ((is503 || isTimeout) && attempt < maxAttempts) {
          debugPrint('[GeminiService] API spike/timeout (attempt $attempt/$maxAttempts). Retrying in ${attempt * 1000}ms...');
          await Future.delayed(Duration(milliseconds: attempt * 1000));
          
          try {
            initialize(GeminiConfig.apiKey, modelId: GeminiConfig.modelId);
          } catch (_) {}
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Gemini API failed after $maxAttempts attempts');
  }

  // ---------------------------------------------------------------------------
  // 1. PARSE RESUME — Extract structured data from PDF / image
  // ---------------------------------------------------------------------------

  Future<ResumeData?> parseResume(Uint8List bytes, String mimeType) async {
    if (_model == null) {
      debugPrint('[GeminiService] Not initialized — auto-initializing with GeminiConfig');
      initialize(GeminiConfig.apiKey, modelId: GeminiConfig.modelId);
    }

    try {
      final prompt = TextPart(_parseResumePrompt);

      String resolvedMime = mimeType.toLowerCase().trim();
      if (resolvedMime.isEmpty || resolvedMime == 'application/octet-stream') {
        resolvedMime = 'application/pdf';
      }

      final cleanText = await AIService.extractTextFromBytesAsyncStatic(bytes);
      debugPrint('[DEBUG-PIPELINE-3] AI REQUEST SENT: provider=Gemini, mimeType=$resolvedMime, cleanTextLength=${cleanText.length}');

      if (resolvedMime == 'application/pdf' || resolvedMime.startsWith('image/')) {
        try {
          final filePart = DataPart(resolvedMime, bytes);
          final response = await _generateContentWithRetry([
            Content.multi([prompt, filePart]),
          ], timeout: const Duration(seconds: 15));

          final text = response.text;
          debugPrint('================ RAW AI RESUME RESPONSE ================');
          debugPrint(text ?? '[NULL/EMPTY RESPONSE]');
          debugPrint('=========================================================');
          debugPrint('[DEBUG-PIPELINE-4] AI RAW RESPONSE: provider=Gemini (Multimodal), length=${text?.length ?? 0}');
          if (text != null && text.isNotEmpty) {
            final jsonMap = _extractJson(text);
            debugPrint('[DEBUG-PIPELINE-5] AI JSON: provider=Gemini (Multimodal), decodedMapKeys=${jsonMap?.keys.toList()}');
            if (jsonMap != null) {
              final res = ResumeData.fromJson(jsonMap, rawText: cleanText);
              debugPrint('[DEBUG-PIPELINE-6] RESUME MODEL: provider=Gemini (Multimodal), name="${res.fullName}", email="${res.email}", phone="${res.phone}", title="${res.title}", location="${res.location}", summary="${res.summary}", skills=${res.skills.length}, exp=${res.experience.length}, edu=${res.education.length}, proj=${res.projects.length}');
              return res;
            }
          }
        } on GeminiQuotaExceededException {
          rethrow;
        } catch (e) {
          debugPrint('[GeminiService] Multimodal DataPart failed ($e). Attempting fast text extraction...');
        }
      }

      if (cleanText.length > 15) {
        try {
          final textPrompt = '$_parseResumePrompt\n\nRESUME CONTENT:\n$cleanText';
          final response = await _generateContentWithRetry([
            Content.text(textPrompt),
          ], timeout: const Duration(seconds: 12));

          final text = response.text;
          debugPrint('================ RAW AI RESUME RESPONSE ================');
          debugPrint(text ?? '[NULL/EMPTY RESPONSE]');
          debugPrint('=========================================================');
          debugPrint('[DEBUG-PIPELINE-4] AI RAW RESPONSE: provider=Gemini (Text-Fallback), length=${text?.length ?? 0}');
          if (text != null && text.isNotEmpty) {
            final jsonMap = _extractJson(text);
            debugPrint('[DEBUG-PIPELINE-5] AI JSON: provider=Gemini (Text-Fallback), decodedMapKeys=${jsonMap?.keys.toList()}');
            if (jsonMap != null) {
              final res = ResumeData.fromJson(jsonMap, rawText: cleanText);
              debugPrint('[DEBUG-PIPELINE-6] RESUME MODEL: provider=Gemini (Text-Fallback), name="${res.fullName}", email="${res.email}", phone="${res.phone}", title="${res.title}", location="${res.location}", summary="${res.summary}", skills=${res.skills.length}, exp=${res.experience.length}, edu=${res.education.length}, proj=${res.projects.length}');
              return res;
            }
          }
        } on GeminiQuotaExceededException {
          rethrow;
        } catch (e) {
          debugPrint('[GeminiService] Text-fallback parse failed ($e)');
        }
      }

      return null;
    } on GeminiQuotaExceededException {
      rethrow;
    } catch (e, stack) {
      debugPrint('[GeminiService] parseResume error: $e');
      debugPrint('$stack');
      return null;
    }
  }



  // ---------------------------------------------------------------------------
  // 2. TAILOR RESUME — Optimise for a specific job posting
  // ---------------------------------------------------------------------------

  Future<TailoredResult> tailorResume(
    ResumeData currentResume,
    String targetJobTitle,
    String jobDescription,
  ) async {
    if (_model == null) {
      return const TailoredResult(matchScore: 50, atsScore: 50);
    }

    try {
      final prompt = '''
You are an expert ATS resume optimiser.

Given the candidate's current resume data and a target job posting, produce a tailored version that maximises ATS match score.

CURRENT RESUME:
```json
${jsonEncode(currentResume.toJson())}
```

TARGET JOB TITLE: $targetJobTitle

TARGET JOB DESCRIPTION:
$jobDescription

Return a JSON object with EXACTLY these fields:
{
  "summary": "An ATS-optimised professional summary (2-4 sentences) that naturally incorporates keywords from the job description",
  "skills": ["list", "of", "all", "skills", "the candidate should highlight", "including existing ones and new relevant ones"],
  "suggestedKeywords": ["additional", "keywords", "from the job description", "not yet in the resume"],
  "matchScore": 92.5,
  "atsScore": 94.0,
  "experience": [{"company":"...","role":"...","startDate":"...","endDate":"...","description":["bullet points optimised for this job"]}]
}

Rules:
- matchScore and atsScore should be realistic percentages (0-100) based on how well the resume matches
- Keep all factual information accurate — do NOT invent experience
- Optimise bullet points to use action verbs and quantified achievements
- Include ALL existing skills plus new relevant ones from the job description
- suggestedKeywords should only contain keywords NOT already in skills
- Return ONLY the JSON object, no markdown or explanation
''';

      final response = await _generateContentWithRetry([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        return const TailoredResult(matchScore: 75, atsScore: 75);
      }

      final jsonMap = _extractJson(text);
      if (jsonMap == null) {
        return const TailoredResult(matchScore: 75, atsScore: 75);
      }

      return TailoredResult.fromJson(jsonMap);
    } on GeminiQuotaExceededException {
      rethrow;
    } catch (e) {
      debugPrint('[GeminiService] tailorResume error: $e');
      return const TailoredResult(matchScore: 60, atsScore: 60);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. ATS ANALYSIS — Score resume for ATS compatibility
  // ---------------------------------------------------------------------------

  Future<AtsResult> analyzeAts(
    ResumeData resume, {
    String? jobDescription,
  }) async {
    if (_model == null) {
      return const AtsResult(
          overallScore: 50,
          keywordScore: 50,
          formatScore: 50,
          contentScore: 50);
    }

    try {
      final jdSection = jobDescription != null && jobDescription.isNotEmpty
          ? '\nTARGET JOB DESCRIPTION:\n$jobDescription'
          : '';

      final prompt = '''
You are an ATS (Applicant Tracking System) expert analyser.

Analyse this resume for ATS compatibility and return scores.

RESUME DATA:
```json
${jsonEncode(resume.toJson())}
```
$jdSection

Return a JSON object with EXACTLY these fields:
{
  "overallScore": 82,
  "keywordScore": 88,
  "formatScore": 95,
  "contentScore": 78,
  "recommendations": [
    "Add quantified achievements to experience bullet points",
    "Include industry-specific certifications",
    "..."
  ]
}

Rules:
- Scores are integers 0-100
- overallScore is a weighted average (keyword: 40%, format: 25%, content: 35%)
- Be realistic — most resumes score 60-85
- Provide 3-5 actionable, specific recommendations
- Return ONLY the JSON object
''';

      final response = await _generateContentWithRetry([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        return const AtsResult(
            overallScore: 70,
            keywordScore: 70,
            formatScore: 80,
            contentScore: 65);
      }

      final jsonMap = _extractJson(text);
      if (jsonMap == null) {
        return const AtsResult(
            overallScore: 70,
            keywordScore: 70,
            formatScore: 80,
            contentScore: 65);
      }

      return AtsResult.fromJson(jsonMap);
    } on GeminiQuotaExceededException {
      rethrow;
    } catch (e) {
      debugPrint('[GeminiService] analyzeAts error: $e');
      return const AtsResult(
          overallScore: 65,
          keywordScore: 65,
          formatScore: 75,
          contentScore: 60);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. ENHANCE SUMMARY — AI-rewrite professional summary
  // ---------------------------------------------------------------------------

  Future<String> enhanceSummary(
    String currentSummary,
    List<String> skills,
  ) async {
    if (_model == null) return currentSummary;

    try {
      final prompt = '''
You are a professional resume writer. Rewrite this professional summary to be more impactful, concise, and ATS-optimised.

CURRENT SUMMARY:
$currentSummary

CANDIDATE'S SKILLS: ${skills.join(', ')}

Rules:
- Keep it 2-4 sentences
- Use strong action-oriented language
- Naturally incorporate key skills
- Include quantified achievements where possible
- Make it compelling for both ATS systems and human recruiters
- Return a JSON object: {"summary": "your enhanced summary here"}
- Return ONLY the JSON object
''';

      final response = await _generateContentWithRetry([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) return currentSummary;

      final jsonMap = _extractJson(text);
      if (jsonMap != null && jsonMap.containsKey('summary')) {
        return jsonMap['summary'] as String? ?? currentSummary;
      }

      return currentSummary;
    } on GeminiQuotaExceededException {
      rethrow;
    } catch (e) {
      debugPrint('[GeminiService] enhanceSummary error: $e');
      return currentSummary;
    }
  }

  Map<String, dynamic>? _extractJson(String text) {
    try {
      return jsonDecode(text.trim()) as Map<String, dynamic>;
    } catch (_) {
      try {
        var cleaned = text.trim();
        if (cleaned.startsWith('```')) {
          cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
          cleaned = cleaned.replaceFirst(RegExp(r'\n?```\s*$'), '');
        }
        return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
      } catch (_) {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (match != null) {
          try {
            return jsonDecode(match.group(0)!) as Map<String, dynamic>;
          } catch (_) {}
        }
        return null;
      }
    }
  }

  static const String _parseResumePrompt = '''
Analyse this resume document completely and extract ALL candidate information into a single flat JSON object.

Return ONLY a JSON object with EXACTLY this structure:

{
  "fullName": "",
  "title": "",
  "email": "",
  "phone": "",
  "location": "",
  "linkedin": "",
  "github": "",
  "summary": "",
  "skills": [],
  "experience": [
    {
      "company": "",
      "role": "",
      "startDate": "",
      "endDate": "",
      "description": []
    }
  ],
  "projects": [
    {
      "name": "",
      "description": [],
      "technologies": [],
      "url": ""
    }
  ],
  "education": [
    {
      "institution": "",
      "degree": "",
      "fieldOfStudy": "",
      "startDate": "",
      "endDate": "",
      "gpa": ""
    }
  ],
  "certifications": [
    {
      "name": "",
      "issuer": "",
      "date": "",
      "description": ""
    }
  ],
  "extracurriculars": [
    {
      "activity": "",
      "organization": "",
      "role": "",
      "description": ""
    }
  ]
}

CRITICAL RULES:
1. Extract text EXACTLY as written. DO NOT rewrite, paraphrase, or alter wordings.
2. "fullName": The candidate's full name as it appears at the top of the resume.
3. "title": The candidate's job title, professional title, or headline if present.
4. "skills": An array of individual skill strings (e.g. ["Python", "React", "AWS"]).
5. "experience": Each entry MUST have "company", "role", "startDate", "endDate", and "description" as an array of bullet point strings.
6. "projects": Each project entry MUST be an independent structured object:
   - "name": Short title of the project ONLY (e.g. "Nexus Search", "AI Search Platform"). NEVER put long descriptions, sentences, or repository URLs into "name".
   - "description": Array of description bullet strings ONLY.
   - "url": Project or GitHub repository URL (e.g. "github.com/Nishanttxx/Nexus-Searchh").
   - "technologies": Array of technologies used in that project.
7. "education": Each entry MUST have "institution", "degree", "fieldOfStudy", "startDate", "endDate", "gpa".
8. If a section is NOT present in the resume, leave it as an EMPTY array [] or EMPTY string "".
9. DO NOT invent, fabricate, or add placeholder data for missing sections.
10. CRITICAL GROUPING RULE: Return exactly one object per semantic resume record. NEVER create objects for individual description sentences, technologies, keywords, or line fragments.
    - Projects: Exactly one project object per actual project. Group all description bullets and details under that single project object.
    - Experience: Exactly one object per job/internship/role. Group all its bullet points under "description".
    - Education: Exactly one object per degree/school. Group institution, degree, dates, and GPA together.
    - Extracurriculars: Group multi-line descriptions into a single extracurricular object.
11. Return ONLY valid JSON. No markdown, no explanations, no code blocks.
''';
}
