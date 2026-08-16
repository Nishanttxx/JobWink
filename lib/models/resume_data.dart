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
    this.extracurriculars = const [],
  });

  /// Evaluates whether this resume object contains meaningful candidate information.
  bool get hasUsableData =>
      fullName.trim().isNotEmpty ||
      email.trim().isNotEmpty ||
      phone.trim().isNotEmpty ||
      summary.trim().isNotEmpty ||
      skills.isNotEmpty ||
      experience.isNotEmpty ||
      education.isNotEmpty ||
      projects.isNotEmpty;

  /// Logs pipeline summary for parsed resume.
  void logPipelineSummary() {
    debugPrint(
      '[ResumeData Pipeline] Parsed $fullName: '
      '${experience.length} experiences, ${education.length} education entries, '
      '${skills.length} skills, ${projects.length} projects, '
      '${extracurriculars.length} extracurriculars.',
    );
  }


  factory ResumeData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> targetJson = json;
    for (final wrapKey in ['resume', 'data', 'candidate', 'parsed_resume', 'parsed', 'resumeData', 'resume_data', 'result', 'extracted_data', 'response']) {
      if (json[wrapKey] is Map) {
        targetJson = Map<String, dynamic>.from(json[wrapKey] as Map);
        break;
      }
    }

    // Helper to try multiple key candidates across top-level and sub-maps
    String getString(List<String> keys) {
      for (final key in keys) {
        final val = targetJson[key];
        if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
      for (final subMapKey in ['personal_info', 'personalInfo', 'contact_info', 'contactInfo', 'contact', 'identity', 'header', 'profile']) {
        if (targetJson[subMapKey] is Map) {
          final subMap = Map<String, dynamic>.from(targetJson[subMapKey] as Map);
          for (final key in keys) {
            final val = subMap[key];
            if (val != null && val is! Map && val is! List && val.toString().trim().isNotEmpty) {
              return val.toString().trim();
            }
          }
        }
      }
      return '';
    }

    dynamic getField(List<String> keys) {
      for (final key in keys) {
        if (targetJson[key] != null) {
          return targetJson[key];
        }
      }
      for (final subMapKey in ['sections', 'details', 'body', 'resume_body', 'content']) {
        if (targetJson[subMapKey] is Map) {
          final subMap = Map<String, dynamic>.from(targetJson[subMapKey] as Map);
          for (final key in keys) {
            if (subMap[key] != null) {
              return subMap[key];
            }
          }
        }
      }
      return null;
    }

    return ResumeData(
      fullName: getString(['fullName', 'full_name', 'name', 'candidateName', 'candidate_name', 'personName', 'person_name', 'headerName', 'contactName']),
      email: getString(['email', 'emailAddress', 'email_address', 'contactEmail', 'contact_email', 'mail']),
      phone: getString(['phone', 'phoneNumber', 'phone_number', 'mobile', 'mobile_number', 'telephone', 'contactPhone', 'contact_phone', 'cell']),
      location: getString(['location', 'address', 'city', 'cityState', 'city_state', 'residence', 'place', 'country']),
      linkedin: getString(['linkedin', 'linkedinUrl', 'linkedin_url', 'linkedIn', 'linkedin_profile', 'linkedinProfile']),
      github: getString(['github', 'githubUrl', 'github_url', 'portfolio', 'portfolioUrl', 'portfolio_url', 'website', 'personalWebsite']),
      title: getString(['title', 'jobTitle', 'job_title', 'professionalTitle', 'professional_title', 'currentTitle', 'current_title', 'headerTitle', 'headline', 'role']),
      summary: getString(['summary', 'objective', 'about', 'about_me', 'executiveSummary', 'executive_summary', 'bio', 'overview', 'professional_summary']),
      skills: _parseStringList(getField(['skills', 'keySkills', 'key_skills', 'technicalSkills', 'technical_skills', 'coreCompetencies', 'core_competencies', 'competencies', 'skills_list', 'technologies'])),
      experience: _parseList(getField(['experience', 'workExperience', 'work_experience', 'employmentHistory', 'employment_history', 'workHistory', 'work_history', 'jobs', 'experiences', 'career_history']), ExperienceEntry.fromJson),
      projects: _parseList(getField(['projects', 'projectHistory', 'project_history', 'keyProjects', 'key_projects', 'personalProjects', 'personal_projects', 'projects_list']), ProjectEntry.fromJson),
      education: _parseList(getField(['education', 'academicHistory', 'academic_history', 'academics', 'qualification', 'qualifications', 'education_history', 'educational_background']), EducationEntry.fromJson),
      extracurriculars: _parseExtracurriculars(targetJson),
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
        'experience': experience.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
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
      extracurriculars: extracurriculars ?? this.extracurriculars,
    );
  }

  // ── Helpers ──

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
      dynamic value, T Function(Map<String, dynamic>) fromJson) {
    if (value is List) {
      final list = <T>[];
      for (final item in value) {
        if (item is Map) {
          try {
            final map = Map<String, dynamic>.from(item);
            list.add(fromJson(map));
          } catch (_) {}
        }
      }
      return list;
    }
    return [];
  }

  static List<ExtracurricularEntry> _parseExtracurriculars(Map<String, dynamic> targetJson) {
    final results = <ExtracurricularEntry>[];
    final processedKeys = <String>{};

    final possibleKeys = [
      'certifications',
      'certificates',
      'certification',
      'extracurriculars',
      'extracurricular',
      'extracurricular_activities',
      'activities',
      'achievements',
      'awards',
      'licenses',
      'courses',
    ];

    void checkSourceMap(Map<String, dynamic> src) {
      for (final key in possibleKeys) {
        if (src.containsKey(key) && src[key] != null && !processedKeys.contains(key)) {
          processedKeys.add(key);
          final val = src[key];
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

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    String getStr(List<String> keys) {
      for (final k in keys) {
        if (json[k] != null && json[k].toString().trim().isNotEmpty) {
          return json[k].toString().trim();
        }
      }
      return '';
    }

    var descList = json['description'] ?? json['bullets'] ?? json['responsibilities'] ?? json['highlights'] ?? json['details'] ?? json['achievements'];
    List<String> parsedDesc = [];
    if (descList is List) {
      parsedDesc = descList.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (descList is String && descList.trim().isNotEmpty) {
      parsedDesc = descList.split('\n').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
    }

    return ExperienceEntry(
      company: getStr(['company', 'companyName', 'employer', 'organization']),
      role: getStr(['role', 'jobTitle', 'title', 'position', 'designation']),
      location: getStr(['location', 'city', 'place', 'address']),
      startDate: getStr(['startDate', 'start_date', 'start', 'from', 'dates']),
      endDate: getStr(['endDate', 'end_date', 'end', 'to']),
      description: parsedDesc,
    );
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

  factory ProjectEntry.fromJson(Map<String, dynamic> json) {
    String getName() {
      for (final k in ['name', 'projectName', 'title', 'projectTitle', 'project']) {
        final val = json[k];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
      return '';
    }

    String getType() {
      for (final k in ['type', 'projectType', 'category', 'kind']) {
        final val = json[k];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
      return '';
    }

    List<String> getBullets() {
      // 1. Direct array of bullets or list description
      final bulletsVal = json['descriptionBullets'] ?? json['bullets'] ?? json['bulletPoints'] ?? json['bullet_points'] ?? json['highlights'] ?? json['description'];
      if (bulletsVal is List) {
        final list = bulletsVal
            .map((e) => e.toString().replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }

      // 2. String description to split
      final descVal = json['description'] ?? json['details'] ?? json['summary'] ?? json['overview'];
      if (descVal != null && descVal.toString().trim().isNotEmpty) {
        return _splitBullets(descVal.toString());
      }

      return const [];
    }


    String getGhUrl() {
      for (final k in ['githubUrl', 'github_url', 'repoUrl', 'repo_url', 'github']) {
        final val = json[k];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
      return '';
    }

    String getDemoUrl() {
      for (final k in ['demoUrl', 'demo_url', 'liveUrl', 'live_url', 'website']) {
        final val = json[k];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
      return '';
    }

    String getLegacyUrl() {
      for (final k in ['url', 'link', 'projectUrl']) {
        final val = json[k];
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
      return '';
    }

    return ProjectEntry(
      id: json['id']?.toString() ?? '',
      name: getName(),
      type: getType(),
      descriptionBullets: getBullets(),
      technologies: ResumeData._parseStringList(
          json['technologies'] ?? json['techStack'] ?? json['tools'] ?? json['tech_stack'] ?? json['tech'] ?? json['stack']),
      githubUrl: getGhUrl(),
      demoUrl: getDemoUrl(),
      url: getLegacyUrl(),
      source: json['source']?.toString() ?? (getGhUrl().isNotEmpty ? 'github' : 'manual'),
      githubOwner: json['githubOwner']?.toString() ?? json['owner']?.toString(),
      githubRepo: json['githubRepo']?.toString() ?? json['repo']?.toString(),
    );
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

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    String getStr(List<String> keys) {
      for (final k in keys) {
        if (json[k] != null && json[k].toString().trim().isNotEmpty) {
          return json[k].toString().trim();
        }
      }
      return '';
    }

    return EducationEntry(
      institution: getStr(['institution', 'university', 'school', 'college', 'academy']),
      degree: getStr(['degree', 'degreeName', 'qualification', 'title']),
      fieldOfStudy: getStr(['fieldOfStudy', 'field_of_study', 'major', 'stream', 'branch', 'specialization']),
      startDate: getStr(['startDate', 'start_date', 'start', 'year', 'dates']),
      endDate: getStr(['endDate', 'end_date', 'end', 'graduationYear']),
      gpa: getStr(['gpa', 'grade', 'score', 'percentage']),
    );
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
        for (final k in keys) {
          if (map[k] != null && map[k].toString().trim().isNotEmpty) {
            return map[k].toString().trim();
          }
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
