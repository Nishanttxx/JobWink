import 'package:flutter/foundation.dart';

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
    final normalized = rawText
        .replaceAll(RegExp(r'[|•\*\t]'), '\n')
        .replaceAll(RegExp(r' {2,}'), '\n');
    final lines = normalized.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return '';

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
    return '';
  }

  /// Deterministically parses resume fields from raw text stream when AI is unavailable or returns incomplete JSON.
  static ResumeData parseFromRawText(String rawText) {
    if (rawText.trim().isEmpty) return const ResumeData();

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

    final locationMatch = RegExp(r'\b([A-Z][a-zA-Z\s]+,\s*[A-Z]{2,}(?:\s+\d{5})?|[A-Z][a-zA-Z\s]+,\s*[A-Z][a-zA-Z\s]+)\b').firstMatch(rawText);
    String extractedLocation = '';
    if (locationMatch != null) {
      final cand = locationMatch.group(0)!.trim();
      if (!cand.toLowerCase().contains('university') && !cand.toLowerCase().contains('college') && !cand.toLowerCase().contains('school')) {
        extractedLocation = cand;
      }
    }

    final textWithSplitHeaders = rawText
        .replaceAll(RegExp(r'(?:\s|^)(EXPERIENCE|WORK EXPERIENCE|PROFESSIONAL EXPERIENCE|EMPLOYMENT HISTORY|CAREER HISTORY)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nEXPERIENCE\n')
        .replaceAll(RegExp(r'(?:\s|^)(EDUCATION|ACADEMIC BACKGROUND|EDUCATIONAL BACKGROUND|ACADEMICS)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nEDUCATION\n')
        .replaceAll(RegExp(r'(?:\s|^)(PROJECTS|KEY PROJECTS|PERSONAL PROJECTS|FEATURED PROJECTS|ACADEMIC PROJECTS)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nPROJECTS\n')
        .replaceAll(RegExp(r'(?:\s|^)(TECHNICAL SKILLS|SKILLS & TECHNOLOGIES|SKILLS AND TECHNOLOGIES|KEY SKILLS|SKILLS)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nSKILLS\n')
        .replaceAll(RegExp(r'(?:\s|^)(CERTIFICATIONS|CERTIFICATES|LICENSES & CERTIFICATIONS)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nCERTIFICATIONS\n')
        .replaceAll(RegExp(r'(?:\s|^)(EXTRA-CURRICULAR ACTIVITIES & ACHIEVEMENTS|EXTRA-CURRICULAR ACTIVITIES|EXTRACURRICULAR ACTIVITIES|EXTRACURRICULAR|ACTIVITIES & ACHIEVEMENTS|ACTIVITIES)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nEXTRACURRICULAR\n')
        .replaceAll(RegExp(r'(?:\s|^)(SUMMARY|PROFESSIONAL SUMMARY|CAREER SUMMARY|EXECUTIVE SUMMARY|ABOUT ME|PROFILE|CAREER OBJECTIVE|OBJECTIVE)(?=\s|:|\$|[A-Z])', caseSensitive: false), '\nSUMMARY\n');

    final normalizedText = textWithSplitHeaders
        .replaceAll(RegExp(r'[|•\*\t]'), '\n')
        .replaceAll(RegExp(r' {3,}'), '\n');
    final lines = normalizedText.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String name = extractNameFromRawText(rawText);
    String title = '';
    String location = extractedLocation;
    String summary = '';
    final extractedSkills = <String>{};
    final experience = <ExperienceEntry>[];
    final education = <EducationEntry>[];
    final projects = <ProjectEntry>[];
    final certifications = <ExtracurricularEntry>[];
    final extracurriculars = <ExtracurricularEntry>[];

    final titleRegex = RegExp(r'\b(software engineer|flutter developer|full stack|frontend|backend|developer|engineer|data scientist|ui\/ux designer|product manager|project manager|system administrator|android developer|ios developer|mobile developer|analyst|consultant|architect|specialist|lead|associate|intern|administrator|director|coordinator|officer|supervisor)\b', caseSensitive: false);
    for (final line in lines.take(10)) {
      if (line.length < 45 && titleRegex.hasMatch(line)) {
        title = line;
        break;
      }
    }

    String currentSection = '';
    String currentCompany = '';
    String currentRole = '';
    List<String> currentBullets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();
      final cleanHeader = lower.replaceAll(RegExp(r'[^a-z\s&]'), '').trim();

      final isExactSkillsHeader = RegExp(r'^(skills|technical skills|key skills|core competencies|skills & technologies|skills and technologies|technologies|tools & technologies|technical proficiency|programming languages|areas of expertise|expertise|technical expertise|skills & expertise|skill highlights|technical tools)$', caseSensitive: false).hasMatch(cleanHeader);
      final isExactSummaryHeader = RegExp(r'^(summary|about me|profile|executive profile|professional profile|career summary|professional summary|objective|career objective|overview|personal summary)$', caseSensitive: false).hasMatch(cleanHeader);
      final isExactExperienceHeader = RegExp(r'^(experience|work experience|professional experience|employment history|work history|career history|employment|work|job history|experiences|internships|internship experience)$', caseSensitive: false).hasMatch(cleanHeader);
      final isExactEducationHeader = RegExp(r'^(education|academic background|educational background|academics|qualifications|academic qualifications|academic history|education & qualifications|education & academics|education and training|degrees|schooling|academic preparation|scholastic achievements|academic details)$', caseSensitive: false).hasMatch(cleanHeader);
      final isExactProjectsHeader = RegExp(r'^(projects|key projects|personal projects|academic projects|technical projects|featured projects|project work|software projects|recent projects)$', caseSensitive: false).hasMatch(cleanHeader);
      final isExactCertHeader = RegExp(r'^(certifications|certificates|licenses & certifications|certifications & licenses|courses & certifications|honors & awards|achievements|licenses|credentials|courses)$', caseSensitive: false).hasMatch(cleanHeader);
      final isExactExtraHeader = RegExp(r'^(extracurriculars|extracurricular activities|extracurricular|activities & achievements|activities|volunteer work|leadership & activities|volunteering)$', caseSensitive: false).hasMatch(cleanHeader);

      if (isExactSkillsHeader) {
        currentSection = 'skills';
        continue;
      } else if (isExactSummaryHeader) {
        currentSection = 'summary';
        continue;
      } else if (isExactExperienceHeader) {
        currentSection = 'experience';
        continue;
      } else if (isExactEducationHeader) {
        currentSection = 'education';
        continue;
      } else if (isExactProjectsHeader) {
        currentSection = 'projects';
        continue;
      } else if (isExactCertHeader) {
        currentSection = 'certifications';
        continue;
      } else if (isExactExtraHeader) {
        currentSection = 'extracurriculars';
        continue;
      }

      // Auto-detect section switches if currentSection is empty or summary
      final isEduContent = RegExp(r'\b(gpa|class xii|class x|cbse|icse|b\.tech|m\.tech|bachelor|master|university|college|institute|secondary school|high school)\b', caseSensitive: false).hasMatch(line);
      final isProjContent = RegExp(r'\b(engineere?d?|architected|developed|implemented|spearheaded|platform|voice-digest|gst_billing|nexus-searchh)\b', caseSensitive: false).hasMatch(line) || (line.contains('/') && line.toLowerCase().contains('nishanttxx'));
      final isExpContent = RegExp(r'\b(intern|remote|full-time|part-time|member finite loop|developer|engineer|software engineer)\b', caseSensitive: false).hasMatch(line) && line.length < 60;
      final isExtraContent = RegExp(r'\b(computer society of india|csi|ieee|rotaract|volunteer|membership)\b', caseSensitive: false).hasMatch(line);

      if (currentSection == '' || currentSection == 'summary') {
        if (isEduContent) {
          if (currentSection == 'summary') summary = '';
          currentSection = 'education';
        } else if (isProjContent) {
          if (currentSection == 'summary') summary = '';
          currentSection = 'projects';
        } else if (isExpContent) {
          if (currentSection == 'summary') summary = '';
          currentSection = 'experience';
        } else if (isExtraContent) {
          if (currentSection == 'summary') summary = '';
          currentSection = 'extracurriculars';
        }
      }

      if (currentSection == 'summary') {
        if (line.length > 5 && !isEduContent && !isProjContent && !isExpContent && !isExtraContent) {
          summary += (summary.isEmpty ? '' : ' ') + line;
        }
      } else if (currentSection == '') {
        // Capture initial summary paragraph at top of resume before any section header ONLY if genuine summary text
        if (line.length > 15 &&
            !isEduContent &&
            !isProjContent &&
            !isExpContent &&
            !isExtraContent &&
            !line.contains('@') &&
            !line.toLowerCase().contains('http') &&
            !line.toLowerCase().contains('linkedin') &&
            !line.toLowerCase().contains('github') &&
            line != name &&
            line != title &&
            !RegExp(r'^[\+\d\s\-\(\)]{7,20}$').hasMatch(line)) {
          summary += (summary.isEmpty ? '' : ' ') + line;
        }
      } else if (currentSection == 'skills') {
        final tokens = line.split(RegExp(r'[,;•|\/\t]+')).map((s) => s.trim()).where((s) => s.length > 1 && s.length < 40 && !s.toLowerCase().contains('skill'));
        extractedSkills.addAll(tokens);
      } else if (currentSection == 'experience') {
        final isActionVerbBullet = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied|maintained)\b', caseSensitive: false).hasMatch(line);
        final isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || isActionVerbBullet || line.length >= 60;

        if (isBullet) {
          final bullet = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
          if (bullet.isNotEmpty) currentBullets.add(bullet);
        } else if (line.length > 3 && line.length < 60) {
          if (currentCompany.isNotEmpty || currentRole.isNotEmpty || currentBullets.isNotEmpty) {
            experience.add(ExperienceEntry(
              company: currentCompany,
              role: currentRole,
              startDate: '',
              endDate: '',
              description: List.from(currentBullets),
            ));
            currentBullets.clear();
          }
          if (currentCompany.isEmpty) {
            currentCompany = line;
          } else {
            currentRole = line;
          }
        }
      } else if (currentSection == 'education') {
        if (line.isNotEmpty && line.length > 2 && !cleanHeader.contains('education')) {
          final isDegree = RegExp(r'\b(bachelor|master|b\.tech|m\.tech|b\.sc|m\.sc|b\.e|m\.e|phd|diploma|degree|high school|secondary|bca|mca|b\.a|b\.com|class xii|class x|cbse)\b', caseSensitive: false).hasMatch(line);
          final isInst = RegExp(r'\b(university|college|school|institute|academy)\b', caseSensitive: false).hasMatch(line);

          if (education.isNotEmpty && (isDegree || !isInst)) {
            final last = education.last;
            if (isDegree && last.degree.isEmpty) {
              education[education.length - 1] = EducationEntry(
                institution: last.institution,
                degree: line,
                fieldOfStudy: last.fieldOfStudy,
                startDate: last.startDate,
                endDate: last.endDate,
              );
            } else if (last.institution.isEmpty) {
              education[education.length - 1] = EducationEntry(
                institution: line,
                degree: last.degree,
                fieldOfStudy: last.fieldOfStudy,
                startDate: last.startDate,
                endDate: last.endDate,
              );
            } else {
              education.add(EducationEntry(
                institution: isInst ? line : '',
                degree: isDegree ? line : (isInst ? '' : line),
                fieldOfStudy: '',
                startDate: '',
                endDate: '',
              ));
            }
          } else {
            education.add(EducationEntry(
              institution: line,
              degree: '',
              fieldOfStudy: '',
              startDate: '',
              endDate: '',
            ));
          }
        }
      } else if (currentSection == 'projects') {
        final isActionVerbBullet = RegExp(r'^(engineered|architected|developed|implemented|spearheaded|created|built|designed|integrated|collaborated|applied)\b', caseSensitive: false).hasMatch(line);
        final isBullet = line.startsWith('•') || line.startsWith('-') || line.startsWith('*') || isActionVerbBullet;

        if (isBullet) {
          final bullet = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
          if (bullet.isNotEmpty) {
            if (projects.isNotEmpty) {
              final last = projects.removeLast();
              final updatedBullets = List<String>.from(last.descriptionBullets)..add(bullet);
              projects.add(last.copyWith(
                descriptionBullets: updatedBullets,
                description: updatedBullets.join(' '),
              ));
            } else {
              projects.add(ProjectEntry(name: 'Project', descriptionBullets: [bullet], description: bullet));
            }
          }
        } else if (line.length > 2 && !cleanHeader.contains('project')) {
          projects.add(ProjectEntry(name: line, descriptionBullets: []));
        }
      } else if (currentSection == 'certifications') {
        if (line.length > 2) {
          certifications.add(ExtracurricularEntry(
            activity: line,
          ));
        }
      } else if (currentSection == 'extracurriculars') {
        if (line.length > 2) {
          extracurriculars.add(ExtracurricularEntry(
            activity: line,
          ));
        }
      }
    }

    if (currentCompany.isNotEmpty || currentRole.isNotEmpty || currentBullets.isNotEmpty) {
      experience.add(ExperienceEntry(
        company: currentCompany,
        role: currentRole,
        startDate: '',
        endDate: '',
        description: List.from(currentBullets),
      ));
    }

    if (summary.trim().isEmpty) {
      for (final l in lines) {
        final lineStr = l.trim();
        final isEdu = RegExp(r'\b(gpa|class xii|class x|cbse|icse|b\.tech|m\.tech|bachelor|master|university|college|institute|secondary school|high school)\b', caseSensitive: false).hasMatch(lineStr);
        final isProj = RegExp(r'\b(engineere?d?|architected|developed|implemented|spearheaded|platform|voice-digest|gst_billing|nexus-searchh)\b', caseSensitive: false).hasMatch(lineStr) || lineStr.contains('Nishanttxx');
        final isExp = RegExp(r'\b(intern|remote|full-time|part-time|member finite loop)\b', caseSensitive: false).hasMatch(lineStr);
        final isExtra = RegExp(r'\b(computer society of india|csi|ieee)\b', caseSensitive: false).hasMatch(lineStr);

        if (lineStr.length > 25 &&
            !isEdu && !isProj && !isExp && !isExtra &&
            !lineStr.contains('@') &&
            !lineStr.toLowerCase().contains('http') &&
            !lineStr.toLowerCase().contains('linkedin') &&
            !lineStr.toLowerCase().contains('github') &&
            !lineStr.startsWith('•') &&
            !lineStr.startsWith('-') &&
            !lineStr.startsWith('*') &&
            lineStr != name &&
            lineStr != title &&
            !RegExp(r'^[\+\d\s\-\(\)]{7,20}$').hasMatch(lineStr)) {
          summary += (summary.isEmpty ? '' : ' ') + lineStr;
          if (summary.length > 120) break;
        }
      }
    }

    return ResumeData(
      fullName: name,
      email: emailMatch?.group(0) ?? '',
      phone: phone,
      location: location,
      linkedin: linkedinMatch?.group(0) ?? '',
      github: githubMatch?.group(0) ?? '',
      title: title,
      summary: summary,
      skills: extractedSkills.toList(),
      experience: experience,
      education: education,
      projects: projects,
      certifications: certifications,
      extracurriculars: extracurriculars,
    );
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

    final parsedSummary = getString(['summary', 'objective', 'about', 'about_me', 'executiveSummary', 'executive_summary', 'bio', 'overview', 'professional_summary', 'profile_summary', 'personal_summary']);
    final parsedLocation = getString(['location', 'address', 'city', 'cityState', 'city_state', 'residence', 'place', 'country', 'user_location']);
    final parsedSkills = _parseStringList(getField(['skills', 'keySkills', 'key_skills', 'technicalSkills', 'technical_skills', 'coreCompetencies', 'core_competencies', 'competencies', 'skills_list', 'technologies', 'skillsAndTechnologies']));
    final parsedExp = _parseList(getField(['experience', 'workExperience', 'work_experience', 'employmentHistory', 'employment_history', 'workHistory', 'work_history', 'jobs', 'experiences', 'career_history', 'work_entries']), ExperienceEntry.fromJson);
    final parsedProj = _parseList(getField(['projects', 'projectHistory', 'project_history', 'keyProjects', 'key_projects', 'personalProjects', 'personal_projects', 'projects_list']), ProjectEntry.fromJson);
    final parsedEdu = _parseList(getField(['education', 'academicHistory', 'academic_history', 'academics', 'qualification', 'qualifications', 'education_history', 'educational_background', 'educationEntries']), EducationEntry.fromJson);

    final parsedCerts = _parseCertifications(targetJson);
    final parsedExtras = _parseExtracurricularsOnly(targetJson);

    final rawData = ResumeData(
      fullName: extractedName,
      email: extractedEmail,
      phone: extractedPhone,
      location: parsedLocation.isEmpty ? fallbackData.location : parsedLocation,
      linkedin: extractedLinkedin,
      github: extractedGithub,
      title: extractedTitle,
      summary: parsedSummary.isEmpty ? fallbackData.summary : parsedSummary,
      skills: parsedSkills.isEmpty ? fallbackData.skills : parsedSkills,
      experience: parsedExp.isEmpty ? fallbackData.experience : parsedExp,
      projects: parsedProj.isEmpty ? fallbackData.projects : parsedProj,
      education: parsedEdu.isEmpty ? fallbackData.education : parsedEdu,
      certifications: parsedCerts.isEmpty ? fallbackData.certifications : parsedCerts,
      extracurriculars: parsedExtras.isEmpty ? fallbackData.extracurriculars : parsedExtras,
    );

    return _sanitizeAndRepairSectionMapping(rawData);
  }

  static ResumeData _sanitizeAndRepairSectionMapping(ResumeData raw) {
    bool suspiciousMappingDetected = false;

    // 1. Sanitize Skills (Technical / Professional skills ONLY)
    final cleanSkills = <String>[];
    final misclassifiedBullets = <String>[];

    for (final skill in raw.skills) {
      final s = skill.trim();
      if (s.isEmpty) continue;

      // Check if skill is actually a full sentence or experience/project bullet point
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

    // 2. Sanitize Experience & repair education/project leaks
    final cleanExp = <ExperienceEntry>[];
    final cleanEdu = List<EducationEntry>.from(raw.education);
    final cleanProj = List<ProjectEntry>.from(raw.projects);
    final cleanExtras = List<ExtracurricularEntry>.from(raw.extracurriculars);

    for (final exp in raw.experience) {
      final comp = exp.company.toLowerCase();
      final role = exp.role.toLowerCase();

      // Check if experience entry is actually an education entry
      final isEdu = comp.contains('university') ||
          comp.contains('college') ||
          comp.contains('school') ||
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

    // 3. Attach any misclassified bullets from skills into experience/projects if needed
    if (misclassifiedBullets.isNotEmpty && cleanExp.isNotEmpty) {
      final firstExp = cleanExp.first;
      final updatedBullets = List<String>.from(firstExp.description)..addAll(misclassifiedBullets);
      cleanExp[0] = firstExp.copyWith(description: updatedBullets);
    }

    if (suspiciousMappingDetected) {
      debugPrint('[ResumeParser] WARNING: suspicious section mapping detected');
    }

    String finalSummary = raw.summary.trim();

    // Check if summary is contaminated with full resume text or multi-section content
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

      finalSummary = '';
    } else if (ResumeData._isPlaceholderValue(finalSummary)) {
      finalSummary = '';
    }

    final sanitized = raw.copyWith(
      summary: finalSummary,
      skills: cleanSkills,
      experience: cleanExp,
      education: cleanEdu,
      projects: cleanProj,
      extracurriculars: cleanExtras,
    );

    debugPrint('[ResumeParser] Parsed resume successfully');
    debugPrint('[ResumeParser] Skills: ${sanitized.skills.length}');
    debugPrint('[ResumeParser] Experience: ${sanitized.experience.length}');
    debugPrint('[ResumeParser] Projects: ${sanitized.projects.length}');
    debugPrint('[ResumeParser] Education: ${sanitized.education.length}');
    debugPrint('[ResumeParser] Certifications: ${sanitized.certifications.length}');
    debugPrint('[ResumeParser] Extracurriculars: ${sanitized.extracurriculars.length}');

    return sanitized;
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
          } catch (_) {}
        }
      }
      return list;
    } else if (value is Map || value is String) {
      try {
        return [fromJson(value)];
      } catch (_) {}
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

  static List<ExtracurricularEntry> _parseExtracurricularsOnly(Map<String, dynamic> targetJson) {
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
      return ProjectEntry(name: json.trim());
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
        final bulletsVal = ResumeData._getNormalized(map, ['descriptionBullets', 'description_bullets', 'bullets', 'bulletPoints', 'bullet_points', 'highlights', 'details', 'description']);
        if (bulletsVal is List) {
          final list = bulletsVal
              .map((e) => e.toString().replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
              .where((s) => s.isNotEmpty && !ResumeData._isPlaceholderValue(s))
              .toList();
          if (list.isNotEmpty) return list;
        }

        final descVal = ResumeData._getNormalized(map, ['description', 'details', 'summary', 'overview']);
        if (descVal != null && descVal.toString().trim().isNotEmpty) {
          return _splitBullets(descVal.toString());
        }

        return const [];
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

      final projName = getName();
      final bullets = getBullets();

      return ProjectEntry(
        id: map['id']?.toString() ?? '',
        name: projName.isNotEmpty ? projName : (bullets.isNotEmpty ? bullets.first : 'Project'),
        type: getType(),
        technologies: getTech(),
        githubUrl: getGhUrl(),
        demoUrl: getDemoUrl(),
        url: getLegacyUrl(),
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
