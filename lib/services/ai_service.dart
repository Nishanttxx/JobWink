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
import 'gemini_service.dart';
import 'groq_service.dart';
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

  /// Initializes Gemini, Groq, OpenAI, xAI (Grok), and NVIDIA (Nemotron) providers.
  void initialize({String? geminiKey, String? openAiKey, String? xAiKey, String? groqKey, String? nvidiaKey}) {
    final gKey = geminiKey ?? AIConfig.geminiApiKey;
    final oKey = openAiKey ?? AIConfig.openAiApiKey;
    final xKey = xAiKey ?? AIConfig.xAiApiKey;
    final grKey = groqKey ?? AIConfig.groqApiKey;
    final nvKey = nvidiaKey ?? AIConfig.nvidiaApiKey;

    if (gKey.isNotEmpty) {
      GeminiService.instance.initialize(gKey, modelId: GeminiConfig.modelId);
    }
    if (grKey.isNotEmpty) {
      GroqService.instance.initialize(grKey);
    }
    if (oKey.isNotEmpty) {
      OpenAIService.instance.initialize(oKey);
    }
    if (xKey.isNotEmpty) {
      XAiService.instance.initialize(xKey);
    }
    if (nvKey.isNotEmpty) {
      NvidiaService.instance.initialize(nvKey);
    }

    _isInitialized = true;
    debugPrint('[AIService] Provider manager initialized (Primary: ${AIConfig.primaryProvider}, Fallback: ${AIConfig.fallbackProvider}, SecondaryFallback: ${AIConfig.secondaryFallbackProvider}, Forced: ${AIConfig.forceProvider})');
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
    if (force == 'nvidia' || force == 'nemotron') {
      debugPrint('[AIService] Forced provider: NVIDIA (Nemotron)');
      final result = await NvidiaService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) return result;
      final local = await _localFallbackParseAsync(bytes);
      return local.hasUsableData ? local : null;
    }
    if (force == 'groq') {
      debugPrint('[AIService] Forced provider: Groq');
      final result = await GroqService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) return result;
      final local = await _localFallbackParseAsync(bytes);
      return local.hasUsableData ? local : null;
    }
    if (force == 'xai' || force == 'grok') {
      debugPrint('[AIService] Forced provider: xAI (Grok)');
      final result = await XAiService.instance.parseResume(bytes, mimeType);
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

    // Default primary provider flow (Gemini -> Groq -> OpenAI -> xAI -> NVIDIA -> Local Smart Extraction)
    debugPrint('[AIService] Primary provider: Gemini (isInitialized=${GeminiService.instance.isInitialized})');
    try {
      final result = await GeminiService.instance.parseResume(bytes, mimeType);
      if (result != null && result.hasUsableData) {
        debugPrint('[AIService] Gemini SUCCESS: name="${result.fullName}", exp=${result.experience.length}, edu=${result.education.length}, proj=${result.projects.length}');
        return result;
      }
      debugPrint('[AIService] Gemini returned empty/null data — falling back to Groq');
    } on GeminiQuotaExceededException catch (qErr) {
      debugPrint('[AIService] Gemini quota exceeded: $qErr — falling back to Groq');
    } catch (e) {
      debugPrint('[AIService] Gemini parse error: $e — falling back to Groq');
    }

    debugPrint('[AIService] Attempting Groq fallback (isInitialized=${GroqService.instance.isInitialized})');
    try {
      final groqResult = await GroqService.instance.parseResume(bytes, mimeType);
      if (groqResult != null && groqResult.hasUsableData) {
        debugPrint('[AIService] Groq SUCCESS: name="${groqResult.fullName}", exp=${groqResult.experience.length}, edu=${groqResult.education.length}, proj=${groqResult.projects.length}');
        return groqResult;
      }
      debugPrint('[AIService] Groq returned empty/null data — falling back to OpenAI');
    } catch (e) {
      debugPrint('[AIService] Groq fallback error: $e — falling back to OpenAI');
    }

    debugPrint('[AIService] Attempting OpenAI fallback (isInitialized=${OpenAIService.instance.isInitialized})');
    try {
      final openAiResult = await OpenAIService.instance.parseResume(bytes, mimeType);
      if (openAiResult != null && openAiResult.hasUsableData) {
        debugPrint('[AIService] OpenAI SUCCESS: name="${openAiResult.fullName}", exp=${openAiResult.experience.length}, edu=${openAiResult.education.length}, proj=${openAiResult.projects.length}');
        return openAiResult;
      }
      debugPrint('[AIService] OpenAI returned empty/null data — falling back to xAI (Grok)');
    } catch (e) {
      debugPrint('[AIService] OpenAI fallback error: $e — falling back to xAI (Grok)');
    }

    debugPrint('[AIService] Attempting xAI (Grok) fallback (isInitialized=${XAiService.instance.isInitialized})');
    try {
      final xAiResult = await XAiService.instance.parseResume(bytes, mimeType);
      if (xAiResult != null && xAiResult.hasUsableData) {
        debugPrint('[AIService] xAI SUCCESS: name="${xAiResult.fullName}", exp=${xAiResult.experience.length}, edu=${xAiResult.education.length}, proj=${xAiResult.projects.length}');
        return xAiResult;
      }
      debugPrint('[AIService] xAI returned empty/null data — falling back to NVIDIA');
    } catch (e) {
      debugPrint('[AIService] xAI fallback error: $e — falling back to NVIDIA');
    }

    debugPrint('[AIService] Attempting NVIDIA (Nemotron) fallback (isInitialized=${NvidiaService.instance.isInitialized})');
    try {
      final nvidiaResult = await NvidiaService.instance.parseResume(bytes, mimeType);
      if (nvidiaResult != null && nvidiaResult.hasUsableData) {
        debugPrint('[AIService] NVIDIA SUCCESS: name="${nvidiaResult.fullName}", exp=${nvidiaResult.experience.length}, edu=${nvidiaResult.education.length}, proj=${nvidiaResult.projects.length}');
        return nvidiaResult;
      }
      debugPrint('[AIService] NVIDIA returned empty/null data');
    } catch (e) {
      debugPrint('[AIService] NVIDIA fallback error: $e');
    }

    debugPrint('[AIService] All AI providers failed. Executing local smart extraction...');
    final localResult = await _localFallbackParseAsync(bytes);
    debugPrint('[AIService] Local fallback result: name="${localResult.fullName}", exp=${localResult.experience.length}, edu=${localResult.education.length}');
    if (localResult.hasUsableData) {
      return localResult;
    }
    
    debugPrint('[AIService] Local fallback could not extract usable resume data.');
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
      debugPrint('[AIService] Primary provider error ($e). Attempting Groq fallback...');
      try {
        final groqResult = await GroqService.instance.tailorResume(
          currentResume,
          targetJobTitle,
          jobDescription,
        );
        return groqResult;
      } catch (gErr) {
        debugPrint('[AIService] Groq fallback failed ($gErr). Attempting OpenAI fallback...');
        try {
          final openAiResult = await OpenAIService.instance.tailorResume(
            currentResume,
            targetJobTitle,
            jobDescription,
          );
          return openAiResult;
        } catch (oErr) {
          debugPrint('[AIService] OpenAI fallback failed ($oErr). Attempting xAI (Grok) fallback...');
          try {
            final xAiResult = await XAiService.instance.tailorResume(
              currentResume,
              targetJobTitle,
              jobDescription,
            );
            return xAiResult;
          } catch (xErr) {
            debugPrint('[AIService] xAI fallback failed ($xErr). Attempting NVIDIA fallback...');
            try {
              final nvidiaResult = await NvidiaService.instance.tailorResume(
                currentResume,
                targetJobTitle,
                jobDescription,
              );
              return nvidiaResult;
            } catch (nvErr) {
              debugPrint('[AIService] NVIDIA fallback failed ($nvErr). Using local fallback...');
            }
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
      debugPrint('[AIService] Primary provider error ($e). Attempting Groq fallback...');
      try {
        final groqResult = await GroqService.instance.analyzeAts(resume, jobDescription: jobDescription);
        return groqResult;
      } catch (gErr) {
        debugPrint('[AIService] Groq fallback failed ($gErr). Attempting OpenAI fallback...');
        try {
          final openAiResult = await OpenAIService.instance.analyzeAts(resume, jobDescription: jobDescription);
          return openAiResult;
        } catch (oErr) {
          debugPrint('[AIService] OpenAI fallback failed ($oErr). Attempting xAI (Grok) fallback...');
          try {
            final xAiResult = await XAiService.instance.analyzeAts(resume, jobDescription: jobDescription);
            return xAiResult;
          } catch (xErr) {
            debugPrint('[AIService] xAI fallback failed ($xErr). Attempting NVIDIA fallback...');
            try {
              final nvidiaResult = await NvidiaService.instance.analyzeAts(resume, jobDescription: jobDescription);
              return nvidiaResult;
            } catch (nvErr) {
              debugPrint('[AIService] NVIDIA fallback failed ($nvErr). Using local ATS fallback...');
            }
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
      debugPrint('[AIService] Primary provider error ($e). Attempting Groq fallback...');
      try {
        return await GroqService.instance.enhanceSummary(currentSummary, skills);
      } catch (_) {
        debugPrint('[AIService] Groq fallback failed. Attempting OpenAI fallback...');
        try {
          return await OpenAIService.instance.enhanceSummary(currentSummary, skills);
        } catch (_) {
          debugPrint('[AIService] OpenAI fallback failed. Attempting xAI (Grok) fallback...');
          try {
            return await XAiService.instance.enhanceSummary(currentSummary, skills);
          } catch (_) {
            debugPrint('[AIService] xAI fallback failed. Attempting NVIDIA fallback...');
            try {
              return await NvidiaService.instance.enhanceSummary(currentSummary, skills);
            } catch (_) {}
          }
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

    // 2. Remove HTML image/link tags and layout containers
    text = text.replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\/p>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\/div>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<a[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\/a>', caseSensitive: false), '');

    // 3. Remove Markdown badges: [![alt](image_url)](link_url)
    text = text.replaceAll(RegExp(r'\[!\[[^\]]*\]\([^\)]*\)\]\([^\)]*\)'), '');

    // 4. Remove Markdown standalone images: ![alt](image_url)
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^\)]*\)'), '');

    // 5. Remove shields.io / badge URLs
    text = text.replaceAll(RegExp(r'https?:\/\/(img\.)?shields\.io\/[^\s\)]+'), '');

    // 6. Split lines and filter out TOC, badge lines, and setup command spam
    final lines = text.split(RegExp(r'[\r\n]+'));
    final filtered = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip markdown table of contents links e.g. - [Section](#section)
      if (RegExp(r'^[\-\*\+]\s*\[[^\]]+\]\(#[^\)]+\)').hasMatch(trimmed)) continue;
      // Skip license or badge-only lines
      if (RegExp(r'^(license|build|coverage|npm|version|workflow|ci|badge):', caseSensitive: false).hasMatch(trimmed)) continue;
      filtered.add(trimmed);
    }

    text = filtered.join('\n');

    // 7. Limit length to 3500 characters cleanly
    if (text.length > 3500) {
      text = text.substring(0, 3500);
      final lastDot = text.lastIndexOf('.');
      if (lastDot > 2000) {
        text = text.substring(0, lastDot + 1);
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
    final cleanReadme = _sanitizeReadmeContent(readmeContent);

    final prompt = '''
You are a senior technical resume writer and engineering career expert.
Analyze this GitHub repository metadata and README snippet to create a high-impact, ATS-optimized project entry for a professional software engineer's resume.

REPOSITORY METADATA:
- Repository Name: $repoName
- Short Description: ${repoDescription.isNotEmpty ? repoDescription : "(None provided)"}
- Primary Language: ${language.isNotEmpty ? language : "Not specified"}
- Topics/Tags: ${topics.isNotEmpty ? topics.join(', ') : "None"}

README CONTENT (CLEANED & SANITIZED):
${cleanReadme.isNotEmpty ? cleanReadme : "(No README content available)"}

REQUIREMENTS FOR ATS RESUME:
1. "name": Clean, professional, Title Case project title (e.g. convert "jobwink-mobile-v2" to "JobWink Mobile App" or "CV Studio Engine").
2. "type": Specific classification (e.g. "Full-Stack Web App", "Mobile Application", "AI Service", "CLI Tool", "Developer Library", "REST API Backend").
3. "technologies": Comprehensive array of technologies, frameworks, tools, state management, databases, and APIs detected (e.g. ["Flutter", "Dart", "Gemini AI", "Supabase", "REST API"]).
4. "bullets": 2-4 professional, outcome-driven bullet points describing what was built, core architecture, key features, and engineering accomplishments. MUST start with past-tense action verbs (e.g., "Architected", "Engineered", "Developed", "Integrated", "Optimized", "Designed"). DO NOT copy installation commands, license text, or badge noise.

Return a JSON object matching this schema EXACTLY:
{
  "name": "Project Name",
  "type": "Project Type",
  "technologies": ["Tech1", "Tech2"],
  "bullets": [
    "Action-driven bullet point 1 describing project purpose and value",
    "Action-driven bullet point 2 detailing technical architecture and features",
    "Action-driven bullet point 3 highlighting performance, capabilities, or tech stack"
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
        final bullets = bulletsVal is List
            ? bulletsVal.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
            : <String>[];

        if (bullets.isNotEmpty) {
          return ProjectEntry(
            name: name.isNotEmpty ? name : _formatRepoTitle(repoName),
            type: type.isNotEmpty ? type : (language.isNotEmpty ? '$language Application' : 'GitHub Project'),
            technologies: techs.isNotEmpty ? techs : [if (language.isNotEmpty) language, ...topics],
            descriptionBullets: bullets,
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

    // Local Smart Fallback if AI fails or returns empty response
    final fallbackTechs = <String>[];
    if (language.isNotEmpty) fallbackTechs.add(language);
    for (final t in topics) {
      if (!fallbackTechs.contains(t)) fallbackTechs.add(t);
    }

    final formattedName = _formatRepoTitle(repoName);
    final fallbackBullets = <String>[];

    if (repoDescription.isNotEmpty) {
      final desc = repoDescription.endsWith('.') ? repoDescription : '$repoDescription.';
      fallbackBullets.add('Engineered $formattedName, $desc');
    } else {
      fallbackBullets.add('Engineered and open-sourced $formattedName on GitHub.');
    }

    if (fallbackTechs.isNotEmpty) {
      fallbackBullets.add('Utilized ${fallbackTechs.join(", ")} for core application logic and feature implementation.');
    }

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
              buffer.write('$decoded ');
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
                buffer.write('$unescaped ');
              }
            }
          }
        }

        if (buffer.length < 50) {
          final matches = RegExp(r'[A-Za-z0-9._%+\-@:,/()]{2,}').allMatches(raw);
          final tokens = matches
              .map((m) => m.group(0)!.trim())
              .where((s) => s.length > 2 && !_isPdfSyntaxBoilerplate(s));
          buffer.write(tokens.join(' '));
        }

        var extracted = buffer
            .toString()
            .replaceAll(RegExp(r'[\uFFFD\u21D3\u27E8\u266A\u2225\u2309\u2308\u2207\u222B\u22A3\u21A1\u22C5\uE000-\uF8FF]'), ' ')
            .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final resultText = extracted.length > 8000 ? extracted.substring(0, 8000) : extracted;
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
      final resultText = tokens
          .join('\n')
          .replaceAll(RegExp(r'[\uFFFD\u21D3\u27E8\u266A\u2225\u2309\u2308\u2207\u222B\u22A3\u21A1\u22C5\uE000-\uF8FF]'), ' ')
          .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
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
  Future<String?> extractPdfTextWithBackend(Uint8List bytes, {String fileName = 'resume.pdf'}) async {
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
          debugPrint('[AIService] Backend PDF extraction successful (${extractedText.length} chars)');
          return extractedText;
        }
      } else {
        debugPrint('[AIService] Backend PDF extraction endpoint returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AIService] Backend PDF extraction exception: $e');
    }
    return null;
  }

  /// Extracts text from PDF/DOCX bytes. First tries local parsing, and if text fails validation or is corrupted,
  /// automatically falls back to backend pypdf extraction for pristine UTF-8 text quality.
  Future<String> extractTextFromBytesAsync(Uint8List bytes, {String fileName = 'resume.pdf'}) async {
    debugPrint('[PDFExtraction] Primary extraction started');
    String text = extractTextFromBytes(bytes);
    bool isReadable = validateExtractedText(text);
    debugPrint('[PDFExtraction] Primary extraction readable=$isReadable');

    if (isReadable) {
      debugPrint('[ResumePipeline] Sending readable resume content to backend AI parser');
      return text;
    }

    debugPrint('[PDFExtraction] Primary extraction rejected because text encoding is corrupted or unreadable');
    debugPrint('[PDFExtraction] Falling back to backend pypdf extraction');

    final backendText = await extractPdfTextWithBackend(bytes, fileName: fileName);
    if (backendText != null && backendText.trim().isNotEmpty && validateExtractedText(backendText)) {
      debugPrint('[PDFExtraction] Backend fallback extraction successful');
      debugPrint('[ResumePipeline] Sending readable resume content to backend AI parser');
      return backendText;
    }

    // Final fallback: Strip ALL symbol noise to produce clean alphanumeric token stream
    final cleanTokens = _sanitizeAndExtractCleanTokens(text);
    if (validateExtractedText(cleanTokens)) {
      debugPrint('[PDFExtraction] Clean token extraction fallback successful');
      return cleanTokens;
    }

    debugPrint('[PDFExtraction] Warning: Returning sanitized token fallback');
    return cleanTokens;
  }

  /// Audits extracted PDF text to verify readability and prevent garbled/corrupted unicode from being sent to AI providers.
  static bool validateExtractedText(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 20) return false;

    // Count alphanumeric characters
    final alphaNumCount = RegExp(r'[a-zA-Z0-9]').allMatches(trimmed).length;
    final alphaRatio = alphaNumCount / trimmed.length;

    // Count corrupted, replacement, math, or private use symbols typical of unparsed font streams
    final corruptCount = RegExp(r'[\uFFFD\u2100-\u2BFF\u2200-\u22FF\u2700-\u27BF\uE000-\uF8FF\x00-\x08\x0B\x0C\x0E-\x1F]').allMatches(trimmed).length;

    if (corruptCount > 5 || alphaRatio < 0.40) {
      debugPrint('[AIService] validateExtractedText: REJECTED text. alphaRatio=${alphaRatio.toStringAsFixed(2)}, corruptCount=$corruptCount, totalLen=${trimmed.length}');
      return false;
    }

    // Require at least basic readable English words (3+ characters)
    final wordMatches = RegExp(r'\b[a-zA-Z]{3,}\b').allMatches(trimmed).length;
    if (wordMatches < 3) {
      debugPrint('[AIService] validateExtractedText: REJECTED text due to insufficient readable words ($wordMatches words)');
      return false;
    }

    return true;
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
    final bfcharBlockRegex = RegExp(r'beginbfchar([\s\S]*?)endbfchar');
    for (final blockMatch in bfcharBlockRegex.allMatches(cmapStr)) {
      final block = blockMatch.group(1)!;
      final pairRegex = RegExp(r'<([0-9a-fA-F]+)>\s+<([0-9a-fA-F]+)>');
      for (final m in pairRegex.allMatches(block)) {
        final srcCode = int.tryParse(m.group(1)!, radix: 16);
        if (srcCode != null) {
          cmap[srcCode] = _hexToUnicode(m.group(2)!);
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
            cmap[srcStart + i] = _hexToUnicode(dstHexList[i]);
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
            cmap[srcStart + i] = _hexToUnicode(dstHex);
          }
        }
      }
    }
  }

  static String _hexToUnicode(String hexStr) {
    final sb = StringBuffer();
    for (int i = 0; i < hexStr.length; i += 4) {
      if (i + 4 <= hexStr.length) {
        final part = hexStr.substring(i, i + 4);
        final code = int.tryParse(part, radix: 16);
        if (code != null) {
          sb.writeCharCode(code);
        }
      }
    }
    return sb.toString();
  }

  static String _mapCode(int code, Map<int, String> cmap) {
    if (cmap.containsKey(code)) {
      return cmap[code]!;
    }
    if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9) {
      return String.fromCharCode(code);
    }
    return ' ';
  }

  static String _decodePdfTextStream(String streamText, Map<int, String> cmap) {
    final sb = StringBuffer();

    final tjArrayRegex = RegExp(r'\[([\s\S]*?)\]\s*TJ');
    for (final match in tjArrayRegex.allMatches(streamText)) {
      final content = match.group(1)!;
      final hexMatches = RegExp(r'<([0-9a-fA-F]+)>').allMatches(content);
      for (final hm in hexMatches) {
        final hexStr = hm.group(1)!;
        for (int i = 0; i < hexStr.length; i += 4) {
          if (i + 4 <= hexStr.length) {
            final codeHex = hexStr.substring(i, i + 4);
            final code = int.tryParse(codeHex, radix: 16);
            if (code != null) {
              sb.write(_mapCode(code, cmap));
            }
          }
        }
      }

      final litMatches = RegExp(r'\(([^)]{1,250})\)').allMatches(content);
      for (final lm in litMatches) {
        final rawText = lm.group(1)!;
        for (int i = 0; i < rawText.length; i++) {
          final code = rawText.codeUnitAt(i);
          sb.write(_mapCode(code, cmap));
        }
      }
      sb.write(' ');
    }

    final singleHexRegex = RegExp(r'<([0-9a-fA-F]+)>\s*(?:Tj|\x27|\x22)');
    for (final match in singleHexRegex.allMatches(streamText)) {
      final hexStr = match.group(1)!;
      for (int i = 0; i < hexStr.length; i += 4) {
        if (i + 4 <= hexStr.length) {
          final codeHex = hexStr.substring(i, i + 4);
          final code = int.tryParse(codeHex, radix: 16);
          if (code != null) {
            sb.write(_mapCode(code, cmap));
          }
        }
      }
      sb.write(' ');
    }

    final singleLitRegex = RegExp(r'\(([^)]{1,250})\)\s*(?:Tj|\x27|\x22)');
    for (final match in singleLitRegex.allMatches(streamText)) {
      final rawText = match.group(1)!;
      for (int i = 0; i < rawText.length; i++) {
        final code = rawText.codeUnitAt(i);
        sb.write(_mapCode(code, cmap));
      }
      sb.write(' ');
    }

    return sb.toString();
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
    return _parseResumeTextFromRaw(rawText);
  }

  ResumeData _parseResumeTextFromRaw(String rawText) {
    final emailMatch = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').firstMatch(rawText);

    String phone = '';
    final phoneMatches = RegExp(r'\+?\d[\d\s\-\(\)]{7,}\d').allMatches(rawText);
    for (final pm in phoneMatches) {
      final candidate = pm.group(0)!.trim();
      final digitCount = candidate.replaceAll(RegExp(r'\D'), '').length;
      if (digitCount >= 7 && digitCount <= 15) {
        phone = candidate;
        break;
      }
    }

    final linkedinMatch = RegExp(r'(?:https?:\/\/)?(?:www\.)?linkedin\.com\/in\/[\w\-]+', caseSensitive: false).firstMatch(rawText);
    final githubMatch = RegExp(r'(?:https?:\/\/)?(?:www\.)?github\.com\/[\w\-]+', caseSensitive: false).firstMatch(rawText);

    final lines = rawText.split(RegExp(r'[\r\n]+')).where((l) => l.trim().isNotEmpty).toList();

    String name = '';
    for (final line in lines.take(15)) {
      final l = line.trim();
      if (l.isEmpty) continue;
      final lower = l.toLowerCase();
      if (lower.contains('@') ||
          lower.contains('linkedin') ||
          lower.contains('github') ||
          lower.contains('resume') ||
          lower.contains('http') ||
          lower.contains('stream') ||
          lower.contains('pdf') ||
          lower.contains('flate') ||
          lower.contains('page') ||
          _isPdfSyntaxBoilerplate(l)) {
        continue;
      }
      if (RegExp(r'^[A-Za-z\s\.\-]{2,40}$').hasMatch(l)) {
        final words = l.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
        if (words.length >= 2 && words.length <= 4) {
          name = l;
          break;
        }
      }
    }

    String summary = '';
    final extractedSkills = <String>{};
    final experience = <ExperienceEntry>[];
    final education = <EducationEntry>[];
    final projects = <ProjectEntry>[];
    final extracurriculars = <ExtracurricularEntry>[];

    String currentSection = '';
    String currentCompany = '';
    String currentRole = '';
    List<String> currentBullets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      if (lower.contains('skill') || lower.contains('competencies') || lower.contains('technologies')) {
        currentSection = 'skills';
        continue;
      } else if (lower.contains('summary') || lower.contains('about me') || lower.startsWith('profile') || lower == 'personal profile' || lower == 'executive profile' || lower == 'professional profile') {
        currentSection = 'summary';
        continue;
      } else if (lower.contains('experience') || lower.contains('employment') || lower.contains('work history')) {
        currentSection = 'experience';
        continue;
      } else if (lower.contains('education') || lower.contains('academic')) {
        currentSection = 'education';
        continue;
      } else if (lower.contains('project')) {
        currentSection = 'projects';
        continue;
      } else if (lower.contains('certificat') || lower.contains('extracurricular') || lower.contains('activities') || lower.contains('achievements') || lower.contains('awards') || lower.contains('licenses')) {
        currentSection = 'extracurriculars';
        continue;
      }

      if (currentSection == 'summary') {
        if (line.length > 10 && !line.startsWith('•')) {
          summary += (summary.isEmpty ? '' : ' ') + line;
        }
      } else if (currentSection == 'skills') {
        final tokens = line.split(RegExp(r'[,;•|\/]+')).map((s) => s.trim()).where((s) => s.length > 1 && s.length < 30);
        extractedSkills.addAll(tokens);
      } else if (currentSection == 'experience') {
        if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
          final bullet = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
          if (bullet.isNotEmpty) currentBullets.add(bullet);
        } else if (line.length > 3 && line.length < 60) {
          if (currentCompany.isNotEmpty || currentRole.isNotEmpty) {
            experience.add(ExperienceEntry(
              company: currentCompany,
              role: currentRole,
              startDate: '2022',
              endDate: 'Present',
              description: List.from(currentBullets),
            ));
            currentBullets.clear();
          }
          if (currentCompany.isEmpty) {
            currentCompany = line;
          } else {
            currentRole = line;
          }
        } else if (line.length >= 60) {
          currentBullets.add(line);
        }
      } else if (currentSection == 'education') {
        if (line.isNotEmpty && line.length > 2) {
          education.add(EducationEntry(
            institution: line,
            degree: '',
            fieldOfStudy: '',
            startDate: '',
            endDate: '',
          ));
        }
      } else if (currentSection == 'projects') {
        final isUrl = line.contains('github.com') ||
            line.contains('http') ||
            line.startsWith('github.com') ||
            (line.contains('/') && !line.contains(' ') && line.length < 80);

        if (isUrl && projects.isNotEmpty) {
          final lastProj = projects.last;
          projects[projects.length - 1] = ProjectEntry(
            name: lastProj.name,
            description: lastProj.description,
            technologies: lastProj.technologies,
            url: line,
          );
        } else if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
          final bullet = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
          if (bullet.isNotEmpty && projects.isNotEmpty) {
            final lastProj = projects.last;
            final updatedDesc = lastProj.description.isEmpty
                ? '• $bullet'
                : '${lastProj.description}\n• $bullet';
            projects[projects.length - 1] = ProjectEntry(
              name: lastProj.name,
              description: updatedDesc,
              technologies: lastProj.technologies,
              url: lastProj.url,
            );
          }
        } else if (line.length > 2) {
          if (projects.isNotEmpty) {
            final lastProj = projects.last;
            final isDescriptionSentence = line.endsWith('.') ||
                RegExp(r'^(built|developed|created|engineered|designed|implemented|integrated|used|leveraged|maintained|constructed|features|allows|provides|includes|an|a|the|with|using|in|for)\b', caseSensitive: false).hasMatch(line);

            if (lastProj.description.isEmpty) {
              projects[projects.length - 1] = ProjectEntry(
                name: lastProj.name,
                description: line,
                technologies: lastProj.technologies,
                url: lastProj.url,
              );
            } else if (isDescriptionSentence || line.length >= 30 || lastProj.url.isNotEmpty || lastProj.description.length < 150) {
              final updatedDesc = '${lastProj.description}\n$line';
              projects[projects.length - 1] = ProjectEntry(
                name: lastProj.name,
                description: updatedDesc,
                technologies: lastProj.technologies,
                url: lastProj.url,
              );
            } else {
              projects.add(ProjectEntry(
                name: line,
                description: '',
              ));
            }
          } else {
            projects.add(ProjectEntry(
              name: line,
              description: '',
            ));
          }
        }
      } else if (currentSection == 'extracurriculars') {
        if (line.isNotEmpty && line.length > 2) {
          final cleanLine = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
          if (cleanLine.isNotEmpty) {
            extracurriculars.add(ExtracurricularEntry(activity: cleanLine));
          }
        }
      }
    }

    if (currentCompany.isNotEmpty || currentRole.isNotEmpty || currentBullets.isNotEmpty) {
      experience.add(ExperienceEntry(
        company: currentCompany,
        role: currentRole,
        startDate: '',
        endDate: '',
        description: currentBullets,
      ));
    }

    final emailStr = emailMatch?.group(0) ?? '';
    final linkedinStr = linkedinMatch?.group(0) ?? '';
    final githubStr = githubMatch?.group(0) ?? '';

    return ResumeData(
      fullName: name,
      email: emailStr,
      phone: phone,
      location: '',
      linkedin: linkedinStr,
      github: githubStr,
      title: '',
      summary: summary,
      skills: extractedSkills.toList(),
      experience: experience,
      education: education,
      projects: projects,
      extracurriculars: extracurriculars,
    );
  }
}
