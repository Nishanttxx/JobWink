import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/resume_data.dart';
import '../models/resume_type.dart';
import 'ai_service.dart';

/// Service wrapping Hugging Face Router API (`https://router.huggingface.co/v1/chat/completions`).
///
/// Uses OpenAI-compatible chat completions interface with support for models like
/// `Qwen/Qwen3.8-27B:featherless-ai` and multimodal / text extraction tasks.
class HuggingFaceService {
  static final HuggingFaceService instance = HuggingFaceService._internal();
  HuggingFaceService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _token;

  /// Initializes Hugging Face service with API Token (HF_TOKEN).
  void initialize(String token) {
    if (token.trim().isNotEmpty) {
      _token = token.trim();
      _isInitialized = true;
      debugPrint('[HuggingFaceService] Initialized successfully');
    } else {
      debugPrint('[HuggingFaceService] Warning: HF_TOKEN is empty');
    }
  }

  // ---------------------------------------------------------------------------
  // 1. PARSE RESUME
  // ---------------------------------------------------------------------------

  Future<ResumeData?> parseResume(
    Uint8List bytes,
    String mimeType, {
    String? cleanText,
  }) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[HuggingFaceService] Processing resume...');

    final textExtract = cleanText ?? AIService.extractTextFromBytes(bytes);
    final prompt = '''
$_parseResumePrompt

RESUME CONTENT / TEXT EXTRACT:
${textExtract.isNotEmpty ? textExtract : "[Binary document uploaded. Extract details accurately.]"}
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null) {
        debugPrint('[HuggingFaceService] parseResume succeeded in ${stopwatch.elapsedMilliseconds}ms');
        final data = ResumeData.fromJson(jsonMap);
        if (data.hasUsableData) {
          data.logPipelineSummary();
        }
        return data;
      }
    } catch (e) {
      debugPrint('[HuggingFaceService] parseResume error: $e');
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 2. TAILOR RESUME
  // ---------------------------------------------------------------------------

  Future<TailoredResult> tailorResume(
    ResumeData currentResume,
    String targetJobTitle,
    String jobDescription, {
    ResumeType resumeType = ResumeType.experience,
  }) async {
    final prompt = '''
You are an authoritative, zero-hallucination ATS resume tailoring engine.

ABSOLUTE SOURCE-OF-TRUTH RULES:
1. The uploaded candidate resume JSON provided below is the ONLY SOURCE OF TRUTH.
2. Every single piece of information in the output MUST be traceable to the uploaded resume.
3. NEVER INVENT, ASSUME, FABRICATE, OR MODIFY:
   - Job titles, company names, employment dates, project names, technologies, skills, tools, frameworks.
   - Certifications, degrees, universities, GPAs/CGPAs (e.g. CGPA 7.66 MUST remain 7.66 exactly), percentages, metrics, downtime reductions, revenue numbers.
   - Responsibilities, achievements, awards, client names, team sizes, links, URLs, locations.
4. NEVER INVENT NUMBERS OR ESTIMATED METRICS:
   - If the source resume says "Developed an IIoT-based predictive maintenance concept", DO NOT change it to "reduced downtime by 30%".
   - If no numerical metric exists in the source text, keep the original qualitative description.
5. PRESERVE FACTUAL VALUES EXACTLY:
   - Dates, company names, institution names, degree titles, project titles, and CGPAs must be preserved without altering or rounding.
6. JOB DESCRIPTION (JD) ROLE:
   - The JD ONLY determines which existing experiences, projects, skills, and bullet points to emphasize or order first.
   - If the JD mentions technologies (e.g. React, Docker, AWS) that DO NOT exist in the candidate's resume, DO NOT ADD THEM to the candidate's skills or experience.
7. RESUME TYPE STRUCTURE (${resumeType.displayName}):
   - Reorder and structure EXISTING content to align with ${resumeType.displayName} layout focus: ${resumeType.description}.
   - Do NOT create fake 2nd projects or fake experiences if the resume only has 1.
8. REPHRASING RULE:
   - You may improve grammar and clarity, but MUST preserve factual meaning. If uncertain, KEEP THE ORIGINAL WORDING.

CANDIDATE RESUME JSON (SOURCE OF TRUTH):
${jsonEncode(currentResume.toJson())}

TARGET JOB TITLE: $targetJobTitle

TARGET JOB DESCRIPTION:
$jobDescription

Return a JSON object matching this structure EXACTLY:
{
  "summary": "An ATS-optimised professional summary using ONLY candidate's existing experience and supported keywords",
  "skills": ["Array of skills existing ONLY in candidate's resume, reordered to prioritize relevance to the job description"],
  "suggestedKeywords": ["Only keywords from the job description that ALREADY EXIST or are authentically supported in the candidate's resume"],
  "matchScore": 88.5,
  "atsScore": 91.0,
  "experience": [{"company":"...","role":"...","startDate":"...","endDate":"...","description":["bullet points using ONLY candidate's actual responsibilities"]}]
}
Return ONLY valid JSON.
''';

    final jsonMap = await generateJsonResponse(prompt);
    if (jsonMap != null) {
      return TailoredResult(
        summary: jsonMap['summary'] as String? ?? currentResume.summary,
        skills: (jsonMap['skills'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            currentResume.skills,
        suggestedKeywords: (jsonMap['suggestedKeywords'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        matchScore: (jsonMap['matchScore'] as num?)?.toDouble() ?? 85.0,
        atsScore: (jsonMap['atsScore'] as num?)?.toDouble() ?? 88.0,
        experience: (jsonMap['experience'] as List<dynamic>?)
                ?.map((e) => ExperienceEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            currentResume.experience,
      );
    }
    throw Exception('Hugging Face service failed to generate valid JSON (Token or API error)');
  }

  // ---------------------------------------------------------------------------
  // 3. ENHANCE SUMMARY
  // ---------------------------------------------------------------------------

  Future<String> enhanceSummary(String currentSummary, String jobTitle) async {
    final prompt = '''
Enhance and polish the following professional summary for a candidate targeting the role of "$jobTitle".

CURRENT SUMMARY:
$currentSummary

Return a JSON object:
{
  "enhancedSummary": "The polished 2-3 sentence summary"
}
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null && jsonMap['enhancedSummary'] != null) {
        return jsonMap['enhancedSummary'] as String;
      }
    } catch (e) {
      debugPrint('[HuggingFaceService] enhanceSummary error: $e');
    }

    return currentSummary;
  }

  // ---------------------------------------------------------------------------
  // 4. PREDICT JOBS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> predictJobs(ResumeData resume) async {
    final prompt = '''
Analyze this candidate's resume and predict 3 suitable job roles with match percentages and reasoning.

RESUME DATA:
${jsonEncode(resume.toJson())}

Return a JSON array wrapped in a key "predictions":
{
  "predictions": [
    {
      "title": "Job Title",
      "matchPercentage": 92,
      "reason": "Brief reason why candidate fits this role",
      "requiredSkills": ["Skill1", "Skill2"]
    }
  ]
}
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null && jsonMap['predictions'] is List) {
        return List<Map<String, dynamic>>.from(jsonMap['predictions'] as List);
      }
    } catch (e) {
      debugPrint('[HuggingFaceService] predictJobs error: $e');
    }

    return [];
  }

  // ---------------------------------------------------------------------------
  // 5. CALCULATE ATS SCORE
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> calculateAtsScore(ResumeData resume, {String? targetJobDescription}) async {
    final prompt = '''
