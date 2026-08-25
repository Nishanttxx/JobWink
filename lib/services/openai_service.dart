import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/resume_data.dart';
import 'ai_service.dart';

/// Service wrapping OpenAI APIs via official dart_openai SDK and direct REST fallback.
///
/// Implements the exact same operations as [GeminiService]:
/// 1. [parseResume]
/// 2. [tailorResume]
/// 3. [analyzeAts]
/// 4. [enhanceSummary]
class OpenAIService {
  static final OpenAIService instance = OpenAIService._internal();
  OpenAIService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _apiKey;

  /// Initializes OpenAI SDK with API Key.
  void initialize(String apiKey) {
    if (apiKey.trim().isNotEmpty) {
      _apiKey = apiKey.trim();
      OpenAI.apiKey = _apiKey!;
      _isInitialized = true;
      debugPrint('[OpenAIService] Initialized successfully');
    } else {
      debugPrint('[OpenAIService] Warning: API key is empty');
    }
  }

  // ---------------------------------------------------------------------------
  // 1. PARSE RESUME
  // ---------------------------------------------------------------------------

  Future<ResumeData?> parseResume(Uint8List bytes, String mimeType) async {
    debugPrint('[OpenAIService] Processing resume...');

    final cleanText = await AIService.instance.extractTextFromBytesAsync(bytes);
    final prompt = '''
$_parseResumePrompt

RESUME CONTENT / TEXT EXTRACT:
${cleanText.isNotEmpty ? cleanText : "[Binary document uploaded. Extract details accurately.]"}
''';

    debugPrint('[DEBUG-PIPELINE-3] AI REQUEST SENT: provider=OpenAI, cleanTextLength=${cleanText.length}');

    try {
      final jsonMap = await generateJsonResponse(prompt);
      final jsonStr = jsonMap != null ? jsonEncode(jsonMap) : null;
      debugPrint('[DEBUG-PIPELINE-4] AI RAW RESPONSE: provider=OpenAI, length=${jsonStr?.length ?? 0}, snippet=${jsonStr != null && jsonStr.length > 200 ? jsonStr.substring(0, 200) : jsonStr}');
      if (jsonMap != null) {
        debugPrint('[DEBUG-PIPELINE-5] AI JSON: provider=OpenAI, keys=${jsonMap.keys.toList()}');
        final res = ResumeData.fromJson(jsonMap, rawText: cleanText);
        debugPrint('[DEBUG-PIPELINE-6] RESUME MODEL: provider=OpenAI, name="${res.fullName}", email="${res.email}", phone="${res.phone}", title="${res.title}", exp=${res.experience.length}');
        return res;
      }
    } catch (e) {
      debugPrint('[OpenAIService] parseResume error: $e');
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
    debugPrint('[OpenAIService] Processing resume tailoring...');

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
- Return ONLY valid JSON
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null) {
        debugPrint('[OpenAIService] Resume tailoring successful');
        return TailoredResult.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('[OpenAIService] tailorResume error: $e');
    }
    return const TailoredResult(matchScore: 70, atsScore: 70);
  }

  // ---------------------------------------------------------------------------
  // 3. ATS ANALYSIS
  // ---------------------------------------------------------------------------

