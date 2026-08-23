import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/resume_data.dart';
import 'ai_service.dart';

/// Service wrapping xAI (Grok) API via direct HTTP REST endpoint (`https://api.x.ai/v1/chat/completions`).
///
/// Implements the exact same operations as [GeminiService] and [OpenAIService]:
/// 1. [parseResume]
/// 2. [tailorResume]
/// 3. [analyzeAts]
/// 4. [enhanceSummary]
class XAiService {
  static final XAiService instance = XAiService._internal();
  XAiService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _apiKey;

  /// Initializes xAI service with API Key.
  void initialize(String apiKey) {
    if (apiKey.trim().isNotEmpty) {
      _apiKey = apiKey.trim();
      _isInitialized = true;
      debugPrint('[XAiService] Initialized successfully');
    } else {
      debugPrint('[XAiService] Warning: API key is empty');
    }
  }

  // ---------------------------------------------------------------------------
  // 1. PARSE RESUME
  // ---------------------------------------------------------------------------

  Future<ResumeData?> parseResume(Uint8List bytes, String mimeType) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[XAiService] Processing resume...');

    final cleanText = await AIService.instance.extractTextFromBytesAsync(bytes);
    final prompt = '''
$_parseResumePrompt

RESUME CONTENT / TEXT EXTRACT:
${cleanText.isNotEmpty ? cleanText : "[Binary document uploaded. Extract details accurately.]"}
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null) {
        debugPrint('[XAiService] parseResume succeeded in ${stopwatch.elapsedMilliseconds}ms');
        return ResumeData.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('[XAiService] parseResume error: $e');
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
    throw Exception('xAI failed to generate valid JSON for resume tailoring.');
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
    throw Exception('xAI failed to generate valid JSON for ATS analysis.');
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
    throw Exception('xAI failed to enhance summary.');
  }

  // ---------------------------------------------------------------------------
  // REST API HELPER
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> generateJsonResponse(String prompt) async {
    final apiKey = _apiKey ?? AIConfig.xAiApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[XAiService] Error: xAI API key is missing');
      return null;
    }

    final model = AIConfig.xAiModel;
    final url = Uri.parse('https://api.x.ai/v1/chat/completions');

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
          'temperature': 0.2,
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
        debugPrint('[XAiService] REST API error status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (err) {
      debugPrint('[XAiService] REST API call failed: $err');
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
Analyse this resume document completely and extract candidate information into JSON:

{
  "fullName": "",
  "email": "",
  "phone": "",
  "location": "",
  "linkedin": "",
  "github": "",
  "title": "",
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

CRITICAL RULES FOR VERBATIM EXTRACTION & SECTION ACCURACY:
1. VERBATIM TEXT EXTRACTION: Extract text EXACTLY as written in the uploaded resume document. DO NOT rewrite, paraphrase, rephrase, summarize, embellish, improve grammar, or alter wordings.
2. ONLY FILL AVAILABLE SECTIONS: Extract and populate ONLY the sections that are explicitly present in the uploaded resume document. If a section (such as Education, Experience, Projects, Skills, Summary, Certifications, or Extracurriculars) is NOT present in the resume, leave it as an EMPTY array [] or EMPTY string "".
3. ABSOLUTELY NO FABRICATION OR DUMMY DATA: DO NOT invent, assume, infer, extrapolate, or populate dummy, placeholder, synthetic, or default data for missing fields or missing sections.
4. "fullName", "email", "phone", "location", "linkedin", "github": Extract contact details ONLY if present in the document.
5. "summary": Extract the summary / objective paragraph ONLY if explicitly present in the document verbatim. Leave empty "" if omitted.
6. "skills": Extract ONLY technical / professional skills explicitly listed in the resume.
7. "experience": Include ONLY employment / work history entries present in the resume. Each job/role MUST be exactly one object with all its description bullet points grouped under "description".
8. "projects": Include ONLY projects present in the resume. Each project MUST be exactly one structured object with short title in "name", repo/link in "url", and all bullet points grouped under "description". NEVER split a project's bullet points, sentences, or bold keywords into multiple project objects.
9. "education": Include ONLY academic entries present in the resume. Group institution, degree, dates, and GPA together.
10. "certifications" & "extracurriculars": Include ONLY certifications, activities, or awards present in the resume.
11. CRITICAL GROUPING RULE: Return exactly one object per real project and one object per job role. Never create separate objects for description sentences, technologies, or keywords.
12. Return ONLY valid JSON adhering strictly to the schema above.
''';
}
