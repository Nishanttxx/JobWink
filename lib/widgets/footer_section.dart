import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../animations/gsap_timeline.dart';
import '../config/backend_config.dart';
import '../theme/app_theme.dart';
import 'report_bug_modal.dart';

class FooterSection extends StatefulWidget {
  final Function(String section)? onNavClick;
  const FooterSection({super.key, this.onNavClick});

  @override
  State<FooterSection> createState() => _FooterSectionState();
}

class _FooterSectionState extends State<FooterSection> {
  bool _isTriggered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 850;

    return GsapScrollTrigger(
      triggerKey: 'footer_section',
      onEnter: () => setState(() => _isTriggered = true),
      onLeave: () => setState(() => _isTriggered = false),
      child: Container(
        width: double.infinity,
        color: const Color(0xFF0F1012),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Index 0: Massive Typography "Jobwink"
            GsapStaggeredReveal(
              index: 0,
              isTriggered: _isTriggered,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(
                    'Jobwink',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 90 : 160,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withAlpha(240),
                      letterSpacing: isMobile ? -2 : -4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Divider(color: Color(0xFF22242B), height: 1),

            // Index 1: Bottom Bar Links & Copyright
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1240),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: 36,
                ),
                child: GsapStaggeredReveal(
                  index: 1,
                  isTriggered: _isTriggered,
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFooterBrand(),
                            const SizedBox(height: 24),
                            _buildFooterLinks(isMobile),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildFooterBrand(),
                            Flexible(child: _buildFooterLinks(isMobile)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Jobwink',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Build a Job Winning Resume with AI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textMutedDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '© 2026 Jobwink. All rights reserved.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF636674),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(bool isMobile) {
    final links = [
      {'label': 'Features', 'key': 'features'},
      {'label': 'How it works', 'key': 'steps'},
      {'label': 'Report Bug 🐛', 'key': 'bug'},
      {'label': 'Privacy', 'key': 'privacy'},
    ];

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: links
              .map(
                (l) => MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (l['key'] == 'bug') {
                        ReportBugModal.show(context, routeName: 'LandingPage');
                      } else if (l['key'] == 'privacy') {
                        Navigator.pushNamed(context, '/privacy');
                      } else {
                        widget.onNavClick?.call(l['key']!);
                      }
                    },
                    child: Text(
                      l['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC0C2CE),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mail_outline_rounded,
              color: AppTheme.primaryOrange,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                BackendConfig.adminEmail.isNotEmpty
                    ? BackendConfig.adminEmail
                    : 'contact@jobwink.app',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
