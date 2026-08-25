import 'package:flutter/foundation.dart';

class _ProjectHeaderInfo {
  final String name;
  final String subtitle;
  final String repoUrl;

  const _ProjectHeaderInfo({
    required this.name,
    this.subtitle = '',
    this.repoUrl = '',
  });
}

class _ExperienceHeaderInfo {
  final String role;
  final String company;
  final String location;
  final String startDate;
  final String endDate;

  const _ExperienceHeaderInfo({
    required this.role,
    required this.company,
    this.location = '',
    this.startDate = '',
    this.endDate = '',
  });
}

/// Structured resume data extracted by Gemini AI.
///
/// Field names match the existing frontend controllers in [ResumeEditorScreen]
/// so extracted data can populate the UI without any mapping layer.
class ResumeData {
  // ── Identity fields (maps to existing TextEditingControllers) ──
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String linkedin;
  final String github;

  // ── Professional Summary ──
  final String title;
  final String summary;

  // ── Skills ──
  final List<String> skills;
  final List<SkillGroupEntry> skillGroups;

  // ── Dynamic Sections ──
  final List<ExperienceEntry> experience;
  final List<ProjectEntry> projects;
  final List<EducationEntry> education;
  final List<ExtracurricularEntry> certifications;
  final List<ExtracurricularEntry> extracurriculars;

  // ── Metadata & Invalidation ──
  static const String currentParserVersion = 'v3.1.0';
  final String parserVersion;
  final String fileHash;

  const ResumeData({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.github = '',
    this.title = '',
    this.summary = '',
    this.skills = const [],
    this.skillGroups = const [],
    this.experience = const [],
    this.projects = const [],
    this.education = const [],
    this.certifications = const [],
    this.extracurriculars = const [],
    this.parserVersion = currentParserVersion,
    this.fileHash = '',
  });

  /// Evaluates whether this resume object contains meaningful structured section data (skills, experience, etc.).
  bool get hasStructuredSections =>
      summary.trim().isNotEmpty ||
      skills.isNotEmpty ||
      skillGroups.isNotEmpty ||
      experience.isNotEmpty ||
      education.isNotEmpty ||
      projects.isNotEmpty ||
      certifications.isNotEmpty ||
      extracurriculars.isNotEmpty;

  /// Evaluates whether this resume object contains meaningful candidate information.
  bool get hasUsableData =>
      hasStructuredSections ||
      (fullName.trim().isNotEmpty && (email.trim().isNotEmpty || phone.trim().isNotEmpty));

  /// Logs comprehensive debug metrics required for pipeline traceability.
  void logResumeMappingDebug({
    required String stage,
    int? extractedTextLength,
    String? extractedTextSnippet,
    int? aiResponseLength,
    String? rawJsonString,
  }) {
    debugPrint('\n================ [RESUME-MAPPING-DEBUG: $stage] ================');
    if (extractedTextLength != null) debugPrint('Extracted text length: $extractedTextLength');
    if (extractedTextSnippet != null && extractedTextSnippet.isNotEmpty) {
      final firstPart = extractedTextSnippet.length > 150 ? extractedTextSnippet.substring(0, 150) : extractedTextSnippet;
      final lastPart = extractedTextSnippet.length > 150 ? extractedTextSnippet.substring(extractedTextSnippet.length - 150) : '';
      debugPrint('Extracted text portions: FIRST="$firstPart" | LAST="$lastPart"');
    }
    if (aiResponseLength != null) debugPrint('AI parser response length: $aiResponseLength');
    if (rawJsonString != null && rawJsonString.isNotEmpty) {
      final snippet = rawJsonString.length > 300 ? '${rawJsonString.substring(0, 300)}...' : rawJsonString;
      debugPrint('Parsed JSON: $snippet');
    }
    debugPrint('\nResumeModel values:');
    debugPrint('\nIdentity/Profile:');
    debugPrint('Name: "${fullName.isEmpty ? "Not specified" : fullName}"');
    debugPrint('Title: "${title.isEmpty ? "Not specified" : title}"');
    debugPrint('Email: "${email.isEmpty ? "Not specified" : email}"');
    debugPrint('Phone: "${phone.isEmpty ? "Not specified" : phone}"');
    debugPrint('Location: "${location.isEmpty ? "Not specified" : location}"');
    debugPrint('LinkedIn: "${linkedin.isEmpty ? "Not specified" : linkedin}"');
    debugPrint('GitHub: "${github.isEmpty ? "Not specified" : github}"');
    debugPrint('\nSkills (${skills.length}):');
    debugPrint('${skills.take(10).toList()}');
    debugPrint('\nEducation (${education.length}):');
    debugPrint('${education.map((e) => e.degree.isNotEmpty ? (e.institution.isNotEmpty ? "${e.degree} at ${e.institution}" : e.degree) : e.institution).toList()}');
    debugPrint('\nExperience (${experience.length}):');
    debugPrint('${experience.map((e) => "${e.company} (${e.role})").toList()}');
    debugPrint('\nProjects (${projects.length}):');
    debugPrint('${projects.map((e) => e.name).toList()}');
    debugPrint('\nCertifications (${certifications.length}):');
    debugPrint('${certifications.map((e) => e.activity).toList()}');
    debugPrint('\nSummary:');
    debugPrint('"${summary.isEmpty ? "Not specified" : summary}"');
    debugPrint('=================================================================\n');
  }

  /// Identifies placeholder strings like "Not specified", "N/A", "None", single symbols, etc.
  static bool isPlaceholderValue(String s) => _isPlaceholderValue(s);

  static bool _isPlaceholderValue(String s) {
    final lower = s.toLowerCase().trim();
    if (lower.isEmpty) return true;
    final placeholders = {
      'not specified',
      '[not specified]',
      'not_specified',
      'not provided',
      '[not provided]',
      'not_provided',
      'n/a',
      'n / a',
      'na',
      'none',
      'unknown',
      'undefined',
      'null',
      'nil',
      '[name]',
      '[email]',
      '[phone]',
      '[title]',
      '[job title]',
      '[location]',
      '[linkedin]',
      '[github]',
      'no professional summary provided.',
      'no summary provided.',
      'no summary',
      'not available',
      'tbd',
      '&',
      '-',
      '--',
      '---',
      '•',
      '|',
      '*',
      '~',
      '_',
      ':',
      ';',
    };
    return placeholders.contains(lower) ||
        RegExp(r'^\[.*(?:specified|provided|available|applicable|name|title|email|phone|address|location).*\]$', caseSensitive: false).hasMatch(lower);
  }

  /// Deterministically extracts candidate name from raw header text if AI omitted it.
  static String extractNameFromRawText(String rawText) {
    if (rawText.trim().isEmpty) return '';

    final headerPart = rawText.split(RegExp(r'\b(SKILLS|EXPERIENCE|EDUCATION|PROJECTS|SUMMARY|CERTIFICATIONS|EXTRACURRICULARS)\b', caseSensitive: false)).first;

    final normalized = headerPart
        .replaceAll(RegExp(r'[|•\*\t]'), '\n')
        .replaceAll(RegExp(r' {2,}'), '\n');
    final lines = normalized.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    for (final line in lines.take(10)) {
      var candidate = line
          .replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '')
          .replaceAll(RegExp(r'\+?\d[\d\s\-\(\)]{7,}\d'), '')
          .replaceAll(RegExp(r'(?:https?:\/\/)?(?:www\.)?linkedin\.com\/\S+', caseSensitive: false), '')
          .replaceAll(RegExp(r'(?:https?:\/\/)?(?:www\.)?github\.com\/\S+', caseSensitive: false), '')
          .replaceAll(RegExp(r'[|•\-\*\/:\\]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (candidate.isEmpty) continue;
      final lower = candidate.toLowerCase();
      if (lower.contains('summary') ||
          lower.contains('curriculum') ||
          lower.contains('resume') ||
          lower.contains('education') ||
          lower.contains('experience') ||
          lower.contains('skills') ||
          lower.contains('projects') ||
          lower.contains('page ') ||
          lower.contains('contact') ||
          lower.contains('profile')) {
        continue;
      }

      final words = candidate.split(RegExp(r'\s+')).where((w) => RegExp(r'^[A-Za-z\.\-]{2,}$').hasMatch(w)).toList();
      if (words.isNotEmpty && words.length <= 4) {
        return words.join(' ');
      }
    }

    final leadMatch = RegExp(r'^([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3}|[A-Z]{2,}(?:\s+[A-Z]{2,}){1,3})\b').firstMatch(headerPart.trim());
    if (leadMatch != null) {
      return leadMatch.group(1)!.trim();
    }

    return '';
  }

  /// Deterministically parses resume fields from raw text stream using a strict hierarchical pipeline:
  /// RAW TEXT -> SECTIONS -> RECORD BLOCKS -> ENTITY FIELDS
  static ResumeData parseFromRawText(String rawText) {
    if (rawText.trim().isEmpty) return const ResumeData();

    debugPrint('\n================ RESUME EXTRACTION ================');
    debugPrint('\n[RAW TEXT]');
    debugPrint('Length: ${rawText.length}');

    final emailMatch = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').firstMatch(rawText);

    // Sanitize text for phone extraction so URL digits aren't mistaken for phone numbers
    String textForPhone = rawText
        .replaceAll(RegExp(r'https?:\/\/\S+'), '')
        .replaceAll(RegExp(r'linkedin\.com\/\S+'), '')
        .replaceAll(RegExp(r'github\.com\/\S+'), '');

    String phone = '';
    final explicitPlusPhone = RegExp(r'\+\d{1,4}[\s\-\.]?\(?\d{2,4}\)?[\s\-\.]?\d{3,4}(?:[\s\-\.]?\d{3,4})?\b').firstMatch(textForPhone);
    if (explicitPlusPhone != null) {
      phone = explicitPlusPhone.group(0)!.trim();
    } else {
      final phoneMatches = RegExp(r'\b(?:\+?\d{1,4}[\s\-\.]?)?\(?\d{2,4}\)?[\s\-\.]?\d{3,4}(?:[\s\-\.]?\d{3,4})?\b').allMatches(textForPhone);
      for (final pm in phoneMatches) {
        final candidate = pm.group(0)!.trim();
        final digitCount = candidate.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount >= 7 && digitCount <= 15) {
          phone = candidate;
          break;
        }
      }
    }

    final linkedinMatch = RegExp(r'(?:https?:\/\/)?(?:www\.)?linkedin\.com\/in\/[\w\-]+', caseSensitive: false).firstMatch(rawText);
    final githubMatch = RegExp(r'(?:https?:\/\/)?(?:www\.)?github\.com\/[\w\-]+', caseSensitive: false).firstMatch(rawText);

    String name = extractNameFromRawText(rawText);
    String title = '';

    // Step 1: Normalize Section Breaks and Divide Raw Text into Section Blocks
    final normalizedText = _normalizeSectionBreaks(rawText);
    final sectionBlocks = _splitIntoSectionBlocks(normalizedText);

    // Location detection strictly from header block
    String extractedLocation = '';
    final headerLines = sectionBlocks['header'] ?? [];
    for (final line in headerLines) {
      final locMatch = RegExp(r'\b([A-Z][a-zA-Z\s]{2,20},\s*[A-Z][a-zA-Z\s]{2,20})\b').firstMatch(line);
      if (locMatch != null) {
        final cand = locMatch.group(0)!.trim();
        final candLower = cand.toLowerCase();
        final isTechOrSkill = RegExp(r'\b(python|docker|java|c\+\+|dart|flutter|html|css|sql|react|node|aws|git|rest|api|linux|tools|skills|cloud|supabase|firebase|postman)\b', caseSensitive: false).hasMatch(candLower);
        if (!candLower.contains('summary') &&
            !candLower.contains('university') &&
            !candLower.contains('college') &&
            !candLower.contains('school') &&
            !isTechOrSkill) {
          extractedLocation = cand;
          break;
        }
      }
    }

    // Title detection from header block
    final titleRegex = RegExp(r'\b(software engineer|flutter developer|full stack|frontend|backend|developer|engineer|data scientist|ui\/ux designer|product manager|project manager|system administrator|android developer|ios developer|mobile developer|analyst|consultant|architect|specialist|lead|associate|intern|administrator|director|coordinator|officer|supervisor)\b', caseSensitive: false);
    for (final line in headerLines) {
      if (line.length < 45 && titleRegex.hasMatch(line)) {
        title = line;
        break;
      }
    }

    // Extract Summary
    final summary = (sectionBlocks['summary'] ?? []).join(' ').trim();

    // Step 2: Extract Hierarchical Entities for each section block
    final skillGroups = _extractSkillGroupsFromBlock(sectionBlocks['skills'] ?? []);
    final flatSkills = skillGroups.expand((g) => g.items).toList();
    if (flatSkills.isEmpty && (sectionBlocks['skills'] ?? []).isNotEmpty) {
      for (final line in sectionBlocks['skills']!) {
        final tokens = line.split(RegExp(r'[,;•|\/\t]+')).map((s) => s.trim()).where((s) => s.length > 1 && s.length < 40 && !s.toLowerCase().contains('skill'));
        flatSkills.addAll(tokens);
      }
    }

    final education = _extractEducationFromBlock(sectionBlocks['education'] ?? []);
    final experience = _extractExperienceFromBlock(sectionBlocks['experience'] ?? []);
    final projects = _extractProjectsFromBlock(sectionBlocks['projects'] ?? []);
    final certifications = _extractExtracurricularsFromBlock(sectionBlocks['certifications'] ?? []);
    final extracurriculars = _extractExtracurricularsFromBlock(sectionBlocks['extracurriculars'] ?? []);

    final parsedData = ResumeData(
      fullName: name,
      email: emailMatch?.group(0) ?? '',
      phone: phone,
      location: extractedLocation,
      linkedin: linkedinMatch?.group(0) ?? '',
      github: githubMatch?.group(0) ?? '',
      title: title,
      summary: summary,
      skills: flatSkills.where((s) => s.trim().isNotEmpty && !ResumeData._isPlaceholderValue(s)).toSet().toList(),
      skillGroups: skillGroups,
      experience: experience,
      education: education,
      projects: projects,
      certifications: certifications,
      extracurriculars: extracurriculars,
    );

    final sanitizedData = validateAndSanitizeAll(parsedData);

    debugPrint('\n================ [RAW-PARSER-RESULT] ================');
    debugPrint('Name: ${sanitizedData.fullName}');
    debugPrint('Email: ${sanitizedData.email}');
    debugPrint('Phone: ${sanitizedData.phone}');
    debugPrint('Projects: ${sanitizedData.projects.length}');
    debugPrint('Education: ${sanitizedData.education.length}');
    debugPrint('Experience: ${sanitizedData.experience.length}');
    debugPrint('Certifications: ${sanitizedData.certifications.length}');
    debugPrint('Skill Groups: ${sanitizedData.skillGroups.length}\n');

    return sanitizedData;
  }

  // ---------------------------------------------------------------------------
  // Hierarchical Block & Entity Extractors
  // ---------------------------------------------------------------------------

  static String _normalizeSectionBreaks(String rawText) {
    if (rawText.trim().isEmpty) return rawText;
    return rawText;
  }

