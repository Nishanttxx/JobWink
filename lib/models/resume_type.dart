import 'resume_data.dart';

/// Validation result for selected resume focus criteria.
class ResumeFocusCriteriaResult {
  final bool isValid;
  final int experienceCount;
  final int projectCount;
  final int requiredExperience;
  final int requiredProjects;
  final String primaryMessage;
  final String? detailMessage;

  const ResumeFocusCriteriaResult({
    required this.isValid,
    required this.experienceCount,
    required this.projectCount,
    required this.requiredExperience,
    required this.requiredProjects,
    this.primaryMessage = 'Meet the criteria to build your resume.',
    this.detailMessage,
  });

  String get fullMessage {
    if (isValid) return '';
    if (detailMessage != null && detailMessage!.isNotEmpty) {
      return '$primaryMessage\n$detailMessage';
    }
    return primaryMessage;
  }
}

/// Supported target resume structure formats.
///
/// Controls section layout ordering, AI tailoring prompt priorities,
/// and content weighting without creating separate independent generators.
enum ResumeType {
  experience,
  project,
  hybrid,
  fresher;

  String get displayName {
    switch (this) {
      case ResumeType.experience:
        return 'Experience Based';
      case ResumeType.project:
        return 'Project Based';
      case ResumeType.hybrid:
        return 'Hybrid';
      case ResumeType.fresher:
        return 'Fresher';
    }
  }

  String get description {
    switch (this) {
      case ResumeType.experience:
        return 'Prioritizes professional work history, business impact, scale, and core career strengths.';
      case ResumeType.project:
        return 'Primary focus on technical projects, system architecture, tech stack breakdown, and portfolio.';
      case ResumeType.hybrid:
        return 'Balanced structure combining targeted professional experience with strategic technical projects.';
      case ResumeType.fresher:
        return 'Prioritizes academic credentials, capstone/self-directed projects, internships, and campus leadership.';
    }
  }

  String get criteriaSummary {
    switch (this) {
      case ResumeType.experience:
        return 'Min: 3 Experiences • 2 Projects';
      case ResumeType.project:
        return 'Min: 1 Experience • 3 Projects';
      case ResumeType.hybrid:
        return 'Min: 2 Experiences • 2 Projects';
      case ResumeType.fresher:
        return 'No minimum requirements';
    }
  }

  String get id {
    switch (this) {
      case ResumeType.experience:
        return 'experience';
      case ResumeType.project:
        return 'project';
      case ResumeType.hybrid:
        return 'hybrid';
      case ResumeType.fresher:
        return 'fresher';
    }
  }

  static ResumeType fromString(String? val) {
    if (val == null) return ResumeType.experience;
    switch (val.toLowerCase().trim()) {
      case 'project':
      case 'project based':
      case 'project_based':
        return ResumeType.project;
      case 'hybrid':
        return ResumeType.hybrid;
      case 'fresher':
        return ResumeType.fresher;
      case 'experience':
      case 'experience based':
      case 'experience_based':
      default:
        return ResumeType.experience;
    }
  }

  /// Evaluates whether an individual [ExperienceEntry] is meaningful and valid.
  static bool isExperienceValid(ExperienceEntry e) {
    final hasRole = e.role.trim().isNotEmpty && !ResumeData.isPlaceholderValue(e.role);
    final hasCompany = e.company.trim().isNotEmpty && !ResumeData.isPlaceholderValue(e.company);
    final hasBullets = e.description.any((b) => b.trim().isNotEmpty && !ResumeData.isPlaceholderValue(b));
    return hasRole || hasCompany || hasBullets;
  }

  /// Evaluates whether an individual [ProjectEntry] is meaningful and valid.
  static bool isProjectValid(ProjectEntry p) {
    final hasName = p.name.trim().isNotEmpty && !ResumeData.isPlaceholderValue(p.name);
    final hasBullets = p.descriptionBullets.any((b) => b.trim().isNotEmpty && !ResumeData.isPlaceholderValue(b));
    final hasTech = p.technologies.any((t) => t.trim().isNotEmpty && !ResumeData.isPlaceholderValue(t));
    return hasName || hasBullets || hasTech;
  }

