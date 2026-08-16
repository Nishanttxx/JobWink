import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AtsScoreGauge extends StatefulWidget {
  final int score;
  final bool isTriggered;
  final bool showProgressBars;

  const AtsScoreGauge({
    super.key,
    this.score = 82,
    this.isTriggered = true,
    this.showProgressBars = true,
  });


  @override
  State<AtsScoreGauge> createState() => _AtsScoreGaugeState();
}

class _AtsScoreGaugeState extends State<AtsScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isTriggered) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AtsScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTriggered != oldWidget.isTriggered) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (widget.isTriggered) {
        if (disableAnimations) {
          _controller.value = 1.0;
        } else {
          _controller.forward(from: 0.0);
        }
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _controller.value != 1.0) {
      _controller.value = 1.0;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedScore = (widget.score * _animation.value).round();
        final progress = (widget.score / 100.0) * _animation.value;
        final trackColor = AppTheme.getTrackColor(context);
        final primaryTextColor = AppTheme.getTextColor(context);
        final mutedTextColor = AppTheme.getMutedTextColor(context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 180-degree Arch Gauge
            SizedBox(
              width: 260,
              height: 160,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  CustomPaint(
                    size: const Size(260, 160),
                    painter: ArchGaugePainter(
                      progress: progress,
                      trackColor: trackColor,
                    ),
                  ),
                  Positioned(
                    top: 55,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrangeLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'EXCELLENT MATCH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryOrange,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$animatedScore',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/100',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Overall ATS Score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.showProgressBars) ...[
              const SizedBox(height: 24),
              // Progress Bars Section
              _buildProgressBar(
                label: 'Keyword Density',
                percentage: 0.88,
                percentageText: '88%',
                animProgress: _animation.value,
                trackColor: trackColor,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              ),
              const SizedBox(height: 12),
              _buildProgressBar(
                label: 'Format Score',
                percentage: 0.95,
                percentageText: '95%',
                animProgress: _animation.value,
                trackColor: trackColor,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              ),
              const SizedBox(height: 12),
              _buildProgressBar(
                label: 'Content Quality',
                percentage: 0.78,
                percentageText: '78%',
                animProgress: _animation.value,
                trackColor: trackColor,
                primaryTextColor: primaryTextColor,
                mutedTextColor: mutedTextColor,
              ),
            ],
          ],
        );

      },
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double percentage,
    required String percentageText,
    required double animProgress,
    required Color trackColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    final currentFill = percentage * animProgress;

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: mutedTextColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 9,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: currentFill.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF8B5E),
                      AppTheme.primaryOrange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withAlpha(50),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            percentageText,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class ArchGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;

  ArchGaugePainter({
    required this.progress,
    this.trackColor = const Color(0xFFEEECE6),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 16);
    final radius = (size.width - 36) / 2;
    const strokeWidth = 18.0;
    const startAngle = math.pi; // 180 degrees (left)
    const totalSweep = math.pi; // 180 degrees (semi-circle top)

    // Background track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, totalSweep, false, trackPaint);

    if (progress > 0) {
      final currentSweep = totalSweep * progress.clamp(0.0, 1.0);

      // Gradient progress arc
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + totalSweep,
        colors: const [
          Color(0xFFFF9A6C),
          AppTheme.primaryOrange,
          Color(0xFFDC4810),
        ],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, startAngle, currentSweep, false, progressPaint);

      // Glowing dot at indicator head
      final dotAngle = startAngle + currentSweep;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);
      final dotOffset = Offset(dotX, dotY);

      // Outer glow
      final glowPaint = Paint()
        ..color = AppTheme.primaryOrange.withAlpha(100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dotOffset, 12, glowPaint);

      // White ring
      final whiteRingPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset, 9, whiteRingPaint);

      // Inner dot center
      final dotCenterPaint = Paint()
        ..color = AppTheme.primaryOrange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotOffset, 5, dotCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArchGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