  /// Normalizes a candidate heading line by trimming, stripping list numbers,
  /// bullets, markdown hashes, dashes, and trailing colons, converting to lowercase,
  /// removing non-alphanumeric chars (preserving '&' and space), and collapsing spaces.
  /// Normalizes a candidate heading line by trimming, stripping list numbers,
  /// bullets, markdown hashes, dashes, and trailing colons, converting to lowercase,
  /// removing non-alphanumeric chars (preserving '&' and space), and collapsing spaces.
  static String _normalizeHeadingCandidate(String line) {
    var s = line.trim();
    // Strip leading list numbers, Roman numerals, bullets, markdown hashes, dashes
    s = s.replaceFirst(
      RegExp(r'^(?:[#*_\-–—•◦°▪▫●○◆◇►▶▸⁃∙\t]+|\d+[\.\)\:\-]\s*|[ivxlcdm]+[\.\)\:\-]\s*)', caseSensitive: false),
      '',
    ).trim();
    // Strip trailing colons, dashes, hashes, underscores, vertical bars
    s = s.replaceFirst(RegExp(r'[:#*_\-–—|\s]+$'), '').trim();
    // Convert to lowercase, remove characters except a-z, 0-9, &, and spaces, collapse spaces
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s&]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String? _detectSectionHeaderFromNormalized(String norm) {
    if (norm.isEmpty) return null;

    // Reject if too long (section headers are concise: <= 5 words, <= 45 chars)
    if (norm.length > 45 || norm.split(' ').length > 5) return null;

    // 1. summary
    if (const {
      'summary',
      'professional summary',
      'executive summary',
      'profile summary',
      'career summary',
      'personal summary',
      'summary objective',
      'summary and objective',
      'summary & objective',
      'about me',
      'about',
      'profile',
      'career profile',
      'professional profile',
      'career objective',
      'objective',
      'overview',
      'bio',
    }.contains(norm) ||
        RegExp(r'^(professional |career |profile |executive |personal )?(summary|profile|objective|overview|bio)( (&|and) (summary|profile|objective|overview|bio))?$').hasMatch(norm) ||
        RegExp(r'^about( me)?$').hasMatch(norm)) {
      return 'summary';
    }

    // 2. skills
    if (const {
      'skills',
      'technical skills',
      'key skills',
      'core skills',
      'technologies',
      'technical proficiencies',
      'core competencies',
      'competencies',
      'areas of expertise',
      'technical capabilities',
      'specializations',
      'hard skills',
      'toolbox',
    }.contains(norm) ||
        RegExp(r'^(technical |key |core |it |software |developer |professional )?(skills|competencies|proficiencies|technologies|expertise|capabilities)$').hasMatch(norm) ||
        RegExp(r'^(tech|technical) stack$').hasMatch(norm) ||
        RegExp(r'^(programming )?languages( (&|and) tools)?$').hasMatch(norm) ||
        RegExp(r'^(tools (&|and) )?technologies$').hasMatch(norm)) {
      return 'skills';
    }

    // 3. experience
    if (const {
      'experience',
      'work experience',
      'professional experience',
      'employment',
      'employment history',
      'work history',
      'career history',
      'relevant experience',
      'internships',
      'internship experience',
      'practical experience',
      'industry experience',
      'professional background',
      'experience history',
      'career background',
      'work background',
      'previous experience',
      'job history',
      'positions held',
      'professional journey',
      'career record',
      'work record',
      'employment record',
      'career highlights',
    }.contains(norm) ||
        RegExp(r'^(work |professional |relevant |industry |practical |internship |previous |career )?experience( history)?$').hasMatch(norm) ||
        RegExp(r'^(employment|work|career|job) history$').hasMatch(norm) ||
        RegExp(r'^(positions held|employment record|career background|professional journey)$').hasMatch(norm)) {
      return 'experience';
    }

    // 4. education
    if (const {
      'education',
      'educational background',
      'academic background',
      'academics',
      'academic history',
      'academic qualification',
      'academic qualifications',
      'qualifications',
      'educational qualifications',
      'degrees',
      'schooling',
      'education & qualifications',
      'education and qualifications',
      'academic details',
      'academic record',
      'education details',
      'education history',
      'studies',
      'academic credentials',
      'formal education',
      'scholastic record',
      'education & training',
    }.contains(norm) ||
        RegExp(r'^(educational |academic |formal )?education( (&|and) (qualifications|training))?$').hasMatch(norm) ||
        RegExp(r'^(academic |educational )?(background|qualifications|history|record|details|credentials)$').hasMatch(norm) ||
        RegExp(r'^(academics|degrees|schooling|studies|scholastic record)$').hasMatch(norm)) {
      return 'education';
    }

    // 5. projects
    if (const {
      'projects',
      'key projects',
      'personal projects',
      'academic projects',
      'technical projects',
      'selected projects',
      'project work',
      'projects & repositories',
      'projects and repositories',
      'repositories',
      'github projects',
      'open source projects',
      'open source contributions',
      'major projects',
      'relevant projects',
      'software projects',
      'portfolio',
      'portfolio projects',
      'featured projects',
      'notable projects',
      'projects open source',
      'client projects',
      'selected work',
      'selected works',
      'selected works & repositories',
      'selected works and repositories',
      'selected work & repositories',
      'selected work and repositories',
      'featured work',
      'featured works',
      'capstone projects',
      'coursework projects',
    }.contains(norm) ||
        RegExp(r'^(key |personal |academic |technical |selected |major |notable |capstone |coursework |software |client |featured |portfolio )?projects?( (&|and) repositories)?$').hasMatch(norm) ||
        RegExp(r'^(selected|featured) works?( (&|and) repositories)?$').hasMatch(norm) ||
        RegExp(r'^(repositories|portfolio|open source contributions|open source projects)$').hasMatch(norm)) {
      return 'projects';
    }

    // 6. certifications
    if (const {
      'certifications',
      'certification',
      'certificate',
      'certificates',
      'certifications & licenses',
      'certifications and licenses',
      'licenses & certifications',
      'licenses and certifications',
      'licenses and licenses',
      'credentials',
      'courses & certifications',
      'courses and certifications',
      'certifications & courses',
      'certifications courses',
      'accreditations',
      'licenses',
      'professional certifications',
      'certified courses',
      'training & certifications',
      'certifications & credentials',
      'certifications and credentials',
      'accreditations & certificates',
      'accreditations and certificates',
      'accreditations & certifications',
      'accreditations and certifications',
    }.contains(norm) ||
        RegExp(r'^(professional |certified |training (&|and) )?(certifications?|certificates?|licenses?|credentials?|accreditations?)( (&|and) (certifications?|certificates?|licenses?|credentials?|accreditations?|courses?|training))?$').hasMatch(norm)) {
      return 'certifications';
    }

    // 7. extracurriculars
    if (const {
      'extracurricular activities',
      'extracurricular activities & achievements',
      'extracurricular activities and achievements',
      'extra curricular activities',
      'extra curricular activities & achievements',
      'extra curricular activities and achievements',
      'extracurriculars',
      'extra curriculars',
      'extra curricular',
      'extracurricular',
      'co curricular activities',
      'cocurricular activities',
      'volunteer experience',
      'volunteering',
      'activities',
      'leadership & activities',
      'leadership activities',
      'leadership & involvement',
      'leadership experience',
      'leadership',
      'involvement',
      'campus involvement',
      'activities & achievements',
      'activities and achievements',
      'community involvement',
      'community service',
      'extracurricular involvement',
      'positions of responsibility',
      'responsibilities',
      'awards & achievements',
      'awards and achievements',
      'awards',
      'honors',
      'honors & awards',
      'honors and awards',
      'publications',
      'associations',
      'affiliations',
    }.contains(norm) ||
        RegExp(r'^(extra|co|cocurricular)[\s\-]?curricular( (activities|involvement|experience))?( (&|and) (achievements|awards))?$').hasMatch(norm) ||
        RegExp(r'^(leadership|activities|volunteering|volunteer experience|community service|campus involvement|positions of responsibility|publications|associations|affiliations)( (&|and) (activities|involvement|achievements|awards))?$').hasMatch(norm) ||
        RegExp(r'^(honors|awards)( (&|and) (honors|awards|achievements))?$').hasMatch(norm)) {
      return 'extracurriculars';
    }

    return null;
  }

  static String? _detectSectionHeader(String line) {
    var trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.endsWith(':')) {
      trimmed = trimmed.substring(0, trimmed.length - 1).trim();
    }

    // Filter out content lines containing punctuation, dates, contact info
    if (trimmed.contains(':') ||
        trimmed.contains('|') ||
        trimmed.contains(';') ||
        trimmed.contains(',') ||
        trimmed.contains('@') ||
        trimmed.contains('http://') ||
        trimmed.contains('https://') ||
        trimmed.contains('www.')) {
      return null;
    }
    if (RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\b', caseSensitive: false).hasMatch(trimmed)) return null;
    if (RegExp(r'\b\d{4}\s*[\–\-—\to]\s*(\d{4}|Present)\b', caseSensitive: false).hasMatch(trimmed)) return null;

    final norm = _normalizeHeadingCandidate(trimmed);
    return _detectSectionHeaderFromNormalized(norm);
  }

  /// Returns true if the text matches any known section header alias.
  static bool isKnownSectionHeader(String text) {
    return _detectSectionHeader(text) != null;
  }

  static Map<String, List<String>> _splitIntoSectionBlocks(String rawText) {
    final blocks = <String, List<String>>{
      'header': [],
      'summary': [],
      'skills': [],
      'education': [],
      'experience': [],
      'projects': [],
      'certifications': [],
      'extracurriculars': [],
    };

    if (rawText.trim().isEmpty) return blocks;

    final rawLines = rawText.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    String currentSection = 'header';

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];

      // Header contact info lines should stay in header
      if (currentSection == 'header') {
        if (line.contains('@') ||
            line.contains('linkedin.com') ||
            line.contains('github.com') ||
            RegExp(r'\+\d{1,4}').hasMatch(line)) {
          blocks['header']?.add(line);
          continue;
        }
      }

