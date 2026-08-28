import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';
import 'custom_badge.dart';
import 'spotlight_card.dart';

class FeaturesSection extends StatefulWidget {
  final Function(String featureKey)? onFeatureTap;
  const FeaturesSection({super.key, this.onFeatureTap});

  @override
  State<FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<FeaturesSection> {
  bool _isTriggered = false;

  final List<Map<String, dynamic>> _features = [
    {
      'key': 'builder',
      'icon': Icons.auto_awesome_rounded,
      'title': 'AI Resume Builder',
      'desc':
          'Generate clean, professional, ATS-optimized resume sections tailored to your background and career level.',
      'badge': 'Core Engine',
    },
    {
      'key': 'tailor',
      'icon': Icons.tune_rounded,
      'title': 'AI Resume Tailoring',
      'desc':
          'Paste target job descriptions to instantly customize your bullet points, summary, and skills for maximum match rate.',
      'badge': 'High Impact',
    },
    {
      'key': 'ats',
      'icon': Icons.analytics_rounded,
      'title': 'Real-Time ATS Score',
      'desc':
          'Get an accurate ATS readiness score (0-100%) with actionable feedback on layout, keywords, and density.',
      'badge': 'Instant Feedback',
    },
    {
      'key': 'prediction',
      'icon': Icons.psychology_rounded,
      'title': 'Job Prediction Match',
      'desc':
          'Analyze job post requirements against your candidate profile to predict shortlist and interview probability.',
      'badge': 'Predictive ML',
    },
    {
      'key': 'github',
      'icon': Icons.code_rounded,
      'title': 'GitHub Project Import',
      'desc':
          'Connect repository URLs to auto-extract tech stacks and convert README summaries into recruiter-ready accomplishments.',
      'badge': 'Developer Tool',
    },
    {
      'key': 'optimize',
      'icon': Icons.bolt_rounded,
      'title': 'Bullet & Tone Optimizer',
      'desc':
          'Enhance weak bullet points with action verbs, quantifiable metrics, and professional industry phrasing.',
      'badge': 'Smart Edits',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1050;
    final isTablet = screenWidth >= 650 && screenWidth < 1050;
    final isDark = AppTheme.isDarkMode(context);

    int crossAxisCount = 3;
    if (isTablet) crossAxisCount = 2;
    if (!isDesktop && !isTablet) crossAxisCount = 1;

    return GsapScrollTrigger(
      triggerKey: 'features_section',
      onEnter: () => setState(() => _isTriggered = true),
      onLeave: () => setState(() => _isTriggered = false),
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          vertical: isDesktop ? 80 : 48,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1240),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 20,
            ),
            child: Column(
              children: [
                // Header Badge & Titles
                GsapStaggeredReveal(
                  index: 0,
                  isTriggered: _isTriggered,
                  child: const CustomBadge(
                    label: 'Platform Capabilities',
                    icon: Icons.star_outline_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                GsapStaggeredReveal(
                  index: 1,
                  isTriggered: _isTriggered,
                  child: Text(
                    'Built for Serious Job Seekers',
                    style: AppTheme.getDisplayFont(
                      fontSize: isDesktop ? 40 : 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                GsapStaggeredReveal(
                  index: 2,
                  isTriggered: _isTriggered,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      'Everything you need to create, optimize, tailor, and track your resume with AI precision and recruiter-tested structure.',
                      style: AppTheme.getBodyFont(
                        fontSize: 15,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Features Grid with Sibling Focus Dimming & 3D Tilt Spotlight
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardWidth = (constraints.maxWidth -
                            (crossAxisCount - 1) * 20) /
                        crossAxisCount;

                    return SpotlightCardGroup(
                      groupId: 'features_section_group',
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(_features.length, (index) {
                          final feat = _features[index];
                          return GsapStaggeredReveal(
                            index: 3 + index,
                            isTriggered: _isTriggered,
                            child: SizedBox(
                              width: cardWidth,
                              child: SpotlightCardTile(
                                id: 'feat_${feat['key']}',
                                hoverScale: 1.02,
                                borderRadius: BorderRadius.circular(20),
                                accentColor: AppTheme.primaryOrange,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getSurfaceColor(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.getBorderColor(context),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withAlpha(50)
                                            : Colors.black.withAlpha(10),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme
                                                  .getPrimaryLightColor(
                                                      context),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme
                                                    .getPrimaryBorderColor(
                                                        context),
                                              ),
                                            ),
                                            child: Icon(
                                              feat['icon'] as IconData,
                                              color: AppTheme.primaryOrange,
                                              size: 24,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withAlpha(15)
                                                  : Colors.black.withAlpha(8),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              feat['badge'] as String,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.getMutedTextColor(
                                                    context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        feat['title'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.getTextColor(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        feat['desc'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          color: AppTheme.getMutedTextColor(
                                              context),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
