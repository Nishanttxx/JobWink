import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';
import 'custom_badge.dart';
import 'shuffle.dart';
import 'spotlight_card.dart';

class HeroSection extends StatefulWidget {
  final VoidCallback? onStartFreeTap;
  final VoidCallback? onSeeHowItWorksTap;

  const HeroSection({
    super.key,
    this.onStartFreeTap,
    this.onSeeHowItWorksTap,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  bool _isTriggered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final isTablet = screenWidth >= 650 && screenWidth < 980;
    final isDark = AppTheme.isDarkMode(context);

    return GsapScrollTrigger(
      triggerKey: 'hero_section',
      onEnter: () => setState(() => _isTriggered = true),
      onLeave: () => setState(() => _isTriggered = false),
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          children: [

            // Background Radial Glow Effect
            Positioned(
              top: -100,
              child: Container(
                width: 600,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryOrange
                          .withAlpha(isDark ? 50 : 30),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),

            // Hero Main Content
            Container(
              constraints: const BoxConstraints(maxWidth: 1240),
              padding: EdgeInsets.only(
                top: isDesktop ? 70 : 40,
                bottom: isDesktop ? 80 : 50,
                left: isDesktop ? 32 : 20,
                right: isDesktop ? 32 : 20,
              ),
              child: Column(
                children: [
                  // Eyebrow Pill
                  GsapStaggeredReveal(
                    index: 0,
                    isTriggered: _isTriggered,
                    child: const CustomBadge(
                      label: 'AI-POWERED CAREER PLATFORM',
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Headline
                  GsapStaggeredReveal(
                    index: 1,
                    isTriggered: _isTriggered,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Shuffle(
                        text: 'Build a Resume That Gets You Hired.',
                        style: GoogleFonts.syne(
                          fontSize: isDesktop
                              ? 58
                              : (isTablet ? 42 : 32),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          height: 1.1,
                          color: AppTheme.getTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                        triggerOnHover: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtitle Description
                  GsapStaggeredReveal(
                    index: 2,
                    isTriggered: _isTriggered,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Text(
                        'Create, tailor, analyze, and optimize your resume with AI — then discover how well your profile matches the jobs you\'re targeting.',
                        style: AppTheme.getBodyFont(
                          fontSize: isDesktop ? 18 : 15,
                          height: 1.5,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Call to Action Buttons
                  GsapStaggeredReveal(
                    index: 3,
                    isTriggered: _isTriggered,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        // Primary CTA: Build My Resume
                        ElevatedButton(
                          onPressed: widget.onStartFreeTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 32 : 24,
                              vertical: isDesktop ? 18 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Build My Resume',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isDesktop ? 16 : 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),

                        // Secondary CTA: See How It Works
                        OutlinedButton(
                          onPressed: widget.onSeeHowItWorksTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.getTextColor(context),
                            side: BorderSide(
                              color: AppTheme.getBorderColor(context),
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 28 : 22,
                              vertical: isDesktop ? 18 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'See How It Works',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isDesktop ? 16 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Trust Indicator Pills
                  GsapStaggeredReveal(
                    index: 4,
                    isTriggered: _isTriggered,
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _trustBadge(context, Icons.check_circle_outline,
                            'Instant AI Parsing'),
                        _trustBadge(context, Icons.security_rounded,
                            'No Credit Card Required'),
                        _trustBadge(context, Icons.speed_rounded,
                            '98% ATS Compliance'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Hero Visual Showcase Card
                  GsapStaggeredReveal(
                    index: 5,
                    isTriggered: _isTriggered,
                    child: SpotlightCardTile(
                      hoverScale: 1.01,
                      borderRadius: BorderRadius.circular(24),
                      accentColor: AppTheme.primaryOrange,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1060),
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
                                  ? Colors.black.withAlpha(90)
                                  : Colors.black.withAlpha(20),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Mock App Bar Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFFF5F56),
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFFFBD2E),
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: Color(0xFF27C93F),
                                            shape: BoxShape.circle),
                                      ),
                                    ],
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        'JobWink Studio — Interactive Resume & ATS Match Engine',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryOrange.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'LIVE DEMO',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Hero Visual Layout Body
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: isDesktop
                                  ? Row(
                                      children: [
                                        Expanded(
                                            flex: 6,
                                            child:
                                                _buildHeroResumePreview(context)),
                                        const SizedBox(width: 24),
                                        Expanded(
                                            flex: 5,
                                            child:
                                                _buildHeroAtsCard(context)),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildHeroResumePreview(context),
                                        const SizedBox(height: 20),
                                        _buildHeroAtsCard(context),
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
          ],
        ),
      ),
    );
  }

  Widget _trustBadge(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.primaryOrange),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.getMutedTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroResumePreview(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2027) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'ALEXANDER WRIGHT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ATS Verified',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Senior Full-Stack Engineer | Flutter & Cloud Solutions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Text(
            'KEY HIGHLIGHTS & IMPACT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          _bullet(
            context,
            'Engineered high-throughput microservices reducing API latency by 42%.',
          ),
          const SizedBox(height: 6),
          _bullet(
            context,
            'Led cross-functional team of 8 engineers delivering enterprise Flutter web suite on schedule.',
          ),
          const SizedBox(height: 6),
          _bullet(
            context,
            'Automated GitHub CI/CD workflows, cutting deployment cycles from 2 hours to 12 minutes.',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAtsCard(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryLightColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getPrimaryBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Job Match & ATS Rating',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '95% Match',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Matched Role: Senior Lead Engineer',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.95,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(20),
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag(context, 'Flutter', true),
              _tag(context, 'Dart', true),
              _tag(context, 'Supabase', true),
              _tag(context, 'REST API', true),
              _tag(context, 'CI/CD', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.check_circle_rounded,
              size: 14, color: AppTheme.primaryOrange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.getTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(BuildContext context, String label, bool matched) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextColor(context),
        ),
      ),
    );
  }
}