  /// Counts the number of non-empty, non-placeholder experience records.
  static int countValidExperiences(List<ExperienceEntry> list) {
    return list.where(isExperienceValid).length;
  }

  /// Counts the number of non-empty, non-placeholder project records.
  static int countValidProjects(List<ProjectEntry> list) {
    return list.where(isProjectValid).length;
  }

  /// Validates the resume data against the mandatory criteria for this selected focus.
  ResumeFocusCriteriaResult validateCriteria(ResumeData resume) {
    final expCount = countValidExperiences(resume.experience);
    final projCount = countValidProjects(resume.projects);

    switch (this) {
      case ResumeType.experience:
        const reqExp = 3;
        const reqProj = 2;
        final isValid = expCount >= reqExp && projCount >= reqProj;
        String? detail;
        if (!isValid) {
          final missingExp = reqExp - expCount;
          final missingProj = reqProj - projCount;
          if (missingExp > 0 && missingProj > 0) {
            detail = 'You need at least 3 experiences and 2 projects.';
          } else if (missingExp > 0) {
            detail = 'Add at least $missingExp more experience${missingExp > 1 ? 's' : ''}.';
          } else if (missingProj > 0) {
            detail = 'Add at least $missingProj more project${missingProj > 1 ? 's' : ''}.';
          }
        }
        return ResumeFocusCriteriaResult(
          isValid: isValid,
          experienceCount: expCount,
          projectCount: projCount,
          requiredExperience: reqExp,
          requiredProjects: reqProj,
          detailMessage: detail,
        );

      case ResumeType.project:
        const reqExp = 1;
        const reqProj = 3;
        final isValid = projCount >= reqProj && expCount >= reqExp;
        String? detail;
        if (!isValid) {
          final missingExp = reqExp - expCount;
          final missingProj = reqProj - projCount;
          if (missingProj > 0 && missingExp > 0) {
            detail = 'You need at least 3 projects and 1 experience.';
          } else if (missingProj > 0) {
            detail = 'Add at least $missingProj more project${missingProj > 1 ? 's' : ''}.';
          } else if (missingExp > 0) {
            detail = 'Add at least $missingExp more experience${missingExp > 1 ? 's' : ''}.';
          }
        }
        return ResumeFocusCriteriaResult(
          isValid: isValid,
          experienceCount: expCount,
          projectCount: projCount,
          requiredExperience: reqExp,
          requiredProjects: reqProj,
          detailMessage: detail,
        );

      case ResumeType.hybrid:
        const reqExp = 2;
        const reqProj = 2;
        final isValid = expCount >= reqExp && projCount >= reqProj;
        String? detail;
        if (!isValid) {
          final missingExp = reqExp - expCount;
          final missingProj = reqProj - projCount;
          if (missingExp > 0 && missingProj > 0) {
            detail = 'You need at least 2 projects and 2 experiences.';
          } else if (missingExp > 0) {
            detail = 'Add at least $missingExp more experience${missingExp > 1 ? 's' : ''}.';
          } else if (missingProj > 0) {
            detail = 'Add at least $missingProj more project${missingProj > 1 ? 's' : ''}.';
          }
        }
        return ResumeFocusCriteriaResult(
          isValid: isValid,
          experienceCount: expCount,
          projectCount: projCount,
          requiredExperience: reqExp,
          requiredProjects: reqProj,
          detailMessage: detail,
        );

      case ResumeType.fresher:
        return ResumeFocusCriteriaResult(
          isValid: true,
          experienceCount: expCount,
          projectCount: projCount,
          requiredExperience: 0,
          requiredProjects: 0,
          detailMessage: null,
        );
    }
  }
}