      final detected = _detectSectionHeader(line);
      if (detected != null) {
        currentSection = detected;
        continue;
      }
      blocks[currentSection]?.add(line);
    }

    final detectedSectionsList = blocks.entries
        .where((e) => e.key != 'header' && e.value.isNotEmpty)
        .map((e) => e.key.toUpperCase())
        .toList();
    debugPrint('[PIPELINE] SECTIONS DETECTED: $detectedSectionsList');
    for (final sec in ['education', 'experience', 'projects', 'skills', 'certifications', 'extracurriculars']) {
      final lines = blocks[sec] ?? [];
      if (lines.isNotEmpty) {
        debugPrint('[PIPELINE] Section: ${sec.toUpperCase()} (content lines: ${lines.length})');
      }
    }

    return blocks;
  }

  static List<SkillGroupEntry> _extractSkillGroupsFromBlock(List<String> lines) {
    final groups = <SkillGroupEntry>[];
    String? currentCategory;
    final currentItems = <String>[];

    void flushGroup() {
      if (currentCategory != null && currentCategory!.trim().isNotEmpty && currentItems.isNotEmpty) {
        final uniqueItems = <String>[];
        for (final item in currentItems) {
          final trimmed = item.trim();
          if (trimmed.isNotEmpty && !ResumeData._isPlaceholderValue(trimmed) && !uniqueItems.contains(trimmed)) {
            uniqueItems.add(trimmed);
          }
        }
        if (uniqueItems.isNotEmpty) {
          groups.add(SkillGroupEntry(
            category: currentCategory!.trim(),
            items: uniqueItems,
          ));
        }
      }
      currentCategory = null;
      currentItems.clear();
    }

    const knownCatPrefixes = [
      'backend tools',
      'backend',
      'testing & api',
      'testing api',
      'testing',
      'languages & tools',
      'programming languages',
      'languages',
      'soft skills',
      'frontend tools',
      'frontend',
      'databases & tools',
      'databases',
      'frameworks & libraries',
      'frameworks',
      'devops & cloud',
      'cloud & devops',
      'cloud',
      'devops',
      'tools & technologies',
      'tools',
      'core competencies',
      'technical proficiencies',
      'technical skills',
    ];

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty || isKnownSectionHeader(cleanLine) || ResumeData._isPlaceholderValue(cleanLine)) continue;

      if (cleanLine.contains(':')) {
        final colonIdx = cleanLine.indexOf(':');
        final catPart = cleanLine.substring(0, colonIdx).trim();
        final restPart = cleanLine.substring(colonIdx + 1).trim();

        if (catPart.length < 40 && !catPart.contains(',')) {
          flushGroup();
          currentCategory = catPart;
          if (restPart.isNotEmpty) {
            final tokens = restPart.split(RegExp(r'[,;•|\/\t]+')).map((s) => s.trim()).where((s) => s.isNotEmpty && !ResumeData._isPlaceholderValue(s)).toList();
            currentItems.addAll(tokens);
          }
          continue;
        }
      }

      bool matchedPrefix = false;
      final lowerLine = cleanLine.toLowerCase();
      for (final prefix in knownCatPrefixes) {
        if (lowerLine.startsWith(prefix) && cleanLine.length > prefix.length) {
          final nextChar = cleanLine[prefix.length];
          if (nextChar == ' ' || nextChar == ':' || nextChar == '-' || nextChar == '|') {
            flushGroup();
            currentCategory = cleanLine.substring(0, prefix.length).trim();
            final restPart = cleanLine.substring(prefix.length).replaceFirst(RegExp(r'^[:\-\|\s]+'), '').trim();
            if (restPart.isNotEmpty) {
              final tokens = restPart.split(RegExp(r'[,;•|\t]+')).map((s) => s.trim()).where((s) => s.isNotEmpty && !ResumeData._isPlaceholderValue(s)).toList();
              currentItems.addAll(tokens);
            }
            matchedPrefix = true;
            break;
          }
        }
      }
      if (matchedPrefix) continue;

      final isHeaderCandidate = cleanLine.length < 35 && !cleanLine.contains(',') && !RegExp(r'\b(python|javascript|java|c\+\+|dart|flutter|html|css|sql|react|node|docker|aws|git|supabase|firebase|postman|rest api|pydantic|dbms)\b', caseSensitive: false).hasMatch(cleanLine);
      if (isHeaderCandidate) {
        flushGroup();
        currentCategory = cleanLine;
      } else {
        final tokens = cleanLine.split(RegExp(r'[,;•|\/\t]+')).map((s) => s.trim()).where((s) => s.isNotEmpty && !ResumeData._isPlaceholderValue(s)).toList();
        currentCategory ??= 'Technical Skills';
        currentItems.addAll(tokens);
      }
    }

    flushGroup();
    return groups;
  }

  // ---------------------------------------------------------------------------
  // Record State Machine Extractors
  // ---------------------------------------------------------------------------

  static bool _isSingleTechnologyKeyword(String text) {
    final s = text.trim().toLowerCase();
    if (s.isEmpty) return false;
    return RegExp(
      r'^(flutter|dart|gemini|gemini api|prompt engineering|llm|llms|generative ai|genai|react|react\.js|reactjs|vue|vue\.js|angular|node|node\.js|express|express\.js|python|java|c\+\+|c#|c|html|css|html\/css|javascript|typescript|docker|kubernetes|aws|gcp|azure|supabase|firebase|mongodb|postgresql|postgres|mysql|sqlite|redis|graphql|rest api|api|apis|postman|git|github|gitlab|ci\/cd|pydantic|dbms|pandas|numpy|scikit-learn|tensorflow|pytorch|logistic regression|knn|decision tree|gridsearchcv|riverpod|bloc|redux|tailwind|bootstrap|linux|bash|fastapi|flask|django|api testing|testing api|backend tools|languages|soft skills)$',
      caseSensitive: false,
    ).hasMatch(s);
  }

  static _ProjectHeaderInfo? _tryParseProjectHeader(String line) {
    final cleanLine = line.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
    if (cleanLine.isEmpty) return null;

    if (isKnownSectionHeader(cleanLine) || isKnownSectionHeader(line) || ResumeData._isPlaceholderValue(cleanLine)) {
      return null;
    }

    // A bullet point or numbered item is NEVER a standalone project header
    if (line.startsWith('•') || line.startsWith('◦') || line.startsWith('°') || line.startsWith('▪') || line.startsWith('▫') || line.startsWith('●') || line.startsWith('○') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line)) {
      return null;
    }

    // Action verb lines or descriptive sentences are not headers
    if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating|collaborating|researching|automating|testing|authored)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if (RegExp(r'^[a-z]').hasMatch(cleanLine) || RegExp(r'^(and|for|with|in|to|of|from|by|into|during|via|under|about|the|an|a)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if (_isSingleTechnologyKeyword(cleanLine)) {
      return null;
    }
    if ((cleanLine.endsWith('.') || cleanLine.endsWith(';') || cleanLine.endsWith(',')) && !cleanLine.contains('|')) {
      return null;
    }
    if (cleanLine.length > 75 && !cleanLine.contains('|')) {
      return null;
    }

    // 1. Pipe Separated: "Project Title | Tech Stack | Link"
    if (line.contains('|')) {
      final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final name = parts[0];
        if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed)\b', caseSensitive: false).hasMatch(name)) {
          return null;
        }
        if (_isSingleTechnologyKeyword(name) || isKnownSectionHeader(name)) {
          return null;
        }
        String sub = parts.length > 1 ? parts[1] : '';
        String repo = '';
        if (parts.length > 2) {
          final p2 = parts[2];
          if (p2.contains('github.com') || p2.contains('/') || p2.contains('.')) {
            repo = p2.startsWith('http') ? p2 : (p2.contains('github.com') ? 'https://$p2' : 'https://github.com/$p2');
          } else if (sub.isEmpty) {
            sub = p2;
          }
        } else if (parts.length == 2) {
          final p1 = parts[1];
          if (p1.contains('github.com') || (p1.contains('/') && !p1.contains(' '))) {
            repo = p1.startsWith('http') ? p1 : (p1.contains('github.com') ? 'https://$p1' : 'https://github.com/$p1');
            sub = '';
          }
        }
        return _ProjectHeaderInfo(name: name, subtitle: sub, repoUrl: repo);
      }
    }

    // 2. Dash Separated: "Project Title – Tech Stack"
    if (line.contains(' – ') || line.contains(' — ') || line.contains(' - ')) {
      final sep = line.contains(' – ') ? ' – ' : (line.contains(' — ') ? ' — ' : ' - ');
      final parts = line.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final name = parts[0];
        if (!RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed)\b', caseSensitive: false).hasMatch(name) && !_isSingleTechnologyKeyword(name) && !isKnownSectionHeader(name) && name.length < 50) {
          String sub = parts.length > 1 ? parts[1] : '';
          String repo = '';
          if (sub.contains('github.com') || (sub.contains('/') && !sub.contains(' '))) {
            repo = sub.startsWith('http') ? sub : (sub.contains('github.com') ? 'https://$sub' : 'https://github.com/$sub');
            sub = '';
          }
          return _ProjectHeaderInfo(name: name, subtitle: sub, repoUrl: repo);
        }
      }
    }

    // 3. Standalone multi-word title line (e.g. "Smart Home IoT Platform" or "Resume Builder")
    // Must be at least 2 words, no commas, capitalized, and not a continuation fragment
    final words = cleanLine.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2 && cleanLine.length <= 50 && !cleanLine.contains(',') && !_isSingleTechnologyKeyword(cleanLine) && !isKnownSectionHeader(cleanLine) && RegExp(r'^[A-Z0-9]').hasMatch(cleanLine)) {
      return _ProjectHeaderInfo(name: cleanLine);
    }

    return null;
  }

  static List<ProjectEntry> _extractProjectsFromBlock(List<String> lines) {
    final projects = <ProjectEntry>[];
    String? currentName;
    String currentSubtitle = '';
    String currentRepo = '';
    final currentDescriptions = <String>[];
    String currentBullet = '';

    void flushCurrentBullet() {
      if (currentBullet.trim().isNotEmpty) {
        final b = currentBullet.trim();
        if (!currentDescriptions.contains(b) && !ResumeData._isPlaceholderValue(b)) {
          currentDescriptions.add(b);
        }
        currentBullet = '';
      }
    }

    void flushCurrentProject() {
      if (currentName != null && currentName!.trim().isNotEmpty && !isKnownSectionHeader(currentName!) && !ResumeData._isPlaceholderValue(currentName!)) {
        flushCurrentBullet();
        projects.add(ProjectEntry(
          name: currentName!.trim(),
          type: currentSubtitle.trim(),
          githubUrl: currentRepo.trim(),
          descriptionBullets: List.from(currentDescriptions),
          description: currentDescriptions.join(' '),
        ));
      }
      currentName = null;
      currentSubtitle = '';
      currentRepo = '';
      currentDescriptions.clear();
      currentBullet = '';
    }

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty || isKnownSectionHeader(cleanLine) || ResumeData._isPlaceholderValue(cleanLine)) continue;

      final header = _tryParseProjectHeader(line);
      if (header != null) {
        flushCurrentProject();
        currentName = header.name;
        currentSubtitle = header.subtitle;
        currentRepo = header.repoUrl;
        continue;
      }

      if (currentName == null) {
        final words = cleanLine.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.length >= 2 && cleanLine.length < 50 && !cleanLine.endsWith('.') && !_isSingleTechnologyKeyword(cleanLine) && !isKnownSectionHeader(cleanLine) && RegExp(r'^[A-Z]').hasMatch(cleanLine)) {
          currentName = cleanLine;
        }
        continue;
      }

      if (currentRepo.isEmpty && (cleanLine.contains('github.com/') || (cleanLine.contains('/') && !cleanLine.contains(' ') && cleanLine.length < 50))) {
        currentRepo = cleanLine.startsWith('http') ? cleanLine : (cleanLine.contains('github.com') ? 'https://$cleanLine' : 'https://github.com/$cleanLine');
        continue;
      }

      final isNewBullet = line.startsWith('•') || line.startsWith('◦') || line.startsWith('°') || line.startsWith('▪') || line.startsWith('▫') || line.startsWith('●') || line.startsWith('○') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line);
      final isActionVerbStart = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed)\b', caseSensitive: false).hasMatch(cleanLine);

      if (isNewBullet || (isActionVerbStart && currentBullet.isNotEmpty)) {
        flushCurrentBullet();
        currentBullet = cleanLine;
      } else {
        if (currentBullet.isNotEmpty) {
          if (cleanLine.startsWith(',') || cleanLine.startsWith('.') || cleanLine.startsWith(';') || cleanLine.startsWith(':')) {
            currentBullet = '$currentBullet$cleanLine';
          } else if (currentBullet.endsWith('-')) {
            currentBullet = currentBullet.substring(0, currentBullet.length - 1) + cleanLine;
          } else {
            currentBullet = '$currentBullet $cleanLine';
          }
        } else {
          currentBullet = cleanLine;
        }
      }
    }

    flushCurrentProject();

    debugPrint('[PROJECT EXTRACTION] RAW PROJECT BLOCK:');
    debugPrint(lines.isNotEmpty ? lines.join('\n') : '[EMPTY]');
    debugPrint('[PROJECT EXTRACTION] RAW EXTRACTED PROJECTS:');
    for (final p in projects) {
      debugPrint(' - name: "${p.name}", url: "${p.githubUrl}", bullets: ${p.descriptionBullets.length}');
    }
    debugPrint('[PROJECT EXTRACTION] RAW PROJECT COUNT: ${projects.length}');

    return projects;
  }

  static _ExperienceHeaderInfo? _tryParseExperienceHeader(String line) {
    final cleanLine = line.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
    if (cleanLine.isEmpty) return null;

    if (isKnownSectionHeader(cleanLine) || isKnownSectionHeader(line) || ResumeData._isPlaceholderValue(cleanLine)) {
      return null;
    }

    if (line.startsWith('•') || line.startsWith('◦') || line.startsWith('°') || line.startsWith('▪') || line.startsWith('▫') || line.startsWith('●') || line.startsWith('○') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line)) {
      return null;
    }
    if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating|collaborating|researching)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if (RegExp(r'^[a-z]').hasMatch(cleanLine) || RegExp(r'^(and|for|with|in|to|of|from|by|into|during|via|under|about)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if (_isSingleTechnologyKeyword(cleanLine)) {
      return null;
    }
    if ((cleanLine.endsWith('.') || cleanLine.endsWith(';') || cleanLine.endsWith(',')) && !cleanLine.contains('|')) {
      return null;
    }

    final datePattern = RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4})\s*[\–\-—\to]+\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4}|Present|Current)\b', caseSensitive: false);

    if (line.contains('|')) {
      final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        String role = parts[0];
        if (_isSingleTechnologyKeyword(role) || isKnownSectionHeader(role)) return null;
        String company = parts.length > 1 ? parts[1] : '';
        String location = '';
        String startDate = '';
        String endDate = '';

        for (int i = 2; i < parts.length; i++) {
          final p = parts[i];
          final dateMatch = datePattern.firstMatch(p);
          if (dateMatch != null && startDate.isEmpty) {
            startDate = dateMatch.group(1) ?? '';
            endDate = dateMatch.group(2) ?? '';
          } else if (location.isEmpty) {
            location = p;
          }
        }
        return _ExperienceHeaderInfo(role: role, company: company, location: location, startDate: startDate, endDate: endDate);
      }
    }

    final isDateRange = RegExp(r'^\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4}|Present|Current)?\s*$', caseSensitive: false).hasMatch(cleanLine);
    if (isDateRange) {
      return null;
    }

    if (line.contains(' – ') || line.contains(' — ') || line.contains(' - ')) {
      final sep = line.contains(' – ') ? ' – ' : (line.contains(' — ') ? ' — ' : ' - ');
      final parts = line.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final isDate0 = RegExp(r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?[a-z]*\s*\d{4}\b', caseSensitive: false).hasMatch(parts[0]);
      final isDate1 = parts.length > 1 && RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?[a-z]*\s*\d{4}|Present|Current)\b', caseSensitive: false).hasMatch(parts[1]);
      if (isDate0 && isDate1) {
        return null;
      }
      if (parts.length >= 2 && parts[0].length < 50 && !isDate0 && !_isSingleTechnologyKeyword(parts[0]) && !isKnownSectionHeader(parts[0])) {
        return _ExperienceHeaderInfo(role: parts[0], company: parts[1]);
      }
    }

    return null;
  }

  static List<ExperienceEntry> _extractExperienceFromBlock(List<String> lines) {
    final experience = <ExperienceEntry>[];
    String? currentRole;
    String currentCompany = '';
    String currentLocation = '';
    String currentStart = '';
    String currentEnd = '';
    final currentDescriptions = <String>[];
    String currentBullet = '';

    void flushCurrentBullet() {
      if (currentBullet.trim().isNotEmpty) {
        final b = currentBullet.trim();
        if (!currentDescriptions.contains(b) && !ResumeData._isPlaceholderValue(b)) {
          currentDescriptions.add(b);
        }
        currentBullet = '';
      }
    }

    void flushCurrentExperience() {
      if ((currentRole != null && currentRole!.trim().isNotEmpty && !isKnownSectionHeader(currentRole!) && !ResumeData._isPlaceholderValue(currentRole!)) ||
          (currentCompany.trim().isNotEmpty && !isKnownSectionHeader(currentCompany) && !ResumeData._isPlaceholderValue(currentCompany))) {
        flushCurrentBullet();
        experience.add(ExperienceEntry(
          role: currentRole ?? '',
          company: currentCompany.trim(),
          location: currentLocation.trim(),
          startDate: currentStart.trim(),
          endDate: currentEnd.trim(),
          description: List.from(currentDescriptions),
        ));
      }
      currentRole = null;
      currentCompany = '';
      currentLocation = '';
      currentStart = '';
      currentEnd = '';
      currentDescriptions.clear();
      currentBullet = '';
    }

    final datePattern = RegExp(r'^\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4})\s*[\–\-—\to]+\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{1,2}/\d{4}|\d{4}|Present|Current)?\s*$', caseSensitive: false);

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty || isKnownSectionHeader(cleanLine) || ResumeData._isPlaceholderValue(cleanLine)) continue;

      final header = _tryParseExperienceHeader(line);
      if (header != null) {
        flushCurrentExperience();
        currentRole = header.role;
        currentCompany = header.company;
        currentLocation = header.location;
        currentStart = header.startDate;
        currentEnd = header.endDate;
        continue;
      }

      if (currentRole == null && currentCompany.isEmpty) {
        if (cleanLine.length < 50 && !cleanLine.endsWith('.') && !_isSingleTechnologyKeyword(cleanLine) && !isKnownSectionHeader(cleanLine) && RegExp(r'^[A-Z]').hasMatch(cleanLine)) {
          currentRole = cleanLine;
        }
        continue;
      }

      final dateMatch = datePattern.firstMatch(cleanLine);
      if (dateMatch != null) {
        currentStart = dateMatch.group(1) ?? '';
        currentEnd = dateMatch.group(2) ?? '';
        continue;
      }

      final isNewBullet = line.startsWith('•') || line.startsWith('◦') || line.startsWith('°') || line.startsWith('▪') || line.startsWith('▫') || line.startsWith('●') || line.startsWith('○') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line);
      final isActionVerbStart = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|collaborated|researched)\b', caseSensitive: false).hasMatch(cleanLine);

      if (isNewBullet || (isActionVerbStart && currentBullet.isNotEmpty)) {
        flushCurrentBullet();
        currentBullet = cleanLine;
      } else {
        if (currentBullet.isNotEmpty) {
          if (cleanLine.startsWith(',') || cleanLine.startsWith('.') || cleanLine.startsWith(';') || cleanLine.startsWith(':')) {
            currentBullet = '$currentBullet$cleanLine';
          } else if (currentBullet.endsWith('-')) {
            currentBullet = currentBullet.substring(0, currentBullet.length - 1) + cleanLine;
          } else {
            currentBullet = '$currentBullet $cleanLine';
          }
        } else {
          currentBullet = cleanLine;
        }
      }
    }

    flushCurrentExperience();
    return experience;
  }

  static List<EducationEntry> _extractEducationFromBlock(List<String> lines) {
    final education = <EducationEntry>[];
    String? currentDegree;
    String currentInst = '';
    String currentStart = '';
    String currentEnd = '';
    String currentGpa = '';

    final degreeRegex = RegExp(
      r'\b(b\.?\s*tech|m\.?\s*tech|b\.?\s*sc|m\.?\s*sc|b\.?\s*e|m\.?\s*e|b\.?\s*com|m\.?\s*com|bba|mba|bca|mca|b\.?\s*des|m\.?\s*des|phd|diploma|bachelor(?:\s+of\s+[a-z\s&]+)?|master(?:\s+of\s+[a-z\s&]+)?|b\.?\s*s\.?|m\.?\s*s\.?|b\.?\s*a\.?|m\.?\s*a\.?|bs|ms|ba|ma|class\s*(?:xii|x|xi|ix|12|10|11|9)\b|12th|10th|cbse|icse|intermediate|matriculation|ssc|hsc|degree|associate(?:\s+degree)?)\b',
      caseSensitive: false,
    );

    void flushCurrentEducation() {
      final deg = (currentDegree != null &&
              currentDegree!.trim().isNotEmpty &&
              !isKnownSectionHeader(currentDegree!) &&
              !ResumeData._isPlaceholderValue(currentDegree!) &&
              !_isStopWordOrPreposition(currentDegree!))
          ? currentDegree!.trim()
          : '';
      final inst = (currentInst.trim().isNotEmpty &&
              !isKnownSectionHeader(currentInst) &&
              !ResumeData._isPlaceholderValue(currentInst) &&
              !_isStopWordOrPreposition(currentInst))
          ? currentInst.trim()
          : '';

      if (deg.isNotEmpty || inst.isNotEmpty) {
        final entry = EducationEntry(
          degree: deg,
          institution: inst,
          startDate: currentStart.trim(),
          endDate: currentEnd.trim(),
          gpa: currentGpa.trim(),
        );
        if (validateEducation(entry)) {
          education.add(entry);
        }
      }
      currentDegree = null;
      currentInst = '';
      currentStart = '';
      currentEnd = '';
      currentGpa = '';
    }

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty || isKnownSectionHeader(cleanLine) || ResumeData._isPlaceholderValue(cleanLine) || _isStopWordOrPreposition(cleanLine)) continue;

      final isDegreeLine = degreeRegex.hasMatch(cleanLine);

      if (line.contains('|')) {
        final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (isDegreeLine && currentDegree != null) {
          flushCurrentEducation();
        }
        for (int i = 0; i < parts.length; i++) {
          final p = parts[i];
          if (isKnownSectionHeader(p) || ResumeData._isPlaceholderValue(p) || _isStopWordOrPreposition(p)) continue;
          final isDeg = degreeRegex.hasMatch(p);
          final isInst = RegExp(r'\b(university|college|school|institute|academy|campus|polytechnic)\b', caseSensitive: false).hasMatch(p);
          final dateMatch = RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)?\b', caseSensitive: false).firstMatch(p);
          final gpaMatch = RegExp(r'\b(?:gpa:?\s*|grade:?\s*|cgpa:?\s*)?(\d+(?:\.\d+)?|\d+\%)\b', caseSensitive: false).firstMatch(p);

          if (isDeg && (currentDegree == null || currentDegree!.isEmpty)) {
            currentDegree = p;
          } else if (isInst && currentInst.isEmpty) {
            currentInst = p;
          } else if (dateMatch != null && currentStart.isEmpty) {
            currentStart = dateMatch.group(1) ?? '';
            currentEnd = dateMatch.group(2) ?? '';
          } else if (gpaMatch != null && currentGpa.isEmpty && (p.toLowerCase().contains('gpa') || p.toLowerCase().contains('grade') || p.toLowerCase().contains('cgpa') || p.contains('%'))) {
            currentGpa = p.replaceAll(RegExp(r'^(gpa|grade|cgpa):?\s*', caseSensitive: false), '').trim();
          } else if (currentDegree == null || currentDegree!.isEmpty) {
            currentDegree = p;
          } else if (currentInst.isEmpty) {
            currentInst = p;
          }
        }
        continue;
      }

      if (isDegreeLine && currentDegree != null && (currentInst.isNotEmpty || currentStart.isNotEmpty || currentGpa.isNotEmpty)) {
        flushCurrentEducation();
      }

      final isGpa = cleanLine.toLowerCase().contains('gpa') || cleanLine.toLowerCase().contains('grade') || cleanLine.toLowerCase().contains('cgpa') || cleanLine.contains('%') || RegExp(r'^\d+(\.\d+)?$').hasMatch(cleanLine);
      if (isGpa && currentGpa.isEmpty) {
        currentGpa = cleanLine.replaceAll(RegExp(r'^(gpa|grade|cgpa):?\s*', caseSensitive: false), '').trim();
        continue;
      }

      final dateMatch = RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)?\b', caseSensitive: false).firstMatch(cleanLine);
      if (dateMatch != null && currentStart.isEmpty && cleanLine.length < 40) {
        currentStart = dateMatch.group(1) ?? '';
        currentEnd = dateMatch.group(2) ?? '';
        continue;
      }

      final isInst = RegExp(r'\b(university|college|school|institute|academy|campus|polytechnic)\b', caseSensitive: false).hasMatch(cleanLine);
      if (isInst && currentInst.isEmpty) {
        currentInst = cleanLine;
        continue;
      }

      if (isDegreeLine) {
        if (currentDegree == null || currentDegree!.isEmpty) {
          currentDegree = cleanLine;
        } else {
          currentDegree = '$currentDegree $cleanLine';
        }
      } else if (currentDegree == null || currentDegree!.isEmpty) {
        currentDegree = cleanLine;
      } else if (currentInst.isEmpty) {
        currentInst = cleanLine;
      }
    }

    flushCurrentEducation();
    return education;
  }

  static List<ExtracurricularEntry> _extractExtracurricularsFromBlock(List<String> lines) {
    final list = <ExtracurricularEntry>[];

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty || isKnownSectionHeader(cleanLine) || ResumeData._isPlaceholderValue(cleanLine) || _isStopWordOrPreposition(cleanLine) || cleanLine.length < 3) {
        continue;
      }

      final isDateOnly = RegExp(r'^(?:(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{4})\s*[\–\-—\to]*\s*(?:(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}|\d{4}|Present)?$', caseSensitive: false).hasMatch(cleanLine);
      if (isDateOnly) {
        if (list.isNotEmpty) {
          final last = list.removeLast();
          final updatedDesc = last.description.isNotEmpty ? '$cleanLine • ${last.description}' : cleanLine;
          list.add(last.copyWith(description: updatedDesc));
        }
        continue;
      }

      if (cleanLine.contains('|')) {
        final parts = cleanLine.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty && !ResumeData._isPlaceholderValue(s) && !_isStopWordOrPreposition(s)).toList();
        if (parts.isNotEmpty) {
          final act = parts[0];
          final org = parts.length > 1 ? parts[1] : '';
          final desc = parts.length > 2 ? parts.sublist(2).join(' • ') : '';
          final entry = ExtracurricularEntry(
            activity: act,
            organization: org,
            description: desc,
          );
          if (validateExtracurricular(entry)) {
            list.add(entry);
          }
          continue;
        }
      }

      if (cleanLine.contains(' – ') || cleanLine.contains(' — ') || cleanLine.contains(' - ')) {
        final sep = cleanLine.contains(' – ') ? ' – ' : (cleanLine.contains(' — ') ? ' — ' : ' - ');
        final parts = cleanLine.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty && !ResumeData._isPlaceholderValue(s) && !_isStopWordOrPreposition(s)).toList();
        if (parts.length >= 2) {
          final isPart0Date = RegExp(r'^(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}$|^\d{4}$', caseSensitive: false).hasMatch(parts[0]);
          final isPart1Date = RegExp(r'^(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}$|^\d{4}$|^Present$', caseSensitive: false).hasMatch(parts[1]);
          if (isPart0Date && isPart1Date) {
            if (list.isNotEmpty) {
              final last = list.removeLast();
              final updatedDesc = last.description.isNotEmpty ? '$cleanLine • ${last.description}' : cleanLine;
              list.add(last.copyWith(description: updatedDesc));
            }
            continue;
          }

          final entry = ExtracurricularEntry(
            activity: parts[0],
            organization: parts[1],
            description: parts.length > 2 ? parts.sublist(2).join(' • ') : '',
          );
          if (validateExtracurricular(entry)) {
            list.add(entry);
          }
          continue;
        }
      }

      // Check if line is a descriptive bullet / action verb belonging to previous item
      final isActionBullet = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|researched|assisted|organized)\b', caseSensitive: false).hasMatch(cleanLine) ||
          line.startsWith('•') || line.startsWith('-') || line.startsWith('*');
      if (isActionBullet && list.isNotEmpty) {
        final last = list.removeLast();
        final updatedDesc = last.description.isNotEmpty ? '${last.description} • $cleanLine' : cleanLine;
        list.add(last.copyWith(description: updatedDesc));
        continue;
      }

      final entry = ExtracurricularEntry(activity: cleanLine);
      if (validateExtracurricular(entry)) {
        list.add(entry);
      }
    }

    return list;
  }

  factory ResumeData.fromJson(Map<String, dynamic> json, {String? rawText}) {
    Map<String, dynamic> targetJson = json;
    for (final wrapKey in ['resume', 'data', 'candidate', 'parsed_resume', 'parsed', 'resumeData', 'resume_data', 'result', 'extracted_data', 'response']) {
      if (json[wrapKey] is Map) {
        targetJson = Map<String, dynamic>.from(json[wrapKey] as Map);
        break;
      }
    }

    String getString(List<String> keys) {
      final val = _getNormalized(targetJson, keys);
      if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
        final s = val.toString().trim();
        if (!_isPlaceholderValue(s)) return s;
      }
      for (final subMapKey in ['personal', 'personal_info', 'personalInfo', 'contact_info', 'contactInfo', 'contact', 'contactInformation', 'contact_information', 'identity', 'header', 'profile', 'user', 'basics', 'info', 'details']) {
        final subMapVal = _getNormalized(targetJson, [subMapKey]);
        if (subMapVal is Map) {
          final sVal = _getNormalized(subMapVal, keys);
          if (sVal != null && sVal is! Map && sVal is! List && sVal.toString().trim().isNotEmpty) {
            final s = sVal.toString().trim();
            if (!_isPlaceholderValue(s)) return s;
          }
        }
      }
      return '';
    }

    dynamic getField(List<String> keys) {
      final val = _getNormalized(targetJson, keys);
      if (val != null) return val;
      for (final subMapKey in ['sections', 'details', 'body', 'resume_body', 'content', 'data', 'personal', 'personal_info', 'contact']) {
        final subMapVal = _getNormalized(targetJson, [subMapKey]);
        if (subMapVal is Map) {
          final sVal = _getNormalized(subMapVal, keys);
          if (sVal != null) return sVal;
        }
      }
      return null;
    }

    var extractedName = getString(['fullName', 'full_name', 'name', 'candidateName', 'candidate_name', 'personName', 'person_name', 'headerName', 'contactName']);
    var extractedEmail = getString(['email', 'emailAddress', 'email_address', 'contactEmail', 'contact_email', 'mail']);
    var extractedPhone = getString(['phone', 'phoneNumber', 'phone_number', 'mobile', 'mobile_number', 'telephone', 'contactPhone', 'contact_phone', 'cell']);
    var extractedLinkedin = getString(['linkedin', 'linkedinUrl', 'linkedin_url', 'linkedIn', 'linkedin_profile', 'linkedinProfile']);
    var extractedGithub = getString(['github', 'githubUrl', 'github_url', 'portfolio', 'portfolioUrl', 'portfolio_url', 'website', 'personalWebsite', 'github_portfolio', 'personal_website']);
    var extractedTitle = getString(['jobTitle', 'job_title', 'title', 'professionalTitle', 'professional_title', 'currentTitle', 'current_title', 'headerTitle', 'headline', 'role', 'designation']);

    final jsonRawText = getString(['raw_text', 'rawText', 'extracted_text', 'extractedText']);
    final effectiveRawText = (rawText != null && rawText.isNotEmpty) ? rawText : jsonRawText;

    // Deterministic fallback for ALL missing/empty fields if raw text is available
    ResumeData fallbackData = const ResumeData();
    if (effectiveRawText.isNotEmpty) {
      fallbackData = parseFromRawText(effectiveRawText);
      if (extractedName.isEmpty) extractedName = fallbackData.fullName;
      if (extractedEmail.isEmpty) extractedEmail = fallbackData.email;
      if (extractedPhone.isEmpty) extractedPhone = fallbackData.phone;
      if (extractedLinkedin.isEmpty) extractedLinkedin = fallbackData.linkedin;
      if (extractedGithub.isEmpty) extractedGithub = fallbackData.github;
      if (extractedTitle.isEmpty) extractedTitle = fallbackData.title;
    }

    debugPrint('[MODEL FROM JSON] projects = ${targetJson['projects']}');
    debugPrint('[MODEL FROM JSON] education = ${targetJson['education']}');
    debugPrint('[MODEL FROM JSON] experience = ${targetJson['experience']}');
    debugPrint('[MODEL FROM JSON] skills = ${targetJson['skills']}');

    final parsedSummary = getString(['summary', 'objective', 'about', 'about_me', 'executiveSummary', 'executive_summary', 'bio', 'overview', 'professional_summary', 'profile_summary', 'personal_summary']);
    final parsedLocation = getString(['location', 'address', 'city', 'cityState', 'city_state', 'residence', 'place', 'country', 'user_location']);
    
    // Parse skills & skill groups flexibly
    final rawSkillsField = getField(['skills', 'keySkills', 'key_skills', 'technicalSkills', 'technical_skills', 'coreCompetencies', 'core_competencies', 'competencies', 'skills_list', 'technologies', 'skillsAndTechnologies']);
    List<String> parsedSkills = [];
    List<SkillGroupEntry> parsedSkillGroups = _parseList(getField(['skillGroups', 'skill_groups', 'categorizedSkills', 'categorized_skills', 'skillsByCategory', 'skill_categories']), SkillGroupEntry.fromJson);

    if (rawSkillsField is Map) {
      for (final entry in rawSkillsField.entries) {
        final cat = entry.key.toString().trim();
        final items = _parseStringList(entry.value);
        if (items.isNotEmpty) {
          parsedSkillGroups.add(SkillGroupEntry(category: cat, items: items));
          parsedSkills.addAll(items);
        }
      }
    } else if (rawSkillsField is List) {
      for (final item in rawSkillsField) {
        if (item is Map && (item.containsKey('category') || item.containsKey('group') || item.containsKey('name')) && (item.containsKey('items') || item.containsKey('skills') || item.containsKey('list'))) {
          final group = SkillGroupEntry.fromJson(item);
          if (group.category.isNotEmpty && group.items.isNotEmpty) {
            parsedSkillGroups.add(group);
            parsedSkills.addAll(group.items);
          }
        } else {
          final sList = _parseStringList([item]);
          parsedSkills.addAll(sList);
        }
      }
    } else if (rawSkillsField is String) {
      parsedSkills = _parseStringList(rawSkillsField);
    }
    parsedSkills = parsedSkills.toSet().toList();

    final parsedExp = _parseList(getField(['experience', 'workExperience', 'work_experience', 'employmentHistory', 'employment_history', 'workHistory', 'work_history', 'jobs', 'experiences', 'career_history', 'work_entries']), ExperienceEntry.fromJson);
    final parsedProj = _parseList(getField(['projects', 'projectHistory', 'project_history', 'keyProjects', 'key_projects', 'personalProjects', 'personal_projects', 'projects_list', 'portfolio']), ProjectEntry.fromJson);
    final parsedEdu = _parseList(getField(['education', 'academicHistory', 'academic_history', 'academics', 'qualification', 'qualifications', 'education_history', 'educational_background', 'educationEntries']), EducationEntry.fromJson);
    final parsedCerts = _parseCertifications(targetJson);
    final parsedExtras = _parseExtracurriculars(targetJson);

    final validExp = validateAndSanitizeExperience(parsedExp);
    final sanitizedProj = validateAndSanitizeProjects(parsedProj);
    final validProj = sanitizedProj.where(validateProject).toList();
    final validEdu = parsedEdu.where(validateEducation).toList();
    final validCerts = parsedCerts.where(validateCertification).toList();
    final validExtras = parsedExtras.where(validateExtracurricular).toList();
    final validSkillGroups = parsedSkillGroups.where(validateSkillGroup).toList();
    final validSkills = parsedSkills
        .where((s) => s.trim().isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s))
        .toList();

    debugPrint('[PIPELINE] AI EXTRACTION:');
    debugPrint('   skills=${validSkills.length}');
    debugPrint('   education=${validEdu.length}');
    debugPrint('   experience=${validExp.length}');
    debugPrint('   projects=${validProj.length}');
    debugPrint('   certifications=${validCerts.length}');

    final validFallbackExp = validateAndSanitizeExperience(fallbackData.experience);
    final validFallbackProj = validateAndSanitizeProjects(fallbackData.projects).where(validateProject).toList();
    final validFallbackEdu = fallbackData.education.where(validateEducation).toList();
    final validFallbackCerts = fallbackData.certifications.where(validateCertification).toList();
    final validFallbackExtras = fallbackData.extracurriculars.where(validateExtracurricular).toList();
    final validFallbackSkills = fallbackData.skills
        .where((s) => s.trim().isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s))
        .toList();
    final validFallbackSkillGroups = fallbackData.skillGroups.where(validateSkillGroup).toList();

    final parsedParserVersion = getString(['parserVersion', 'parser_version']);
    final parsedFileHash = getString(['fileHash', 'file_hash']);

    final rawData = ResumeData(
      fullName: extractedName.isNotEmpty ? extractedName : fallbackData.fullName,
      email: extractedEmail.isNotEmpty ? extractedEmail : fallbackData.email,
      phone: extractedPhone.isNotEmpty ? extractedPhone : fallbackData.phone,
      location: (parsedLocation.isEmpty || _isPlaceholderValue(parsedLocation)) ? fallbackData.location : parsedLocation,
      linkedin: extractedLinkedin.isNotEmpty ? extractedLinkedin : fallbackData.linkedin,
      github: extractedGithub.isNotEmpty ? extractedGithub : fallbackData.github,
      title: extractedTitle.isNotEmpty ? extractedTitle : fallbackData.title,
      summary: (parsedSummary.isEmpty || _isPlaceholderValue(parsedSummary)) ? fallbackData.summary : parsedSummary,
      skills: validSkills.isEmpty ? validFallbackSkills : validSkills,
      skillGroups: validSkillGroups.isEmpty ? validFallbackSkillGroups : validSkillGroups,
      experience: validExp.isEmpty ? validFallbackExp : validExp,
      projects: validProj.isEmpty ? validFallbackProj : validProj,
      education: validEdu.isEmpty ? validFallbackEdu : validEdu,
      certifications: validCerts.isEmpty ? validFallbackCerts : validCerts,
      extracurriculars: validExtras.isEmpty ? validFallbackExtras : validExtras,
      parserVersion: parsedParserVersion.isNotEmpty ? parsedParserVersion : currentParserVersion,
      fileHash: parsedFileHash.isNotEmpty ? parsedFileHash : fallbackData.fileHash,
    );

    final result = _sanitizeAndRepairSectionMapping(rawData, fallbackData: fallbackData);
    final finalResult = validateAndSanitizeAll(result);

    debugPrint('[PIPELINE] FINAL RESUMEMODEL:');
    debugPrint('   Candidate: "${finalResult.fullName}" (${finalResult.email})');
    debugPrint('   skills=${finalResult.skills.length}');
    debugPrint('   education=${finalResult.education.length}');
    debugPrint('   experience=${finalResult.experience.length}');
    debugPrint('   projects=${finalResult.projects.length}');
    debugPrint('   certifications=${finalResult.certifications.length}');

    return finalResult;
  }

  static ResumeData _sanitizeAndRepairSectionMapping(ResumeData raw, {ResumeData? fallbackData}) {
    bool suspiciousMappingDetected = false;

    // 1. Sanitize Skills (Technical / Professional skills ONLY)
    final cleanSkills = <String>[];
    final misclassifiedBullets = <String>[];

    for (final skill in raw.skills) {
      final s = skill.trim();
      if (s.isEmpty || _isPlaceholderValue(s)) continue;

      final isFullSentence = s.length > 70 ||
          RegExp(r'^(engineered|developed|implemented|spearheaded|created|managed|designed|led|built|architected)\b', caseSensitive: false).hasMatch(s) ||
          (s.contains(' ') && s.split(' ').length > 8);

      if (isFullSentence) {
        suspiciousMappingDetected = true;
        misclassifiedBullets.add(s);
      } else {
        cleanSkills.add(s);
      }
    }

    final cleanSkillGroups = List<SkillGroupEntry>.from(raw.skillGroups);

    // 2. Sanitize Experience & repair education/project leaks
    final rawExpFiltered = <ExperienceEntry>[];
    final cleanEdu = List<EducationEntry>.from(raw.education);
    var cleanProj = validateAndSanitizeProjects(raw.projects);
    final cleanExtras = List<ExtracurricularEntry>.from(raw.extracurriculars);
    final cleanCerts = List<ExtracurricularEntry>.from(raw.certifications);

    for (final exp in raw.experience) {
      final comp = exp.company.toLowerCase();
      final role = exp.role.toLowerCase();

      final isEdu = comp.contains('university') ||
          comp.contains('college') ||
          (comp.contains('school') && !comp.contains('skill')) ||
          role.contains('b.tech') ||
          role.contains('bachelor') ||
          role.contains('master') ||
          role.contains('degree');

      if (isEdu) {
        suspiciousMappingDetected = true;
        cleanEdu.add(EducationEntry(
          institution: exp.company,
          degree: exp.role,
          startDate: exp.startDate,
          endDate: exp.endDate,
        ));
      } else {
        rawExpFiltered.add(exp);
      }
    }

    var cleanExp = validateAndSanitizeExperience(rawExpFiltered);

    if (misclassifiedBullets.isNotEmpty && cleanExp.isNotEmpty) {
      final firstExp = cleanExp.first;
      final updatedBullets = List<String>.from(firstExp.description)..addAll(misclassifiedBullets);
      cleanExp[0] = firstExp.copyWith(description: updatedBullets);
    }

    if (suspiciousMappingDetected) {
      debugPrint('[ResumeParser] WARNING: suspicious section mapping detected');
    }

    String finalSummary = raw.summary.trim();

    final isContaminatedSummary = finalSummary.length > 100 && (
      RegExp(r'\b(gpa|class xii|class x|cbse|icse|matriculation|engineered|architected|developed|work experience|professional experience|extra-curricular|extracurricular|institute|university|college|b\.tech|bachelor|master)\b', caseSensitive: false).hasMatch(finalSummary)
    );

    if (isContaminatedSummary) {
      debugPrint('[ResumeParser] Summary is contaminated with multi-section text. Repairing and redistributing sections...');
      final reParsed = parseFromRawText(finalSummary);

      if (cleanEdu.isEmpty && reParsed.education.isNotEmpty) {
        cleanEdu.addAll(reParsed.education);
      }
      if (cleanProj.isEmpty && reParsed.projects.isNotEmpty) {
        cleanProj.addAll(reParsed.projects);
      }
      if (cleanExp.isEmpty && reParsed.experience.isNotEmpty) {
        cleanExp.addAll(reParsed.experience);
      }
      if (cleanExtras.isEmpty && reParsed.extracurriculars.isNotEmpty) {
        cleanExtras.addAll(reParsed.extracurriculars);
      }
      if (cleanSkillGroups.isEmpty && reParsed.skillGroups.isNotEmpty) {
        cleanSkillGroups.addAll(reParsed.skillGroups);
      }
      if (cleanSkills.isEmpty && reParsed.skills.isNotEmpty) {
        cleanSkills.addAll(reParsed.skills);
      }

      finalSummary = '';
    } else if (ResumeData._isPlaceholderValue(finalSummary)) {
      finalSummary = '';
    }

    cleanProj = validateAndSanitizeProjects(cleanProj);
    cleanExp = validateAndSanitizeExperience(cleanExp);

    // Fallback backfilling for any empty section if fallbackData has entries
    if (fallbackData != null) {
      if (cleanSkills.isEmpty && fallbackData.skills.isNotEmpty) {
        cleanSkills.addAll(fallbackData.skills);
      }
      if (cleanSkillGroups.isEmpty && fallbackData.skillGroups.isNotEmpty) {
        cleanSkillGroups.addAll(fallbackData.skillGroups);
      }
      if (cleanEdu.isEmpty && fallbackData.education.isNotEmpty) {
        cleanEdu.addAll(fallbackData.education);
      }
      if (cleanProj.isEmpty && fallbackData.projects.isNotEmpty) {
        cleanProj.addAll(fallbackData.projects);
      }
      if (cleanExp.isEmpty && fallbackData.experience.isNotEmpty) {
        cleanExp.addAll(fallbackData.experience);
      }
      if (cleanExtras.isEmpty && fallbackData.extracurriculars.isNotEmpty) {
        cleanExtras.addAll(fallbackData.extracurriculars);
      }
      if (cleanCerts.isEmpty && fallbackData.certifications.isNotEmpty) {
        cleanCerts.addAll(fallbackData.certifications);
      }
      if (finalSummary.isEmpty && fallbackData.summary.isNotEmpty) {
        finalSummary = fallbackData.summary;
      }
    }

    final sanitized = raw.copyWith(
      summary: finalSummary,
      skills: cleanSkills,
      skillGroups: cleanSkillGroups,
      experience: cleanExp,
      education: cleanEdu,
      projects: cleanProj,
      certifications: cleanCerts,
      extracurriculars: cleanExtras,
    );

    debugPrint('[CERTIFICATIONS] RAW COUNT: ${raw.certifications.length}');
    debugPrint('[CERTIFICATIONS] FINAL COUNT: ${sanitized.certifications.length}');
    debugPrint('[Loaded certifications]: ${sanitized.certifications.length}');

    debugPrint('[PROJECT EXTRACTION] RAW COUNT: ${raw.projects.length}');
    debugPrint('[PROJECT EXTRACTION] FINAL COUNT: ${sanitized.projects.length}');

    debugPrint('[EDUCATION] RAW COUNT: ${raw.education.length}');
    debugPrint('[EDUCATION] FINAL COUNT: ${sanitized.education.length}');

    debugPrint('[EXPERIENCE] RAW COUNT: ${raw.experience.length}');
    debugPrint('[EXPERIENCE] FINAL COUNT: ${sanitized.experience.length}');

    debugPrint('[SKILLS] RAW COUNT: ${raw.skillGroups.isNotEmpty ? raw.skillGroups.length : raw.skills.length}');
    debugPrint('[SKILLS] FINAL COUNT: ${sanitized.skillGroups.isNotEmpty ? sanitized.skillGroups.length : sanitized.skills.length}');

    final hasStructuredData = sanitized.projects.isNotEmpty ||
        sanitized.education.isNotEmpty ||
        sanitized.experience.isNotEmpty ||
        sanitized.skills.isNotEmpty ||
        sanitized.skillGroups.isNotEmpty ||
        sanitized.certifications.isNotEmpty ||
        sanitized.extracurriculars.isNotEmpty;

    if (!hasStructuredData) {
      debugPrint('[ResumeParser] EXTRACTION FAILED: no structured records found');
    } else {
      debugPrint('[ResumeParser] Parsed resume successfully');
    }
    debugPrint('[ResumeParser] Skills: ${sanitized.skillGroups.isNotEmpty ? sanitized.skillGroups.length : sanitized.skills.length}');
    debugPrint('[ResumeParser] Experience: ${sanitized.experience.length}');
    debugPrint('[ResumeParser] Projects: ${sanitized.projects.length}');
    debugPrint('[ResumeParser] Education: ${sanitized.education.length}');
    debugPrint('[ResumeParser] Certifications: ${sanitized.certifications.length}');
    debugPrint('[ResumeParser] Extracurriculars: ${sanitized.extracurriculars.length}');

    return sanitized;
  }

  static List<ProjectEntry> validateAndSanitizeProjects(List<ProjectEntry> rawProjects) {
    final cleanProjects = <ProjectEntry>[];

    bool isFragmentOrBullet(ProjectEntry p) {
      final name = p.name.trim();
      if (name.isEmpty) return true;

      if (isKnownSectionHeader(name) || _isPlaceholderValue(name)) return true;

      if (name.toLowerCase() == 'project' ||
          name.toLowerCase() == 'projects' ||
          name.toLowerCase() == 'key projects' ||
          name.toLowerCase() == 'personal projects') {
        return true;
      }

      if (_isSingleTechnologyKeyword(name)) {
        return true;
      }

      final lower = name.toLowerCase();
      // Single word names that are generic nouns or adjectives or verbs (e.g. Search, AI, Engineering, Digest, AI-powered)
      if (!name.contains(' ') && !name.contains('|') && !name.contains('-') && (
        lower == 'search' ||
        lower == 'ai' ||
        lower == 'engineering' ||
        lower == 'digest' ||
        lower == 'voice' ||
        lower == 'ai-powered' ||
        lower == 'developer' ||
        lower == 'app' ||
        lower == 'web' ||
        lower == 'backend' ||
        lower == 'frontend' ||
        lower == 'system' ||
        lower == 'platform' ||
        lower == 'model' ||
        lower == 'tool' ||
        lower == 'api' ||
        lower == 'application'
      )) {
        return true;
      }

      if (RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(name)) {
        return true;
      }
      if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(name)) {
        return true;
      }
      if (RegExp(r'^[a-z]').hasMatch(name) || RegExp(r'^(and|for|with|in|to|of|from|by|into|during|via|under|about|the|an|a)\b', caseSensitive: false).hasMatch(name)) {
        return true;
      }
      if (name.length > 70 || RegExp(r'[.!?]\s+[A-Z]').hasMatch(name) || (name.endsWith('.') && !name.contains('|'))) {
        return true;
      }
      if (p.description.isEmpty && p.descriptionBullets.isEmpty && p.githubUrl.isEmpty && p.type.isEmpty) {
        return true;
      }

      return false;
    }

    for (final p in rawProjects) {
      final isRepoOnly = (p.name.contains('github.com/') || (p.name.contains('/') && !p.name.contains(' ') && p.name.length < 50));
      if (isRepoOnly && cleanProjects.isNotEmpty) {
        final last = cleanProjects.removeLast();
        final repoUrl = p.name.startsWith('http') ? p.name : (p.name.contains('github.com') ? 'https://${p.name}' : 'https://github.com/${p.name}');
        final updatedBullets = List<String>.from(last.descriptionBullets);
        final textToAdd = p.description.isNotEmpty ? p.description : '';
        if (textToAdd.isNotEmpty && !updatedBullets.contains(textToAdd)) {
          updatedBullets.add(textToAdd);
        }
        for (final b in p.descriptionBullets) {
          if (b.isNotEmpty && !updatedBullets.contains(b)) {
            updatedBullets.add(b);
          }
        }
        cleanProjects.add(last.copyWith(
          githubUrl: last.githubUrl.isEmpty ? repoUrl : last.githubUrl,
          descriptionBullets: updatedBullets,
          description: updatedBullets.join(' '),
        ));
        continue;
      }

      if (isFragmentOrBullet(p)) {
        if (cleanProjects.isNotEmpty) {
          final last = cleanProjects.removeLast();
          final updatedBullets = List<String>.from(last.descriptionBullets);

          final fragments = <String>[];
          final nameClean = p.name.trim();
          if (nameClean.isNotEmpty &&
              !ResumeData._isPlaceholderValue(nameClean) &&
              !isKnownSectionHeader(nameClean) &&
              nameClean.toLowerCase() != 'project' &&
              nameClean.toLowerCase() != 'projects' &&
              nameClean.toLowerCase() != 'key projects' &&
              nameClean.toLowerCase() != 'personal projects') {
            fragments.add(nameClean);
          }

          if (p.descriptionBullets.isNotEmpty) {
            for (final b in p.descriptionBullets) {
              final bClean = b.trim();
              if (bClean.isNotEmpty && !fragments.contains(bClean) && !isKnownSectionHeader(bClean)) {
                fragments.add(bClean);
              }
            }
          } else if (p.description.trim().isNotEmpty && !fragments.contains(p.description.trim()) && !isKnownSectionHeader(p.description.trim())) {
            fragments.add(p.description.trim());
          }

          for (final f in fragments) {
            final cleanF = f.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
            if (cleanF.isEmpty || isKnownSectionHeader(cleanF) || _isPlaceholderValue(cleanF)) continue;

            final isNewBullet = f.startsWith('•') || f.startsWith('◦') || f.startsWith('°') || f.startsWith('▪') || f.startsWith('▫') || f.startsWith('-') || f.startsWith('*') ||
                RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating|benchmarked|benchmark|generated|analyzed|deployed|automated|configured|trained|evaluated|authored|researched|fine-tuned|tested|orchestrated|established|delivered|directed)\b', caseSensitive: false).hasMatch(cleanF);

            if (isNewBullet || updatedBullets.isEmpty) {
              if (!updatedBullets.contains(cleanF)) {
                updatedBullets.add(cleanF);
              }
            } else {
              final lastB = updatedBullets.removeLast();
              String merged;
              if (cleanF.startsWith(',') || cleanF.startsWith('.') || cleanF.startsWith(';') || cleanF.startsWith(':')) {
                merged = '$lastB$cleanF';
              } else if (lastB.endsWith('-')) {
                merged = '${lastB.substring(0, lastB.length - 1)}$cleanF';
              } else {
                merged = '$lastB $cleanF';
              }
              updatedBullets.add(merged);
            }
          }

          cleanProjects.add(last.copyWith(
            descriptionBullets: updatedBullets,
            description: updatedBullets.join(' '),
          ));
        }
        continue;
      }

      var name = p.name;
      var subtitle = p.type;
      var repoUrl = p.effectiveGithubUrl;
      final bullets = List<String>.from(p.descriptionBullets);

      if (name.contains('|')) {
        final parts = name.split('|').map((s) => s.trim()).toList();
        name = parts[0];
        if (parts.length > 1 && subtitle.isEmpty) subtitle = parts[1];
        if (parts.length > 2 && repoUrl.isEmpty) {
          final p2 = parts[2];
          if (p2.contains('github.com') || p2.contains('/')) {
            repoUrl = p2.startsWith('http') ? p2 : (p2.contains('github.com') ? 'https://$p2' : 'https://github.com/$p2');
          }
        }
      }

      name = name.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();

      if (p.description.isNotEmpty && bullets.isEmpty) {
        bullets.add(p.description);
      }

      final cleanBullets = <String>[];
      for (final b in bullets) {
        final trimmed = b.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
        if (trimmed.isNotEmpty && !ResumeData._isPlaceholderValue(trimmed) && !cleanBullets.contains(trimmed) && !isKnownSectionHeader(trimmed)) {
          cleanBullets.add(trimmed);
        }
      }

      cleanProjects.add(ProjectEntry(
        id: p.id,
        name: name,
        type: subtitle,
        githubUrl: repoUrl,
        demoUrl: p.demoUrl,
        technologies: p.technologies,
        source: p.source,
        githubOwner: p.githubOwner,
        githubRepo: p.githubRepo,
        descriptionBullets: cleanBullets,
        description: cleanBullets.join(' '),
      ));
    }

    debugPrint('\n[PROJECT VALIDATION]');
    debugPrint('Expected semantic records based on headers: ${cleanProjects.length}');
    debugPrint('AI returned: ${rawProjects.length}');
    debugPrint('Final normalized: ${cleanProjects.length}');
    for (int i = 0; i < cleanProjects.length; i++) {
      final cp = cleanProjects[i];
      debugPrint('\n[PROJECT ${i + 1}] ${cp.name}');
      debugPrint('Descriptions: ${cp.descriptionBullets.length}');
    }

    return cleanProjects;
  }

  static List<ExperienceEntry> validateAndSanitizeExperience(List<ExperienceEntry> rawExp) {
    final cleanExp = <ExperienceEntry>[];

    bool isFragmentOrBullet(ExperienceEntry e) {
      final role = e.role.trim();
      final comp = e.company.trim();

      if (comp.isEmpty && role.isEmpty) return true;

      if (_isSingleTechnologyKeyword(role) || _isSingleTechnologyKeyword(comp)) {
        return true;
      }

      if (isKnownSectionHeader(role) || isKnownSectionHeader(comp) || _isPlaceholderValue(role) || _isPlaceholderValue(comp)) {
        return true;
      }

      final combined = '$role $comp'.trim();
      if (RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(combined)) {
        return true;
      }
      if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(combined)) {
        return true;
      }
      if (RegExp(r'^[a-z]').hasMatch(role) && comp.isEmpty) {
        return true;
      }
      if ((role.length > 70 || RegExp(r'[.!?]\s+[A-Z]').hasMatch(role)) && comp.isEmpty) {
        return true;
      }

      return false;
    }

    for (final e in rawExp) {
      if (isFragmentOrBullet(e)) {
        if (cleanExp.isNotEmpty) {
          final last = cleanExp.removeLast();
          final updatedBullets = List<String>.from(last.description);

          final fragments = <String>[];
          final roleClean = e.role.trim();
          final compClean = e.company.trim();
          if (roleClean.isNotEmpty &&
              !ResumeData._isPlaceholderValue(roleClean) &&
              !isKnownSectionHeader(roleClean)) {
            fragments.add(roleClean);
          }
          if (compClean.isNotEmpty &&
              !ResumeData._isPlaceholderValue(compClean) &&
              !isKnownSectionHeader(compClean) &&
              !fragments.contains(compClean)) {
            fragments.add(compClean);
          }
          for (final b in e.description) {
            final bClean = b.trim();
            if (bClean.isNotEmpty && !fragments.contains(bClean) && !isKnownSectionHeader(bClean)) {
              fragments.add(bClean);
            }
          }

          for (final f in fragments) {
            final cleanF = f.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
            if (cleanF.isEmpty || isKnownSectionHeader(cleanF) || _isPlaceholderValue(cleanF)) continue;

            final isNewBullet = f.startsWith('•') || f.startsWith('◦') || f.startsWith('°') || f.startsWith('▪') || f.startsWith('▫') || f.startsWith('-') || f.startsWith('*') ||
                RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating|benchmarked|benchmark|generated|analyzed|deployed|automated|configured|trained|evaluated|authored|researched|fine-tuned|tested|orchestrated|established|delivered|directed)\b', caseSensitive: false).hasMatch(cleanF);

            if (isNewBullet || updatedBullets.isEmpty) {
              if (!updatedBullets.contains(cleanF)) {
                updatedBullets.add(cleanF);
              }
            } else {
              final lastB = updatedBullets.removeLast();
              String merged;
              if (cleanF.startsWith(',') || cleanF.startsWith('.') || cleanF.startsWith(';') || cleanF.startsWith(':')) {
                merged = '$lastB$cleanF';
              } else if (lastB.endsWith('-')) {
                merged = '${lastB.substring(0, lastB.length - 1)}$cleanF';
              } else {
                merged = '$lastB $cleanF';
              }
              updatedBullets.add(merged);
            }
          }

          cleanExp.add(last.copyWith(
            description: updatedBullets,
          ));
        }
        continue;
      }

      var role = e.role.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      var company = e.company.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      var location = e.location.trim();
      var startDate = e.startDate.trim();
      var endDate = e.endDate.trim();
      final bullets = List<String>.from(e.description);

      if (role.contains('|')) {
        final parts = role.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          role = parts[0];
          if (parts.length > 1 && company.isEmpty) company = parts[1];
          for (int i = 2; i < parts.length; i++) {
            final p = parts[i];
            final dateMatch = RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)?\b', caseSensitive: false).firstMatch(p);
            if (dateMatch != null && startDate.isEmpty) {
              startDate = dateMatch.group(1) ?? '';
              endDate = dateMatch.group(2) ?? '';
            } else if (location.isEmpty) {
              location = p;
            }
          }
        }
      }

      final cleanBullets = <String>[];
      for (final b in bullets) {
        final trimmed = b.replaceFirst(RegExp(r'^(?:[•◦°▪▫●○◆◇►▶▸⁃∙\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
        if (trimmed.isNotEmpty && !ResumeData._isPlaceholderValue(trimmed) && !cleanBullets.contains(trimmed) && !isKnownSectionHeader(trimmed)) {
          cleanBullets.add(trimmed);
        }
      }

      cleanExp.add(ExperienceEntry(
        role: role,
        company: company,
        location: location,
        startDate: startDate,
        endDate: endDate,
        description: cleanBullets,
      ));
    }

    debugPrint('\n[EXPERIENCE VALIDATION]');
    debugPrint('AI/raw returned: ${rawExp.length}');
    debugPrint('Final normalized experience: ${cleanExp.length}');
    for (int i = 0; i < cleanExp.length; i++) {
      final ce = cleanExp[i];
      debugPrint('\n[EXPERIENCE ${i + 1}] ${ce.role} at ${ce.company} (${ce.startDate} - ${ce.endDate})');
      debugPrint('Bullets: ${ce.description.length}');
    }

    return cleanExp;
  }

  // ---------------------------------------------------------------------------
  // Entity Validation & Pipeline Audit Layer
  // ---------------------------------------------------------------------------

  static bool validateProject(ProjectEntry p) {
    final name = p.name.trim();
    if (name.isEmpty) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (empty)');
      return false;
    }
    if (isKnownSectionHeader(name)) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (is known section header)');
      return false;
    }
    if (_isPlaceholderValue(name)) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (placeholder)');
      return false;
    }
    if (name.length > 70 || RegExp(r'[.!?]\s+[A-Z]').hasMatch(name) || (name.endsWith('.') && !name.contains('|'))) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (sentence/fragment)');
      return false;
    }
    if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(name)) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (starts with action verb)');
      return false;
    }
    if (RegExp(r'^[a-z]').hasMatch(name) || RegExp(r'^(and|for|with|in|to|of|from|by|into|during|via|under|about|the|an|a)\b', caseSensitive: false).hasMatch(name)) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (starts with lowercase/preposition)');
      return false;
    }
    final isSingleTech = _isSingleTechnologyKeyword(name);
    if (isSingleTech && p.githubUrl.isEmpty && p.type.isEmpty) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (standalone tech keyword)');
      return false;
    }
    debugPrint('[PROJECT SANITIZER] ACCEPTED: "${p.name}"');
    return true;
  }

  static bool _isStopWordOrPreposition(String text) {
    final s = text.trim().toLowerCase();
    if (s.isEmpty) return true;
    return const {
      'in', 'with', 'a', 'an', 'the', 'to', 'for', 'of', 'from',
      'by', 'at', 'on', 'and', 'or', 'as', 'is', 'are', 'was', 'were',
      'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did',
      'but', 'if', 'then', 'else', 'when', 'where', 'why', 'how', 'all',
      'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such',
      'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
      'can', 'will', 'just', 'should', 'now', '&', '-', '•', '|', '~', '_',
      ':', ';', ',', '.', '(', ')', '[', ']', '{', '}',
    }.contains(s);
  }

  static bool validateEducation(EducationEntry e) {
    final inst = e.institution.trim();
    final deg = e.degree.trim();
    if (inst.isEmpty && deg.isEmpty) return false;
    if (_isStopWordOrPreposition(inst) && deg.isEmpty) return false;
    if (_isStopWordOrPreposition(deg) && inst.isEmpty) return false;
    if (_isStopWordOrPreposition(inst) && _isStopWordOrPreposition(deg)) return false;
    if (isKnownSectionHeader(inst) || isKnownSectionHeader(deg)) return false;
    if (_isPlaceholderValue(inst) && _isPlaceholderValue(deg)) return false;
    if (inst.length < 3 && deg.length < 3) return false;
    return true;
  }

  static bool validateExperience(ExperienceEntry e) {
    final comp = e.company.trim();
    final role = e.role.trim();
    if (comp.isEmpty && role.isEmpty) return false;
    if (_isStopWordOrPreposition(comp) && role.isEmpty) return false;
    if (_isStopWordOrPreposition(role) && comp.isEmpty) return false;
    if (_isStopWordOrPreposition(comp) && _isStopWordOrPreposition(role)) return false;
    if (isKnownSectionHeader(comp) || isKnownSectionHeader(role)) return false;
    if (_isPlaceholderValue(comp) && _isPlaceholderValue(role)) return false;
    if (comp.length < 2 && role.length < 2) return false;
    if (RegExp(r'^(collaborated|worked|engineered|developed|built|managed|led|spearheaded|researched)\b', caseSensitive: false).hasMatch(comp) && role.isEmpty) return false;
    return true;
  }

  static bool validateCertification(ExtracurricularEntry c) {
    final act = c.activity.trim();
    if (act.isEmpty || _isStopWordOrPreposition(act) || _isPlaceholderValue(act)) return false;
    if (isKnownSectionHeader(act)) return false;
    if (act.length < 3) return false;
    // Reject sentence-length action verb bullet points as certification titles
    if (act.length > 80 ||
        (act.contains(' ') &&
            act.split(' ').length > 8 &&
            RegExp(r'^(collaborated|worked|engineered|developed|built|managed|led|spearheaded|researched)\b',
                    caseSensitive: false)
                .hasMatch(act))) {
      return false;
    }
    return true;
  }

  static bool validateExtracurricular(ExtracurricularEntry e) {
    final act = e.activity.trim();
    if (act.isEmpty || _isStopWordOrPreposition(act) || _isPlaceholderValue(act)) return false;
    if (isKnownSectionHeader(act)) return false;
    if (act.length < 3) return false;
    if (RegExp(r'^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}$', caseSensitive: false).hasMatch(act)) return false;
    if (RegExp(r'^\d{4}\s*[\–\-—\to]\s*(\d{4}|Present)$', caseSensitive: false).hasMatch(act)) return false;
    if (RegExp(r'^(collaborated|worked|engineered|developed|built|managed|led|spearheaded|researched)\b', caseSensitive: false).hasMatch(act) && (act.length > 50 || act.split(' ').length > 6)) {
      return false;
    }
    return true;
  }

  static bool validateSkillGroup(SkillGroupEntry g) {
    if (isKnownSectionHeader(g.category) && g.items.isEmpty) return false;
    return g.category.trim().isNotEmpty && g.items.isNotEmpty;
  }

  static ResumeData validateAndSanitizeAll(ResumeData data) {
    final validProjects = validateAndSanitizeProjects(data.projects);
    final validEducation = data.education.where(validateEducation).toList();
    final validExperience = validateAndSanitizeExperience(data.experience);
    final validCertifications = data.certifications.where(validateCertification).toList();
    final validExtracurriculars = data.extracurriculars.where(validateExtracurricular).toList();
    final validSkillGroups = data.skillGroups.where(validateSkillGroup).toList();
    final validSkills = data.skills
        .where((s) => s.trim().isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s))
        .toList();

    debugPrint('[PIPELINE] NORMALIZATION:');
    debugPrint('   skills=${validSkills.length}');
    debugPrint('   education=${validEducation.length}');
    debugPrint('   experience=${validExperience.length}');
    debugPrint('   projects=${validProjects.length}');
    debugPrint('   certifications=${validCertifications.length}');

    return data.copyWith(
      projects: validProjects,
      education: validEducation,
      experience: validExperience,
      certifications: validCertifications,
      extracurriculars: validExtracurriculars,
      skillGroups: validSkillGroups,
      skills: validSkills,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin': linkedin,
        'github': github,
        'title': title,
        'summary': summary,
        'skills': skills,
        'skillGroups': skillGroups.map((e) => e.toJson()).toList(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'extracurriculars':
            extracurriculars.map((e) => e.toJson()).toList(),
        'parserVersion': parserVersion.isNotEmpty ? parserVersion : currentParserVersion,
        'fileHash': fileHash,
      };

  /// Returns a copy with optionally overridden fields.
  ResumeData copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? linkedin,
    String? github,
    String? title,
    String? summary,
    List<String>? skills,
    List<SkillGroupEntry>? skillGroups,
    List<ExperienceEntry>? experience,
    List<ProjectEntry>? projects,
    List<EducationEntry>? education,
    List<ExtracurricularEntry>? certifications,
    List<ExtracurricularEntry>? extracurriculars,
    String? parserVersion,
    String? fileHash,
  }) {
    return ResumeData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      skills: skills ?? this.skills,
      skillGroups: skillGroups ?? this.skillGroups,
      experience: experience ?? this.experience,
      projects: projects ?? this.projects,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      extracurriculars: extracurriculars ?? this.extracurriculars,
      parserVersion: parserVersion ?? this.parserVersion,
      fileHash: fileHash ?? this.fileHash,
    );
  }

  // ── Helpers ──

  static String _normKey(String k) {
    return k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static dynamic _getNormalized(Map map, List<String> keys) {
    final normKeys = keys.map(_normKey).toSet();
    for (final entry in map.entries) {
      final keyNorm = _normKey(entry.key.toString());
      if (normKeys.contains(keyNorm)) {
        return entry.value;
      }
    }
    return null;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      final list = <String>[];
      for (final e in value) {
        if (e is Map) {
          final map = Map<String, dynamic>.from(e);
          final s = map['name'] ?? map['skill'] ?? map['keyword'] ?? map['title'] ?? map['value'];
          if (s != null && s.toString().trim().isNotEmpty) {
            list.add(s.toString().trim());
          }
        } else if (e != null) {
          final str = e.toString().trim();
          if (str.isNotEmpty && !str.startsWith('{') && !str.endsWith('}')) {
            list.add(str);
          }
        }
      }
      return list;
    }
    if (value is String && value.trim().isNotEmpty) {
      final str = value.trim();
      if (!str.startsWith('{') && !str.endsWith('}')) {
        return str.split(RegExp(r'[,;\n]')).map((e) => e.trim()).where((s) => s.isNotEmpty && !s.startsWith('{')).toList();
      }
    }
    return [];
  }

  static List<T> _parseList<T>(
      dynamic value, T Function(dynamic) fromJson) {
    if (value is List) {
      final list = <T>[];
      for (final item in value) {
        if (item != null) {
          try {
            list.add(fromJson(item));
          } catch (e, stackTrace) {
            debugPrint('[RESUME JSON PARSE ERROR] Exception parsing list item for type $T: $e\nItem value: $item\n$stackTrace');
          }
        }
      }
      return list;
    } else if (value is Map || value is String) {
      try {
        return [fromJson(value)];
      } catch (e, stackTrace) {
        debugPrint('[RESUME JSON PARSE ERROR] Exception parsing single item for type $T: $e\nItem value: $value\n$stackTrace');
      }
    }
    return [];
  }

  static List<ExtracurricularEntry> _parseCertifications(Map<String, dynamic> targetJson) {
    final results = <ExtracurricularEntry>[];

    final possibleKeys = [
      'certifications',
      'certificates',
      'certification',
      'certificate',
      'licenses',
      'courses',
      'credentials',
      'accreditations',
      'training',
    ];

    void checkSourceMap(Map<String, dynamic> src) {
      for (final key in possibleKeys) {
        final val = _getNormalized(src, [key]);
        if (val != null) {
          if (val is List) {
            for (final item in val) {
              final entry = ExtracurricularEntry.fromJson(item);
              if (validateCertification(entry)) {
                if (!results.any((r) => r.activity == entry.activity && r.organization == entry.organization)) {
                  results.add(entry);
                }
              }
            }
          } else if (val is String && val.trim().isNotEmpty && !_isPlaceholderValue(val.trim())) {
            final lines = val.split(RegExp(r'[\n;]')).map((e) => e.trim()).where((s) => s.isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s));
            for (final line in lines) {
              if (line.contains('|')) {
                final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s)).toList();
                if (parts.isNotEmpty) {
                  final entry = ExtracurricularEntry(
                    activity: parts[0],
                    organization: parts.length > 1 ? parts[1] : '',
                    description: parts.length > 2 ? parts.sublist(2).join(' • ') : '',
                  );
                  if (validateCertification(entry)) {
                    results.add(entry);
                  }
                  continue;
                }
              }
              final entry = ExtracurricularEntry(activity: line);
              if (validateCertification(entry) && !results.any((r) => r.activity == line)) {
                results.add(entry);
              }
            }
          }
        }
      }
    }

    checkSourceMap(targetJson);
    for (final subMapKey in ['sections', 'details', 'body', 'resume_body', 'content']) {
      if (targetJson[subMapKey] is Map) {
        checkSourceMap(Map<String, dynamic>.from(targetJson[subMapKey] as Map));
      }
    }

    return results;
  }

  static List<ExtracurricularEntry> _parseExtracurriculars(Map<String, dynamic> targetJson) {
    final results = <ExtracurricularEntry>[];

    final possibleKeys = [
      'extracurriculars',
      'extracurricular',
      'extracurricular_activities',
      'activities',
      'achievements',
      'awards',
      'volunteering',
      'volunteer',
      'community',
      'leadership',
      'involvement',
      'honors',
      'publications',
      'responsibilities',
    ];

    void checkSourceMap(Map<String, dynamic> src) {
      for (final key in possibleKeys) {
        final val = _getNormalized(src, [key]);
        if (val != null) {
          if (val is List) {
            for (final item in val) {
              final entry = ExtracurricularEntry.fromJson(item);
              if (validateExtracurricular(entry)) {
                if (!results.any((r) => r.activity == entry.activity && r.organization == entry.organization)) {
                  results.add(entry);
                }
              }
            }
          } else if (val is String && val.trim().isNotEmpty && !_isPlaceholderValue(val.trim())) {
            final lines = val.split(RegExp(r'[\n;]')).map((e) => e.trim()).where((s) => s.isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s));
            for (final line in lines) {
              if (line.contains('|')) {
                final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty && !_isPlaceholderValue(s) && !_isStopWordOrPreposition(s)).toList();
                if (parts.isNotEmpty) {
                  final entry = ExtracurricularEntry(
                    activity: parts[0],
                    organization: parts.length > 1 ? parts[1] : '',
                    description: parts.length > 2 ? parts.sublist(2).join(' • ') : '',
                  );
                  if (validateExtracurricular(entry)) {
                    results.add(entry);
                  }
                  continue;
                }
              }
              final entry = ExtracurricularEntry(activity: line);
              if (validateExtracurricular(entry) && !results.any((r) => r.activity == line)) {
                results.add(entry);
              }
            }
          }
        }
      }
    }

    checkSourceMap(targetJson);
    for (final subMapKey in ['sections', 'details', 'body', 'resume_body', 'content']) {
      if (targetJson[subMapKey] is Map) {
        checkSourceMap(Map<String, dynamic>.from(targetJson[subMapKey] as Map));
      }
    }

    return results;
  }
}