Calculate comprehensive ATS score for this resume.

RESUME DATA:
${jsonEncode(resume.toJson())}

${targetJobDescription != null ? "TARGET JOB:\n$targetJobDescription" : ""}

Return a JSON object:
{
  "overallScore": 88,
  "formatScore": 90,
  "contentScore": 85,
  "keywordScore": 88,
  "suggestions": ["Suggestion 1", "Suggestion 2"]
}
''';

    try {
      final jsonMap = await generateJsonResponse(prompt);
      if (jsonMap != null) return jsonMap;
    } catch (e) {
      debugPrint('[HuggingFaceService] calculateAtsScore error: $e');
    }

    return {
      'overallScore': 80,
      'formatScore': 85,
      'contentScore': 80,
      'keywordScore': 75,
      'suggestions': ['Add more quantifiable achievements.'],
    };
  }

  // ---------------------------------------------------------------------------
  // REST API HELPER (OpenAI-compatible chat completions)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> generateJsonResponse(String prompt, {List<Map<String, dynamic>>? messageContent}) async {
    // On Flutter Web: always use the secure backend proxy — no token is sent from client.
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/ai/huggingface'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt, 'model': AIConfig.huggingFaceModel}),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final jsonResult = data['json'] as Map<String, dynamic>?;
          if (jsonResult != null) return jsonResult;
        } else if (response.statusCode == 401) {
          debugPrint('[HuggingFaceService] Backend proxy: HF_TOKEN not configured on server. Skipping provider.');
        } else {
          debugPrint('[HuggingFaceService] Backend proxy error: ${response.statusCode}');
        }
      } catch (err) {
        debugPrint('[HuggingFaceService] Backend proxy call failed: $err');
      }
      return null;
    }

    // Native/desktop: direct call (token must be provided via initialize())
    final token = _token ?? '';
    if (token.trim().isEmpty) {
      debugPrint('[HuggingFaceService] Error: No API token configured');
      return null;
    }

    final url = Uri.parse('${AIConfig.huggingFaceBaseUrl}/chat/completions');
    final dynamic contentPayload = messageContent ?? prompt;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'model': AIConfig.huggingFaceModel,
          'messages': [{'role': 'user', 'content': contentPayload}],
          'max_tokens': 4096,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices.first['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            return _extractJson(content);
          }
        }
      } else {
        debugPrint('[HuggingFaceService] REST API error status: ${response.statusCode}');
      }
    } catch (err) {
      debugPrint('[HuggingFaceService] REST API call failed: $err');
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
7. "experience": Include ONLY employment / work history entries present in the resume, preserving original bullet point text verbatim.
8. "projects": Include ONLY projects present in the resume, preserving original description text verbatim.
9. "education": Include ONLY academic entries present in the resume. Leave missing fields (degree, field, dates) empty if not in text.
10. "certifications" & "extracurriculars": Include ONLY certifications, activities, or awards present in the resume.
11. Return ONLY valid JSON adhering strictly to the schema above.
''';
}
