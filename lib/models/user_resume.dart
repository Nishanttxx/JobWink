enum CvTemplateType { nationalAts, internationalGlobal }

class UserResume {
  final String id;
  final String userId;
  final String title;
  final int atsScore;
  final List<String> extractedSkills;
  final List<String> missingKeywords;
  final DateTime lastUpdatedAt;
  final CvTemplateType templateType;

  const UserResume({
    required this.id,
    required this.userId,
    required this.title,
    required this.atsScore,
    required this.extractedSkills,
    required this.missingKeywords,
    required this.lastUpdatedAt,
    required this.templateType,
  });

  factory UserResume.fromJson(Map<String, dynamic> json) {
    return UserResume(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? 'Master Resume',
      atsScore: (json['atsScore'] as num? ?? 85).toInt(),
      extractedSkills: List<String>.from(json['extractedSkills'] ?? []),
      missingKeywords: List<String>.from(json['missingKeywords'] ?? []),
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : DateTime.now(),
      templateType: json['templateType'] == 'INTERNATIONAL'
          ? CvTemplateType.internationalGlobal
          : CvTemplateType.nationalAts,
    );
  }
}