// ---------------------------------------------------------------------------
// Experience
// ---------------------------------------------------------------------------

class ExperienceEntry {
  final String company;
  final String role;
  final String location;
  final String startDate;
  final String endDate;
  final List<String> description;

  const ExperienceEntry({
    this.company = '',
    this.role = '',
    this.location = '',
    this.startDate = '',
    this.endDate = '',
    this.description = const [],
  });

  factory ExperienceEntry.fromJson(dynamic json) {
    if (json == null) return const ExperienceEntry();

    if (json is String && json.trim().isNotEmpty) {
      return ExperienceEntry(role: json.trim());
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      String getStr(List<String> keys) {
        final val = ResumeData._getNormalized(map, keys);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          final s = val.toString().trim();
          if (!ResumeData._isPlaceholderValue(s)) return s;
        }
        return '';
      }

      var descVal = ResumeData._getNormalized(map, ['description', 'bullets', 'bulletPoints', 'bullet_points', 'responsibilities', 'highlights', 'details', 'achievements', 'summary']);
      List<String> parsedDesc = ResumeData._parseStringList(descVal);

      var comp = getStr(['company', 'companyName', 'company_name', 'employer', 'organization', 'firm', 'workplace', 'client']);
      var role = getStr(['role', 'jobTitle', 'job_title', 'title', 'position', 'designation', 'occupation']);
      var loc = getStr(['location', 'city', 'place', 'address']);
      var start = getStr(['startDate', 'start_date', 'start', 'from', 'dates']);
      var end = getStr(['endDate', 'end_date', 'end', 'to']);

      if (comp.isEmpty && role.isEmpty) {
        final fallbackStr = getStr(['name', 'title', 'text']);
        if (fallbackStr.isNotEmpty) role = fallbackStr;
      }

      return ExperienceEntry(
        company: comp,
        role: role,
        location: loc,
        startDate: start,
        endDate: end,
        description: parsedDesc,
      );
    }

