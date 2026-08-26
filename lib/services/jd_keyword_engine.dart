import 'package:flutter/foundation.dart';
import '../models/resume_data.dart';

/// Engine responsible for analyzing Job Descriptions, determining keyword weightage
/// (High, Medium, Low), and performing authentic semantic matching strictly against
/// a candidate's Projects and Experience sections without fabricating experience.
class JdKeywordEngine {
  JdKeywordEngine._();
  static final JdKeywordEngine instance = JdKeywordEngine._();

  // Core technical terms, frameworks, languages, AI/ML models, algorithms, and databases
  static final Set<String> _coreTechnicalDict = {
    // Programming Languages & Runtimes
    'python', 'python3', 'javascript', 'typescript', 'dart', 'flutter', 'java', 'kotlin',
    'swift', 'golang', 'go', 'c++', 'c#', 'rust', 'php', 'ruby', 'sql', 'html',
    'css', 'sass', 'node.js', 'nodejs', 'node', 'react', 'react native', 'vue', 'angular',
    'next.js', 'express', 'fastapi', 'django', 'flask', 'spring boot', 'laravel',

    // Databases & Cloud Infrastructure
    'postgresql', 'postgres', 'mysql', 'mongodb', 'redis', 'sqlite', 'oracle',
    'dynamodb', 'elasticsearch', 'supabase', 'firebase', 'aws', 'amazon web services',
    'azure', 'gcp', 'google cloud', 'google cloud platform', 'docker', 'dockerized',
    'kubernetes', 'k8s', 'terraform', 'graphql', 'rest api', 'rest apis', 'restful apis',
    'restful api', 'microservices', 'ci/cd', 'git', 'github', 'gitlab',

    // AI / ML & Data Science
    'tensorflow', 'pytorch', 'scikit-learn', 'sklearn', 'opencv', 'nlp',
    'natural language processing', 'llm', 'llms', 'large language model',
    'large language models', 'rag', 'machine learning', 'ml', 'deep learning',
    'artificial intelligence', 'ai', 'ai/ml', 'data science', 'computer vision',
    'neural networks', 'transformers', 'genai', 'generative ai', 'gen ai',
    'prompt engineering', 'model deployment', 'data engineering', 'data processing',
    'logistic regression', 'decision tree', 'decision trees', 'knn', 'gridsearchcv',
    'api development', 'api orchestration', 'gemini api', 'openai',
  };

  // Secondary tools, methodologies, and engineering concepts
  static final Set<String> _secondaryTechnicalDict = {
    'agile', 'scrum', 'jira', 'confluence', 'github actions', 'gitlab ci',
    'unit testing', 'integration testing', 'api testing', 'system architecture',
    'oops', 'object-oriented programming', 'state management', 'bloc', 'provider',
    'riverpod', 'redux', 'mvvm', 'clean architecture', 'web sockets', 'webhooks',
    'oauth', 'jwt', 'stripe', 'aws s3', 'aws lambda', 'cloud functions',
    'pandas', 'numpy', 'matplotlib', 'seaborn', 'keras', 'huggingface',
    'full stack', 'frontend', 'backend', 'cybersecurity', 'scalable solutions',
    'scalable backend services', 'software engineering', 'software development',
  };

  // Generic words that MUST NOT be highlighted / given high weight
  static final Set<String> _genericWordDict = {
    'the', 'and', 'with', 'for', 'you', 'that', 'this', 'have', 'from',
    'will', 'your', 'team', 'work', 'role', 'job', 'looking', 'engineer',
    'developer', 'senior', 'junior', 'lead', 'manager', 'experience',
    'years', 'strong', 'ability', 'skills', 'good', 'must', 'requirements',
    'responsibilities', 'company', 'position', 'location', 'full', 'time',
    'development', 'system', 'application', 'technology', 'technologies',
    'building', 'solutions', 'tools', 'using', 'developed', 'communication',
    'collaboration', 'written', 'verbal', 'problem', 'solving', 'environment',
    'hands-on', 'degree', 'computer', 'science', 'engineering', 'knowledge',
    'we', 'our', 'they', 'seeking', 'needed', 'wanted', 'about', 'join',
    'preferred', 'required', 'qualifications', 'plus', 'desired', 'candidate',
  };

  /// Extracts keywords from a Job Description and categorizes their weightage:
  /// HIGH WEIGHT, MEDIUM WEIGHT, LOW WEIGHT.
  List<JobKeyword> extractKeywordsFromJd(String jobDescription) {
    if (jobDescription.trim().isEmpty) return const [];

    final weightedMap = _analyzeAndScoreJdKeywords(jobDescription);
    return weightedMap.values.toList();
  }

