import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../animations/gsap_timeline.dart';

class LogoCloud extends StatefulWidget {
  const LogoCloud({super.key});

  @override
  State<LogoCloud> createState() => _LogoCloudState();
}

class _LogoCloudState extends State<LogoCloud> {
  bool _isTriggered = false;

  @override
  Widget build(BuildContext context) {
    final logos = [
      'Indeed',
      'Naukri.com',
      'Wellfound',
      'LinkedIn',
      'Glassdoor',
      'Monster',
      'ZipRecruiter',
      'Foundit',
      'SimplyHired',
      'FlexJobs',
      'CareerBuilder',
      'Hired',
    ];

    final logoColor = AppTheme.isDarkMode(context)
        ? const Color(0xFFE4E4E7)
        : const Color(0xFF2C2D30);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: GsapScrollTrigger(
          triggerKey: 'logo_cloud',
          onEnter: () => setState(() => _isTriggered = true),
          onLeave: () => setState(() => _isTriggered = false),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1240),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                GsapStaggeredReveal(
                  index: 0,
                  isTriggered: _isTriggered,
                  child: Text(
                    'Optimized for top hiring platforms & job portals',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getMutedTextColor(context),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Horizontal Moving Infinite Marquee Animation
                GsapStaggeredReveal(
                  index: 1,
                  isTriggered: _isTriggered,
                  child: SizedBox(
                    height: 50,
                    child: InfiniteLogoMarquee(
                      logos: logos,
                      itemBuilder: (logo) => _buildLogoItem(logo, logoColor),
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

  Widget _buildLogoItem(String name, Color logoColor) {
    TextStyle logoStyle;
    switch (name) {
      case 'Indeed':
        logoStyle = GoogleFonts.inter(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: logoColor,
        );
        break;
      case 'Naukri.com':
        logoStyle = GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: logoColor,
        );
        break;
      case 'Wellfound':
        logoStyle = GoogleFonts.outfit(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: logoColor,
        );
        break;
      case 'LinkedIn':
        logoStyle = GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: logoColor,
        );
        break;
      case 'Glassdoor':
        logoStyle = GoogleFonts.lexend(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: logoColor,
        );
        break;
      case 'Monster':
        logoStyle = GoogleFonts.bebasNeue(
          fontSize: 25,
          letterSpacing: 1.2,
          color: logoColor,
        );
        break;
      case 'ZipRecruiter':
        logoStyle = GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: logoColor,
        );
        break;
      case 'Foundit':
        logoStyle = GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: logoColor,
        );
        break;
      case 'SimplyHired':
        logoStyle = GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: logoColor,
        );
        break;
      case 'FlexJobs':
        logoStyle = GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: logoColor,
        );
        break;
      case 'CareerBuilder':
        logoStyle = GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: logoColor,
        );
        break;
      case 'Hired':
        logoStyle = GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: logoColor,
        );
        break;
      default:
        logoStyle = GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: logoColor,
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: 0.85,
          child: Text(name, style: logoStyle),
        ),
      ),
    );
  }
}

class InfiniteLogoMarquee extends StatefulWidget {
  final List<String> logos;
  final Widget Function(String name) itemBuilder;
  final double speed; // Pixels per frame (~30-40 px/sec)

  const InfiniteLogoMarquee({
    super.key,
    required this.logos,
    required this.itemBuilder,
    this.speed = 35.0,
  });

  @override
  State<InfiniteLogoMarquee> createState() => _InfiniteLogoMarqueeState();
}

class _InfiniteLogoMarqueeState extends State<InfiniteLogoMarquee>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animController;
  bool _isHovered = false;

  late final List<String> _repeatedLogos;

  @override
  void initState() {
    super.initState();
    _repeatedLogos = [
      ...widget.logos,
      ...widget.logos,
      ...widget.logos,
      ...widget.logos,
    ];
    _scrollController = ScrollController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animController.repeat();
      }
    });
  }

  void _onTick() {
    if (_isHovered || !mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final totalWidth = maxScroll + _scrollController.position.viewportDimension;
    final singleSetWidth = totalWidth / 4;

    double nextOffset = _scrollController.offset + (widget.speed / 60.0);
    if (nextOffset >= singleSetWidth) {
      nextOffset = nextOffset % singleSetWidth;
    }

    _scrollController.jumpTo(nextOffset);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _isHovered = true,
        onExit: (_) => _isHovered = false,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.08, 0.92, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _repeatedLogos.map((logo) => widget.itemBuilder(logo)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