    return const ExperienceEntry();
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'role': role,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'description': description,
      };

  ExperienceEntry copyWith({
    String? company,
    String? role,
    String? location,
    String? startDate,
    String? endDate,
    List<String>? description,
  }) {
    return ExperienceEntry(
      company: company ?? this.company,
      role: role ?? this.role,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
    );
  }
}

// ---------------------------------------------------------------------------
// Project
// ---------------------------------------------------------------------------
// Projects
// ---------------------------------------------------------------------------

class ProjectEntry {
  final String id;
  final String name;
  final String type;
  final List<String> descriptionBullets;
  final List<String> technologies;
  final String githubUrl;
  final String demoUrl;
  final String legacyUrl;
  final String source; // 'manual' | 'github'
  final String? githubOwner;
  final String? githubRepo;

  ProjectEntry({
    String? id,
    this.name = '',
    this.type = '',
    List<String>? descriptionBullets,
    String? description,
    this.technologies = const [],
    this.githubUrl = '',
    this.demoUrl = '',
    String url = '',
    this.source = 'manual',
    this.githubOwner,
    this.githubRepo,
  })  : id = (id != null && id.isNotEmpty)
            ? id
            : 'proj_${DateTime.now().microsecondsSinceEpoch}',
        descriptionBullets = descriptionBullets ??
            (description != null && description.isNotEmpty
                ? _splitBullets(description)
                : const []),
        legacyUrl = url;