  Future<AtsResult> analyzeAts(
    ResumeData resume, {
    String? jobDescription,
  }) async {
    debugPrint('[OpenAIService] Processing ATS analysis...');

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
- Return ONLY valid JSON
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null) {
        debugPrint('[OpenAIService] ATS analysis successful');
        return AtsResult.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('[OpenAIService] analyzeAts error: $e');
    }
    return const AtsResult(
      overallScore: 70,
      keywordScore: 70,
      formatScore: 80,
      contentScore: 65,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ENHANCE SUMMARY
  // ---------------------------------------------------------------------------

  Future<String> enhanceSummary(
    String currentSummary,
    List<String> skills,
  ) async {
    debugPrint('[OpenAIService] Processing summary enhancement...');

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
- Return ONLY valid JSON
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null && jsonMap.containsKey('summary')) {
        debugPrint('[OpenAIService] Summary enhancement successful');
        return jsonMap['summary'] as String? ?? currentSummary;
      }
    } catch (e) {
      debugPrint('[OpenAIService] enhanceSummary error: $e');
    }
    return currentSummary;
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> generateJsonResponse(String prompt) async {
    final model = AIConfig.openAiModel.isNotEmpty
        ? AIConfig.openAiModel
        : 'gpt-4o-mini';

    // On Flutter Web: always use the secure backend proxy — no key is sent from client.
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/ai/proxy'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'url': 'https://api.openai.com/v1/chat/completions',
            'headers': {'Content-Type': 'application/json'},
            'payload': {
              'model': model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'response_format': {'type': 'json_object'},
              'temperature': 0.2,
            },
          }),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final body = data['body'] as Map<String, dynamic>?;
          final choices = body?['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final text = choices.first['message']['content'] as String?;
            if (text != null && text.isNotEmpty) {
              return _extractJson(text);
            }
          }
        } else if (response.statusCode == 401) {
          debugPrint('[OpenAIService] Backend proxy: OPENAI_API_KEY not configured on server.');
        } else {
          debugPrint('[OpenAIService] Backend proxy error: ${response.statusCode}');
        }
      } catch (err) {
        debugPrint('[OpenAIService] Backend proxy call failed: $err');
      }
      return null;
    }

    // Native/desktop: direct call (key must be provided via initialize())
    final apiKey = _apiKey ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[OpenAIService] Error: OPENAI_API_KEY is not configured');
      return null;
    }

    // Primary attempt using SDK
    try {
      OpenAI.apiKey = apiKey;

      final chatCompletion = await OpenAI.instance.chat.create(
        model: model,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
        responseFormat: {"type": "json_object"},
      ).timeout(const Duration(seconds: 20));

      final text = chatCompletion.choices.first.message.content?.first.text;
      if (text != null && text.isNotEmpty) {
        return _extractJson(text);
      }
    } catch (e) {
      debugPrint('[OpenAIService] SDK call failed ($e), trying REST fallback...');
    }


    // Direct HTTP REST fallback
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
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
          if (text != null) {
            return _extractJson(text);
          }
        }
      } else {
        debugPrint('[OpenAIService] REST API error status: ${response.statusCode}');
      }
    } catch (restErr) {
      debugPrint('[OpenAIService] REST API fallback failed: $restErr');
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
Extract information from THIS uploaded resume ONLY. Infer the structure dynamically from the resume itself.
Do NOT assume any fixed section names, order, or candidate information.

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
      "location": "",
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
1. Extract text EXACTLY as written in this resume. DO NOT rewrite, paraphrase, or alter wordings.
2. "fullName": The candidate's full name as it appears at the top of the resume.
3. "title": The candidate's job title, professional headline, or current role if present.
4. "skills": An array of individual skill strings found in the resume.
5. "experience": Extract all work experience records (full-time, part-time, internships, contract).
   - "company": Employer / organization name.
   - "role": Job title / position held.
   - "startDate" & "endDate": Employment dates as written in the resume.
   - "location": City, state, or country if present.
   - "description": Array of description bullet points. Group all bullets for this job under this single experience object.
6. "projects": Extract all technical, academic, and personal projects.
   - "name": Full name/title of the project. NEVER split a project title across multiple project objects.
   - "description": Array of description bullet strings.
   - "url": Project, GitHub repository, or live demo URL if present.
   - "technologies": Array of technologies/tools used in that project.
7. "education": Extract all educational qualifications.
   - "institution": School, college, university, or institute name.
   - "degree": Degree, diploma, or certificate name.
   - "fieldOfStudy": Major / field / branch if present.
   - "startDate" & "endDate": Dates or graduation year.
   - "gpa": GPA, percentage, or score if present.
8. "certifications": Extract certifications, licenses, and accredited courses independently.
9. "extracurriculars": Extract extracurricular activities, volunteer work, leadership roles, honors, awards, or publications.
10. If a section is NOT present in the resume, leave it as an EMPTY array [] or EMPTY string "". DO NOT invent or fabricate data.
11. CRITICAL GROUPING RULE: Return exactly one object per semantic resume record. NEVER split description bullets or technologies into separate broken records.
12. Return ONLY valid JSON. No markdown, no conversational commentary.
''';
}