  /// Calculates weighted score for every candidate keyword in the JD.
  Map<String, JobKeyword> _analyzeAndScoreJdKeywords(String jobDescription) {
    final cleanJd = jobDescription.toLowerCase();
    final candidateScores = <String, double>{};
    final candidatePhrases = <String, String>{};

    // 1. Identify section contexts in JD (Required vs Preferred vs Responsibilities)
    final requiredSection = _extractSectionText(cleanJd, [
      'requirements', 'required', 'required skills', 'must have', 'must-have',
      'qualifications', 'basic qualifications', 'minimum qualifications',
    ]);
    final preferredSection = _extractSectionText(cleanJd, [
      'preferred', 'preferred qualifications', 'nice to have', 'nice-to-have',
      'bonus', 'good to have', 'plus', 'desired',
    ]);
    final respSection = _extractSectionText(cleanJd, [
      'responsibilities', 'duties', 'what you will do', 'what you\'ll do',
      'role', 'key responsibilities',
    ]);

    // 2. Scan for dictionary terms in JD
    final allKnownTerms = {..._coreTechnicalDict, ..._secondaryTechnicalDict};
    for (final term in allKnownTerms) {
      final termMatches = _countTermOccurrences(cleanJd, term);
      if (termMatches > 0) {
        double score = 0.0;

        // Base technical specificity
        if (_coreTechnicalDict.contains(term)) {
          score += 35.0;
        } else if (_secondaryTechnicalDict.contains(term)) {
          score += 20.0;
        }

        // Section requirement strength
        if (requiredSection.isNotEmpty && _containsTerm(requiredSection, term)) {
          score += 35.0;
        } else if (respSection.isNotEmpty && _containsTerm(respSection, term)) {
          score += 25.0;
        } else if (preferredSection.isNotEmpty && _containsTerm(preferredSection, term)) {
          score += 15.0;
        } else {
          score += 20.0;
        }

        // Frequency weighting: Repeated terms get higher weight
        if (termMatches >= 3) {
          score += 30.0;
        } else if (termMatches == 2) {
          score += 15.0;
        }

        // Multi-word bonus
        if (term.contains(' ')) {
          score += 10.0;
        }

        candidateScores[term] = score;
        candidatePhrases[term] = _formatCapitalization(term);
      }
    }

    // 3. Scan capitalized multi-word phrases and technical terms from JD
    final phraseRegex = RegExp(r'\b[A-Z][A-Za-z0-9+#.]{1,25}(?:\s+[A-Z][A-Za-z0-9+#.]{1,25})*\b');
    for (final match in phraseRegex.allMatches(jobDescription)) {
      final phrase = match.group(0)?.trim();
      if (phrase == null || phrase.length < 2) continue;
      final lower = phrase.toLowerCase();

      if (_genericWordDict.contains(lower)) continue;
      if (lower.split(' ').any((w) => _genericWordDict.contains(w) && w == lower.split(' ').first)) {
        // Skip phrases starting with common sentence starters like 'We are', 'Seeking an'
        continue;
      }
      if (lower.split(' ').every((w) => _genericWordDict.contains(w))) continue;

      if (!candidateScores.containsKey(lower)) {
        double score = 15.0;
        final termMatches = _countTermOccurrences(cleanJd, lower);

        if (requiredSection.isNotEmpty && _containsTerm(requiredSection, lower)) {
          score += 30.0;
        } else if (respSection.isNotEmpty && _containsTerm(respSection, lower)) {
          score += 20.0;
        } else if (preferredSection.isNotEmpty && _containsTerm(preferredSection, lower)) {
          score += 10.0;
        }

        if (termMatches >= 3) {
          score += 25.0;
        } else if (termMatches == 2) {
          score += 12.0;
        }

        if (phrase.contains(' ')) {
          score += 10.0;
        }

        candidateScores[lower] = score;
        candidatePhrases[lower] = phrase;
      }
    }

    // 4. Classify into HIGH, MEDIUM, LOW priority
    final resultMap = <String, JobKeyword>{};
    for (final entry in candidateScores.entries) {
      final term = entry.key;
      final score = entry.value;
      final originalPhrase = candidatePhrases[term] ?? _formatCapitalization(term);

      String priority;
      if (score >= 55.0) {
        priority = 'high';
      } else if (score >= 30.0) {
        priority = 'medium';
      } else {
        priority = 'low';
      }

      resultMap[term] = JobKeyword(
        keyword: originalPhrase,
        priority: priority,
      );
    }

    return resultMap;
  }