  static List<String> _splitBullets(String text) {
    if (text.trim().isEmpty) return const [];
    return text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Backward-compatible description string (joined by newlines).
  String get description => descriptionBullets.join('\n');

  /// Getter for description list.
  List<String> get descriptionList => descriptionBullets;

  /// Effective list of bullets.
  List<String> get effectiveBullets => descriptionBullets.isNotEmpty
      ? descriptionBullets
      : (description.isNotEmpty ? _splitBullets(description) : const []);

  /// Unified url getter.
  String get url {
    if (githubUrl.isNotEmpty) return githubUrl;
    if (demoUrl.isNotEmpty) return demoUrl;
    return legacyUrl;
  }

  /// Effective GitHub URL.
  String get effectiveGithubUrl {
    if (githubUrl.isNotEmpty) return githubUrl;
    if (source == 'github' && legacyUrl.isNotEmpty) return legacyUrl;
    if (legacyUrl.contains('github.com')) return legacyUrl;
    return '';
  }

  /// Effective Demo URL.
  String get effectiveDemoUrl {
    if (demoUrl.isNotEmpty) return demoUrl;
    if (source != 'github' && legacyUrl.isNotEmpty && !legacyUrl.contains('github.com')) return legacyUrl;
    return '';
  }

  ProjectEntry copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? descriptionBullets,
    String? description,
    List<String>? technologies,
    String? githubUrl,
    String? demoUrl,
    String? url,
    String? source,
    String? githubOwner,
    String? githubRepo,
  }) {
    return ProjectEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      descriptionBullets: descriptionBullets ??
          (description != null
              ? _splitBullets(description)
              : this.descriptionBullets),
      technologies: technologies ?? this.technologies,
      githubUrl: githubUrl ?? this.githubUrl,
      demoUrl: demoUrl ?? this.demoUrl,
      url: url ?? legacyUrl,
      source: source ?? this.source,
      githubOwner: githubOwner ?? this.githubOwner,
      githubRepo: githubRepo ?? this.githubRepo,
    );
  }

  factory ProjectEntry.fromJson(dynamic json) {
    if (json == null) return ProjectEntry();

    if (json is String && json.trim().isNotEmpty) {
      final str = json.trim();
      final repoPrefixMatch = RegExp(r'^((?:https?://)?(?:www\.)?github\.com/)?([A-Za-z0-9_\-\.]+/[A-Za-z0-9_\-\.]+)\s+(.*)', caseSensitive: false).firstMatch(str);
      if (repoPrefixMatch != null) {
        final repoPath = repoPrefixMatch.group(2)!;
        final rest = repoPrefixMatch.group(3)!.trim();
        final repoName = repoPath.contains('/') ? repoPath.split('/')[1] : repoPath;
        final cleanTitle = repoName.replaceAll('-', ' ').replaceAll('_', ' ').trim();
        return ProjectEntry(
          name: cleanTitle,
          githubUrl: 'https://github.com/$repoPath',
          descriptionBullets: rest.isNotEmpty ? [rest] : [],
          description: rest,
        );
      }
      if (str.length > 90 || RegExp(r'[.!?]\s+[A-Z]').hasMatch(str)) {
        return ProjectEntry(
          name: 'Project',
          descriptionBullets: [str],
          description: str,
        );
      }
      return ProjectEntry(name: str);
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);

      String getName() {
        final val = ResumeData._getNormalized(map, ['name', 'projectName', 'project_name', 'title', 'projectTitle', 'project_title', 'project', 'heading']);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          final s = val.toString().trim();
          if (!ResumeData._isPlaceholderValue(s)) return s;
        }
        return '';
      }

      String getType() {
        final val = ResumeData._getNormalized(map, ['type', 'projectType', 'category', 'kind']);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
        return '';
      }

      List<String> getBullets() {
        final list = <String>[];
        final descVal = ResumeData._getNormalized(map, ['description', 'summary', 'overview']);
        if (descVal is String && descVal.trim().isNotEmpty && !ResumeData._isPlaceholderValue(descVal)) {
          list.addAll(_splitBullets(descVal));
        } else if (descVal is List) {
          list.addAll(ResumeData._parseStringList(descVal));
        }

        final bulletsVal = ResumeData._getNormalized(map, ['descriptionBullets', 'description_bullets', 'bullets', 'bulletPoints', 'bullet_points', 'highlights', 'details']);
        if (bulletsVal is List) {
          for (final b in bulletsVal) {
            final str = b.toString().replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim();
            if (str.isNotEmpty && !ResumeData._isPlaceholderValue(str) && !list.contains(str)) {
              list.add(str);
            }
          }
        }

        return list;
      }

      String getGhUrl() {
        final val = ResumeData._getNormalized(map, ['githubUrl', 'github_url', 'repoUrl', 'repo_url', 'github', 'link', 'url']);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
        return '';
      }

      String getDemoUrl() {
        final val = ResumeData._getNormalized(map, ['demoUrl', 'demo_url', 'liveUrl', 'live_url', 'website']);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
        return '';
      }

      String getLegacyUrl() {
        final val = ResumeData._getNormalized(map, ['url', 'link', 'projectUrl']);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
        return '';
      }

      List<String> getTech() {
        final techVal = ResumeData._getNormalized(map, ['technologies', 'techStack', 'tech_stack', 'tools', 'skills']);
        return ResumeData._parseStringList(techVal);
      }

      var projName = getName();
      var ghUrl = getGhUrl();
      var legacyUrl = getLegacyUrl();
      var bullets = getBullets();

      if (projName.contains('|')) {
        final parts = projName.split('|').map((s) => s.trim()).toList();
        projName = parts[0];
        final subtitle = parts.length > 1 ? parts[1] : '';
        if (ghUrl.isEmpty && legacyUrl.isEmpty && parts.length > 2) {
          final p2 = parts[2];
          if (p2.contains('github.com') || p2.contains('/')) {
            ghUrl = p2.startsWith('http') ? p2 : (p2.contains('github.com') ? 'https://$p2' : 'https://github.com/$p2');
          }
        }
        if (subtitle.isNotEmpty && !bullets.contains(subtitle)) {
          bullets = [subtitle, ...bullets];
        }
      }

      final repoPrefixMatch = RegExp(r'^((?:https?://)?(?:www\.)?github\.com/)?([A-Za-z0-9_\-\.]+/[A-Za-z0-9_\-\.]+)\s+(.*)', caseSensitive: false).firstMatch(projName);

      if (repoPrefixMatch != null) {
        final repoPath = repoPrefixMatch.group(2)!;
        final restText = repoPrefixMatch.group(3)!.trim();
        if (ghUrl.isEmpty && legacyUrl.isEmpty) {
          ghUrl = 'https://github.com/$repoPath';
        }
        final repoName = repoPath.contains('/') ? repoPath.split('/')[1] : repoPath;
        projName = repoName.replaceAll('-', ' ').replaceAll('_', ' ').trim();

        if (restText.isNotEmpty && !bullets.contains(restText)) {
          bullets = [restText, ...bullets];
        }
      } else if (projName.length > 90 || RegExp(r'[.!?]\s+[A-Z]').hasMatch(projName)) {
        final sentenceMatch = RegExp(r'^(.*?)[.!?]\s+(.*)', dotAll: true).firstMatch(projName);
        if (sentenceMatch != null && sentenceMatch.group(1)!.trim().length < 50) {
          final shortTitle = sentenceMatch.group(1)!.trim();
          final restText = sentenceMatch.group(2)!.trim();
          projName = shortTitle;
          if (restText.isNotEmpty && !bullets.contains(restText)) {
            bullets = [restText, ...bullets];
          }
        } else {
          if (!bullets.contains(projName)) {
            bullets = [projName, ...bullets];
          }
          projName = 'Project';
        }
      }

      if (projName.isEmpty) {
        String derivedName = '';
        for (final b in bullets) {
          if (b.length < 50 && !RegExp(r'^(engineered|architected|developed|built|implemented)\b', caseSensitive: false).hasMatch(b)) {
            derivedName = b;
            break;
          }
        }
        projName = derivedName.isNotEmpty ? derivedName : 'Project';
      }

      return ProjectEntry(
        id: map['id']?.toString() ?? '',
        name: projName,
        type: getType(),
        technologies: getTech(),
        githubUrl: ghUrl,
        demoUrl: getDemoUrl(),
        url: legacyUrl,
        descriptionBullets: bullets,
        description: bullets.join(' '),
      );
    }

    return ProjectEntry();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'descriptionBullets': descriptionBullets,
        'description': description,
        'technologies': technologies,
        'githubUrl': githubUrl,
        'demoUrl': demoUrl,
        'url': url,
        'source': source,
        'githubOwner': githubOwner,
        'githubRepo': githubRepo,
      };
}

