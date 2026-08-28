import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';
import 'custom_badge.dart';
import 'spotlight_card.dart';

class StepsSection extends StatefulWidget {
  final VoidCallback? onGetStartedTap;
  const StepsSection({super.key, this.onGetStartedTap});

  @override
  State<StepsSection> createState() => _StepsSectionState();
}

class _StepsSectionState extends State<StepsSection> {
  bool _isTriggered = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'number': '01',
      'title': 'Upload or Create',
      'desc':
          'Import your existing PDF/DOCX resume or build a new profile from scratch using AI guidance.',
      'icon': Icons.cloud_upload_outlined,
    },
    {
      'number': '02',
      'title': 'Add Target Job',
      'desc':
          'Paste any job posting URL or job description text to establish your baseline target requirements.',
      'icon': Icons.description_outlined,
    },
    {
      'number': '03',
      'title': 'Tailor & Optimize',
      'desc':
          'JobWink AI automatically adjusts bullet points, highlights missing skills, and boosts ATS match density.',
      'icon': Icons.auto_fix_high_rounded,
    },
    {
      'number': '04',
      'title': 'Apply & Succeed',
      'desc':
          'Export ATS-verified PDF/DOCX documents and view predictive interview probability analytics.',
      'icon': Icons.verified_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1050;
    final isTablet = screenWidth >= 650 && screenWidth < 1050;
    final isDark = AppTheme.isDarkMode(context);

    int crossAxisCount = 4;
    if (isTablet) crossAxisCount = 2;
    if (!isDesktop && !isTablet) crossAxisCount = 1;

    return GsapScrollTrigger(
      triggerKey: 'steps_section',
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
                    label: 'Simple Workflow',
                    icon: Icons.timeline_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                GsapStaggeredReveal(
                  index: 1,
                  isTriggered: _isTriggered,
                  child: Text(
                    'How JobWink Works',
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
                      '4 simple steps to transform your career materials into ATS-ready job applications.',
                      style: AppTheme.getBodyFont(
                        fontSize: 15,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 56),

                // 4-Step Cards Layout with Spotlight & Sibling Focus Dimming
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardWidth = (constraints.maxWidth -
                            (crossAxisCount - 1) * 20) /
                        crossAxisCount;

                    final accentColors = [
                      AppTheme.primaryOrange,
                      const Color(0xFFF59E0B),
                      const Color(0xFF10B981),
                      const Color(0xFF3B82F6),
                    ];

                    return SpotlightCardGroup(
                      groupId: 'steps_section_group',
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 24,
                        children: List.generate(_steps.length, (index) {
                          final step = _steps[index];
                          final accent = accentColors[index % accentColors.length];

                          return GsapStaggeredReveal(
                            index: 3 + index,
                            isTriggered: _isTriggered,
                            child: SizedBox(
                              width: cardWidth,
                              height: isDesktop ? 235 : (isTablet ? 215 : null),
                              child: SpotlightCardTile(
                                id: 'step_${step['number']}',
                                hoverScale: 1.02,
                                borderRadius: BorderRadius.circular(20),
                                accentColor: accent,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          step['number'] as String,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primaryOrange,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme
                                                .getPrimaryLightColor(context),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            step['icon'] as IconData,
                                            color: AppTheme.primaryOrange,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      step['title'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.getTextColor(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      step['desc'] as String,
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