  /// Extracts keywords from JD, ranks them, and matches them ONLY against
  /// `resume.projects` and `resume.experience`.
  ///
  /// Strictly excludes Skills, Summary, Education, Certifications, Extracurriculars.
  List<String> extractProjectsAndExperienceKeywords({
    required String jobDescription,
    required ResumeData resume,
    List<String>? aiExtractedKeywords,
  }) {
    if (jobDescription.trim().isEmpty) return const [];

    final jdAnalysis = _analyzeAndScoreJdKeywords(jobDescription);

    // Merge in any AI-provided extracted keywords with priority
    if (aiExtractedKeywords != null && aiExtractedKeywords.isNotEmpty) {
      for (final rawKw in aiExtractedKeywords) {
        final kw = rawKw.trim();
        if (kw.length < 2) continue;
        final lower = kw.toLowerCase();
        if (_genericWordDict.contains(lower)) continue;

        if (!jdAnalysis.containsKey(lower)) {
          final isCore = _coreTechnicalDict.contains(lower);
          final priority = isCore ? 'high' : 'medium';
          jdAnalysis[lower] = JobKeyword(keyword: _formatCapitalization(kw), priority: priority);
        }
      }
    }

    // Separate into high weight, medium weight, and low weight
    final highWeightKeywords = <String>[];
    final mediumWeightKeywords = <String>[];
    final lowWeightKeywords = <String>[];

    for (final kw in jdAnalysis.values) {
      if (kw.priority == 'high') {
        highWeightKeywords.add(kw.keyword);
      } else if (kw.priority == 'medium') {
        mediumWeightKeywords.add(kw.keyword);
      } else {
        lowWeightKeywords.add(kw.keyword);
      }
    }

    // Build project-only text corpus
    final projBuffer = StringBuffer();
    for (final proj in resume.projects) {
      projBuffer.writeln('${proj.name} ${proj.type} ${proj.technologies.join(' ')}');
      projBuffer.writeln(proj.description);
      for (final b in proj.descriptionBullets) {
        projBuffer.writeln(b);
      }
    }
    final projCorpus = projBuffer.toString();

    // Build experience-only text corpus
    final expBuffer = StringBuffer();
    for (final exp in resume.experience) {
      expBuffer.writeln('${exp.role} ${exp.company} ${exp.location}');
      for (final b in exp.description) {
        expBuffer.writeln(b);
      }
    }
    final expCorpus = expBuffer.toString();

    // Eligible terms to darken: HIGH WEIGHT + relevant MEDIUM WEIGHT
    final eligibleTerms = <JobKeyword>[
      ...jdAnalysis.values.where((k) => k.priority == 'high' || k.priority == 'medium'),
    ];

    // Sort by multi-word phrase length descending so full phrases match first
    eligibleTerms.sort((a, b) => b.keyword.length.compareTo(a.keyword.length));

    final projectMatches = <String>{};
    final experienceMatches = <String>{};
    final allMatchedHighlightTerms = <String>{};

    for (final item in eligibleTerms) {
      final term = item.keyword;

      final matchedInProj = _findMatchingAliasesInText(term, projCorpus);
      if (matchedInProj.isNotEmpty) {
        projectMatches.addAll(matchedInProj);
        allMatchedHighlightTerms.addAll(matchedInProj);
      }

      final matchedInExp = _findMatchingAliasesInText(term, expCorpus);
      if (matchedInExp.isNotEmpty) {
        experienceMatches.addAll(matchedInExp);
        allMatchedHighlightTerms.addAll(matchedInExp);
      }
    }

    // Sort matched highlight terms by length descending for clean regex tokenization
    final sortedMatchedKeywords = allMatchedHighlightTerms.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Structured [HIGHLIGHT] & [WEIGHT DEBUG] Logging
    debugPrint('============================================================');
    debugPrint('[HIGHLIGHT-1] JOB DESCRIPTION:\n$jobDescription');
    debugPrint('[HIGHLIGHT-2] AI KEYWORDS:\n${aiExtractedKeywords ?? []}');
    debugPrint('[HIGHLIGHT-3] NORMALIZED KEYWORDS:\n${jdAnalysis.values.map((k) => '${k.keyword} (${k.priority.toUpperCase()})').toList()}');
    debugPrint('[HIGHLIGHT-4] PROJECT TEXT:\n$projCorpus');
    debugPrint('[HIGHLIGHT-5] EXPERIENCE TEXT:\n$expCorpus');
    debugPrint('[HIGHLIGHT-6] PROJECT MATCHES:\n${projectMatches.toList()}');
    debugPrint('[HIGHLIGHT-7] EXPERIENCE MATCHES:\n${experienceMatches.toList()}');
    debugPrint('[WEIGHT DEBUG] Job Keywords:');
    debugPrint(jdAnalysis.values.map((k) => '${k.keyword} (${k.priority.toUpperCase()})').toList().toString());
    debugPrint('[WEIGHT DEBUG] HIGH WEIGHT:');
    debugPrint(highWeightKeywords.toString());
    debugPrint('[WEIGHT DEBUG] MEDIUM WEIGHT:');
    debugPrint(mediumWeightKeywords.toString());
    debugPrint('[WEIGHT DEBUG] Project Matches:');
    debugPrint(projectMatches.toList().toString());
    debugPrint('[WEIGHT DEBUG] Experience Matches:');
    debugPrint(experienceMatches.toList().toString());
    debugPrint('[WEIGHT DEBUG] Highlighted Spans:');
    debugPrint(sortedMatchedKeywords.toString());
    debugPrint('============================================================');

    return sortedMatchedKeywords;
  }