// ---------------------------------------------------------------------------
// Education
// ---------------------------------------------------------------------------

class EducationEntry {
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final String startDate;
  final String endDate;
  final String gpa;

  const EducationEntry({
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.startDate = '',
    this.endDate = '',
    this.gpa = '',
  });

  factory EducationEntry.fromJson(dynamic json) {
    if (json == null) return const EducationEntry();

    if (json is String && json.trim().isNotEmpty) {
      final str = json.trim();
      final isDegree = RegExp(r'\b(bachelor|master|b\.tech|m\.tech|b\.sc|m\.sc|b\.e|m\.e|phd|diploma|degree|bca|mca|b\.a|b\.com|bs|ms|be|me|btech|mtech|bba|mba)\b', caseSensitive: false).hasMatch(str);
      return EducationEntry(
        degree: isDegree ? str : '',
        institution: isDegree ? '' : str,
      );
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      String getStr(List<String> keys) {
        final val = ResumeData._getNormalized(map, keys);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          final s = val.toString().trim();
          if (!ResumeData._isPlaceholderValue(s)) return s;
        }
        return '';
      }

      var deg = getStr(['degree', 'degreeName', 'degree_name', 'qualification', 'title', 'program', 'course', 'name', 'details']);
      var inst = getStr(['institution', 'institutionName', 'institution_name', 'university', 'school', 'college', 'academy', 'institute', 'organization', 'place']);
      var field = getStr(['fieldOfStudy', 'field_of_study', 'major', 'stream', 'branch', 'specialization', 'field']);
      var start = getStr(['startDate', 'start_date', 'start', 'year', 'dates', 'from']);
      var end = getStr(['endDate', 'end_date', 'end', 'graduationYear', 'graduation_year', 'to']);
      var gpaVal = getStr(['gpa', 'grade', 'score', 'percentage', 'cgpa']);

      if (deg.isEmpty && inst.isEmpty) {
        final fallbackStr = getStr(['text', 'description', 'heading', 'summary']);
        if (fallbackStr.isNotEmpty) {
          deg = fallbackStr;
        }
      }

      return EducationEntry(
        institution: inst,
        degree: deg,
        fieldOfStudy: field,
        startDate: start,
        endDate: end,
        gpa: gpaVal,
      );
    }

