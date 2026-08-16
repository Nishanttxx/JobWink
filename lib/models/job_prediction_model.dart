class JobPredictionResult {
  final String id;
  final String resumeId;
  final String? resumeVersionId;
  final String? tailoredResumeHash;
  final String jobTitle;
  final String jobDescription;
  final Map<String, dynamic> extractedFeatures;
  final double structuredProbability;
  final double fitProbability;
  final double combinedProbability;
  final bool isMatch;
  final String estimatedMatchLevel;
  final bool isStale;
  final String disclaimer;
  final DateTime createdAt;

  JobPredictionResult({
    required this.id,
    required this.resumeId,
    this.resumeVersionId,
    this.tailoredResumeHash,
    required this.jobTitle,
    required this.jobDescription,
    required this.extractedFeatures,
    required this.structuredProbability,
    required this.fitProbability,
    required this.combinedProbability,
    required this.isMatch,
    required this.estimatedMatchLevel,
    required this.isStale,
    required this.disclaimer,
    required this.createdAt,
  });

  factory JobPredictionResult.fromJson(Map<String, dynamic> json) {
    return JobPredictionResult(
      id: json['id'] as String? ?? '',
      resumeId: json['resume_id'] as String? ?? '',
      resumeVersionId: json['resume_version_id'] as String?,
      tailoredResumeHash: json['tailored_resume_hash'] as String?,
      jobTitle: json['job_title'] as String? ?? 'Target Role',
      jobDescription: json['job_description'] as String? ?? '',
      extractedFeatures: Map<String, dynamic>.from(json['extracted_features'] as Map? ?? {}),
      structuredProbability: (json['structured_probability'] as num?)?.toDouble() ?? 0.0,
      fitProbability: (json['fit_probability'] as num?)?.toDouble() ?? 0.0,
      combinedProbability: (json['combined_probability'] as num?)?.toDouble() ?? 0.0,
      isMatch: json['is_match'] as bool? ?? false,
      estimatedMatchLevel: json['estimated_match_level'] as String? ?? 'Low Model Match',
      isStale: json['is_stale'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ??
          'Model-estimated probability based on statistical feature match.',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resume_id': resumeId,
      'resume_version_id': resumeVersionId,
      'tailored_resume_hash': tailoredResumeHash,
      'job_title': jobTitle,
      'job_description': jobDescription,
      'extracted_features': extractedFeatures,
      'structured_probability': structuredProbability,
      'fit_probability': fitProbability,
      'combined_probability': combinedProbability,
      'is_match': isMatch,
      'estimated_match_level': estimatedMatchLevel,
      'is_stale': isStale,
      'disclaimer': disclaimer,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
