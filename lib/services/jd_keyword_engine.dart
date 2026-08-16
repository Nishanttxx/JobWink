import '../models/resume_data.dart';

/// Engine responsible for extracting ATS keywords from Job Descriptions,
/// prioritizing them, and performing authentic semantic matching against
/// a candidate's resume without fabricating experience.
class JdKeywordEngine {
  JdKeywordEngine._();
  static final JdKeywordEngine instance = JdKeywordEngine._();

  // Known high-priority technical terms, frameworks, tools, and certifications
  static final Set<String> _highPriorityDict = {
    // Languages & Core Runtimes
    'python', 'javascript', 'typescript', 'dart', 'flutter', 'java', 'kotlin',
    'swift', 'golang', 'go', 'c++', 'c#', 'rust', 'php', 'ruby', 'sql', 'html',
    'css', 'sass', 'node.js', 'nodejs', 'react', 'react native', 'vue', 'angular',
    'next.js', 'express', 'fastapi', 'django', 'flask', 'spring boot', 'laravel',

    // Databases & Cloud
    'postgresql', 'postgres', 'mysql', 'mongodb', 'redis', 'sqlite', 'oracle',
    'dynamodb', 'elasticsearch', 'supabase', 'firebase', 'aws', 'azure', 'gcp',
    'google cloud', 'docker', 'kubernetes', 'k8s', 'terraform', 'graphql',
    'rest api', 'restful apis', 'restful api', 'microservices', 'ci/cd', 'git',

    // AI / ML & Specializations
    'tensorflow', 'pytorch', 'scikit-learn', 'opencv', 'nlp', 'llm', 'rag',
    'machine learning', 'deep learning', 'artificial intelligence', 'data science',
    'computer vision', 'neural networks', 'transformers', 'genai', 'generative ai',
    'cybersecurity', 'data engineering', 'full stack', 'frontend', 'backend',
  };

  static final Set<String> _mediumPriorityDict = {
    'agile', 'scrum', 'jira', 'confluence', 'github actions', 'gitlab ci',
    'unit testing', 'integration testing', 'system architecture', 'oops',
    'object-oriented programming', 'state management', 'bloc', 'provider',
    'riverpod', 'redux', 'mvvm', 'clean architecture', 'web sockets', 'webhooks',
    'oauth', 'jwt', 'stripe', 'aws s3', 'aws lambda', 'cloud functions',
    'pandas', 'numpy', 'matplotlib', 'seaborn', 'keras', 'huggingface',
  };

  /// Extracts keywords from a Job Description and categorizes their priority.
  List<JobKeyword> extractKeywordsFromJd(String jobDescription) {
    if (jobDescription.trim().isEmpty) return const [];

    final Map<String, JobKeyword> extractedMap = {};
    final cleanJd = jobDescription.toLowerCase();

    // 1. Match against known dictionaries
    for (final term in _highPriorityDict) {
      if (_containsTerm(cleanJd, term)) {
        final original = _formatCapitalization(term);
        extractedMap[term] = JobKeyword(keyword: original, priority: 'high');
      }
    }

    for (final term in _mediumPriorityDict) {
      if (_containsTerm(cleanJd, term) && !extractedMap.containsKey(term)) {
        final original = _formatCapitalization(term);
        extractedMap[term] = JobKeyword(keyword: original, priority: 'medium');
      }
    }

    // 2. Extract capitalized technology words / phrases from JD
    final regExp = RegExp(r'\b[A-Z][A-Za-z0-9+#.]{1,20}(?:\s+[A-Z][A-Za-z0-9+#.]{1,20})*\b');
    final matches = regExp.allMatches(jobDescription);
    for (final match in matches) {
      final phrase = match.group(0)?.trim();
      if (phrase == null || phrase.length < 2) continue;
      final lower = phrase.toLowerCase();

      // Skip common non-technical English words
      if (_isCommonWord(lower)) continue;

      if (!extractedMap.containsKey(lower)) {
        final priority = _highPriorityDict.contains(lower)
            ? 'high'
            : (_mediumPriorityDict.contains(lower) ? 'medium' : 'low');
        extractedMap[lower] = JobKeyword(keyword: phrase, priority: priority);
      }
    }

    return extractedMap.values.toList();
  }

  /// Verifies which keywords are authentically present in the candidate's resume.
  /// Sets [matched: true] if present, [matched: false] if missing.
  /// **NEVER modifies plain text or fabricates candidate experience.**
  List<JobKeyword> matchKeywordsAgainstResume(
    List<JobKeyword> keywords,
    ResumeData resume,
  ) {
    if (keywords.isEmpty) return const [];

    // Aggregate all candidate text for semantic checking
    final resumeTextBuffer = StringBuffer();
    resumeTextBuffer.writeln(resume.title);
    resumeTextBuffer.writeln(resume.summary);
    resumeTextBuffer.writeln(resume.skills.join(' '));

    for (final exp in resume.experience) {
      resumeTextBuffer.writeln('${exp.role} ${exp.company}');
      resumeTextBuffer.writeln(exp.description.join(' '));
    }
    for (final proj in resume.projects) {
      resumeTextBuffer.writeln('${proj.name} ${proj.description} ${proj.technologies}');
    }
    for (final edu in resume.education) {
      resumeTextBuffer.writeln('${edu.degree} ${edu.fieldOfStudy} ${edu.institution}');
    }
    for (final extra in resume.extracurriculars) {
      resumeTextBuffer.writeln('${extra.activity} ${extra.role} ${extra.description}');
    }

    final fullResumeText = resumeTextBuffer.toString().toLowerCase();

    return keywords.map((kw) {
      final isMatched = _isKeywordInText(kw.keyword, fullResumeText);
      return kw.copyWith(matched: isMatched);
    }).toList();
  }

