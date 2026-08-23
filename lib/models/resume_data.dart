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
    if (extractedTextLength != null) debugPrint('1. Extracted text length: $extractedTextLength');
    if (extractedTextSnippet != null && extractedTextSnippet.isNotEmpty) {
      final firstPart = extractedTextSnippet.length > 150 ? extractedTextSnippet.substring(0, 150) : extractedTextSnippet;
      final lastPart = extractedTextSnippet.length > 150 ? extractedTextSnippet.substring(extractedTextSnippet.length - 150) : '';
      debugPrint('2. Extracted text portions: FIRST="$firstPart" | LAST="$lastPart"');
    }
    if (aiResponseLength != null) debugPrint('3. AI parser response length: $aiResponseLength');
    if (rawJsonString != null && rawJsonString.isNotEmpty) {
      final snippet = rawJsonString.length > 300 ? '${rawJsonString.substring(0, 300)}...' : rawJsonString;
      debugPrint('4. Parsed JSON: $snippet');
    }
    debugPrint('5. ResumeModel values:');
    debugPrint('   6. Identity/Profile -> Name: "${fullName.isEmpty ? "Not specified" : fullName}", Title: "${title.isEmpty ? "Not specified" : title}", Email: "${email.isEmpty ? "Not specified" : email}", Phone: "${phone.isEmpty ? "Not specified" : phone}", Location: "${location.isEmpty ? "Not specified" : location}", LinkedIn: "${linkedin.isEmpty ? "Not specified" : linkedin}", GitHub: "${github.isEmpty ? "Not specified" : github}"');
    debugPrint('   7. Skills (${skills.length}): ${skills.take(5).toList()}');
    debugPrint('   8. Education (${education.length}): ${education.map((e) => e.institution).toList()}');
    debugPrint('   9. Experience (${experience.length}): ${experience.map((e) => "${e.company} (${e.role})").toList()}');
    debugPrint('   10. Projects (${projects.length}): ${projects.map((e) => e.name).toList()}');
    debugPrint('   11. Certifications (${certifications.length}): ${certifications.map((e) => e.activity).toList()}');
    debugPrint('   12. Summary: "${summary.isEmpty ? "Not specified" : summary}"');
    debugPrint('=================================================================\n');
  }

  /// Identifies placeholder strings like "Not specified", "N/A", "None", etc.
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
    final explicitPlusPhone = RegExp(r'\+\d{1,4}[\s\-\.]?\d{7,12}\b').firstMatch(textForPhone);
    if (explicitPlusPhone != null) {
      phone = explicitPlusPhone.group(0)!.trim();
    } else {
      final phoneMatches = RegExp(r'\b(?:\+?\d{1,3}[\s\-\.]?)?\(?\d{3}\)?[\s\-\.]?\d{3}[\s\-\.]?\d{4}\b').allMatches(textForPhone);
      for (final pm in phoneMatches) {
        final candidate = pm.group(0)!.trim();
        final digitCount = candidate.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount >= 10 && digitCount <= 15) {
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
      skills: flatSkills.toSet().toList(),
      skillGroups: skillGroups,
      experience: experience,
      education: education,
      projects: projects,
      certifications: certifications,
      extracurriculars: extracurriculars,
    );

    debugPrint('\n====================================================');
    debugPrint('FINAL EXTRACTION');
    debugPrint('====================================================');
    debugPrint('Name: ${parsedData.fullName}');
    debugPrint('Email: ${parsedData.email}');
    debugPrint('Phone: ${parsedData.phone}');
    debugPrint('Projects: ${parsedData.projects.length}');
    debugPrint('Education: ${parsedData.education.length}');
    debugPrint('Experience: ${parsedData.experience.length}');
    debugPrint('Skill Groups: ${parsedData.skillGroups.length}\n');

    return validateAndSanitizeAll(parsedData);
  }

  // ---------------------------------------------------------------------------
  // Hierarchical Block & Entity Extractors
  // ---------------------------------------------------------------------------

  static String _normalizeSectionBreaks(String rawText) {
    if (rawText.trim().isEmpty) return rawText;

    var text = rawText;

    final headings = [
      r'PROFESSIONAL SUMMARY',
      r'EXECUTIVE SUMMARY',
      r'PROFILE SUMMARY',
      r'CAREER OBJECTIVE',
      r'ABOUT ME',
      r'SUMMARY',
      r'OBJECTIVE',
      r'TECHNICAL SKILLS',
      r'SKILLS & TOOLS',
      r'SKILLS & TECHNOLOGIES',
      r'PROGRAMMING LANGUAGES',
      r'CORE COMPETENCIES',
      r'KEY SKILLS',
      r'SKILLS',
      r'WORK EXPERIENCE',
      r'PROFESSIONAL EXPERIENCE',
      r'EMPLOYMENT HISTORY',
      r'RELEVANT EXPERIENCE',
      r'INTERNSHIP EXPERIENCE',
      r'INTERNSHIPS',
      r'EXPERIENCE',
      r'KEY PROJECTS',
      r'PERSONAL PROJECTS',
      r'TECHNICAL PROJECTS',
      r'ACADEMIC PROJECTS',
      r'SELECTED PROJECTS',
      r'PROJECTS',
      r'EDUCATIONAL BACKGROUND',
      r'ACADEMIC BACKGROUND',
      r'ACADEMIC HISTORY',
      r'EDUCATION & QUALIFICATIONS',
      r'EDUCATION',
      r'ACADEMICS',
      r'QUALIFICATIONS',
      r'CERTIFICATIONS & LICENSES',
      r'LICENSES & CERTIFICATIONS',
      r'CERTIFICATIONS',
      r'CERTIFICATES',
      r'AWARDS & ACHIEVEMENTS',
      r'HONORS & AWARDS',
      r'ACHIEVEMENTS',
      r'EXTRACURRICULAR ACTIVITIES',
      r'CO-CURRICULAR ACTIVITIES',
      r'VOLUNTEER EXPERIENCE',
      r'EXTRACURRICULARS',
      r'VOLUNTEERING',
      r'ACTIVITIES',
    ];

    for (final heading in headings) {
      final pattern = RegExp(
        r'(?<!\b(?:soft|backend|frontend|testing|mobile|database|cloud|with|in|and|of|for|has|have|had|years|practical|hands-on|industry)\s+)(?:^|[\r\n|•\-\*]|[ ]{2,}|\b(?=[A-Z]{4,}\b))(' + heading + r')\b(?!\s*:)',
        caseSensitive: false,
      );

      text = text.replaceAllMapped(pattern, (m) {
        final matchedHeading = m.group(1)!.trim();
        return '\n\n$matchedHeading\n';
      });
    }

    final skillCategories = [
      r'Backend Tools',
      r'Testing API',
      r'Languages',
      r'Soft Skills',
      r'Frontend Tools',
      r'Databases',
      r'Frameworks',
      r'DevOps & Cloud',
      r'Cloud & DevOps',
    ];

    for (final cat in skillCategories) {
      final catPattern = RegExp(
        r'(?:^|[\r\n\t|•\-\*]|[ ]{2,})\s*(' + cat + r'\s*:)',
        caseSensitive: false,
      );
      text = text.replaceAllMapped(catPattern, (m) {
        return '\n${m.group(1)!.trim()} ';
      });
    }

    return text;
  }

  static bool _isSectionHeaderLine(String line, String sectionKey) {
    if (line.contains(':') || line.contains('|')) return false;
    if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–')) return false;
    if (line.contains('@') || line.contains('http') || line.contains('.com') || line.contains('.in') || line.contains('.org')) return false;
    if (RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{4}\b', caseSensitive: false).hasMatch(line)) return false;
    if (RegExp(r'\b\d{4}\s*[\–\-—\to]\s*(\d{4}|Present)\b', caseSensitive: false).hasMatch(line)) return false;

    final clean = line.toLowerCase().replaceAll(RegExp(r'[^a-z\s&]'), '').trim();
    if (clean.isEmpty || clean.split(RegExp(r'\s+')).length > 5 || clean.length > 35) return false;

    switch (sectionKey) {
      case 'summary':
        return RegExp(r'^(summary|professional summary|executive summary|profile summary|profile|about me|about|objective|career objective|personal summary|bio)$').hasMatch(clean);
      case 'skills':
        return RegExp(r'^(skills|technical skills|key skills|core skills|skills & tools|skills and tools|skills & technologies|skills and technologies|technologies|technical proficiencies|core competencies|competencies|areas of expertise|expertise|technical expertise|programming languages|languages & tools)$').hasMatch(clean);
      case 'experience':
        return RegExp(r'^(experience|work experience|professional experience|employment|employment history|work history|career history|relevant experience|internships|internship experience)$').hasMatch(clean);
      case 'education':
        return RegExp(r'^(education|educational background|academic background|academics|academic history|academic qualification|qualifications|educational qualifications|degrees|schooling|education & qualifications)$').hasMatch(clean);
      case 'projects':
        return RegExp(r'^(projects|key projects|personal projects|academic projects|technical projects|selected projects|project work|projects & repositories|repositories|github projects|open source projects)$').hasMatch(clean);
      case 'certifications':
        return RegExp(r'^(certifications|certificates|certifications & licenses|licenses & certifications|credentials|courses & certifications|awards & achievements|achievements|honors & awards)$').hasMatch(clean);
      case 'extracurriculars':
        return RegExp(r'^(extracurricular activities|extracurriculars|co-curricular activities|volunteer experience|volunteering|activities|leadership & activities|leadership activities|involvement)$').hasMatch(clean);
      default:
        return false;
    }
  }

  static String? _detectSectionHeader(String line) {
    for (final sec in ['skills', 'experience', 'education', 'projects', 'certifications', 'extracurriculars', 'summary']) {
      if (_isSectionHeaderLine(line, sec)) {
        return sec;
      }
    }
    return null;
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

    final rawLines = rawText.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    String currentSection = 'header';

    for (final line in rawLines) {
      final detected = _detectSectionHeader(line);
      if (detected != null) {
        currentSection = detected;
        continue;
      }
      blocks[currentSection]?.add(line);
    }

    debugPrint('================ SECTION DEBUG ================');
    for (final entry in blocks.entries) {
      debugPrint('\n[SECTION: ${entry.key}] (${entry.value.length} lines)');
      debugPrint(entry.value.join('\n'));
    }
    debugPrint('================================================');

    debugPrint('[PROJECT BLOCK LENGTH] ${blocks['projects']?.length ?? 0}');
    debugPrint('[PROJECT BLOCK]');
    debugPrint(blocks['projects']?.isNotEmpty == true ? blocks['projects']!.join('\n') : '[EMPTY]');

    debugPrint('[EDUCATION BLOCK LENGTH] ${blocks['education']?.length ?? 0}');
    debugPrint('[EXPERIENCE BLOCK LENGTH] ${blocks['experience']?.length ?? 0}');
    debugPrint('[SKILLS BLOCK LENGTH] ${blocks['skills']?.length ?? 0}');

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

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty) continue;

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

  static _ProjectHeaderInfo? _tryParseProjectHeader(String line) {
    final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
    if (cleanLine.isEmpty) return null;

    if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line)) {
      return null;
    }
    if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if (RegExp(r'^[a-z]').hasMatch(cleanLine) || RegExp(r'^(and|for|with|in|to|of|from|by|into|during|via|under|about|the|an|a)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if ((cleanLine.endsWith('.') || cleanLine.endsWith(';')) && !cleanLine.contains('|')) {
      return null;
    }
    if (cleanLine.length > 75 && !cleanLine.contains('|')) {
      return null;
    }

    if (line.contains('|')) {
      final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final name = parts[0];
        if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed)\b', caseSensitive: false).hasMatch(name)) {
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

    if (line.contains(' – ') || line.contains(' — ') || line.contains(' - ')) {
      final sep = line.contains(' – ') ? ' – ' : (line.contains(' — ') ? ' — ' : ' - ');
      final parts = line.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final name = parts[0];
        if (!RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed)\b', caseSensitive: false).hasMatch(name) && name.length < 50) {
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

    if (cleanLine.length <= 40 && !cleanLine.contains(',') && RegExp(r'^[A-Z0-9]').hasMatch(cleanLine)) {
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
        if (!currentDescriptions.contains(b)) {
          currentDescriptions.add(b);
        }
        currentBullet = '';
      }
    }

    void flushCurrentProject() {
      if (currentName != null && currentName!.trim().isNotEmpty) {
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
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty) continue;

      final header = _tryParseProjectHeader(line);
      if (header != null) {
        flushCurrentProject();
        currentName = header.name;
        currentSubtitle = header.subtitle;
        currentRepo = header.repoUrl;
        continue;
      }

      if (currentName == null) {
        if (cleanLine.length < 40 && !cleanLine.endsWith('.') && RegExp(r'^[A-Z]').hasMatch(cleanLine)) {
          currentName = cleanLine;
        }
        continue;
      }

      if (currentRepo.isEmpty && (cleanLine.contains('github.com/') || (cleanLine.contains('/') && !cleanLine.contains(' ') && cleanLine.length < 50))) {
        currentRepo = cleanLine.startsWith('http') ? cleanLine : (cleanLine.contains('github.com') ? 'https://$cleanLine' : 'https://github.com/$cleanLine');
        continue;
      }

      final isNewBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line);
      final isActionVerbStart = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed)\b', caseSensitive: false).hasMatch(cleanLine);

      if (isNewBullet || (isActionVerbStart && currentBullet.isNotEmpty)) {
        flushCurrentBullet();
        currentBullet = cleanLine;
      } else {
        if (currentBullet.isNotEmpty) {
          if (currentBullet.endsWith('-')) {
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
    final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
    if (cleanLine.isEmpty) return null;

    if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line)) {
      return null;
    }
    if (RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if (RegExp(r'^[a-z]').hasMatch(cleanLine) || RegExp(r'^(and|for|with|in|to|of|from|by|into|during|via|under|about)\b', caseSensitive: false).hasMatch(cleanLine)) {
      return null;
    }
    if ((cleanLine.endsWith('.') || cleanLine.endsWith(';')) && !cleanLine.contains('|')) {
      return null;
    }

    if (line.contains('|')) {
      final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        String role = parts[0];
        String company = parts.length > 1 ? parts[1] : '';
        String location = '';
        String startDate = '';
        String endDate = '';

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
        return _ExperienceHeaderInfo(role: role, company: company, location: location, startDate: startDate, endDate: endDate);
      }
    }

    final isDateRange = RegExp(r'^\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)?\s*$', caseSensitive: false).hasMatch(cleanLine);
    if (isDateRange) {
      return null;
    }

    if (line.contains(' – ') || line.contains(' — ') || line.contains(' - ')) {
      final sep = line.contains(' – ') ? ' – ' : (line.contains(' — ') ? ' — ' : ' - ');
      final parts = line.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final isDate0 = RegExp(r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}\b', caseSensitive: false).hasMatch(parts[0]);
      final isDate1 = parts.length > 1 && RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)\b', caseSensitive: false).hasMatch(parts[1]);
      if (isDate0 && isDate1) {
        return null;
      }
      if (parts.length >= 2 && parts[0].length < 50 && !isDate0) {
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
        if (!currentDescriptions.contains(b)) {
          currentDescriptions.add(b);
        }
        currentBullet = '';
      }
    }

    void flushCurrentExperience() {
      if ((currentRole != null && currentRole!.trim().isNotEmpty) || currentCompany.trim().isNotEmpty) {
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

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty) continue;

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
        if (cleanLine.length < 50 && !cleanLine.endsWith('.') && RegExp(r'^[A-Z]').hasMatch(cleanLine)) {
          currentRole = cleanLine;
        }
        continue;
      }

      final dateMatch = RegExp(r'^\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)?\s*$', caseSensitive: false).firstMatch(cleanLine);
      if (dateMatch != null && currentStart.isEmpty) {
        currentStart = dateMatch.group(1) ?? '';
        currentEnd = dateMatch.group(2) ?? '';
        continue;
      }

      final isNewBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || line.startsWith('—') || RegExp(r'^\d+[\.\)]').hasMatch(line);
      final isActionVerbStart = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed)\b', caseSensitive: false).hasMatch(cleanLine);

      if (isNewBullet || (isActionVerbStart && currentBullet.isNotEmpty)) {
        flushCurrentBullet();
        currentBullet = cleanLine;
      } else {
        if (currentBullet.isNotEmpty) {
          if (currentBullet.endsWith('-')) {
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

    void flushCurrentEducation() {
      if ((currentDegree != null && currentDegree!.trim().isNotEmpty) || currentInst.trim().isNotEmpty) {
        education.add(EducationEntry(
          degree: currentDegree ?? '',
          institution: currentInst.trim(),
          startDate: currentStart.trim(),
          endDate: currentEnd.trim(),
          gpa: currentGpa.trim(),
        ));
      }
      currentDegree = null;
      currentInst = '';
      currentStart = '';
      currentEnd = '';
      currentGpa = '';
    }

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty) continue;

      final isDegreeLine = RegExp(r'\b(b\.tech|m\.tech|b\.sc|m\.sc|b\.e|m\.e|b\.com|m\.com|bba|mba|bca|mca|b\.des|m\.des|phd|diploma|bachelor|master|class\s*(?:xii|x|xi|ix|12|10|11|9)\b|12th|10th|cbse|icse|intermediate|matriculation|ssc|hsc)\b', caseSensitive: false).hasMatch(cleanLine);

      if (line.contains('|')) {
        final parts = line.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (isDegreeLine && currentDegree != null) {
          flushCurrentEducation();
        }
        for (final p in parts) {
          final isDeg = RegExp(r'\b(b\.tech|m\.tech|class\s*(?:xii|x|xi|ix|12|10)\b|bachelor|master|bca|mca|b\.sc|m\.sc|b\.e|m\.e|phd|diploma|cbse|icse|degree)\b', caseSensitive: false).hasMatch(p);
          final isInst = RegExp(r'\b(university|college|school|institute|academy)\b', caseSensitive: false).hasMatch(p);
          final dateMatch = RegExp(r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4})\s*[\–\-—\to]*\s*((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)?\s*\d{4}|Present)?\b', caseSensitive: false).firstMatch(p);
          final gpaMatch = RegExp(r'\b(?:gpa:?\s*|grade:?\s*)?(\d+(?:\.\d+)?|\d+\%)\b', caseSensitive: false).firstMatch(p);

          if (isDeg && (currentDegree == null || currentDegree!.isEmpty)) {
            currentDegree = p;
          } else if (isInst && currentInst.isEmpty) {
            currentInst = p;
          } else if (dateMatch != null && currentStart.isEmpty) {
            currentStart = dateMatch.group(1) ?? '';
            currentEnd = dateMatch.group(2) ?? '';
          } else if (gpaMatch != null && currentGpa.isEmpty && (p.toLowerCase().contains('gpa') || p.toLowerCase().contains('grade') || p.contains('%'))) {
            currentGpa = p.replaceAll(RegExp(r'^(gpa|grade):?\s*', caseSensitive: false), '').trim();
          }
        }
        continue;
      }

      if (isDegreeLine && currentDegree != null && (currentInst.isNotEmpty || currentStart.isNotEmpty || currentGpa.isNotEmpty)) {
        flushCurrentEducation();
      }

      final isGpa = cleanLine.toLowerCase().contains('gpa') || cleanLine.toLowerCase().contains('grade') || cleanLine.contains('%') || RegExp(r'^\d+(\.\d+)?$').hasMatch(cleanLine);
      if (isGpa && currentGpa.isEmpty) {
        currentGpa = cleanLine.replaceAll(RegExp(r'^(gpa|grade):?\s*', caseSensitive: false), '').trim();
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

      if (currentDegree == null || currentDegree!.isEmpty) {
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
    String currentActivity = '';

    void flushActivity() {
      if (currentActivity.trim().isNotEmpty) {
        list.add(ExtracurricularEntry(activity: currentActivity.trim()));
        currentActivity = '';
      }
    }

    for (final line in lines) {
      final cleanLine = line.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();
      if (cleanLine.isEmpty) continue;

      final isNewBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || line.startsWith('–') || RegExp(r'^\d+[\.\)]').hasMatch(line);
      if (isNewBullet && currentActivity.isNotEmpty) {
        flushActivity();
        currentActivity = cleanLine;
      } else {
        if (currentActivity.isNotEmpty) {
          currentActivity = '$currentActivity $cleanLine';
        } else {
          currentActivity = cleanLine;
        }
      }
    }

    flushActivity();
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

    final validExp = parsedExp.where(validateExperience).toList();
    final sanitizedProj = validateAndSanitizeProjects(parsedProj);
    final validProj = sanitizedProj.where(validateProject).toList();
    final validEdu = parsedEdu.where(validateEducation).toList();
    final validSkillGroups = parsedSkillGroups.where(validateSkillGroup).toList();
    final validSkills = parsedSkills.where((s) => s.trim().isNotEmpty && !_isPlaceholderValue(s)).toList();

    final rawData = ResumeData(
      fullName: extractedName.isNotEmpty ? extractedName : fallbackData.fullName,
      email: extractedEmail.isNotEmpty ? extractedEmail : fallbackData.email,
      phone: extractedPhone.isNotEmpty ? extractedPhone : fallbackData.phone,
      location: (parsedLocation.isEmpty || _isPlaceholderValue(parsedLocation)) ? fallbackData.location : parsedLocation,
      linkedin: extractedLinkedin.isNotEmpty ? extractedLinkedin : fallbackData.linkedin,
      github: extractedGithub.isNotEmpty ? extractedGithub : fallbackData.github,
      title: extractedTitle.isNotEmpty ? extractedTitle : fallbackData.title,
      summary: (parsedSummary.isEmpty || _isPlaceholderValue(parsedSummary)) ? fallbackData.summary : parsedSummary,
      skills: validSkills.isEmpty ? fallbackData.skills : validSkills,
      skillGroups: validSkillGroups.isEmpty ? fallbackData.skillGroups : validSkillGroups,
      experience: validExp.isEmpty ? fallbackData.experience : validExp,
      projects: validProj.isEmpty ? fallbackData.projects : validProj,
      education: validEdu.isEmpty ? fallbackData.education : validEdu,
      certifications: parsedCerts.isEmpty ? fallbackData.certifications : parsedCerts,
      extracurriculars: parsedExtras.isEmpty ? fallbackData.extracurriculars : parsedExtras,
    );

    final result = _sanitizeAndRepairSectionMapping(rawData, fallbackData: fallbackData);

    debugPrint('[PIPELINE STAGE 5: FRONTEND STATE]');
    debugPrint('Candidate: "${result.fullName}" (${result.email})');
    debugPrint('Total Projects: ${result.projects.length}');
    debugPrint('Total Education: ${result.education.length}');
    debugPrint('Total Experience: ${result.experience.length}');
    debugPrint('Total Skill Groups: ${result.skillGroups.length}');

    return result;
  }

  static ResumeData _sanitizeAndRepairSectionMapping(ResumeData raw, {ResumeData? fallbackData}) {
    bool suspiciousMappingDetected = false;

    // 1. Sanitize Skills (Technical / Professional skills ONLY)
    final cleanSkills = <String>[];
    final misclassifiedBullets = <String>[];

    for (final skill in raw.skills) {
      final s = skill.trim();
      if (s.isEmpty) continue;

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
    final cleanExp = <ExperienceEntry>[];
    final cleanEdu = List<EducationEntry>.from(raw.education);
    var cleanProj = validateAndSanitizeProjects(raw.projects);
    final cleanExtras = List<ExtracurricularEntry>.from(raw.extracurriculars);

    for (final exp in raw.experience) {
      final comp = exp.company.toLowerCase();
      final role = exp.role.toLowerCase();

      final isEdu = comp.contains('university') ||
          comp.contains('college') ||
          (comp.contains('school') && !comp.contains('3skill')) ||
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
        cleanExp.add(exp);
      }
    }

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
      RegExp(r'\b(gpa|class xii|class x|cbse|icse|engineered|architected|developed|experience|extra-curricular|extracurricular|institute|university|nitte|st\. karen)\b', caseSensitive: false).hasMatch(finalSummary)
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
      extracurriculars: cleanExtras,
    );

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

      if (name.toLowerCase() == 'project' || name.toLowerCase() == 'projects' || name.toLowerCase() == 'key projects' || name.toLowerCase() == 'personal projects') {
        return true;
      }
      if (RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|optimized|maintained|utilized|led|managed|focusing|reducing|demonstrating)\b', caseSensitive: false).hasMatch(name)) {
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
      final isSingleTech = RegExp(r'\b(flutter|gemini|prompt engineering|llm|react|supabase|riverpod|gstr-1|cgst|sgst|igst|python|docker|dart|c\+\+|api|tools|database|git)\b', caseSensitive: false).hasMatch(name);
      if (isSingleTech && p.githubUrl.isEmpty && p.type.isEmpty && p.descriptionBullets.isEmpty && p.description.isEmpty) {
        return true;
      }
      if (p.description.isEmpty && p.descriptionBullets.isEmpty && p.githubUrl.isEmpty && p.type.isEmpty) {
        return true;
      }

      return false;
    }

    for (final p in rawProjects) {
      if (isFragmentOrBullet(p)) {
        if (cleanProjects.isNotEmpty) {
          final last = cleanProjects.removeLast();
          final updatedBullets = List<String>.from(last.descriptionBullets);
          final textToAdd = p.description.isNotEmpty ? p.description : p.name;
          if (textToAdd.isNotEmpty && !updatedBullets.contains(textToAdd)) {
            updatedBullets.add(textToAdd);
          }
          for (final b in p.descriptionBullets) {
            if (b.isNotEmpty && !updatedBullets.contains(b)) {
              updatedBullets.add(b);
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

      name = name.replaceFirst(RegExp(r'^(?:[•\-\*–—>]|\d+[\.\)\-]\s*|\(\d+\)\s*)\s*'), '').trim();

      if (p.description.isNotEmpty && bullets.isEmpty) {
        bullets.add(p.description);
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
        descriptionBullets: bullets,
        description: bullets.join(' '),
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

  // ---------------------------------------------------------------------------
  // Entity Validation & Pipeline Audit Layer
  // ---------------------------------------------------------------------------

  static bool validateProject(ProjectEntry p) {
    final name = p.name.trim();
    if (name.isEmpty) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (empty)');
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
    final isSingleTech = RegExp(r'^(flutter|gemini|gemini api|prompt engineering|llm|llm responses|react|supabase|riverpod|gstr-1|cgst|sgst|igst|python|docker|dart|c\+\+|api|tools|database|git)$', caseSensitive: false).hasMatch(name);
    if (isSingleTech && p.githubUrl.isEmpty && p.type.isEmpty) {
      debugPrint('[PROJECT SANITIZER] REJECTED: "${p.name}" (standalone tech keyword)');
      return false;
    }
    debugPrint('[PROJECT SANITIZER] ACCEPTED: "${p.name}"');
    return true;
  }

  static bool validateEducation(EducationEntry e) {
    if (e.institution.trim().isEmpty && e.degree.trim().isEmpty) return false;
    if (_isPlaceholderValue(e.institution) && _isPlaceholderValue(e.degree)) return false;
    return true;
  }

  static bool validateExperience(ExperienceEntry e) {
    if (e.company.trim().isEmpty && e.role.trim().isEmpty) return false;
    if (_isPlaceholderValue(e.company) && _isPlaceholderValue(e.role)) return false;
    return true;
  }

  static bool validateSkillGroup(SkillGroupEntry g) {
    return g.category.trim().isNotEmpty && g.items.isNotEmpty;
  }

  static ResumeData validateAndSanitizeAll(ResumeData data) {
    final validProjects = validateAndSanitizeProjects(data.projects);

    final validEducation = data.education.where(validateEducation).toList();
    final validExperience = data.experience.where(validateExperience).toList();
    final validSkillGroups = data.skillGroups.where(validateSkillGroup).toList();

    debugPrint('[PIPELINE STAGE 4: NORMALIZED RECORDS]');
    debugPrint('   - Projects (${validProjects.length}): ${validProjects.map((p) => p.name).toList()}');
    debugPrint('   - Education (${validEducation.length}): ${validEducation.map((e) => e.degree.isNotEmpty ? e.degree : e.institution).toList()}');
    debugPrint('   - Experience (${validExperience.length}): ${validExperience.map((e) => "${e.company} (${e.role})").toList()}');
    debugPrint('   - Skill Groups (${validSkillGroups.length}): ${validSkillGroups.map((g) => g.category).toList()}');

    return data.copyWith(
      projects: validProjects,
      education: validEducation,
      experience: validExperience,
      skillGroups: validSkillGroups,
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
    ];

    void checkSourceMap(Map<String, dynamic> src) {
      final val = _getNormalized(src, possibleKeys);
      if (val != null) {
        if (val is List) {
          for (final item in val) {
            final entry = ExtracurricularEntry.fromJson(item);
            if (entry.activity.isNotEmpty || entry.role.isNotEmpty || entry.organization.isNotEmpty || entry.description.isNotEmpty) {
              results.add(entry);
            }
          }
        } else if (val is String && val.trim().isNotEmpty) {
          final lines = val.split(RegExp(r'[\n;]')).map((e) => e.trim()).where((s) => s.isNotEmpty);
          for (final line in lines) {
            results.add(ExtracurricularEntry(activity: line));
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
      'community',
      'certifications',
      'certificates',
      'certification',
      'certificate',
      'licenses',
      'courses',
      'credentials',
    ];

    void checkSourceMap(Map<String, dynamic> src) {
      for (final key in possibleKeys) {
        final val = _getNormalized(src, [key]);
        if (val != null) {
          if (val is List) {
            for (final item in val) {
              final entry = ExtracurricularEntry.fromJson(item);
              if (entry.activity.isNotEmpty || entry.role.isNotEmpty || entry.organization.isNotEmpty || entry.description.isNotEmpty) {
                if (!results.any((r) => r.activity == entry.activity && r.organization == entry.organization)) {
                  results.add(entry);
                }
              }
            }
          } else if (val is String && val.trim().isNotEmpty) {
            final lines = val.split(RegExp(r'[\n;]')).map((e) => e.trim()).where((s) => s.isNotEmpty);
            for (final line in lines) {
              if (!results.any((r) => r.activity == line)) {
                results.add(ExtracurricularEntry(activity: line));
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
      return ExtracurricularEntry(activity: json.trim());
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
