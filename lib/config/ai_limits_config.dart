/// Central configuration file for daily per-user AI operation limits.
class AILimitsConfig {
  /// Daily limit for resume extraction operations (Development: 20)
  static const int resumeExtractLimit = 20;

  /// Daily limit for resume tailoring operations (Development: 20)
  static const int tailorLimit = 20;

  /// Daily limit for ATS score analysis operations (Development: 20)
  static const int atsLimit = 20;

  /// Operation identifiers matching database records
  static const String opResumeExtract = 'resume_extract';
  static const String opTailor = 'tailor';
  static const String opAts = 'ats';

  /// Helper to fetch the maximum daily limit for a given operation identifier.
  static int getLimitForOperation(String operation) {
    switch (operation) {
      case opResumeExtract:
        return resumeExtractLimit;
      case opTailor:
        return tailorLimit;
      case opAts:
        return atsLimit;
      default:
        return 5;
    }
  }
}