    return const EducationEntry();
  }

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'startDate': startDate,
        'endDate': endDate,
        'gpa': gpa,
      };
}

// ---------------------------------------------------------------------------
// Extracurricular
// ---------------------------------------------------------------------------

class ExtracurricularEntry {
  final String activity;
  final String role;
  final String organization;
  final String description;

  const ExtracurricularEntry({
    this.activity = '',
    this.role = '',
    this.organization = '',
    this.description = '',
  });

  factory ExtracurricularEntry.fromJson(dynamic json) {
    if (json is String) {
      final s = json.trim();
      if (s.contains('|')) {
        final parts = s.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty && !ResumeData._isPlaceholderValue(p)).toList();
        if (parts.isNotEmpty) {
          return ExtracurricularEntry(
            activity: parts[0],
            organization: parts.length > 1 ? parts[1] : '',
            description: parts.length > 2 ? parts.sublist(2).join(' • ') : '',
          );
        }
      }
      if (s.contains(' – ') || s.contains(' — ') || s.contains(' - ')) {
        final sep = s.contains(' – ') ? ' – ' : (s.contains(' — ') ? ' — ' : ' - ');
        final parts = s.split(sep).map((p) => p.trim()).where((p) => p.isNotEmpty && !ResumeData._isPlaceholderValue(p)).toList();
        if (parts.length >= 2) {
          return ExtracurricularEntry(
            activity: parts[0],
            organization: parts[1],
            description: parts.length > 2 ? parts.sublist(2).join(' • ') : '',
          );
        }
      }
      return ExtracurricularEntry(activity: s);
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      String getStr(List<String> keys) {
        final val = ResumeData._getNormalized(map, keys);
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          final s = val.toString().trim();
          if (!ResumeData._isPlaceholderValue(s)) return s;
        }
        return '';
      }

      return ExtracurricularEntry(
        activity: getStr(['activity', 'title', 'name', 'certificateName', 'certificationName', 'certification', 'certificate', 'certName', 'award', 'course', 'courseName', 'license', 'licenseName']),
        role: getStr(['role', 'position', 'grade', 'level', 'type']),
        organization: getStr(['organization', 'issuingOrganization', 'issuer', 'authority', 'company', 'institution', 'vendor', 'issuedBy', 'provider', 'school']),
        description: getStr(['description', 'details', 'summary', 'date', 'year', 'issueDate', 'issuedDate', 'dates', 'credentialId', 'credential_id', 'link', 'url']),
      );
    }
    return const ExtracurricularEntry();
  }

  ExtracurricularEntry copyWith({
    String? activity,
    String? role,
    String? organization,
    String? description,
  }) {
    return ExtracurricularEntry(
      activity: activity ?? this.activity,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'activity': activity,
        'role': role,
        'organization': organization,
        'description': description,
      };
}

// ---------------------------------------------------------------------------
// Tailor Result
// ---------------------------------------------------------------------------

class TailoredResult {
  final String summary;
  final List<String> skills;
  final List<String> suggestedKeywords;
  final double matchScore;
  final double atsScore;
  final List<ExperienceEntry> experience;

  const TailoredResult({
    this.summary = '',
    this.skills = const [],
    this.suggestedKeywords = const [],
    this.matchScore = 0.0,
    this.atsScore = 0.0,
    this.experience = const [],
  });

  factory TailoredResult.fromJson(Map<String, dynamic> json) {
    return TailoredResult(
      summary: json['summary'] as String? ?? '',
      skills: ResumeData._parseStringList(json['skills']),
      suggestedKeywords:
          ResumeData._parseStringList(json['suggestedKeywords']),
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      atsScore: (json['atsScore'] as num?)?.toDouble() ?? 0.0,
      experience: ResumeData._parseList(
          json['experience'], ExperienceEntry.fromJson),
    );
  }
}

// ---------------------------------------------------------------------------
// ATS Analysis Result
// ---------------------------------------------------------------------------

class AtsResult {
  final int overallScore;
  final int keywordScore;
  final int formatScore;
  final int contentScore;
  final List<String> recommendations;

  const AtsResult({
    this.overallScore = 0,
    this.keywordScore = 0,
    this.formatScore = 0,
    this.contentScore = 0,
    this.recommendations = const [],
  });

  factory AtsResult.fromJson(Map<String, dynamic> json) {
    return AtsResult(
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      keywordScore: (json['keywordScore'] as num?)?.toInt() ?? 0,
      formatScore: (json['formatScore'] as num?)?.toInt() ?? 0,
      contentScore: (json['contentScore'] as num?)?.toInt() ?? 0,
      recommendations:
          ResumeData._parseStringList(json['recommendations']),
    );
  }
}

// ---------------------------------------------------------------------------
// Job Keywords & ATS Match Analysis Result
// ---------------------------------------------------------------------------

class JobKeywordsAnalysisResult {
  final double atsScore;
  final double matchScore;
  final String summary;
  final Map<String, int> categoryScores;
  final List<String> extractedJobKeywords;
  final List<String> matchedKeywords;
  final List<String> partiallyMatchedKeywords;
  final List<String> missingKeywords;
  final List<String> strengths;
  final List<String> gaps;

  const JobKeywordsAnalysisResult({
    this.atsScore = 0.0,
    this.matchScore = 0.0,
    this.summary = '',
    this.categoryScores = const {
      'keywordSkillMatch': 0,
      'experienceMatch': 0,
      'projectMatch': 0,
      'responsibilityMatch': 0,
      'educationMatch': 0,
      'overallRelevance': 0,
    },
    this.extractedJobKeywords = const [],
    this.matchedKeywords = const [],
    this.partiallyMatchedKeywords = const [],
    this.missingKeywords = const [],
    this.strengths = const [],
    this.gaps = const [],
  });

  factory JobKeywordsAnalysisResult.fromJson(Map<String, dynamic> json) {
    final catScoresMap = json['categoryScores'] is Map
        ? Map<String, dynamic>.from(json['categoryScores'] as Map)
        : <String, dynamic>{};

    final keywordSkill = ((catScoresMap['keywordSkillMatch'] as num?)?.toInt() ?? 0).clamp(0, 30);
    final experience = ((catScoresMap['experienceMatch'] as num?)?.toInt() ?? 0).clamp(0, 20);
    final project = ((catScoresMap['projectMatch'] as num?)?.toInt() ?? 0).clamp(0, 15);
    final responsibility = ((catScoresMap['responsibilityMatch'] as num?)?.toInt() ?? 0).clamp(0, 15);
    final education = ((catScoresMap['educationMatch'] as num?)?.toInt() ?? 0).clamp(0, 10);
    final relevance = ((catScoresMap['overallRelevance'] as num?)?.toInt() ?? 0).clamp(0, 10);

    final calculatedSum = keywordSkill + experience + project + responsibility + education + relevance;

    final rawScore = (json['atsScore'] as num?)?.toDouble();
    final validatedAtsScore = rawScore != null
        ? rawScore.clamp(0.0, 100.0)
        : calculatedSum.toDouble().clamp(0.0, 100.0);

    final finalAtsScore = calculatedSum > 0 ? (validatedAtsScore > 0 ? validatedAtsScore : calculatedSum.toDouble()) : 0.0;

    final matched = ResumeData._parseStringList(json['matchedKeywords']);
    final partial = ResumeData._parseStringList(json['partiallyMatchedKeywords']);
    final missing = ResumeData._parseStringList(json['missingKeywords']);

    final allExtracted = <String>[...matched, ...partial, ...missing];

    return JobKeywordsAnalysisResult(
      atsScore: finalAtsScore,
      matchScore: finalAtsScore,
      summary: json['summary'] as String? ?? '',
      categoryScores: {
        'keywordSkillMatch': keywordSkill,
        'experienceMatch': experience,
        'projectMatch': project,
        'responsibilityMatch': responsibility,
        'educationMatch': education,
        'overallRelevance': relevance,
      },
      extractedJobKeywords: allExtracted,
      matchedKeywords: matched,
      partiallyMatchedKeywords: partial,
      missingKeywords: missing,
      strengths: ResumeData._parseStringList(json['strengths']),
      gaps: ResumeData._parseStringList(json['gaps']),
    );
  }

  Map<String, dynamic> toJson() => {
        'atsScore': atsScore,
        'matchScore': matchScore,
        'summary': summary,
        'categoryScores': categoryScores,
        'extractedJobKeywords': extractedJobKeywords,
        'matchedKeywords': matchedKeywords,
        'partiallyMatchedKeywords': partiallyMatchedKeywords,
        'missingKeywords': missingKeywords,
        'strengths': strengths,
        'gaps': gaps,
      };
}

// ---------------------------------------------------------------------------
// Skill Group Entry
// ---------------------------------------------------------------------------

class SkillGroupEntry {
  final String category;
  final List<String> items;

  const SkillGroupEntry({
    this.category = '',
    this.items = const [],
  });

  factory SkillGroupEntry.fromJson(dynamic json) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final cat = map['category'] as String? ?? map['name'] as String? ?? map['group'] as String? ?? 'General';
      final rawItems = map['items'] ?? map['skills'] ?? map['list'] ?? [];
      final list = ResumeData._parseStringList(rawItems);
      return SkillGroupEntry(category: cat, items: list);
    }
    return const SkillGroupEntry();
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'items': items,
      };
}
