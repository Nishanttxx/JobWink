class JobMatch {
  final String id;
  final String jobTitle;
  final String companyName;
  final String companyLogoUrl;
  final String location;
  final String salaryRange;
  final double matchPercentage;
  final String platformSource;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final String description;
  final DateTime postedAt;
  final String? applyUrl;
  final String? jobUrl;
  final bool remote;
  final String workplaceType;

  const JobMatch({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.companyLogoUrl,
    required this.location,
    required this.salaryRange,
    required this.matchPercentage,
    required this.platformSource,
    required this.matchingSkills,
    required this.missingSkills,
    required this.description,
    required this.postedAt,
    this.applyUrl,
    this.jobUrl,
    this.remote = false,
    this.workplaceType = 'On-site',
  });

  String get timeAgoString {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inHours < 1) {
      final mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return 'Posted $mins min ago';
    } else if (diff.inHours < 24) {
      return 'Posted ${diff.inHours} hours ago';
    } else {
      return 'Posted ${diff.inDays} days ago';
    }
  }

  factory JobMatch.fromJson(Map<String, dynamic> json) {
    // Determine skills list
    final List<String> reqSkills = List<String>.from(
      json['required_skills'] ?? json['matchingSkills'] ?? [],
    );

    final String title =
        json['job_title'] as String? ?? json['jobTitle'] as String? ?? 'Untitled Position';
    final String company =
        json['company_name'] as String? ?? json['companyName'] as String? ?? 'Company';
    final String logo =
        json['company_logo_url'] as String? ?? json['companyLogoUrl'] as String? ?? '';
    final String loc = json['location'] as String? ?? 'Remote';
    final String salary =
        json['salary_range'] as String? ?? json['salaryRange'] as String? ?? 'Competitive';
    final double match = json['matchPercentage'] != null
        ? (json['matchPercentage'] as num).toDouble()
        : 90.0;
    final String source =
        json['platform_source'] as String? ?? json['source'] as String? ?? 'Public Board';

    final String desc = json['description'] as String? ?? '';

    DateTime parsedDate = DateTime.now();
    final rawDate = json['source_updated_at'] ??
        json['source_posted_at'] ??
        json['posted_at'] ??
        json['postedAt'];
    if (rawDate != null) {
      try {
        parsedDate = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    return JobMatch(
      id: json['id'] as String? ?? json['external_job_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      jobTitle: title,
      companyName: company,
      companyLogoUrl: logo,
      location: loc,
      salaryRange: salary,
      matchPercentage: match,
      platformSource: source,
      matchingSkills: reqSkills.isNotEmpty ? reqSkills.take(3).toList() : ['Flutter', 'Dart', 'API'],
      missingSkills: reqSkills.length > 3 ? reqSkills.skip(3).take(2).toList() : ['System Architecture'],
      description: desc,
      postedAt: parsedDate,
      applyUrl: json['apply_url'] as String? ?? json['job_url'] as String? ?? json['jobUrl'] as String?,
      jobUrl: json['job_url'] as String? ?? json['apply_url'] as String? ?? json['jobUrl'] as String?,
      remote: json['remote'] as bool? ?? false,
      workplaceType: json['workplace_type'] as String? ?? 'On-site',
    );
  }
}
