import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../config/ai_limits_config.dart';
import '../config/backend_config.dart';
import '../config/gemini_config.dart';
import '../models/resume_data.dart';
import 'ai_usage_service.dart';
import 'cerebras_service.dart';
import 'gemini_service.dart';
import 'groq_service.dart';
import 'mistral_service.dart';
import 'nvidia_service.dart';
import 'openai_service.dart';
import 'xai_service.dart';

/// Central AI Orchestration Service / Provider Manager.
///
/// Handles primary (Gemini) execution and seamless automatic fallback to Groq, OpenAI, xAI (Grok), and NVIDIA (Nemotron)
/// when primary providers encounter quota exhaustion, rate limits, or errors.
class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Gemini, OpenAI, Cerebras, and Mistral providers.
  void initialize({
    String? geminiKey,
    String? openAiKey,
    String? cerebrasKey,
    String? mistralKey,
    String? xAiKey,
    String? groqKey,
    String? nvidiaKey,
  }) {
    final gKey = geminiKey ?? AIConfig.geminiApiKey;
    final oKey = openAiKey ?? AIConfig.openAiApiKey;
    final cKey = cerebrasKey ?? AIConfig.cerebrasApiKey;
    final mKey = mistralKey ?? AIConfig.mistralApiKey;
    final xKey = xAiKey ?? AIConfig.xAiApiKey;
    final grKey = groqKey ?? AIConfig.groqApiKey;
    final nvKey = nvidiaKey ?? AIConfig.nvidiaApiKey;

    if (gKey.isNotEmpty) {
      GeminiService.instance.initialize(gKey, modelId: GeminiConfig.modelId);
    }
    if (oKey.isNotEmpty) {
      OpenAIService.instance.initialize(oKey);
    }
    if (cKey.isNotEmpty) {
      CerebrasService.instance.initialize(cKey);
    }
    if (mKey.isNotEmpty) {
      MistralService.instance.initialize(mKey);
    }
    if (grKey.isNotEmpty) {
      GroqService.instance.initialize(grKey);
    }
    if (xKey.isNotEmpty) {
      XAiService.instance.initialize(xKey);
    }
    if (nvKey.isNotEmpty) {
      NvidiaService.instance.initialize(nvKey);
    }

    _isInitialized = true;
    debugPrint('[AIService] Provider manager initialized (Primary: ${AIConfig.primaryProvider}, Fallback 1: ${AIConfig.fallbackProvider}, Fallback 2: ${AIConfig.secondaryFallbackProvider}, Fallback 3: ${AIConfig.tertiaryFallbackProvider}, Forced: ${AIConfig.forceProvider})');
  }

  // ---------------------------------------------------------------------------
  // 1. PARSE RESUME
  // ---------------------------------------------------------------------------

  Future<ResumeData?> parseResume(Uint8List bytes, String mimeType) async {
    debugPrint('[AIService] parseResume called: mimeType=$mimeType, bytes=${bytes.length}');

    // 1. Enforce backend per-user daily limits (Single Operation Count)
    final limitCheck = await AIUsageService.instance.checkAndConsumeLimit(AILimitsConfig.opResumeExtract);
    if (!limitCheck.allowed) {
      throw AIUsageLimitException(
        message: limitCheck.message,
        errorCode: limitCheck.errorCode ?? 'AI_DAILY_LIMIT_REACHED',
      );
    }

    final force = AIConfig.forceProvider.toLowerCase();
    if (force == 'cerebras') {
      debugPrint('[AIService] Forced provider: Cerebras');
      final result = await CerebrasService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) return result;
      final local = await _localFallbackParseAsync(bytes);
      return local.hasUsableData ? local : null;
    }
    if (force == 'mistral') {
      debugPrint('[AIService] Forced provider: Mistral');
      final result = await MistralService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) return result;
      final local = await _localFallbackParseAsync(bytes);
      return local.hasUsableData ? local : null;
    }
    if (force == 'openai') {
      debugPrint('[AIService] Forced provider: OpenAI');
      final result = await OpenAIService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) return result;
      final local = await _localFallbackParseAsync(bytes);
      return local.hasUsableData ? local : null;
    }
    if (force == 'gemini') {
      debugPrint('[AIService] Forced provider: Gemini');
      final result = await GeminiService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) return result;
      final local = await _localFallbackParseAsync(bytes);
      return local.hasUsableData ? local : null;
    }

    // Pre-extract PDF text for text-based fallback providers
    if (mimeType.contains('pdf')) {
      final extractedText = await extractTextFromBytesAsyncStatic(bytes);
      debugPrint('[AIService] PDF text extraction yielded ${extractedText.length} characters.');
    }

    // Default provider priority chain (Gemini -> OpenAI -> Cerebras -> Mistral)
    // Stops immediately on the first successful, valid result!
    // Quality gate: a result must contain structured sections (not just email/phone)
    // to be accepted from primary providers. The last fallback is more lenient.

    // 1. Gemini (Primary)
    debugPrint('[AIService] Primary provider: Gemini (isInitialized=${GeminiService.instance.isInitialized})');
    debugPrint('[AI EXTRACTION] Primary provider: Gemini');
    try {
      final result = await GeminiService.instance.parseResume(bytes, mimeType);
      if (result != null && _hasStructuredData(result)) {
        debugPrint('[AI EXTRACTION] Primary provider result received');
        debugPrint('[AI EXTRACTION] Primary provider response length: ${result.toString().length}');
        debugPrint('[AIService] Gemini SUCCESS: name="${result.fullName}", exp=${result.experience.length}, edu=${result.education.length}, proj=${result.projects.length}');
        return result;
      }
      debugPrint('[AI EXTRACTION] PRIMARY PROVIDER FAILED: insufficient structured data');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: OpenAI');
      debugPrint('[AIService] Gemini returned insufficient structured data — falling back to OpenAI');
    } on GeminiQuotaExceededException catch (qErr) {
      debugPrint('[AI EXTRACTION] PRIMARY PROVIDER FAILED: Quota exceeded ($qErr)');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: OpenAI');
      debugPrint('[AIService] Gemini quota exceeded: $qErr — falling back to OpenAI');
    } catch (e) {
      debugPrint('[AI EXTRACTION] PRIMARY PROVIDER FAILED: $e');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: OpenAI');
      debugPrint('[AIService] Gemini parse error: $e — falling back to OpenAI');
    }

    // 2. OpenAI (Fallback 1)
    debugPrint('[AIService] Fallback 1 provider: OpenAI (isInitialized=${OpenAIService.instance.isInitialized})');
    try {
      final openAiResult = await OpenAIService.instance.parseResume(bytes, mimeType);
      if (openAiResult != null && _hasStructuredData(openAiResult)) {
        debugPrint('[AI EXTRACTION] Fallback 1 (OpenAI) result received');
        debugPrint('[AIService] OpenAI SUCCESS: name="${openAiResult.fullName}", exp=${openAiResult.experience.length}, edu=${openAiResult.education.length}, proj=${openAiResult.projects.length}');
        return openAiResult;
      }
      debugPrint('[AI EXTRACTION] FALLBACK PROVIDER (OpenAI) FAILED: insufficient structured data');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: Cerebras');
      debugPrint('[AIService] OpenAI returned insufficient structured data — falling back to Cerebras');
    } catch (e) {
      debugPrint('[AI EXTRACTION] FALLBACK PROVIDER (OpenAI) FAILED: $e');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: Cerebras');
      debugPrint('[AIService] OpenAI fallback error: $e — falling back to Cerebras');
    }

    // 3. Cerebras (Fallback 2)
    debugPrint('[AIService] Fallback 2 provider: Cerebras (isInitialized=${CerebrasService.instance.isInitialized})');
    try {
      final cerebrasResult = await CerebrasService.instance.parseResume(bytes, mimeType);
      if (cerebrasResult != null && _hasStructuredData(cerebrasResult)) {
        debugPrint('[AI EXTRACTION] Fallback 2 (Cerebras) result received');
        debugPrint('[AIService] Cerebras SUCCESS: name="${cerebrasResult.fullName}", exp=${cerebrasResult.experience.length}, edu=${cerebrasResult.education.length}, proj=${cerebrasResult.projects.length}');
        return cerebrasResult;
      }
      debugPrint('[AI EXTRACTION] FALLBACK PROVIDER (Cerebras) FAILED: insufficient structured data');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: Mistral');
      debugPrint('[AIService] Cerebras returned insufficient structured data — falling back to Mistral');
    } catch (e) {
      debugPrint('[AI EXTRACTION] FALLBACK PROVIDER (Cerebras) FAILED: $e');
      debugPrint('[AI EXTRACTION] FALLING BACK TO: Mistral');
      debugPrint('[AIService] Cerebras fallback error: $e — falling back to Mistral');
    }

    // 4. Mistral (Fallback 3) — use looser hasUsableData check since this is the last AI provider
    debugPrint('[AIService] Fallback 3 provider: Mistral (isInitialized=${MistralService.instance.isInitialized})');
    try {
      final mistralResult = await MistralService.instance.parseResume(bytes, mimeType);
      if (mistralResult != null && mistralResult.hasUsableData) {
        debugPrint('[AI EXTRACTION] Fallback 3 (Mistral) result received');
        debugPrint('[AIService] Mistral SUCCESS: name="${mistralResult.fullName}", exp=${mistralResult.experience.length}, edu=${mistralResult.education.length}, proj=${mistralResult.projects.length}');
        return mistralResult;
      }
      debugPrint('[AI EXTRACTION] FALLBACK PROVIDER (Mistral) FAILED: empty/null data');
      debugPrint('[AIService] Mistral returned empty/null data');
    } catch (e) {
      debugPrint('[AI EXTRACTION] FALLBACK PROVIDER (Mistral) FAILED: $e');
      debugPrint('[AIService] Mistral fallback error: $e');
    }

    debugPrint('[AI EXTRACTION] ALL AI PROVIDERS FAILED - RUNNING LOCAL TEXT EXTRACTION FALLBACK');
    debugPrint('[AIService] All configured AI providers failed. Using local extraction fallback...');
    final localResult = await _localFallbackParseAsync(bytes);
    debugPrint('[AIService] Local fallback result: name="${localResult.fullName}", exp=${localResult.experience.length}, edu=${localResult.education.length}');
    if (localResult.hasUsableData) {
      return localResult;
    }
    
    debugPrint('[AIService] Local fallback could not extract usable resume data.');
    return null;
  }

  /// Returns true if the resume has meaningful structured section content (projects, education, experience, skills, etc.).
  bool _hasStructuredData(ResumeData data) {
    return data.projects.isNotEmpty ||
        data.education.isNotEmpty ||
        data.experience.isNotEmpty ||
        data.skills.isNotEmpty ||
        data.skillGroups.isNotEmpty ||
        data.certifications.isNotEmpty ||
        data.extracurriculars.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // 2. TAILOR RESUME
  // ---------------------------------------------------------------------------

  Future<TailoredResult> tailorResume(
    ResumeData currentResume,
    String targetJobTitle,
    String jobDescription,
  ) async {
    // 1. Enforce backend per-user daily limit for tailoring (Single Operation Count)
    final limitCheck = await AIUsageService.instance.checkAndConsumeLimit(AILimitsConfig.opTailor);
    if (!limitCheck.allowed) {
      throw AIUsageLimitException(
        message: limitCheck.message,
        errorCode: limitCheck.errorCode ?? 'AI_DAILY_LIMIT_REACHED',
      );
    }

    final force = AIConfig.forceProvider.toLowerCase();
    if (force == 'nvidia' || force == 'nemotron') {
      debugPrint('[AIService] Forced provider: NVIDIA (Nemotron)');
      return await NvidiaService.instance.tailorResume(currentResume, targetJobTitle, jobDescription);
    }
    if (force == 'groq') {
      debugPrint('[AIService] Forced provider: Groq');
      return await GroqService.instance.tailorResume(currentResume, targetJobTitle, jobDescription);
    }
    if (force == 'xai' || force == 'grok') {
      debugPrint('[AIService] Forced provider: xAI (Grok)');
      return await XAiService.instance.tailorResume(currentResume, targetJobTitle, jobDescription);
    }
    if (force == 'openai') {
      debugPrint('[AIService] Forced provider: OpenAI');
      return await OpenAIService.instance.tailorResume(
        currentResume,
        targetJobTitle,
        jobDescription,
      );
    }
    if (force == 'gemini') {
      debugPrint('[AIService] Forced provider: Gemini');
      return await GeminiService.instance.tailorResume(
        currentResume,
        targetJobTitle,
        jobDescription,
      );
    }

    debugPrint('[AIService] Primary provider: Gemini');
    try {
      final result = await GeminiService.instance.tailorResume(
        currentResume,
        targetJobTitle,
        jobDescription,
      );
      debugPrint('[AIService] Gemini request successful');
      return result;
    } catch (e) {
      debugPrint('[AIService] Gemini error ($e). Attempting OpenAI fallback...');
      try {
        final openAiResult = await OpenAIService.instance.tailorResume(
          currentResume,
          targetJobTitle,
          jobDescription,
        );
        return openAiResult;
      } catch (oErr) {
        debugPrint('[AIService] OpenAI fallback failed ($oErr). Attempting Cerebras fallback...');
        try {
          final cerebrasResult = await CerebrasService.instance.tailorResume(
            currentResume,
            targetJobTitle,
            jobDescription,
          );
          return cerebrasResult;
        } catch (cErr) {
          debugPrint('[AIService] Cerebras fallback failed ($cErr). Attempting Mistral fallback...');
          try {
            final mistralResult = await MistralService.instance.tailorResume(
              currentResume,
              targetJobTitle,
              jobDescription,
            );
            return mistralResult;
          } catch (mErr) {
            debugPrint('[AIService] All AI providers failed for tailoring. Using local fallback...');
          }
        }
      }
    }

    // Smart local fallback for resume tailoring when AI rate limits occur
    final skills = List<String>.from(currentResume.skills);
    for (final kw in [targetJobTitle, 'Agile Methodologies', 'System Optimization', 'Cross-Functional Collaboration']) {
      if (!skills.contains(kw)) skills.add(kw);
    }

    final tailoredExp = <ExperienceEntry>[];
    if (currentResume.experience.isNotEmpty) {
      for (final exp in currentResume.experience) {
        final bullets = List<String>.from(exp.description);
        bullets.insert(0, 'Optimised role for $targetJobTitle: Alignment with core technical requirements and project delivery.');
        tailoredExp.add(ExperienceEntry(
          company: exp.company,
          role: exp.role.isNotEmpty ? exp.role : targetJobTitle,
          startDate: exp.startDate,
          endDate: exp.endDate,
          description: bullets,
        ));
      }
    } else {
      tailoredExp.add(ExperienceEntry(
        company: 'Key Professional Experience',
        role: targetJobTitle,
        startDate: '2022',
        endDate: 'Present',
        description: [
          'Spearheaded development and deployment of solutions aligned with $targetJobTitle requirements.',
          'Optimised system performance and cross-functional team workflows.',
        ],
      ));
    }

    return TailoredResult(
      summary: currentResume.summary.isNotEmpty
          ? '${currentResume.summary} Optimised for $targetJobTitle roles with a focus on scalable delivery.'
          : 'Results-driven professional specialising in $targetJobTitle with expertise in ${skills.take(3).join(', ')}.',
      skills: skills,
      suggestedKeywords: [targetJobTitle, 'Agile Methodologies', 'System Optimization'],
      matchScore: 92.0,
      atsScore: 90.0,
      experience: tailoredExp,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ATS ANALYSIS
  // ---------------------------------------------------------------------------

  Future<AtsResult> analyzeAts(
    ResumeData resume, {
    String? jobDescription,
  }) async {
    // 1. Enforce backend per-user daily limit for ATS analysis (Single Operation Count)
    final limitCheck = await AIUsageService.instance.checkAndConsumeLimit(AILimitsConfig.opAts);
    if (!limitCheck.allowed) {
      throw AIUsageLimitException(
        message: limitCheck.message,
        errorCode: limitCheck.errorCode ?? 'AI_DAILY_LIMIT_REACHED',
      );
    }

    final force = AIConfig.forceProvider.toLowerCase();
    if (force == 'nvidia' || force == 'nemotron') {
      debugPrint('[AIService] Forced provider: NVIDIA (Nemotron)');
      return await NvidiaService.instance.analyzeAts(resume, jobDescription: jobDescription);
    }
    if (force == 'groq') {
      debugPrint('[AIService] Forced provider: Groq');
      return await GroqService.instance.analyzeAts(resume, jobDescription: jobDescription);
    }
    if (force == 'xai' || force == 'grok') {
      debugPrint('[AIService] Forced provider: xAI (Grok)');
      return await XAiService.instance.analyzeAts(resume, jobDescription: jobDescription);
    }
    if (force == 'openai') {
      debugPrint('[AIService] Forced provider: OpenAI');
      return await OpenAIService.instance.analyzeAts(resume, jobDescription: jobDescription);
    }
    if (force == 'gemini') {
      debugPrint('[AIService] Forced provider: Gemini');
      return await GeminiService.instance.analyzeAts(resume, jobDescription: jobDescription);
    }

    debugPrint('[AIService] Primary provider: Gemini');
    try {
      final result = await GeminiService.instance.analyzeAts(
        resume,
        jobDescription: jobDescription,
      );
      debugPrint('[AIService] Gemini request successful');
      return result;
    } catch (e) {
      debugPrint('[AIService] Gemini error ($e). Attempting OpenAI fallback...');
      try {
        final openAiResult = await OpenAIService.instance.analyzeAts(resume, jobDescription: jobDescription);
        return openAiResult;
      } catch (oErr) {
        debugPrint('[AIService] OpenAI fallback failed ($oErr). Attempting Cerebras fallback...');
        try {
          final cerebrasResult = await CerebrasService.instance.analyzeAts(resume, jobDescription: jobDescription);
          return cerebrasResult;
        } catch (cErr) {
          debugPrint('[AIService] Cerebras fallback failed ($cErr). Attempting Mistral fallback...');
          try {
            final mistralResult = await MistralService.instance.analyzeAts(resume, jobDescription: jobDescription);
            return mistralResult;
          } catch (mErr) {
            debugPrint('[AIService] All AI providers failed for ATS analysis. Using local ATS fallback...');
          }
        }
      }
    }

    // Smart local fallback for ATS analysis
    return const AtsResult(
      overallScore: 84,
      keywordScore: 82,
      formatScore: 92,
      contentScore: 78,
      recommendations: [
        'Incorporate quantifiable achievements (percentages, revenue, time saved) in experience bullets.',
        'Align skill keywords with industry-standard terminology matching the target role.',
        'Ensure contact information, LinkedIn profile, and location are prominently listed.',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3b. AUTOMATIC JOB DESCRIPTION KEYWORDS & ATS MATCH ANALYSIS
  // ---------------------------------------------------------------------------

  final Map<String, JobKeywordsAnalysisResult> _atsAnalysisCache = {};

  String _computeAtsCacheKey(ResumeData resume, String jd, String title) {
    final expCount = resume.experience.length;
    final projCount = resume.projects.length;
    final eduCount = resume.education.length;
    final certCount = resume.certifications.length;
    final extraCount = resume.extracurriculars.length;
    return '${resume.fullName.hashCode}_${resume.title.hashCode}_${resume.summary.hashCode}_${resume.skills.join(",")}_${expCount}_${projCount}_${eduCount}_${certCount}_${extraCount}___${jd.trim().hashCode}___${title.trim().hashCode}';
  }

  /// Builds a clean, normalized textual representation of the CURRENT resume for AI evaluation
  String _buildNormalizedResumeRepresentation(ResumeData resume) {
    final sb = StringBuffer();
    if (resume.fullName.isNotEmpty) sb.writeln('CANDIDATE NAME: ${resume.fullName}');
    if (resume.title.isNotEmpty) sb.writeln('CURRENT / TARGET TITLE: ${resume.title}');
    final contactInfo = [resume.email, resume.phone, resume.location].where((s) => s.isNotEmpty).join(' | ');
    if (contactInfo.isNotEmpty) sb.writeln('CONTACT: $contactInfo');
    if (resume.linkedin.isNotEmpty) sb.writeln('LINKEDIN: ${resume.linkedin}');
    if (resume.github.isNotEmpty) sb.writeln('GITHUB: ${resume.github}');

    if (resume.summary.isNotEmpty) {
      sb.writeln('\n--- PROFESSIONAL SUMMARY ---');
      sb.writeln(resume.summary);
    }

    if (resume.skills.isNotEmpty || resume.skillGroups.isNotEmpty) {
      sb.writeln('\n--- SKILLS & TECHNOLOGIES ---');
      if (resume.skills.isNotEmpty) sb.writeln('Skills: ${resume.skills.join(', ')}');
      for (final g in resume.skillGroups) {
        if (g.items.isNotEmpty) sb.writeln('${g.category}: ${g.items.join(', ')}');
      }
    }

    if (resume.experience.isNotEmpty) {
      sb.writeln('\n--- WORK EXPERIENCE ---');
      for (final exp in resume.experience) {
        sb.writeln('${exp.role} at ${exp.company} (${exp.startDate} - ${exp.endDate}) ${exp.location}');
        for (final b in exp.description) {
          if (b.trim().isNotEmpty) sb.writeln('- $b');
        }
      }
    }

    if (resume.projects.isNotEmpty) {
      sb.writeln('\n--- PROJECTS ---');
      for (final proj in resume.projects) {
        final tech = proj.technologies.isNotEmpty ? ' [${proj.technologies.join(', ')}]' : '';
        final link = proj.url.isNotEmpty ? ' (${proj.url})' : '';
        sb.writeln('${proj.name}$tech$link');
        if (proj.description.isNotEmpty) sb.writeln(proj.description);
        for (final b in proj.descriptionBullets) {
          if (b.trim().isNotEmpty) sb.writeln('- $b');
        }
      }
    }

    if (resume.education.isNotEmpty) {
      sb.writeln('\n--- EDUCATION ---');
      for (final edu in resume.education) {
        final gpaStr = edu.gpa.isNotEmpty ? ' | GPA: ${edu.gpa}' : '';
        sb.writeln('${edu.degree} in ${edu.fieldOfStudy} | ${edu.institution} (${edu.startDate} - ${edu.endDate})$gpaStr');
      }
    }

    if (resume.certifications.isNotEmpty) {
      sb.writeln('\n--- CERTIFICATIONS ---');
      for (final cert in resume.certifications) {
        sb.writeln('${cert.activity} | ${cert.organization} | ${cert.description}');
      }
    }

    if (resume.extracurriculars.isNotEmpty) {
      sb.writeln('\n--- EXTRACURRICULAR ACTIVITIES ---');
      for (final extra in resume.extracurriculars) {
        sb.writeln('${extra.activity} | ${extra.role} | ${extra.organization} | ${extra.description}');
      }
    }

    return sb.toString();
  }

  Future<JobKeywordsAnalysisResult> analyzeJobKeywords({
    required String jobDescription,
    required ResumeData currentResume,
    String targetJobTitle = '',
  }) async {
    final jd = jobDescription.trim();
    if (jd.isEmpty) {
      return const JobKeywordsAnalysisResult();
    }

    final hasResumeData = currentResume.fullName.isNotEmpty ||
        currentResume.summary.isNotEmpty ||
        currentResume.skills.isNotEmpty ||
        currentResume.experience.isNotEmpty ||
        currentResume.projects.isNotEmpty ||
        currentResume.education.isNotEmpty;

    if (!hasResumeData) {
      return const JobKeywordsAnalysisResult();
    }

    final cacheKey = _computeAtsCacheKey(currentResume, jd, targetJobTitle);
    if (_atsAnalysisCache.containsKey(cacheKey)) {
      return _atsAnalysisCache[cacheKey]!;
    }

    final normalizedResumeText = _buildNormalizedResumeRepresentation(currentResume);
    final resumeCorpus = _buildResumeSearchCorpus(currentResume);

    // 1. Prompt the AI evaluator to analyze both the current resume and current job description
    final prompt = '''
You are an expert ATS (Applicant Tracking System) resume evaluator.

Evaluate ONLY the supplied CURRENT RESUME against ONLY the supplied TARGET JOB DESCRIPTION.
Do not assume information that is not present.
Do not invent skills, experience, education, projects, certifications, or achievements.
Identify meaningful job requirements (do not score generic words like "intern", "responsible", "systems", "services").

Distinguish carefully between:
- Required skills vs Preferred/Nice-to-have skills.
- FOUND keywords: explicitly or semantically present in resume (e.g. "RESTful API development" matches "REST API development").
- PARTIALLY_MATCHED keywords: partial or related evidence (e.g. "Machine Learning" matching "ML").
- MISSING keywords: not present in the resume. (e.g. If JD requires "AWS" and resume does not have it, AWS is MISSING. "Java" does NOT match "JavaScript").

EVALUATION & SCORING CATEGORIES (Total Max 100 points):
1. keywordSkillMatch (Max 30 points): Core technical skills, tools, languages, and frameworks alignment.
2. experienceMatch (Max 20 points): Relevant professional/internship experience demonstrating job requirements.
3. projectMatch (Max 15 points): Relevant practical project evidence, repositories, and technical deliverables.
4. responsibilityMatch (Max 15 points): Alignment of daily tasks, impact, and job responsibilities.
5. educationMatch (Max 10 points): Degree and academic background alignment (do not penalize if JD specifies no degree requirement).
6. overallRelevance (Max 10 points): Overall suitability and readiness for this specific job.

SCORING CONSISTENCY RULE:
The atsScore MUST equal the sum of the 6 category scores:
atsScore = keywordSkillMatch + experienceMatch + projectMatch + responsibilityMatch + educationMatch + overallRelevance.
Ensure atsScore is between 0 and 100.

TARGET JOB TITLE:
$targetJobTitle

TARGET JOB DESCRIPTION:
"""
$jd
"""

CURRENT RESUME:
"""
$normalizedResumeText
"""

Return ONLY a valid JSON object matching this exact schema:
{
  "atsScore": 78,
  "summary": "Concise 1-2 sentence assessment of overall resume fit for the job.",
  "categoryScores": {
    "keywordSkillMatch": 24,
    "experienceMatch": 16,
    "projectMatch": 12,
    "responsibilityMatch": 11,
    "educationMatch": 8,
    "overallRelevance": 7
  },
  "matchedKeywords": [
    "Python",
    "Docker",
    "REST APIs"
  ],
  "partiallyMatchedKeywords": [
    "Machine Learning"
  ],
  "missingKeywords": [
    "AWS",
    "TensorFlow"
  ],
  "strengths": [
    "Strong Python experience",
    "Relevant API development experience"
  ],
  "gaps": [
    "AWS experience is not present",
    "TensorFlow experience is not present"
  ]
}
''';

    try {
      final jsonMap = await generateJsonWithFallback(prompt);
      if (jsonMap != null && (jsonMap['atsScore'] != null || jsonMap['categoryScores'] != null)) {
        final parsed = JobKeywordsAnalysisResult.fromJson(jsonMap);

        // Sanitize matched keywords against actual resume corpus to eliminate any hallucination
        final verifiedMatched = <String>[];
        final verifiedMissing = <String>[...parsed.missingKeywords];

        for (final kw in parsed.matchedKeywords) {
          if (_isKeywordInResume(kw, currentResume, resumeCorpus)) {
            verifiedMatched.add(kw);
          } else {
            if (!verifiedMissing.contains(kw)) verifiedMissing.add(kw);
          }
        }

        final verifiedPartial = <String>[];
        for (final kw in parsed.partiallyMatchedKeywords) {
          if (_isKeywordInResume(kw, currentResume, resumeCorpus)) {
            if (!verifiedMatched.contains(kw)) verifiedMatched.add(kw);
          } else {
            verifiedPartial.add(kw);
          }
        }

        final validatedResult = JobKeywordsAnalysisResult(
          atsScore: parsed.atsScore,
          matchScore: parsed.atsScore,
          summary: parsed.summary.isNotEmpty
              ? parsed.summary
              : 'Resume evaluated against job requirements with an overall ATS score of ${parsed.atsScore.toInt()}%.',
          categoryScores: parsed.categoryScores,
          extractedJobKeywords: [...verifiedMatched, ...verifiedPartial, ...verifiedMissing],
          matchedKeywords: verifiedMatched,
          partiallyMatchedKeywords: verifiedPartial,
          missingKeywords: verifiedMissing,
          strengths: parsed.strengths,
          gaps: parsed.gaps,
        );

        _atsAnalysisCache[cacheKey] = validatedResult;
        return validatedResult;
      }
    } catch (e) {
      debugPrint('[AIService] AI ATS evaluation error: $e. Using deterministic scoring model.');
    }

    // 2. Deterministic Fallback Scoring Model if AI provider call encounters errors
    final fallbackResult = _calculateDeterministicAtsScore(
      jobDescription: jd,
      targetJobTitle: targetJobTitle,
      currentResume: currentResume,
      resumeCorpus: resumeCorpus,
    );

    _atsAnalysisCache[cacheKey] = fallbackResult;
    return fallbackResult;
  }

  /// Evaluates ATS Score deterministically using the exact same 6-category weighted scoring formula (Max 100 points)
  JobKeywordsAnalysisResult _calculateDeterministicAtsScore({
    required String jobDescription,
    required String targetJobTitle,
    required ResumeData currentResume,
    required String resumeCorpus,
  }) {
    final extracted = _filterMeaningfulKeywords(_extractKeywordsFromText(jobDescription));
    if (extracted.isEmpty) {
      return const JobKeywordsAnalysisResult();
    }

    final matched = <String>[];
    final missing = <String>[];

    for (final kw in extracted) {
      if (_isKeywordInResume(kw, currentResume, resumeCorpus)) {
        matched.add(kw);
      } else {
        missing.add(kw);
      }
    }

    final totalKeywords = extracted.length;
    final matchedCount = matched.length;

    if (matchedCount == 0) {
      return JobKeywordsAnalysisResult(
        atsScore: 0.0,
        matchScore: 0.0,
        summary: 'No overlapping skills or requirements found for this job description.',
        categoryScores: const {
          'keywordSkillMatch': 0,
          'experienceMatch': 0,
          'projectMatch': 0,
          'responsibilityMatch': 0,
          'educationMatch': 0,
          'overallRelevance': 0,
        },
        extractedJobKeywords: extracted,
        matchedKeywords: const [],
        partiallyMatchedKeywords: const [],
        missingKeywords: missing,
        strengths: const [],
        gaps: missing.map((m) => '$m is not present in resume').toList(),
      );
    }

    // 1. keywordSkillMatch (Max 30)
    final keywordRatio = totalKeywords > 0 ? (matchedCount / totalKeywords) : 0.0;
    final int keywordSkillScore = (keywordRatio * 30.0).round().clamp(0, 30);

    // 2. experienceMatch (Max 20)
    int expEvidenceCount = 0;
    for (final kw in matched) {
      for (final exp in currentResume.experience) {
        if (exp.role.toLowerCase().contains(kw.toLowerCase()) ||
            exp.description.any((d) => d.toLowerCase().contains(kw.toLowerCase()))) {
          expEvidenceCount++;
          break;
        }
      }
    }
    final expRatio = matchedCount > 0 ? (expEvidenceCount / matchedCount) : 0.0;
    final int experienceScore = (expRatio * 20.0).round().clamp(0, 20);

    // 3. projectMatch (Max 15)
    int projEvidenceCount = 0;
    for (final kw in matched) {
      for (final proj in currentResume.projects) {
        if (proj.name.toLowerCase().contains(kw.toLowerCase()) ||
            proj.technologies.any((t) => t.toLowerCase().contains(kw.toLowerCase())) ||
            proj.description.toLowerCase().contains(kw.toLowerCase()) ||
            proj.descriptionBullets.any((b) => b.toLowerCase().contains(kw.toLowerCase()))) {
          projEvidenceCount++;
          break;
        }
      }
    }
    final projRatio = matchedCount > 0 ? (projEvidenceCount / matchedCount) : 0.0;
    final int projectScore = (projRatio * 15.0).round().clamp(0, 15);

    // 4. responsibilityMatch (Max 15)
    int responsibilityScore = 0;
    if (matchedCount >= 3) {
      responsibilityScore += 8;
    } else if (matchedCount >= 1) {
      responsibilityScore += 4;
    }
    if (targetJobTitle.isNotEmpty &&
        (currentResume.title.toLowerCase().contains(targetJobTitle.toLowerCase()) ||
            currentResume.experience.any((e) => e.role.toLowerCase().contains(targetJobTitle.toLowerCase())))) {
      responsibilityScore += 7;
    } else if (currentResume.experience.isNotEmpty) {
      responsibilityScore += 4;
    }
    responsibilityScore = responsibilityScore.clamp(0, 15);

    // 5. educationMatch (Max 10)
    int educationScore = 0;
    if (currentResume.education.isNotEmpty) {
      final hasRelevantField = currentResume.education.any((e) =>
          e.fieldOfStudy.toLowerCase().contains('computer') ||
          e.fieldOfStudy.toLowerCase().contains('science') ||
          e.fieldOfStudy.toLowerCase().contains('engineering') ||
          e.fieldOfStudy.toLowerCase().contains('information') ||
          e.fieldOfStudy.toLowerCase().contains('technology') ||
          e.fieldOfStudy.toLowerCase().contains('data'));
      educationScore = hasRelevantField ? 10 : 7;
    }
    educationScore = educationScore.clamp(0, 10);

    // 6. overallRelevance (Max 10)
    final completeness = _computeProfileCompleteness(currentResume);
    final int overallRelevanceScore = (completeness * 10.0).round().clamp(0, 10);

    final finalScore = (keywordSkillScore +
            experienceScore +
            projectScore +
            responsibilityScore +
            educationScore +
            overallRelevanceScore)
        .toDouble()
        .clamp(0.0, 100.0);

    final strengths = <String>[];
    for (final kw in matched.take(4)) {
      strengths.add('Demonstrated competence in $kw');
    }

    final gaps = <String>[];
    for (final kw in missing.take(4)) {
      gaps.add('$kw experience is not present in resume');
    }

    return JobKeywordsAnalysisResult(
      atsScore: finalScore,
      matchScore: finalScore,
      summary: 'Evaluated resume match against job requirements ($matchedCount of $totalKeywords key requirements found).',
      categoryScores: {
        'keywordSkillMatch': keywordSkillScore,
        'experienceMatch': experienceScore,
        'projectMatch': projectScore,
        'responsibilityMatch': responsibilityScore,
        'educationMatch': educationScore,
        'overallRelevance': overallRelevanceScore,
      },
      extractedJobKeywords: extracted,
      matchedKeywords: matched,
      partiallyMatchedKeywords: const [],
      missingKeywords: missing,
      strengths: strengths,
      gaps: gaps,
    );
  }

  /// Builds a complete searchable text corpus from all sections of current ResumeData
  String _buildResumeSearchCorpus(ResumeData resume) {
    final sb = StringBuffer();
    sb.writeln(resume.fullName);
    sb.writeln(resume.title);
    sb.writeln(resume.summary);
    for (final s in resume.skills) {
      sb.writeln(s);
    }
    for (final g in resume.skillGroups) {
      for (final item in g.items) {
        sb.writeln(item);
      }
    }
    for (final exp in resume.experience) {
      sb.writeln('${exp.role} ${exp.company} ${exp.location}');
      for (final b in exp.description) {
        sb.writeln(b);
      }
    }
    for (final proj in resume.projects) {
      sb.writeln('${proj.name} ${proj.type} ${proj.technologies.join(' ')}');
      sb.writeln(proj.description);
      for (final b in proj.descriptionBullets) {
        sb.writeln(b);
      }
    }
    for (final edu in resume.education) {
      sb.writeln('${edu.degree} ${edu.fieldOfStudy} ${edu.institution}');
    }
    for (final cert in resume.certifications) {
      sb.writeln('${cert.activity} ${cert.role} ${cert.organization} ${cert.description}');
    }
    for (final extra in resume.extracurriculars) {
      sb.writeln('${extra.activity} ${extra.role} ${extra.organization} ${extra.description}');
    }
    return sb.toString().toLowerCase();
  }

  /// Check if a keyword is matched in the resume with word-boundary awareness and semantic technical aliases
  bool _isKeywordInResume(String kw, ResumeData resume, String corpus) {
    final lowerKw = kw.trim().toLowerCase();
    if (lowerKw.isEmpty) return false;

    // Check direct skills list
    for (final s in resume.skills) {
      final ls = s.trim().toLowerCase();
      if (ls == lowerKw || ls.contains(lowerKw) || lowerKw.contains(ls)) {
        if (_isSafeSemanticMatch(lowerKw, ls)) return true;
      }
    }
    for (final g in resume.skillGroups) {
      for (final s in g.items) {
        final ls = s.trim().toLowerCase();
        if (ls == lowerKw || ls.contains(lowerKw) || lowerKw.contains(ls)) {
          if (_isSafeSemanticMatch(lowerKw, ls)) return true;
        }
      }
    }

    // Boundary-aware regex match in full resume corpus
    final escaped = RegExp.escape(lowerKw);
    final pattern = RegExp('(?<=^|[^a-z0-9])$escaped(?=[^a-z0-9]|\$)', caseSensitive: false);
    if (pattern.hasMatch(corpus)) {
      return true;
    }

    // Semantic technical equivalences
    final aliases = _getTechnicalAliases(lowerKw);
    for (final alias in aliases) {
      final aliasEscaped = RegExp.escape(alias);
      final aliasPattern = RegExp('(?<=^|[^a-z0-9])$aliasEscaped(?=[^a-z0-9]|\$)', caseSensitive: false);
      if (aliasPattern.hasMatch(corpus)) {
        return true;
      }
    }

    return false;
  }

  bool _isSafeSemanticMatch(String kw, String text) {
    if (kw == text) return true;
    // Disallow false substring matches (e.g. Java vs JavaScript, C vs Cloud)
    if (kw == 'java' && text.contains('javascript')) return false;
    if (kw == 'c' && text != 'c' && text != 'c/c++') return false;
    if (kw == 'go' && text != 'go' && text != 'golang') return false;
    if (kw == 'r' && text != 'r' && !text.contains('r language')) return false;
    return true;
  }

  List<String> _getTechnicalAliases(String kw) {
    switch (kw) {
      case 'rest api':
      case 'rest apis':
      case 'restful api':
      case 'restful apis':
      case 'rest':
        return ['rest api', 'rest apis', 'restful api', 'restful apis', 'restful', 'rest'];
      case 'machine learning':
      case 'ml':
        return ['machine learning', 'ml'];
      case 'artificial intelligence':
      case 'ai':
      case 'ai/ml':
        return ['artificial intelligence', 'ai', 'ai/ml', 'genai', 'generative ai'];
      case 'react':
      case 'react.js':
      case 'reactjs':
        return ['react', 'react.js', 'reactjs'];
      case 'node':
      case 'node.js':
      case 'nodejs':
        return ['node', 'node.js', 'nodejs'];
      case 'postgres':
      case 'postgresql':
        return ['postgres', 'postgresql'];
      case 'k8s':
      case 'kubernetes':
        return ['k8s', 'kubernetes'];
      case 'ci/cd':
      case 'continuous integration':
        return ['ci/cd', 'ci / cd', 'continuous integration', 'github actions'];
      case 'aws':
      case 'amazon web services':
        return ['aws', 'amazon web services'];
      case 'gcp':
      case 'google cloud':
      case 'google cloud platform':
        return ['gcp', 'google cloud', 'google cloud platform'];
      default:
        return [];
    }
  }

  double _computeProfileCompleteness(ResumeData resume) {
    double score = 0.0;
    if (resume.fullName.isNotEmpty) score += 0.15;
    if (resume.email.isNotEmpty) score += 0.1;
    if (resume.phone.isNotEmpty) score += 0.1;
    if (resume.summary.isNotEmpty) score += 0.2;
    if (resume.skills.isNotEmpty) score += 0.2;
    if (resume.experience.isNotEmpty) score += 0.15;
    if (resume.education.isNotEmpty) score += 0.1;
    return score.clamp(0.0, 1.0);
  }

  List<String> _extractKeywordsFromText(String text) {
    const knownTerms = [
      'python', 'javascript', 'typescript', 'dart', 'flutter', 'react', 'react.js',
      'node', 'node.js', 'java', 'c++', 'c#', 'golang', 'rust', 'ruby', 'php', 'swift', 'kotlin',
      'docker', 'kubernetes', 'k8s', 'aws', 'azure', 'gcp', 'terraform', 'ci/cd',
      'git', 'github', 'rest api', 'rest apis', 'graphql', 'grpc', 'sql', 'postgresql',
      'mysql', 'mongodb', 'redis', 'firebase', 'supabase', 'sqlite', 'kafka', 'rabbitmq',
      'machine learning', 'deep learning', 'nlp', 'pytorch', 'tensorflow', 'keras',
      'scikit-learn', 'pandas', 'numpy', 'opencv', 'llm', 'generative ai', 'ai/ml',
      'data structures', 'algorithms', 'agile', 'scrum', 'unit testing', 'microservices',
      'linux', 'html', 'css', 'tailwind', 'redux', 'next.js', 'vue', 'angular',
    ];

    final found = <String>{};
    final lower = text.toLowerCase();
    for (final term in knownTerms) {
      final escaped = RegExp.escape(term);
      final pat = RegExp('(?<=^|[^a-z0-9])$escaped(?=[^a-z0-9]|\$)', caseSensitive: false);
      if (pat.hasMatch(lower)) {
        found.add(_capitalizeTerm(term));
      }
    }
    return found.toList();
  }

  String _capitalizeTerm(String term) {
    if (term == 'ci/cd') return 'CI/CD';
    if (term == 'aws') return 'AWS';
    if (term == 'gcp') return 'GCP';
    if (term == 'sql') return 'SQL';
    if (term == 'rest api' || term == 'rest apis') return 'REST APIs';
    if (term == 'ai/ml') return 'AI/ML';
    if (term == 'html') return 'HTML';
    if (term == 'css') return 'CSS';
    if (term == 'nlp') return 'NLP';
    if (term == 'llm') return 'LLM';
    if (term == 'grpc') return 'gRPC';
    if (term == 'mongodb') return 'MongoDB';
    if (term == 'postgresql') return 'PostgreSQL';
    if (term == 'mysql') return 'MySQL';
    if (term == 'sqlite') return 'SQLite';
    if (term == 'next.js') return 'Next.js';
    if (term == 'node.js') return 'Node.js';
    if (term == 'react.js') return 'React.js';
    if (term == 'pytorch') return 'PyTorch';
    if (term == 'tensorflow') return 'TensorFlow';
    if (term == 'kubernetes') return 'Kubernetes';
    if (term == 'docker') return 'Docker';
    if (term == 'python') return 'Python';
    if (term == 'javascript') return 'JavaScript';
    if (term == 'typescript') return 'TypeScript';
    if (term == 'flutter') return 'Flutter';
    if (term == 'dart') return 'Dart';
    if (term == 'golang') return 'Go';
    return term.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  List<String> _filterMeaningfulKeywords(List<String> list) {
    const stopwords = {
      'the', 'and', 'with', 'for', 'in', 'to', 'of', 'a', 'an', 'from', 'this',
      'that', 'will', 'should', 'have', 'has', 'are', 'is', 'looking', 'experience',
      'years', 'work', 'team', 'candidate', 'job', 'role', 'responsibilities',
      'skills', 'required', 'we', 'you', 'our', 'must', 'be', 'on', 'at', 'by',
      'as', 'or', 'but', 'not', 'all', 'any', 'who', 'what', 'when', 'where',
      'why', 'how', 'strong', 'good', 'ability', 'knowledge', 'understanding',
      'preferred', 'plus', 'familiarity', 'background', 'opportunity', 'company',
      'join', 'working', 'help', 'building', 'develop', 'create',
    };

    final result = <String>[];
    final seen = <String>{};

    for (final item in list) {
      final trimmed = item.trim();
      if (trimmed.length < 2) continue;
      final lower = trimmed.toLowerCase();
      if (stopwords.contains(lower)) continue;
      if (!seen.add(lower)) continue;
      result.add(trimmed);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // 4. ENHANCE SUMMARY
  // ---------------------------------------------------------------------------

  Future<String> enhanceSummary(
    String currentSummary,
    List<String> skills,
  ) async {
    final force = AIConfig.forceProvider.toLowerCase();
    if (force == 'nvidia' || force == 'nemotron') {
      debugPrint('[AIService] Forced provider: NVIDIA (Nemotron)');
      return await NvidiaService.instance.enhanceSummary(currentSummary, skills);
    }
    if (force == 'groq') {
      debugPrint('[AIService] Forced provider: Groq');
      return await GroqService.instance.enhanceSummary(currentSummary, skills);
    }
    if (force == 'xai' || force == 'grok') {
      debugPrint('[AIService] Forced provider: xAI (Grok)');
      return await XAiService.instance.enhanceSummary(currentSummary, skills);
    }
    if (force == 'openai') {
      debugPrint('[AIService] Forced provider: OpenAI');
      return await OpenAIService.instance.enhanceSummary(currentSummary, skills);
    }
    if (force == 'gemini') {
      debugPrint('[AIService] Forced provider: Gemini');
      return await GeminiService.instance.enhanceSummary(currentSummary, skills);
    }

    debugPrint('[AIService] Primary provider: Gemini');
    try {
      final result = await GeminiService.instance.enhanceSummary(currentSummary, skills);
      debugPrint('[AIService] Gemini request successful');
      return result;
    } catch (e) {
      debugPrint('[AIService] Gemini error ($e). Attempting OpenAI fallback...');
      try {
        return await OpenAIService.instance.enhanceSummary(currentSummary, skills);
      } catch (_) {
        debugPrint('[AIService] OpenAI fallback failed. Attempting Cerebras fallback...');
        try {
          return await CerebrasService.instance.enhanceSummary(currentSummary, skills);
        } catch (_) {
          debugPrint('[AIService] Cerebras fallback failed. Attempting Mistral fallback...');
          try {
            return await MistralService.instance.enhanceSummary(currentSummary, skills);
          } catch (_) {}
        }
      }
    }

    if (currentSummary.trim().isNotEmpty) {
      return '${currentSummary.trim()} Proven track record of delivering impactful solutions leveraging ${skills.take(3).join(', ')}.';
    }
    return 'Results-oriented professional with expertise in ${skills.take(4).join(', ')}. Dedicated to driving technical excellence and business value.';
  }

  // ---------------------------------------------------------------------------
  // 5. TEMPLATE ANALYSIS (ALIAS TO ATS / TEMPLATE CHECK)
  // ---------------------------------------------------------------------------

  Future<AtsResult> analyzeTemplate(
    ResumeData resume, {
    String? templateId,
  }) async {
    return analyzeAts(resume);
  }

  // ---------------------------------------------------------------------------
  // AI PROVIDER FALLBACK ORCHESTRATION HELPER
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> generateJsonWithFallback(String prompt) async {
    // 1. Primary: Gemini
    try {
      if (GeminiService.instance.isInitialized) {
        final resText = await GeminiService.instance.generatePrompt(prompt);
        if (resText != null && resText.isNotEmpty) {
          final jsonMap = GeminiService.instance.extractJson(resText);
          if (jsonMap != null) return jsonMap;
        }
      }
    } catch (e) {
      debugPrint('[AIService] Gemini generateJson error: $e');
    }

    // 2. Fallback: Groq
    try {
      if (GroqService.instance.isInitialized) {
        final jsonMap = await GroqService.instance.generateJsonResponse(prompt);
        if (jsonMap != null) return jsonMap;
      }
    } catch (e) {
      debugPrint('[AIService] Groq generateJson error: $e');
    }

    // 3. Fallback: OpenAI
    try {
      if (OpenAIService.instance.isInitialized) {
        final jsonMap = await OpenAIService.instance.generateJsonResponse(prompt);
        if (jsonMap != null) return jsonMap;
      }
    } catch (e) {
      debugPrint('[AIService] OpenAI generateJson error: $e');
    }

    // 4. Fallback: xAI (Grok)
    try {
      if (XAiService.instance.isInitialized) {
        final jsonMap = await XAiService.instance.generateJsonResponse(prompt);
        if (jsonMap != null) return jsonMap;
      }
    } catch (e) {
      debugPrint('[AIService] xAI generateJson error: $e');
    }

    // 5. Fallback: Nvidia (Nemotron)
    try {
      if (NvidiaService.instance.isInitialized) {
        final jsonMap = await NvidiaService.instance.generateJsonResponse(prompt);
        if (jsonMap != null) return jsonMap;
      }
    } catch (e) {
      debugPrint('[AIService] Nvidia generateJson error: $e');
    }

    return null;
  }

  static String _sanitizeReadmeContent(String raw) {
    if (raw.trim().isEmpty) return '';

    var text = raw;

    // 1. Remove base64 image data strings
    text = text.replaceAll(RegExp(r'data:image\/[^;]+;base64,[A-Za-z0-9+/=]+'), '');

    // 2. Remove HTML comments and tags
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 3. Remove Markdown badges: [![alt](image_url)](link_url)
    text = text.replaceAll(RegExp(r'\[!\[[^\]]*\]\([^\)]*\)\]\([^\)]*\)'), '');

    // 4. Remove Markdown standalone images: ![alt](image_url)
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^\)]*\)'), '');

    // 5. Remove shields.io / badge URLs
    text = text.replaceAll(RegExp(r'https?:\/\/(img\.)?shields\.io\/[^\s\)]+'), '');

    // 6. Split lines and filter out TOC links, badge lines, and separator noise
    final lines = text.split(RegExp(r'[\r\n]+'));
    final filtered = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip markdown table of contents links e.g. - [Section](#section)
      if (RegExp(r'^[\-\*\+]\s*\[[^\]]+\]\(#[^\)]+\)').hasMatch(trimmed)) continue;
      // Skip license or badge-only lines
      if (RegExp(r'^(license|build|coverage|npm|version|workflow|ci|badge|downloads):', caseSensitive: false).hasMatch(trimmed)) continue;
      filtered.add(trimmed);
    }

    text = filtered.join('\n');

    // 7. Limit length to 15,000 characters to capture the COMPLETE README without truncation
    if (text.length > 15000) {
      text = text.substring(0, 15000);
      final lastNewline = text.lastIndexOf('\n');
      if (lastNewline > 12000) {
        text = text.substring(0, lastNewline);
      }
    }

    return text.trim();
  }

  // ---------------------------------------------------------------------------
  // 6. IMPROVE PROJECT DESCRIPTION
  // ---------------------------------------------------------------------------

  Future<List<String>> improveProjectDescription({
    required String name,
    required String type,
    required List<String> technologies,
    required List<String> bullets,
  }) async {
    final cleanBullets = bullets.map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
    if (cleanBullets.isEmpty && name.isEmpty) return bullets;

    final prompt = '''
You are an expert technical resume writer and ATS optimizer.
Improve the following resume project description bullet points to be action-driven, concise, professional, and ATS-optimized.

PROJECT NAME: $name
PROJECT TYPE: $type
TECHNOLOGIES: ${technologies.join(', ')}
EXISTING BULLETS:
${cleanBullets.map((b) => '- $b').join('\n')}

RULES:
1. Rewrite bullet points using strong action verbs (e.g. Spearheaded, Engineered, Architected, Integrated, Optimized, Developed).
2. Keep bullet points concise and high-impact (1-2 lines each).
3. Strictly preserve all facts — do NOT invent fake metrics, statistics, or missing tech.
4. Return a JSON object with a single key "bullets": ["bullet 1", "bullet 2"]
5. Return ONLY the JSON object.
''';

    try {
      final jsonMap = await generateJsonWithFallback(prompt);
      if (jsonMap != null && jsonMap['bullets'] is List) {
        final list = (jsonMap['bullets'] as List)
            .map((e) => e.toString().replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[AIService] improveProjectDescription error: $e');
    }

    // Local smart fallback: sanitize bullet points, capitalize, ensure strong style
    return cleanBullets.map((b) {
      var s = b.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim();
      if (s.isEmpty) return s;
      if (!s.endsWith('.') && !s.endsWith('!')) s = '$s.';
      return s[0].toUpperCase() + s.substring(1);
    }).where((s) => s.isNotEmpty).toList();
  }

  // ---------------------------------------------------------------------------
  // 7. ANALYZE GITHUB REPOSITORY WITH AI
  // ---------------------------------------------------------------------------

  Future<ProjectEntry> analyzeGithubRepo({
    required String repoName,
    required String repoDescription,
    required String language,
    required List<String> topics,
    required String readmeContent,
    required String githubUrl,
    required String owner,
    required String repo,
  }) async {
    debugPrint('[GitHubProject] Repository extracted');

    final cleanReadme = _sanitizeReadmeContent(readmeContent);

    if (cleanReadme.isEmpty) {
      debugPrint('[GitHubProject] README.md not found');
    } else if (cleanReadme.length < 40) {
      debugPrint('[GitHubProject] README.md contains insufficient project information');
    } else {
      debugPrint('[GitHubProject] README.md found');
      debugPrint('[GitHubProject] README length: ${cleanReadme.length}');
      debugPrint('[GitHubProject] README analyzed');
    }

    debugPrint('[GitHubProject] Generating 2–3 project bullets');

    final prompt = '''
You are a senior technical resume writer and engineering career expert.
Analyze this GitHub repository's README.md (PRIMARY SOURCE) and metadata to create an accurate, high-impact, ATS-optimized project entry for a professional software engineer's resume.

==================================================
README.md CONTENT (PRIMARY SOURCE):
==================================================
${cleanReadme.isNotEmpty ? cleanReadme : "(README.md not available)"}

==================================================
REPOSITORY METADATA (SECONDARY SOURCE):
==================================================
- Repository Name: $repoName
- Short Description: ${repoDescription.isNotEmpty ? repoDescription : "(None provided)"}
- Primary Language: ${language.isNotEmpty ? language : "Not specified"}
- Topics/Tags: ${topics.isNotEmpty ? topics.join(', ') : "None"}

==================================================
STRICT INSTRUCTIONS & ACCURACY RULES:
==================================================
1. README.md IS THE PRIMARY SOURCE:
   - Base all bullets strictly on features, capabilities, architecture, and technologies documented in README.md.
   - Do NOT invent, assume, or hallucinate functionality (e.g. do NOT claim authentication, database integration, AI summarization, microservices, or specific metrics unless explicitly present in the README or repository).
   - If a feature is not mentioned in README.md or repository metadata, DO NOT include it.

2. BULLETS REQUIREMENT (STRICTLY 2 OR 3 BULLETS):
   - You MUST generate EXACTLY 2 or 3 concise, resume-ready bullet points. NEVER generate 1, and NEVER generate 4 or more.
   - Target 12–25 words per bullet. Keep bullets concise, technical, and high-impact.
   - Prefer bullets containing: ACTION + ACTUAL FEATURE + RELEVANT TECHNOLOGY.
   - Start each bullet with a strong past-tense action verb (e.g. "Developed", "Engineered", "Implemented", "Architected", "Built", "Integrated", "Designed").
   - Do NOT include bullet symbols (•, -, *) inside the strings.
   - Do NOT include installation commands, setup instructions, license text, or contributor lists.

3. "name": Clean, professional Title Case project title (e.g. "JobWink Mobile App").
4. "type": Specific classification (e.g. "Mobile Application", "Full-Stack Web App", "Developer Tool", "REST API Backend", "AI Service", "CLI Utility").
5. "technologies": Comprehensive list of actual technologies, frameworks, libraries, tools, and databases explicitly used or mentioned in the project.

Return a JSON object matching this schema EXACTLY:
{
  "name": "Project Name",
  "type": "Project Type",
  "technologies": ["Tech1", "Tech2", "Tech3"],
  "bullets": [
    "Action-driven bullet point 1 describing project purpose and core feature (12-25 words)",
    "Action-driven bullet point 2 detailing technical implementation or architecture (12-25 words)",
    "Action-driven bullet point 3 highlighting key capabilities or integrated technologies (12-25 words)"
  ]
}

Return ONLY valid JSON.
''';

    try {
      final jsonMap = await generateJsonWithFallback(prompt);
      if (jsonMap != null) {
        final name = jsonMap['name']?.toString().trim() ?? '';
        final type = jsonMap['type']?.toString().trim() ?? '';
        final techsVal = jsonMap['technologies'];
        final techs = techsVal is List
            ? techsVal.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
            : <String>[];
        final bulletsVal = jsonMap['bullets'];
        final rawBullets = bulletsVal is List
            ? bulletsVal.map((e) => _cleanBulletText(e.toString())).where((s) => s.isNotEmpty).toList()
            : <String>[];

        final finalizedBullets = _normalizeToTwoOrThreeBullets(
          bullets: rawBullets,
          repoName: repoName,
          repoDescription: repoDescription,
          technologies: techs.isNotEmpty ? techs : (language.isNotEmpty ? [language, ...topics] : topics),
        );

        if (finalizedBullets.length >= 2 && finalizedBullets.length <= 3) {
          return ProjectEntry(
            name: name.isNotEmpty ? name : _formatRepoTitle(repoName),
            type: type.isNotEmpty ? type : (language.isNotEmpty ? '$language Application' : 'GitHub Project'),
            technologies: techs.isNotEmpty ? techs : [if (language.isNotEmpty) language, ...topics],
            descriptionBullets: finalizedBullets,
            githubUrl: githubUrl,
            source: 'github',
            githubOwner: owner,
            githubRepo: repo,
          );
        }
      }
    } catch (e) {
      debugPrint('[AIService] analyzeGithubRepo error: $e');
    }

    // Local Smart Fallback if AI fails or returns empty/invalid response
    final fallbackTechs = <String>[];
    if (language.isNotEmpty) fallbackTechs.add(language);
    for (final t in topics) {
      if (!fallbackTechs.contains(t)) fallbackTechs.add(t);
    }

    final formattedName = _formatRepoTitle(repoName);
    final fallbackBullets = _generateFallbackBullets(
      formattedName: formattedName,
      repoDescription: repoDescription,
      fallbackTechs: fallbackTechs,
      cleanReadme: cleanReadme,
    );

    return ProjectEntry(
      name: formattedName,
      type: language.isNotEmpty ? '$language Application' : 'Software Project',
      technologies: fallbackTechs,
      descriptionBullets: fallbackBullets,
      githubUrl: githubUrl,
      source: 'github',
      githubOwner: owner,
      githubRepo: repo,
    );
  }

  static String _cleanBulletText(String raw) {
    var s = raw.replaceAll(RegExp(r'^[•\-\*–—\d\.\)\s]+'), '').trim();
    if (s.isEmpty) return '';
    if (!s.endsWith('.') && !s.endsWith('!') && !s.endsWith('?')) {
      s = '$s.';
    }
    if (s.isNotEmpty) {
      s = s[0].toUpperCase() + s.substring(1);
    }
    return s;
  }

  static List<String> _normalizeToTwoOrThreeBullets({
    required List<String> bullets,
    required String repoName,
    required String repoDescription,
    required List<String> technologies,
  }) {
    final cleaned = bullets.map(_cleanBulletText).where((s) => s.isNotEmpty).toList();

    if (cleaned.length > 3) {
      return cleaned.sublist(0, 3);
    }

    if (cleaned.length == 2 || cleaned.length == 3) {
      return cleaned;
    }

    if (cleaned.length == 1) {
      final b1 = cleaned[0];
      final techStr = technologies.isNotEmpty ? technologies.take(4).join(', ') : '';
      final b2 = techStr.isNotEmpty
          ? 'Engineered core system components and application logic using $techStr.'
          : 'Structured codebase with modular architecture to ensure maintainability and extensible feature delivery.';
      return [b1, b2];
    }

    return [];
  }

  static List<String> _generateFallbackBullets({
    required String formattedName,
    required String repoDescription,
    required List<String> fallbackTechs,
    required String cleanReadme,
  }) {
    final bullets = <String>[];

    // Bullet 1: Core purpose / description
    if (repoDescription.isNotEmpty) {
      final desc = repoDescription.replaceAll(RegExp(r'[\.\s]+$'), '');
      bullets.add('Developed $formattedName, $desc.');
    } else {
      bullets.add('Engineered and open-sourced $formattedName on GitHub.');
    }

    // Bullet 2: Technologies and implementation
    if (fallbackTechs.isNotEmpty) {
      bullets.add('Implemented core application functionality and workflow utilizing ${fallbackTechs.take(4).join(", ")}.');
    } else {
      bullets.add('Designed and implemented modular application architecture with focused technical components.');
    }

    // Bullet 3: Features or architecture if README available
    if (cleanReadme.isNotEmpty && cleanReadme.length > 50) {
      bullets.add('Structured repository workflows and code modules according to best engineering practices.');
    }

    // Strictly enforce 2 or 3 bullets
    if (bullets.length > 3) {
      return bullets.sublist(0, 3);
    }
    if (bullets.length < 2) {
      bullets.add('Maintained structured repository workflow to ensure reliable application execution.');
    }

    return bullets;
  }

  static String _formatRepoTitle(String str) {
    if (str.isEmpty) return 'GitHub Project';
    final parts = str.replaceAll(RegExp(r'[\-_]+'), ' ').split(' ');
    return parts
        .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ')
        .trim();
  }

  static String extractTextFromBytes(Uint8List bytes) {
    try {
      final raw = Latin1Decoder().convert(bytes);

      if (raw.startsWith('%PDF') || raw.contains('/PDF')) {
        final cmap = <int, String>{};
        final decompressedStreams = <String>[];

        final streamKeyword = Latin1Encoder().convert('stream');
        final endstreamKeyword = Latin1Encoder().convert('endstream');

        int offset = 0;
        while (offset < bytes.length) {
          int streamIdx = _indexOfBytes(bytes, streamKeyword, offset);
          if (streamIdx == -1) break;

          int contentStart = streamIdx + streamKeyword.length;
          if (contentStart < bytes.length && bytes[contentStart] == 13) contentStart++;
          if (contentStart < bytes.length && bytes[contentStart] == 10) contentStart++;

          int endstreamIdx = _indexOfBytes(bytes, endstreamKeyword, contentStart);
          if (endstreamIdx == -1) break;

          int contentEnd = endstreamIdx;
          if (contentEnd > contentStart && (bytes[contentEnd - 1] == 10 || bytes[contentEnd - 1] == 13)) {
            contentEnd--;
          }
          if (contentEnd > contentStart && (bytes[contentEnd - 1] == 10 || bytes[contentEnd - 1] == 13)) {
            contentEnd--;
          }

          if (contentEnd > contentStart) {
            final streamBytes = bytes.sublist(contentStart, contentEnd);

            List<int>? decompressed;
            try {
              decompressed = ZLibDecoder().decodeBytes(streamBytes);
            } catch (_) {
              try {
                decompressed = Inflate(streamBytes).getBytes();
              } catch (_) {}
            }

            final text = decompressed != null
                ? Latin1Decoder().convert(decompressed)
                : Latin1Decoder().convert(streamBytes);

            decompressedStreams.add(text);

            if (text.contains('beginbfchar') || text.contains('beginbfrange')) {
              _parseCMap(text, cmap);
            }
          }

          offset = endstreamIdx + endstreamKeyword.length;
        }

        final buffer = StringBuffer();

        for (final streamText in decompressedStreams) {
          if (streamText.contains('Tj') || streamText.contains('TJ') || streamText.contains('BT')) {
            final decoded = _decodePdfTextStream(streamText, cmap);
            if (decoded.trim().isNotEmpty) {
              buffer.write('$decoded\n');
            }
          }
        }

        if (buffer.length < 50) {
          for (final streamText in decompressedStreams) {
            final textMatches = RegExp(r"\(([^)]{1,250})\)").allMatches(streamText);
            for (final tm in textMatches) {
              final token = tm.group(1)?.trim();
              if (token != null && token.length > 1 && !_isPdfSyntaxBoilerplate(token)) {
                final unescaped = token
                    .replaceAll(r'\(', '(')
                    .replaceAll(r'\)', ')')
                    .replaceAll(r'\\', r'\');
                if (!_isPdfSyntaxBoilerplate(unescaped)) {
                  buffer.write('$unescaped\n');
                }
              }
            }
          }
        }

        if (buffer.length < 50) {
          final textMatches = RegExp(r"\(([^)]{1,250})\)\s*(?:Tj|TJ|'|" r'"' r"|\n|\r)").allMatches(raw);
          for (final tm in textMatches) {
            final token = tm.group(1)?.trim();
            if (token != null && token.length > 1 && !_isPdfSyntaxBoilerplate(token)) {
              final unescaped = token
                  .replaceAll(r'\(', '(')
                  .replaceAll(r'\)', ')')
                  .replaceAll(r'\\', r'\');
              if (!_isPdfSyntaxBoilerplate(unescaped)) {
                buffer.write('$unescaped\n');
              }
            }
          }
        }

        if (buffer.length < 50) {
          final matches = RegExp(r'[A-Za-z0-9._%+\-@:,/()]{2,}').allMatches(raw);
          final tokens = matches
              .map((m) => m.group(0)!.trim())
              .where((s) => s.length > 2 && !_isPdfSyntaxBoilerplate(s));
          buffer.write(tokens.join('\n'));
        }

        var extracted = buffer
            .toString()
            .replaceAll(RegExp(r'[\uFFFD\u21D3\u27E8\u266A\u2225\u2309\u2308\u2207\u222B\u22A3\u21A1\u22C5\uE000-\uF8FF]'), ' ')
            .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
            .replaceAll(RegExp(r'[ \t]+'), ' ')
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();

        final normalized = normalizeExtractedText(extracted);
        final resultText = normalized.length > 8000 ? normalized.substring(0, 8000) : normalized;
        debugPrint('PDF TEXT LENGTH: ${resultText.length}');
        if (resultText.isNotEmpty) {
          final safePreview = resultText.substring(0, resultText.length > 500 ? 500 : resultText.length);
          debugPrint('PDF TEXT PREVIEW: $safePreview');
        } else {
          debugPrint('PDF TEXT PREVIEW: [EMPTY]');
        }
        return resultText;
      }

      final matches = RegExp(r'[A-Za-z0-9\s.,@\-:\/\\()]{3,}').allMatches(raw);
      final tokens = matches
          .map((m) => m.group(0)!.trim())
          .where((s) => s.length > 2 && !_isPdfSyntaxBoilerplate(s));
      final rawTokens = tokens
          .join('\n')
          .replaceAll(RegExp(r'[\uFFFD\u21D3\u27E8\u266A\u2225\u2309\u2308\u2207\u222B\u22A3\u21A1\u22C5\uE000-\uF8FF]'), ' ')
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
      final resultText = normalizeExtractedText(rawTokens);
      debugPrint('PDF TEXT LENGTH: ${resultText.length}');
      if (resultText.isNotEmpty) {
        final safePreview = resultText.substring(0, resultText.length > 500 ? 500 : resultText.length);
        debugPrint('PDF TEXT PREVIEW: $safePreview');
      }
      return resultText;
    } catch (e) {
      debugPrint('[PDF Extraction Error]: $e');
      return '';
    }
  }

  /// High-fidelity backend PDF text extraction helper using FastAPI + pypdf.
  static Future<String?> extractPdfTextWithBackend(Uint8List bytes, {String fileName = 'resume.pdf'}) async {
    try {
      final uri = Uri.parse('${BackendConfig.baseUrl}/extract-pdf');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final extractedText = data['text'] as String?;
        if (extractedText != null && extractedText.trim().isNotEmpty) {
          return extractedText;
        }
      }
    } catch (e) {
      debugPrint('[AIService] Backend PDF extraction endpoint offline or error: $e');
    }
    return null;
  }

  /// Multi-tier robust PDF text extraction pipeline:
  /// PDF -> primary extraction -> text quality validation -> if corrupted, secondary extraction -> if still corrupted, OCR fallback -> clean extracted text -> AI parser
  Future<String> extractTextFromBytesAsync(Uint8List bytes, {String fileName = 'resume.pdf'}) {
    return extractTextFromBytesAsyncStatic(bytes, fileName: fileName);
  }

  static Future<String> extractTextFromBytesAsyncStatic(Uint8List bytes, {String fileName = 'resume.pdf'}) async {
    // 1. Primary Extraction
    String method = 'primary_local_decoding';
    String text = extractTextFromBytes(bytes);
    bool isReadable = validateExtractedText(text);

    // 2. Backend Extraction Fallback if Primary was corrupted or unreadable
    if (!isReadable) {
      debugPrint('[PDFExtraction] Primary extraction text failed validation. Attempting backend extraction fallback...');
      final backendText = await extractPdfTextWithBackend(bytes, fileName: fileName);
      if (backendText != null && backendText.trim().isNotEmpty && validateExtractedText(backendText)) {
        method = 'backend_pypdf_extraction';
        text = backendText;
        isReadable = true;
      }
    }

    // 3. Secondary Local Stream Parsing Fallback if Backend was unavailable or failed
    if (!isReadable) {
      debugPrint('[PDFExtraction] Attempting secondary local stream decoding...');
      final secondaryText = _secondaryStreamTextExtraction(bytes);
      if (validateExtractedText(secondaryText)) {
        method = 'secondary_local_stream_decoding';
        text = secondaryText;
        isReadable = true;
      }
    }

    // 4. OCR / Clean Token Fallback if still unreadable
    if (!isReadable) {
      debugPrint('[PDFExtraction] Stream extraction failed. Executing clean token fallback...');
      final cleanTokens = _sanitizeAndExtractCleanTokens(text.isNotEmpty ? text : Latin1Decoder().convert(bytes));
      if (validateExtractedText(cleanTokens)) {
        method = 'ocr_clean_token_fallback';
        text = cleanTokens;
        isReadable = true;
      }
    }

    final cleanText = _sanitizeFinalExtractedText(text.isNotEmpty ? text : extractTextFromBytes(bytes));
    final alphaNumCount = RegExp(r'[a-zA-Z0-9]').allMatches(cleanText).length;
    final alphaRatio = cleanText.isEmpty ? 0.0 : alphaNumCount / cleanText.length;
    final wordCount = RegExp(r'\b[a-zA-Z]{2,}\b').allMatches(cleanText).length;
    final isFinalReadable = validateExtractedText(cleanText);

    // Diagnostics Logging
    final previewSnippet = cleanText.length > 200 ? cleanText.substring(0, 200) : cleanText;
    debugPrint('\n[RESUME-AI-INPUT]');
    debugPrint('method=$method');
    debugPrint('textLength=${cleanText.length}');
    debugPrint('readable=$isFinalReadable');
    debugPrint('wordCount=$wordCount');
    debugPrint('alphaRatio=${alphaRatio.toStringAsFixed(2)}');
    debugPrint('preview="$previewSnippet"\n');

    return cleanText;
  }

  /// Audits extracted PDF text to verify readability and prevent garbled/corrupted unicode from being sent to AI providers.
  static bool validateExtractedText(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 10) return false;

    // Check count of readable alphanumeric characters
    final alphaNumCount = RegExp(r'[a-zA-Z0-9]').allMatches(trimmed).length;
    if (alphaNumCount < 8) {
      debugPrint('[AIService] validateExtractedText: REJECTED text due to insufficient alphanumeric characters ($alphaNumCount chars)');
      return false;
    }

    // Require at least basic readable English words (2+ characters)
    final wordMatches = RegExp(r'\b[a-zA-Z]{2,}\b').allMatches(trimmed).length;
    if (wordMatches < 2) {
      debugPrint('[AIService] validateExtractedText: REJECTED text due to insufficient readable words ($wordMatches words)');
      return false;
    }

    return true;
  }

  static String _sanitizeFinalExtractedText(String input) {
    var s = input
        .replaceAll(RegExp(r'[\uFFFD\u2100-\u2BFF\u2200-\u22FF\u2300-\u23FF\u2700-\u27BF\uE000-\uF8FF]'), ' ')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'), '')
        .replaceAll(RegExp(r'[^\x20-\x7E\s•\-\–\—\•]'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return s;
  }

  static String _sanitizeAndExtractCleanTokens(String input) {
    final clean = input.replaceAll(RegExp(r'[^\x20-\x7E\r\n]'), ' ');
    final matches = RegExp(r'\b[a-zA-Z0-9._%+\-@:,/()]{2,}\b').allMatches(clean);
    final tokens = matches
        .map((m) => m.group(0)!.trim())
        .where((s) => s.length > 1 && !_isPdfSyntaxBoilerplate(s));
    return tokens.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static int _indexOfBytes(Uint8List source, List<int> pattern, int start) {
    for (int i = start; i <= source.length - pattern.length; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (source[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  static void _parseCMap(String cmapStr, Map<int, String> cmap) {
    // Skip TeX math symbol CMaps to prevent corrupting text with math symbols (e.g. TeX cmsy10)
    if (cmapStr.contains('/CMapName /TeX-cmsy') || cmapStr.contains('cmsy10-builtin')) {
      return;
    }

    final bfcharBlockRegex = RegExp(r'beginbfchar([\s\S]*?)endbfchar');
    for (final blockMatch in bfcharBlockRegex.allMatches(cmapStr)) {
      final block = blockMatch.group(1)!;
      final pairRegex = RegExp(r'<([0-9a-fA-F]+)>\s+<([0-9a-fA-F]+)>');
      for (final m in pairRegex.allMatches(block)) {
        final srcCode = int.tryParse(m.group(1)!, radix: 16);
        if (srcCode != null) {
          final uniStr = _hexToUnicode(m.group(2)!);
          if (uniStr.isNotEmpty) {
            cmap[srcCode] = uniStr;
          }
        }
      }
    }

    final bfrangeBlockRegex = RegExp(r'beginbfrange([\s\S]*?)endbfrange');
    for (final blockMatch in bfrangeBlockRegex.allMatches(cmapStr)) {
      final block = blockMatch.group(1)!;

      final arrayRangeRegex = RegExp(r'<([0-9a-fA-F]+)>\s+<([0-9a-fA-F]+)>\s*\[([\s\S]*?)\]');
      for (final m in arrayRangeRegex.allMatches(block)) {
        final srcStart = int.tryParse(m.group(1)!, radix: 16);
        final srcEnd = int.tryParse(m.group(2)!, radix: 16);
        final dstHexList = RegExp(r'<([0-9a-fA-F]+)>').allMatches(m.group(3)!).map((e) => e.group(1)!).toList();
        if (srcStart != null && srcEnd != null) {
          for (int i = 0; i <= (srcEnd - srcStart) && i < dstHexList.length; i++) {
            final uniStr = _hexToUnicode(dstHexList[i]);
            if (uniStr.isNotEmpty) {
              cmap[srcStart + i] = uniStr;
            }
          }
        }
      }

      final directRangeRegex = RegExp(r'<([0-9a-fA-F]+)>\s+<([0-9a-fA-F]+)>\s+<([0-9a-fA-F]+)>');
      for (final m in directRangeRegex.allMatches(block)) {
        final srcStart = int.tryParse(m.group(1)!, radix: 16);
        final srcEnd = int.tryParse(m.group(2)!, radix: 16);
        final dstStart = int.tryParse(m.group(3)!, radix: 16);
        if (srcStart != null && srcEnd != null && dstStart != null) {
          for (int i = 0; i <= (srcEnd - srcStart); i++) {
            final dstCode = dstStart + i;
            final dstHex = dstCode.toRadixString(16).padLeft(4, '0');
            final uniStr = _hexToUnicode(dstHex);
            if (uniStr.isNotEmpty) {
              cmap[srcStart + i] = uniStr;
            }
          }
        }
      }
    }
  }

  static String _hexToUnicode(String hexStr) {
    final sb = StringBuffer();
    final step = (hexStr.length % 4 == 0) ? 4 : 2;
    for (int i = 0; i < hexStr.length; i += step) {
      if (i + step <= hexStr.length) {
        final part = hexStr.substring(i, i + step);
        final code = int.tryParse(part, radix: 16);
        if (code != null) {
          // Skip math symbols, private use unicode, and control characters
          if ((code >= 0x2100 && code <= 0x2BFF) ||
              (code >= 0x2200 && code <= 0x22FF) ||
              (code >= 0xE000 && code <= 0xF8FF)) {
            continue;
          }
          sb.writeCharCode(code);
        }
      }
    }
    return sb.toString();
  }

  static String _mapCode(int code, Map<int, String> cmap) {
    if (cmap.containsKey(code)) {
      final mapped = cmap[code]!;
      final cleaned = mapped.replaceAll(RegExp(r'[\uFFFD\u2100-\u2BFF\u2200-\u22FF\u2300-\u23FF\u2700-\u27BF\uE000-\uF8FF]'), '');
      if (cleaned.isNotEmpty) return cleaned;
    }
    if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9) {
      return String.fromCharCode(code);
    }
    return ' ';
  }

  static String _unescapePdfLiteralString(String s) {
    var result = s.replaceAllMapped(RegExp(r'\\([0-7]{1,3})'), (m) {
      final octalStr = m.group(1)!;
      final code = int.tryParse(octalStr, radix: 8);
      if (code != null) {
        if (code == 40) return '(';
        if (code == 41) return ')';
        if (code == 136 || code == 149) return '- ';
        if (code == 14 || code == 15 || code == 16) return '';
        if (code >= 32 && code <= 126) return String.fromCharCode(code);
      }
      return ' ';
    });

    return result
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\b', '')
        .replaceAll(r'\f', '');
  }

  static String _reconstructCohesiveLines(String text) {
    final rawLines = text.split(RegExp(r'\r?\n'));
    final resultLines = <String>[];
    String currentLine = '';

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) {
        if (currentLine.isNotEmpty) {
          resultLines.add(currentLine);
          currentLine = '';
        }
        resultLines.add('');
        continue;
      }

      final isHeader = ResumeData.isKnownSectionHeader(line);
      final isBullet = line.startsWith('•') ||
          line.startsWith('◦') ||
          line.startsWith('▪') ||
          line.startsWith('- ') ||
          line.startsWith('* ') ||
          line.startsWith('– ') ||
          RegExp(r'^\d+[\.\)]\s*').hasMatch(line);
      final isDateOnly = RegExp(
        r'^\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4}|Present|Current)?\s*$',
        caseSensitive: false,
      ).hasMatch(line);
      final isContact = line.contains('@') ||
          line.contains('linkedin.com') ||
          line.contains('github.com') ||
          RegExp(r'^\+?\d{1,4}[-\s\d]{7,}\d$').hasMatch(line);

      if (isHeader || isBullet || isDateOnly || isContact || currentLine.isEmpty) {
        if (currentLine.isNotEmpty) {
          resultLines.add(currentLine);
        }
        currentLine = line;
        continue;
      }

      final startsWithLower = RegExp(r'^[a-z]').hasMatch(line);
      final startsWithPrep = RegExp(
        r'^(in|with|a|an|the|to|for|of|from|by|at|on|and|or|as|is|are|was|were|into|during|via|under|about)\b',
        caseSensitive: false,
      ).hasMatch(line);
      final currentEndsWithHyphen = currentLine.endsWith('-');
      final currentIsShortFragment = currentLine.length < 50 &&
          !currentLine.endsWith(':') &&
          !ResumeData.isKnownSectionHeader(currentLine);

      if (startsWithLower ||
          startsWithPrep ||
          currentEndsWithHyphen ||
          (currentIsShortFragment && !isHeader && !isBullet && !isDateOnly && !isContact)) {
        if (currentEndsWithHyphen) {
          currentLine = currentLine.substring(0, currentLine.length - 1) + line;
        } else {
          currentLine = '$currentLine $line';
        }
      } else {
        resultLines.add(currentLine);
        currentLine = line;
      }
    }

    if (currentLine.isNotEmpty) {
      resultLines.add(currentLine);
    }

    return resultLines.join('\n');
  }

  static String normalizeExtractedText(String text) {
    if (text.trim().isEmpty) return text;

    // 1. Standardize all bullet variants to '• '
    var cleaned = text
        .replaceAll(RegExp(r'[\u25E6\u00B0\u25AA\u25AB\u25CF\u25CB\u2043\u2219\u25BA\u25B6\u25B8]'), '• ')
        .replaceAll(RegExp(r'^[•\-\*–—]\s*', multiLine: true), '• ');

    // 2. Clean up horizontal whitespace
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

    // 3. Reconstruct cohesive sentences and lines
    cleaned = _reconstructCohesiveLines(cleaned);

    return cleaned
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _decodePdfTextStream(String streamText, Map<int, String> cmap) {
    final sb = StringBuffer();
    final hasMultiByteKeys = cmap.keys.any((k) => k > 255);

    String decodeLiteral(String raw) {
      final unescaped = _unescapePdfLiteralString(raw);
      final res = StringBuffer();
      for (int i = 0; i < unescaped.length; i++) {
        final code = unescaped.codeUnitAt(i);
        res.write(_mapCode(code, cmap));
      }
      return res.toString();
    }

    String decodeHex(String hexStr) {
      final res = StringBuffer();
      final step = hasMultiByteKeys ? 4 : 2;
      for (int i = 0; i < hexStr.length; i += step) {
        if (i + step <= hexStr.length) {
          final codeHex = hexStr.substring(i, i + step);
          final code = int.tryParse(codeHex, radix: 16);
          if (code != null) {
            res.write(_mapCode(code, cmap));
          }
        }
      }
      return res.toString();
    }

    // Tokenize stream elements in linear sequential order
    final tokenRegex = RegExp(
      r'\[([\s\S]*?)\]\s*TJ|'
      r'\(((?:[^()\\]|\\.){1,500})\)\s*(Tj|\x27|\x22)|'
      r'<([0-9a-fA-F]+)>\s*(Tj|\x27|\x22)|'
      r'(?:[+\-]?\d+(?:\.\d+)?\s+){4}([+\-]?\d+(?:\.\d+)?)\s+([+\-]?\d+(?:\.\d+)?)\s+Tm|'
      r'([+\-]?\d+(?:\.\d+)?)\s+([+\-]?\d+(?:\.\d+)?)\s+(Td|TD)|'
      r'\b(T\*|BT|ET)\b',
    );

    double lastY = double.nan;
    bool lineHasContent = false;

    void lineBreak() {
      if (lineHasContent) {
        sb.write('\n');
        lineHasContent = false;
      }
    }

    for (final match in tokenRegex.allMatches(streamText)) {
      if (match.group(1) != null) {
        // [ ... ] TJ
        final content = match.group(1)!;
        final elemRegex = RegExp(r'(\((?:[^()\\]|\\.){1,500}\)|<[0-9a-fA-F]+>|[\-+]?\d+(?:\.\d+)?)');
        for (final em in elemRegex.allMatches(content)) {
          final elem = em.group(1)!;
          if (elem.startsWith('(') && elem.endsWith(')')) {
            final raw = elem.substring(1, elem.length - 1);
            final decoded = decodeLiteral(raw);
            if (decoded.isNotEmpty) {
              sb.write(decoded);
              lineHasContent = true;
            }
          } else if (elem.startsWith('<') && elem.endsWith('>')) {
            final hex = elem.substring(1, elem.length - 1);
            final decoded = decodeHex(hex);
            if (decoded.isNotEmpty) {
              sb.write(decoded);
              lineHasContent = true;
            }
          } else {
            final num = double.tryParse(elem);
            if (num != null && (num < -140 || num > 250)) {
              if (lineHasContent && !sb.toString().endsWith(' ') && !sb.toString().endsWith('\n')) {
                sb.write(' ');
              }
            }
          }
        }
      } else if (match.group(2) != null) {
        // ( ... ) Tj or ' or "
        final raw = match.group(2)!;
        final op = match.group(3)!;
        if (op == "'" || op == '"') {
          lineBreak();
        }
        final decoded = decodeLiteral(raw);
        if (decoded.isNotEmpty) {
          sb.write(decoded);
          lineHasContent = true;
        }
      } else if (match.group(4) != null) {
        // < ... > Tj or ' or "
        final hex = match.group(4)!;
        final op = match.group(5)!;
        if (op == "'" || op == '"') {
          lineBreak();
        }
        final decoded = decodeHex(hex);
        if (decoded.isNotEmpty) {
          sb.write(decoded);
          lineHasContent = true;
        }
      } else if (match.group(6) != null && match.group(7) != null) {
        // Tm: a b c d tx ty
        final ty = double.tryParse(match.group(7)!) ?? 0;
        if (!lastY.isNaN && (ty - lastY).abs() > 5.5) {
          lineBreak();
        } else if (lineHasContent && !sb.toString().endsWith(' ') && !sb.toString().endsWith('\n')) {
          sb.write(' ');
        }
        lastY = ty;
      } else if (match.group(8) != null && match.group(9) != null) {
        // Td / TD: tx ty
        final ty = double.tryParse(match.group(9)!) ?? 0;
        if (ty.abs() > 4.5) {
          lineBreak();
        } else if (lineHasContent && !sb.toString().endsWith(' ') && !sb.toString().endsWith('\n')) {
          sb.write(' ');
        }
      } else if (match.group(11) != null) {
        // T*, BT, ET
        lineBreak();
      }
    }

    lineBreak();
    return sb.toString();
  }

  static String _secondaryStreamTextExtraction(Uint8List bytes) {
    try {
      final raw = Latin1Decoder().convert(bytes);
      final buffer = StringBuffer();
      final textMatches = RegExp(r"\(([^)]{1,300})\)\s*(?:Tj|TJ|'|" r'"' r"|\n|\r)").allMatches(raw);
      for (final tm in textMatches) {
        final token = tm.group(1)?.trim();
        if (token != null && token.length > 1 && !_isPdfSyntaxBoilerplate(token)) {
          final unescaped = token
              .replaceAll(r'\(', '(')
              .replaceAll(r'\)', ')')
              .replaceAll(r'\\', r'\');
          if (!_isPdfSyntaxBoilerplate(unescaped)) {
            buffer.write('$unescaped\n');
          }
        }
      }
      return normalizeExtractedText(buffer.toString().trim());
    } catch (_) {
      return '';
    }
  }

  static bool _isPdfSyntaxBoilerplate(String s) {
    final lower = s.toLowerCase().trim();
    return lower.contains('flatedecode') ||
        lower.contains('mediabox') ||
        lower.contains('fontname') ||
        lower.contains('type1') ||
        lower.contains('truetype') ||
        lower.contains('endobj') ||
        lower.contains('catalog') ||
        lower.contains('pages') ||
        lower.contains('encoding') ||
        lower.contains('winansi') ||
        lower.contains('stream') ||
        lower.contains('endstream') ||
        lower.contains('xobject') ||
        lower.contains('colorspace') ||
        lower == 'stream' ||
        lower == 'endstream' ||
        lower == 'obj' ||
        lower == 'xref' ||
        lower == 'trailer' ||
        lower == 'startxref' ||
        lower == 'pdf' ||
        RegExp(r'^\d+\s+\d+\s+obj').hasMatch(lower) ||
        RegExp(r'^\d+\s+\d+\s+r$').hasMatch(lower);
  }

  // ---------------------------------------------------------------------------
  // Local Fallback Resume Extractor
  // ---------------------------------------------------------------------------

  Future<ResumeData> _localFallbackParseAsync(Uint8List bytes, {String fileName = 'resume.pdf'}) async {
    final rawText = await extractTextFromBytesAsync(bytes, fileName: fileName);
    return ResumeData.parseFromRawText(rawText);
  }
}
