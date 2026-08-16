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
}