  /// Unified helper combining AI extraction, local JD parsing, and authentic matching.
  List<JobKeyword> extractAndMatch({
    required String jobDescription,
    required ResumeData resume,
    List<JobKeyword>? aiKeywords,
  }) {
    final Map<String, JobKeyword> merged = {};

    // First incorporate AI-provided keywords if available
    if (aiKeywords != null && aiKeywords.isNotEmpty) {
      for (final kw in aiKeywords) {
        if (kw.keyword.trim().isNotEmpty) {
          merged[kw.keyword.toLowerCase().trim()] = kw;
        }
      }
    }

    // Extract local JD keywords to ensure complete coverage
    final localKeywords = extractKeywordsFromJd(jobDescription);
    for (final kw in localKeywords) {
      final key = kw.keyword.toLowerCase().trim();
      if (!merged.containsKey(key)) {
        merged[key] = kw;
      }
    }

    // Authentically match against user's actual resume data
    return matchKeywordsAgainstResume(merged.values.toList(), resume);
  }

  // ── Helper Utilities ──

  bool _isKeywordInText(String keyword, String fullText) {
    final target = keyword.toLowerCase().trim();
    if (target.isEmpty) return false;

    // Exact word boundary match
    final pattern = r'\b' + RegExp.escape(target) + r'\b';
    if (RegExp(pattern, caseSensitive: false).hasMatch(fullText)) {
      return true;
    }

    // Semantic / Morphological Alias Matching
    final aliases = _getSemanticAliases(target);
    for (final alias in aliases) {
      final aliasPattern = r'\b' + RegExp.escape(alias) + r'\b';
      if (RegExp(aliasPattern, caseSensitive: false).hasMatch(fullText)) {
        return true;
      }
    }

    return false;
  }

  List<String> _getSemanticAliases(String term) {
    switch (term) {
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
        return ['rest', 'restful', 'rest api', 'rest apis', 'restful apis'];
      case 'docker':
      case 'dockerized':
      case 'containerization':
        return ['docker', 'dockerized', 'containers'];
      case 'python':
      case 'python3':
        return ['python', 'python3'];
      case 'aws':
      case 'amazon web services':
        return ['aws', 'amazon web services'];
      default:
        // Handle common suffixes e.g., 'ed', 'ing', 's'
        if (term.endsWith('ing')) return [term.substring(0, term.length - 3)];
        if (term.endsWith('ed')) return [term.substring(0, term.length - 2)];
        return [];
    }
  }

  bool _containsTerm(String text, String term) {
    return RegExp(r'\b' + RegExp.escape(term) + r'\b', caseSensitive: false).hasMatch(text);
  }

  String _formatCapitalization(String term) {
    switch (term.toLowerCase()) {
      case 'sql': return 'SQL';
      case 'aws': return 'AWS';
      case 'gcp': return 'GCP';
      case 'nlp': return 'NLP';
      case 'llm': return 'LLM';
      case 'rag': return 'RAG';
      case 'ci/cd': return 'CI/CD';
      case 'api': return 'API';
      case 'apis': return 'APIs';
      case 'restful apis': return 'RESTful APIs';
      case 'rest api': return 'REST API';
      case 'node.js': return 'Node.js';
      case 'next.js': return 'Next.js';
      case 'fastapi': return 'FastAPI';
      case 'postgresql': return 'PostgreSQL';
      case 'mongodb': return 'MongoDB';
      case 'graphql': return 'GraphQL';
      case 'typescript': return 'TypeScript';
      case 'javascript': return 'JavaScript';
      case 'flutter': return 'Flutter';
      case 'dart': return 'Dart';
      case 'python': return 'Python';
      case 'docker': return 'Docker';
      case 'kubernetes': return 'Kubernetes';
      default:
        if (term.length <= 3) return term.toUpperCase();
        return term[0].toUpperCase() + term.substring(1);
    }
  }

  bool _isCommonWord(String word) {
    const commonWords = {
      'the', 'and', 'with', 'for', 'you', 'that', 'this', 'have', 'from',
      'will', 'your', 'team', 'work', 'role', 'job', 'looking', 'engineer',
      'developer', 'senior', 'junior', 'lead', 'manager', 'experience',
      'years', 'strong', 'ability', 'skills', 'good', 'must', 'requirements',
      'responsibilities', 'company', 'position', 'location', 'full', 'time',
    };
    return commonWords.contains(word);
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