  /// Verifies which keywords or semantic aliases are present in [targetText]
  /// with strict word boundary enforcement.
  Set<String> _findMatchingAliasesInText(String term, String targetText) {
    if (targetText.trim().isEmpty) return const {};

    final matched = <String>{};
    final lowerTerm = term.toLowerCase().trim();
    if (lowerTerm.length < 2 && lowerTerm != 'c' && lowerTerm != 'r') return const {};

    // 1. Direct word-boundary match
    final escaped = RegExp.escape(lowerTerm);
    final pattern = RegExp('(?<=^|[^a-zA-Z0-9])$escaped(?=[^a-zA-Z0-9]|\$)', caseSensitive: false);
    if (pattern.hasMatch(targetText)) {
      matched.add(_formatCapitalization(term));
    }

    // 2. Semantic & Morphological Technical Equivalences
    final aliases = _getSemanticAliases(lowerTerm);
    for (final alias in aliases) {
      if (alias.toLowerCase() == lowerTerm) continue;
      final aliasEscaped = RegExp.escape(alias);
      final aliasPattern = RegExp('(?<=^|[^a-zA-Z0-9])$aliasEscaped(?=[^a-zA-Z0-9]|\$)', caseSensitive: false);
      if (aliasPattern.hasMatch(targetText)) {
        matched.add(_formatCapitalization(term));
        matched.add(_formatCapitalization(alias));
      }
    }

    return matched;
  }

  /// Extracts section text if any target header keywords are found.
  String _extractSectionText(String fullText, List<String> headers) {
    for (final h in headers) {
      final idx = fullText.indexOf(h);
      if (idx != -1) {
        final snippet = fullText.substring(idx);
        final endIdx = snippet.indexOf('\n\n');
        return endIdx != -1 ? snippet.substring(0, endIdx) : snippet;
      }
    }
    return '';
  }

  int _countTermOccurrences(String text, String term) {
    final escaped = RegExp.escape(term);
    final pattern = RegExp('(?<=^|[^a-zA-Z0-9])$escaped(?=[^a-zA-Z0-9]|\$)', caseSensitive: false);
    return pattern.allMatches(text).length;
  }

  bool _containsTerm(String text, String term) {
    return _countTermOccurrences(text, term) > 0;
  }

