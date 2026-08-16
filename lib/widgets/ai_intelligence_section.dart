import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';
import 'custom_badge.dart';
import 'spotlight_card.dart';

class AiIntelligenceSection extends StatefulWidget {
  final VoidCallback? onTryTailoring;
  const AiIntelligenceSection({super.key, this.onTryTailoring});

  @override
  State<AiIntelligenceSection> createState() => _AiIntelligenceSectionState();
}

class _AiIntelligenceSectionState extends State<AiIntelligenceSection> {
  bool _isTriggered = false;
  int _activeTab = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.tune_rounded,
      'title': 'Job Tailoring & Skill Gap Detection',
      'desc':
          'Upload target job descriptions to instantly identify missing skills, keywords, and qualifications.',
    },
    {
      'icon': Icons.code_rounded,
      'title': 'GitHub Project Auto-Import',
      'desc':
          'Connect repository URLs to automatically summarize README tech stacks into quantified resume bullet points.',
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'Role Match & Prediction Analytics',
      'desc':
          'Leverage ML probability models to estimate your shortlist likelihood for targeted tech roles.',
    },
    {
      'icon': Icons.auto_fix_high_rounded,
      'title': 'Contextual Rewriting & Formatting',
      'desc':
          'Transform passive statements into high-impact action bullets with metric-driven accomplishments.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;

    return GsapScrollTrigger(
      triggerKey: 'ai_intelligence_section',
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
                // Section Header
                GsapStaggeredReveal(
                  index: 0,
                  isTriggered: _isTriggered,
                  child: const CustomBadge(
                    label: 'AI Core Engine',
                    icon: Icons.psychology_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                GsapStaggeredReveal(
                  index: 1,
                  isTriggered: _isTriggered,
                  child: Text(
                    'Your Resume, Optimized for the Job',
                    style: GoogleFonts.plusJakartaSans(
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
                      'JobWink bridges the gap between your real experience and recruiter expectations with intelligent parsing and real-time tailoring.',
                      style: AppTheme.getBodyFont(
                        fontSize: 15,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Split Layout
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Side: Feature Items List
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: List.generate(_features.length, (idx) {
                                final feat = _features[idx];
                                final isSelected = _activeTab == idx;
                                return GsapStaggeredReveal(
                                  index: 3 + idx,
                                  isTriggered: _isTriggered,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: HoverCardTile(
                                      hoverScale: 1.01,
                                      borderRadius: BorderRadius.circular(16),
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _activeTab = idx),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.getPrimaryLightColor(
                                                    context)
                                                : AppTheme.getSurfaceColor(
                                                    context),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.primaryOrange
                                                  : AppTheme.getBorderColor(
                                                      context),
                                              width: isSelected ? 1.8 : 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                    10),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? AppTheme.primaryOrange
                                                      : AppTheme
                                                          .getPrimaryLightColor(
                                                              context),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                ),
                                                child: Icon(
                                                  feat['icon'] as IconData,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppTheme.primaryOrange,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      feat['title'] as String,
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppTheme
                                                            .getTextColor(
                                                                context),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      feat['desc'] as String,
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontSize: 13,
                                                        color: AppTheme
                                                            .getMutedTextColor(
                                                                context),
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 40),

                          // Right Side: Interactive AI Showcase Card
                          Expanded(
                            flex: 6,
                            child: GsapStaggeredReveal(
                              index: 7,
                              isTriggered: _isTriggered,
                              initialOffset: const Offset(30, 0),
                              child: SpotlightCardTile(
                                hoverScale: 1.01,
                                borderRadius: BorderRadius.circular(20),
                                accentColor: AppTheme.primaryOrange,
                                child: _buildInteractiveShowcase(context),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          ...List.generate(_features.length, (idx) {
                            final feat = _features[idx];
                            final isSelected = _activeTab == idx;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: GestureDetector(
                                onTap: () => setState(() => _activeTab = idx),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.getPrimaryLightColor(context)
                                        : AppTheme.getSurfaceColor(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryOrange
                                          : AppTheme.getBorderColor(context),
                                      width: isSelected ? 1.8 : 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        feat['icon'] as IconData,
                                        color: AppTheme.primaryOrange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feat['title'] as String,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.getTextColor(
                                                context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                          _buildInteractiveShowcase(context),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveShowcase(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Container(
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
                ? Colors.black.withAlpha(60)
                : Colors.black.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _features[_activeTab]['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live Preview',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Tab-specific Interactive Display
          if (_activeTab == 0) _buildTailoringPreview(context),
          if (_activeTab == 1) _buildGithubImportPreview(context),
          if (_activeTab == 2) _buildPredictionPreview(context),
          if (_activeTab == 3) _buildRewritingPreview(context),
        ],
      ),
    );
  }

  Widget _buildTailoringPreview(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Job Posting:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14161C) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '"Looking for a Lead Flutter & Dart Developer with experience in State Management (Provider/Riverpod), Supabase backend, and CI/CD pipelines."',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppTheme.getMutedTextColor(context),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AI Suggested Enhancements:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 8),
        _skillPill(context, 'Flutter / Dart Architecture', true),
        const SizedBox(height: 6),
        _skillPill(context, 'Supabase RLS & Auth Integration', true),
        const SizedBox(height: 6),
        _skillPill(context, 'CI/CD Automated Testing Pipeline', true),
      ],
    );
  }

  Widget _buildGithubImportPreview(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link_rounded, color: AppTheme.primaryOrange, size: 16),
            const SizedBox(width: 6),
            Text(
              'https://github.com/Nishanttxx/Jobwink',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14161C) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Extracted Resume Bullet Point:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Developed JobWink AI career platform in Flutter Web & Supabase, incorporating multi-provider LLM failover and dynamic ATS score evaluation.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.4,
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hiring Probability Score',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.getTextColor(context),
              ),
            ),
            Text(
              '89%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.89,
            minHeight: 8,
            backgroundColor: AppTheme.getBorderColor(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Top Matching Factors:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        _factorRow(context, 'Core Skills Match', 'High (94%)'),
        const SizedBox(height: 6),
        _factorRow(context, 'Experience Relevance', 'Strong (86%)'),
        const SizedBox(height: 6),
        _factorRow(context, 'Education & Certs', 'Matched'),
      ],
    );
  }

  Widget _buildRewritingPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before (Weak):',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '"Worked on building the user interface and fixed bugs in Flutter app."',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.getMutedTextColor(context),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'After JobWink AI (High Impact):',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
          ),
          child: Text(
            '"Engineered 12+ responsive Flutter web components and optimized state pipeline, improving app rendering speed by 35% across all viewports."',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _skillPill(BuildContext context, String text, bool isMatched) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryLightColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.getPrimaryBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factorRow(BuildContext context, String label, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.getMutedTextColor(context),
          ),
        ),
        Text(
          status,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextColor(context),
          ),
        ),
      ],
    );
  }
}
