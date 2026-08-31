import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A polished, lightweight initial website loading / splash screen for JobWink.
///
/// Displays the centered JobWink logo with a smooth GPU-friendly
/// fade-and-scale entrance animation, dark background, and subtle orange loading indicator.
class JobwinkLoadingScreen extends StatefulWidget {
  const JobwinkLoadingScreen({super.key});

  @override
  State<JobwinkLoadingScreen> createState() => _JobwinkLoadingScreenState();
}

class _JobwinkLoadingScreenState extends State<JobwinkLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final bgColor = isDark ? const Color(0xFF08090C) : const Color(0xFF0B0D13);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double logoSize = isMobile ? 76.0 : 96.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Central JobWink Logo with rounded container & subtle orange ambient glow
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.18),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                    child: Image.asset(
                      'assets/images/jobwink_logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(isMobile ? 18 : 22),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryOrange,
                            size: 36,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Brand Name
                Text(
                  'JobWink',
                  style: GoogleFonts.syne(
                    fontSize: isMobile ? 20 : 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Minimal Subtle Loading Indicator
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    strokeCap: StrokeCap.round,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                    backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