  List<String> _getSemanticAliases(String term) {
    switch (term.toLowerCase()) {
      case 'postgresql':
      case 'postgres':
        return ['postgres', 'postgresql'];
      case 'node.js':
      case 'nodejs':
      case 'node':
        return ['node.js', 'nodejs', 'node'];
      case 'react':
      case 'reactjs':
      case 'react.js':
        return ['react', 'reactjs', 'react.js'];
      case 'vue':
      case 'vuejs':
      case 'vue.js':
        return ['vue', 'vuejs', 'vue.js'];
      case 'rest api':
      case 'rest apis':
      case 'restful api':
      case 'restful apis':
      case 'rest':
        return ['rest api', 'rest apis', 'restful api', 'restful apis'];
      case 'docker':
      case 'dockerized':
      case 'containerization':
      case 'containers':
        return ['docker', 'dockerized', 'containers', 'containerization'];
      case 'python':
      case 'python3':
        return ['python', 'python3'];
      case 'git':
      case 'github':
        return ['git', 'github'];
      case 'aws':
      case 'amazon web services':
        return ['aws', 'amazon web services'];
      case 'gcp':
      case 'google cloud':
      case 'google cloud platform':
        return ['gcp', 'google cloud', 'google cloud platform'];
      case 'k8s':
      case 'kubernetes':
        return ['k8s', 'kubernetes'];
      case 'machine learning':
      case 'ml':
        return ['machine learning', 'ml'];
      case 'natural language processing':
      case 'nlp':
        return ['natural language processing', 'nlp'];
      case 'large language model':
      case 'large language models':
      case 'llm':
      case 'llms':
        return ['large language model', 'large language models', 'llm', 'llms'];
      case 'artificial intelligence':
      case 'ai':
      case 'ai/ml':
        return ['artificial intelligence', 'ai', 'ai/ml'];
      case 'generative ai':
      case 'genai':
      case 'gen ai':
        return ['generative ai', 'genai', 'gen ai'];
      case 'scikit-learn':
      case 'sklearn':
        return ['scikit-learn', 'sklearn'];
      case 'ci/cd':
      case 'continuous integration':
        return ['ci/cd', 'continuous integration'];
      case 'typescript':
      case 'ts':
        return ['typescript', 'ts'];
      case 'javascript':
      case 'js':
        return ['javascript', 'js'];
      case 'software engineer':
      case 'software engineering':
      case 'software development':
        return ['software engineer', 'software engineering', 'software development'];
      case 'model deployment':
        return ['model deployment', 'deploy machine learning models', 'deploy machine learning'];
      case 'data processing':
      case 'process datasets':
        return ['data processing', 'process datasets', 'data optimization'];
      case 'scalable backend services':
      case 'scalable solutions':
        return ['scalable backend services', 'scalable solutions'];
      default:
        return [term];
    }
  }

  String _formatCapitalization(String term) {
    switch (term.toLowerCase()) {
      case 'git': return 'Git';
      case 'sql': return 'SQL';
      case 'aws': return 'AWS';
      case 'gcp': return 'GCP';
      case 'nlp': return 'NLP';
      case 'llm': return 'LLM';
      case 'llms': return 'LLMs';
      case 'rag': return 'RAG';
      case 'ci/cd': return 'CI/CD';
      case 'api': return 'API';
      case 'apis': return 'APIs';
      case 'restful apis': return 'RESTful APIs';
      case 'rest api': return 'REST APIs';
      case 'rest apis': return 'REST APIs';
      case 'node.js': return 'Node.js';
      case 'next.js': return 'Next.js';
      case 'fastapi': return 'FastAPI';
      case 'postgresql': return 'PostgreSQL';
      case 'postgres': return 'Postgres';
      case 'mongodb': return 'MongoDB';
      case 'graphql': return 'GraphQL';
      case 'typescript': return 'TypeScript';
      case 'javascript': return 'JavaScript';
      case 'flutter': return 'Flutter';
      case 'dart': return 'Dart';
      case 'python': return 'Python';
      case 'docker': return 'Docker';
      case 'kubernetes': return 'Kubernetes';
      case 'machine learning': return 'Machine Learning';
      case 'ml': return 'ML';
      case 'ai': return 'AI';
      case 'ai/ml': return 'AI/ML';
      case 'generative ai': return 'Generative AI';
      case 'deep learning': return 'Deep Learning';
      case 'computer vision': return 'Computer Vision';
      case 'data engineering': return 'Data Engineering';
      case 'data processing': return 'Data Processing';
      case 'model deployment': return 'Model Deployment';
      case 'prompt engineering': return 'Prompt Engineering';
      default:
        if (term.length <= 3) return term.toUpperCase();
        return term.split(' ').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1);
        }).join(' ');
    }
  }
}

/// Represents an ATS keyword extracted from a Job Description along with its priority and match status.
class JobKeyword {
  final String keyword;
  final String priority; // 'high' | 'medium' | 'low'
  final bool matched;

  const JobKeyword({
    required this.keyword,
    this.priority = 'medium',
    this.matched = false,
  });

  JobKeyword copyWith({
    String? keyword,
    String? priority,
    bool? matched,
  }) {
    return JobKeyword(
      keyword: keyword ?? this.keyword,
      priority: priority ?? this.priority,
      matched: matched ?? this.matched,
    );
  }

  factory JobKeyword.fromJson(Map<String, dynamic> json) {
    return JobKeyword(
      keyword: json['keyword'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      matched: json['matched'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'keyword': keyword,
        'priority': priority,
        'matched': matched,
      };
}
