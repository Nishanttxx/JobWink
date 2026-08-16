import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/job_match.dart';
import '../models/user_resume.dart';
import '../providers/auth_provider.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ats_score_gauge.dart';
import '../widgets/demo_banner.dart';
import '../widgets/page_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock User Resume State
  late UserResume _userResume;

  // Mock Top Job Matches
  final List<JobMatch> _topMatches = [
    JobMatch(
      id: 'job_101',
      jobTitle: 'Senior Flutter Developer',
      companyName: 'TechCorp Global',
      companyLogoUrl: '',
      location: 'Remote (US/EU)',
      salaryRange: '\$130k - \$160k',
      matchPercentage: 94.5,
      platformSource: 'Wellfound',
      matchingSkills: ['Flutter', 'Dart', 'State Management', 'REST APIs'],
      missingSkills: ['GraphQL'],
      description: 'Lead mobile app development across iOS & Android using Flutter.',
      postedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    JobMatch(
      id: 'job_102',
      jobTitle: 'AI Full-Stack Engineer',
      companyName: 'DataWiz AI',
      companyLogoUrl: '',
      location: 'San Francisco, CA (Hybrid)',
      salaryRange: '\$140k - \$175k',
      matchPercentage: 89.2,
      platformSource: 'Indeed',
      matchingSkills: ['Node.js', 'PostgreSQL', 'Python', 'React'],
      missingSkills: ['Kubernetes', 'Docker'],
      description: 'Build responsive web apps powered by Large Language Models.',
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    JobMatch(
      id: 'job_103',
      jobTitle: 'Lead Mobile Architect',
      companyName: 'NextGen Solutions',
      companyLogoUrl: '',
      location: 'Remote',
      salaryRange: '\$150k - \$180k',
      matchPercentage: 86.8,
      platformSource: 'Naukri.com',
      matchingSkills: ['Flutter', 'Dart', 'CI/CD', 'Clean Architecture'],
      missingSkills: ['Swift', 'Kotlin'],
      description: 'Architect scalable cross-platform mobile apps for enterprise users.',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _userResume = UserResume(
      id: 'res_001',
      userId: 'usr_7721',
      title: 'Master Technical Resume',
      atsScore: 88,
      extractedSkills: ['Flutter', 'Dart', 'Node.js', 'PostgreSQL', 'REST APIs', 'Git'],
      missingKeywords: ['GraphQL', 'Kubernetes', 'Docker', 'AWS Lambda'],
      lastUpdatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      templateType: CvTemplateType.nationalAts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDarkMode = AppTheme.isDarkMode(context);

    final auth = AuthProviderScope.of(context);
    final isDemo = !auth.isAuthenticated && DemoService.instance.isDemoMode;
    final name = auth.currentUser?.fullName ??
        (auth.currentUser?.email.isNotEmpty == true
            ? auth.currentUser!.email.split('@').first
            : 'User');

    return Column(
      children: [
        const DemoBanner(),
        Expanded(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                PageHeader(
                  title: 'Overview Dashboard',
                  subtitle: isDemo
                      ? 'Welcome to JobWink Demo 👋 Track ATS scores and real-time job match notifications.'
                      : 'Welcome back, $name 👋 Your resume ATS score is high! We found 3 new 90%+ matches in the last 48 hours.',
                ),

                // 1. Cadence Banner (48-Hour Auto Scan Status)
                _buildRefreshCadenceBanner(context, isDarkMode),
                const SizedBox(height: 28),

                // 2. Quick Action Cards Row
                _buildQuickActionCards(context, isDesktop),
                const SizedBox(height: 32),

                // 3. Main Workspace Layout (Grid)
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildAtsHealthCard(context, isDarkMode),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 6,
                            child: _buildMatchesSection(context, isDarkMode),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildAtsHealthCard(context, isDarkMode),
                          const SizedBox(height: 24),
                          _buildMatchesSection(context, isDarkMode),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshCadenceBanner(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryLightColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getPrimaryBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sync,
            color: AppTheme.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '48-Hour Auto Refresh: Last scanned 4 hours ago. Next automatic job match sync in 44 hours.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFFFFD4C2) : const Color(0xFF9E3609),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.primaryOrange,
                  content: Text(
                    'Syncing new resume job matches across Wellfound, Indeed & Naukri...',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Sync Now',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context, bool isDesktop) {
    final actions = [
      {
        'title': 'Start Swipe Matcher',
        'icon': Icons.swipe_rounded,
        'color': AppTheme.primaryOrange,
        'desc': 'Swipe right to save top roles',
        'route': '/matcher'
      },
      {
        'title': 'Resume Tailoring 🎯',
        'icon': Icons.tune_rounded,
        'color': const Color(0xFF3B82F6),
        'desc': 'AI job description match & ATS optimizer',
        'route': '/cv-studio'
      },
      {
        'title': 'Job Match Prediction ⚡',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF8B5CF6),
        'desc': 'ML hiring probability & feature evaluation',
        'route': '/job-prediction'
      },
      {
        'title': 'Upload & Extract Resume 📤',
        'icon': Icons.cloud_upload_outlined,
        'color': const Color(0xFF10B981),
        'desc': 'Import PDF/DOCX to auto-fill details',
        'route': '/cv-studio'
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions.map((act) {
            final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth);

            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, act['route'] as String),
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.getBorderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (act['color'] as Color).withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      act['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      act['desc'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAtsHealthCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Master Resume ATS Health',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Resume Tailoring',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gauge widget
          Center(
            child: const AtsScoreGauge(),
          ),
          const SizedBox(height: 16),

          Text(
            'Extracted Core Skills',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _userResume.extractedSkills.map((sk) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF0EAE1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sk,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          Text(
            'Recommended Keywords to Add',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _userResume.missingKeywords.map((kw) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryOrange.withValues(alpha:0.3)),
                ),
                child: Text(
                  '+ $kw',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top AI Job Matches',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All (${_topMatches.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._topMatches.map((job) => _buildJobCard(context, job, isDarkMode)),
      ],
    );
  }

  Widget _buildJobCard(BuildContext context, JobMatch job, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    job.companyName.substring(0, 1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.companyName} • ${job.location}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${job.matchPercentage.toStringAsFixed(0)}% Match',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFEBE6DD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  job.platformSource,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                job.salaryRange,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: job.matchingSkills.map((sk) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓ $sk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
