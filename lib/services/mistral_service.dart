import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/resume_data.dart';
import 'ai_service.dart';

/// Service wrapping Mistral API via REST endpoint (`https://api.mistral.ai/v1/chat/completions`).
///
/// Provides fallback AI inference using Mistral models for structured resume parsing.
class MistralService {
  static final MistralService instance = MistralService._internal();
  MistralService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _apiKey;

  /// Initializes Mistral service with API Key.
  void initialize(String apiKey) {
    if (apiKey.trim().isNotEmpty) {
      _apiKey = apiKey.trim();
      _isInitialized = true;
      debugPrint('[MistralService] Initialized successfully');
    } else {
      debugPrint('[MistralService] Warning: API key is empty');
    }
  }

  // ---------------------------------------------------------------------------
  // 1. PARSE RESUME
  // ---------------------------------------------------------------------------

  Future<ResumeData?> parseResume(Uint8List bytes, String mimeType) async {
    debugPrint('[MistralService] Processing resume...');

    final cleanText = await AIService.instance.extractTextFromBytesAsync(bytes);
    final prompt = '''
$_parseResumePrompt

RESUME CONTENT / TEXT EXTRACT:
${cleanText.isNotEmpty ? cleanText : "[Binary document uploaded. Extract details accurately.]"}
''';

    debugPrint('[DEBUG-PIPELINE-3] AI REQUEST SENT: provider=Mistral, cleanTextLength=${cleanText.length}');

    try {
      final jsonMap = await generateJsonResponse(prompt);
      final jsonStr = jsonMap != null ? jsonEncode(jsonMap) : null;
      debugPrint('[DEBUG-PIPELINE-4] AI RAW RESPONSE: provider=Mistral, length=${jsonStr?.length ?? 0}, snippet=${jsonStr != null && jsonStr.length > 200 ? jsonStr.substring(0, 200) : jsonStr}');
      if (jsonMap != null) {
        debugPrint('[DEBUG-PIPELINE-5] AI JSON: provider=Mistral, keys=${jsonMap.keys.toList()}');
        final res = ResumeData.fromJson(jsonMap, rawText: cleanText);
        debugPrint('[DEBUG-PIPELINE-6] RESUME MODEL: provider=Mistral, name="${res.fullName}", email="${res.email}", phone="${res.phone}", title="${res.title}", exp=${res.experience.length}');
        return res;
      }
    } catch (e) {
      debugPrint('[MistralService] parseResume error: $e');
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 2. TAILOR RESUME
  // ---------------------------------------------------------------------------

  Future<TailoredResult> tailorResume(
    ResumeData currentResume,
    String targetJobTitle,
    String jobDescription,
  ) async {
    final prompt = '''
You are an expert resume writer and ATS specialist. Tailor the candidate's resume for the target job title "$targetJobTitle".

CANDIDATE RESUME JSON:
${jsonEncode(currentResume.toJson())}

TARGET JOB DESCRIPTION:
$jobDescription

Return a JSON object matching this structure EXACTLY:
{
  "summary": "Optimised summary tailored to the target job",
  "skills": ["Skill1", "Skill2", "Skill3"],
  "suggestedKeywords": ["Keyword1", "Keyword2"],
  "matchScore": 88.5,
  "atsScore": 91.0,
  "experience": [
    {
      "company": "Company Name",
      "role": "Role / Job Title",
      "startDate": "MMM YYYY",
      "endDate": "MMM YYYY or Present",
      "description": ["Action-oriented bullet 1", "Action-oriented bullet 2"]
    }
  ]
}

Ensure all experience entries, skills, and summary are rewritten professionally to highlight relevance to the target job.
Return ONLY valid JSON.
''';

    final jsonMap = await generateJsonResponse(prompt);
    if (jsonMap != null) {
      return TailoredResult.fromJson(jsonMap);
    }
    throw Exception('Mistral failed to generate valid JSON for resume tailoring.');
  }

  // ---------------------------------------------------------------------------
  // 3. ATS ANALYSIS
  // ---------------------------------------------------------------------------

  Future<AtsResult> analyzeAts(
    ResumeData resume, {
    String? jobDescription,
  }) async {
    final prompt = '''
Perform a detailed ATS (Applicant Tracking System) scan and analysis for this candidate resume.

CANDIDATE RESUME:
${jsonEncode(resume.toJson())}

${jobDescription != null && jobDescription.isNotEmpty ? "TARGET JOB DESCRIPTION:\n$jobDescription" : ""}

Return a JSON object with this EXACT structure:
{
  "overallScore": 85,
  "keywordScore": 80,
  "formatScore": 90,
  "contentScore": 85,
  "recommendations": [
    "Actionable recommendation 1",
    "Actionable recommendation 2",
    "Actionable recommendation 3"
  ]
}
Return ONLY valid JSON.
''';

    final jsonMap = await generateJsonResponse(prompt);
    if (jsonMap != null) {
      return AtsResult.fromJson(jsonMap);
    }
    throw Exception('Mistral failed to generate valid JSON for ATS analysis.');
  }

  // ---------------------------------------------------------------------------
  // 4. ENHANCE SUMMARY
  // ---------------------------------------------------------------------------

  Future<String> enhanceSummary(
    String currentSummary,
    List<String> skills,
  ) async {
    final prompt = '''
Rewrite and enhance the following professional summary into a high-impact, 2-3 sentence executive profile statement:

CURRENT SUMMARY:
$currentSummary

CORE SKILLS:
${skills.join(', ')}

Return JSON:
{
  "summary": "Enhanced executive summary paragraph"
}
Return ONLY valid JSON.
''';

    final jsonMap = await generateJsonResponse(prompt);
    if (jsonMap != null && jsonMap['summary'] is String) {
      return jsonMap['summary'] as String;
    }
    throw Exception('Mistral failed to enhance summary.');
  }

  // ---------------------------------------------------------------------------
  // REST API HELPER
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> generateJsonResponse(String prompt) async {
    final apiKey = _apiKey ?? AIConfig.mistralApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[MistralService] Error: Mistral API key is missing');
      return null;
    }

    final model = AIConfig.mistralModel;
    final baseUrl = AIConfig.mistralBaseUrl;
    final url = Uri.parse('$baseUrl/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final text = choices.first['message']['content'] as String?;
          if (text != null && text.isNotEmpty) {
            return _extractJson(text);
          }
        }
      } else {
        debugPrint('[MistralService] REST API error status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (err) {
      debugPrint('[MistralService] REST API call failed: $err');
    }

    return null;
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
6. "projects": Each entry MUST have "name", "description" as array of strings, "technologies" as array, and "url".
7. "education": Each entry MUST have "institution", "degree", "fieldOfStudy", "startDate", "endDate", "gpa".
8. If a section is NOT present in the resume, leave it as an EMPTY array [] or EMPTY string "".
9. DO NOT invent, fabricate, or add placeholder data for missing sections.
10. Return ONLY valid JSON. No markdown, no explanations, no code blocks.
''';
}
