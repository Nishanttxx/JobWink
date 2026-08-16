import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';
import 'custom_badge.dart';
import 'spotlight_card.dart';

class ProductPreviewSection extends StatefulWidget {
  final VoidCallback? onTryPreview;
  const ProductPreviewSection({super.key, this.onTryPreview});

  @override
  State<ProductPreviewSection> createState() => _ProductPreviewSectionState();
}

class _ProductPreviewSectionState extends State<ProductPreviewSection> {
  bool _isTriggered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final isDark = AppTheme.isDarkMode(context);

    return GsapScrollTrigger(
      triggerKey: 'product_preview_section',
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
                // Header
                GsapStaggeredReveal(
                  index: 0,
                  isTriggered: _isTriggered,
                  child: const CustomBadge(
                    label: 'Product Showcase',
                    icon: Icons.dashboard_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                GsapStaggeredReveal(
                  index: 1,
                  isTriggered: _isTriggered,
                  child: Text(
                    'Everything You Need to Build a Better Job Application',
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
                      'Experience modern AI career tools: intelligent resume builder, real-time ATS optimization, job description tailoring, and predictive match analytics.',
                      style: AppTheme.getBodyFont(
                        fontSize: 15,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Large Main Product Card
                GsapStaggeredReveal(
                  index: 3,
                  isTriggered: _isTriggered,
                  child: SpotlightCardTile(
                    hoverScale: 1.01,
                    borderRadius: BorderRadius.circular(24),
                    accentColor: AppTheme.primaryOrange,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.getSurfaceColor(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.getBorderColor(context),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withAlpha(80)
                                : Colors.black.withAlpha(16),
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top Browser Chrome Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF14161C)
                                  : const Color(0xFF0F1012),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(22),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _dot(const Color(0xFFFF5F56)),
                                    const SizedBox(width: 8),
                                    _dot(const Color(0xFFFFBD2E)),
                                    const SizedBox(width: 8),
                                    _dot(const Color(0xFF27C93F)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 13,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'jobwink.com/studio/resume-builder',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryOrange
                                            .withAlpha(40),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 12,
                                            color: AppTheme.primaryOrange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'AI Active',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Main Dashboard Studio Layout
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: isDesktop
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Left Column: Live Analytics & ATS Gauge
                                      Expanded(
                                        flex: 5,
                                        child: _buildStudioAnalytics(context),
                                      ),
                                      const SizedBox(width: 24),
                                      // Right Column: Interactive Resume Canvas
                                      Expanded(
                                        flex: 7,
                                        child: _buildStudioCanvas(context),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildStudioAnalytics(context),
                                      const SizedBox(height: 24),
                                      _buildStudioCanvas(context),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStudioAnalytics(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ATS Readiness Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2027) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.getBorderColor(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ATS Optimization Status',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '94% Ready',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Metrics Breakdown
              _metricRow(context, 'Keyword Density', '96%', const Color(0xFF10B981)),
              const SizedBox(height: 10),
              _metricRow(context, 'Formatting & Layout', '100%', const Color(0xFF10B981)),
              const SizedBox(height: 10),
              _metricRow(context, 'Job Description Alignment', '91%', AppTheme.primaryOrange),
              const SizedBox(height: 10),
              _metricRow(context, 'Action Verb Power', '88%', AppTheme.primaryOrange),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Job Prediction Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.getPrimaryLightColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.getPrimaryBorderColor(context),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Prediction Insight',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'High interview likelihood (89%) for Senior Software Engineer roles.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.getMutedTextColor(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricRow(
      BuildContext context, String title, String percentage, Color color) {
    final double value = (double.tryParse(percentage.replaceAll('%', '')) ?? 0) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
            Text(
              percentage,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppTheme.getBorderColor(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStudioCanvas(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2027) : const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryOrange,
                    child: Text(
                      'NA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nishant Arya',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Targeting: Staff / Lead Engineer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.primaryOrange.withAlpha(60)),
                ),
                child: Text(
                  'AI Tailored',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Experience Snippet
          Text(
            'PROFESSIONAL EXPERIENCE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Senior Full-Stack Engineer — TechCorp Inc.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          _bulletPoint(
            context,
            'Architected microservices infrastructure in Flutter & Supabase, reducing app load latency by 45%.',
            isHighlighted: true,
          ),
          const SizedBox(height: 6),
          _bulletPoint(
            context,
            'Integrated AI tailoring algorithms to extract keywords from raw job descriptions with 98% accuracy.',
          ),
          const SizedBox(height: 14),

          // GitHub Project Highlight
          Text(
            'FEATURED GITHUB PROJECT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14161C) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded,
                    color: AppTheme.primaryOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nishanttxx/Jobwink',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Auto-summarized from README into ATS bullet points',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF10B981), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(BuildContext context, String text,
      {bool isHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppTheme.primaryOrange
                : AppTheme.getMutedTextColor(context),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
              color: isHighlighted
                  ? AppTheme.getTextColor(context)
                  : AppTheme.getMutedTextColor(context),
            ),
          ),
        ),
      ],
    );
  }
}
