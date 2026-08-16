import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Inherited scope to manage group hover focus state (sibling card dimming).
class SpotlightCardGroup extends StatefulWidget {
  final Widget child;
  final String? groupId;

  const SpotlightCardGroup({
    super.key,
    required this.child,
    this.groupId,
  });

  static SpotlightCardGroupState? of(BuildContext context) {
    return context.findAncestorStateOfType<SpotlightCardGroupState>();
  }

  @override
  State<SpotlightCardGroup> createState() => SpotlightCardGroupState();
}

class SpotlightCardGroupState extends State<SpotlightCardGroup> {
  String? _hoveredCardId;

  String? get hoveredCardId => _hoveredCardId;

  void setHoveredCard(String? cardId) {
    if (_hoveredCardId != cardId) {
      setState(() {
        _hoveredCardId = cardId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SpotlightGroupScope(
      state: this,
      hoveredCardId: _hoveredCardId,
      child: widget.child,
    );
  }
}

class _SpotlightGroupScope extends InheritedWidget {
  final SpotlightCardGroupState state;
  final String? hoveredCardId;

  const _SpotlightGroupScope({
    required this.state,
    required this.hoveredCardId,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SpotlightGroupScope oldWidget) {
    return hoveredCardId != oldWidget.hoveredCardId;
  }
}

/// Advanced interactive Spotlight Card widget providing:
/// - Magnetic 3D tilt based on mouse position
/// - Smooth spring rotation & dampening
/// - Cursor-following radial spotlight glow
/// - Subtle shimmer sweep
/// - Bottom accent line animation
/// - Sibling focus-dimming (when enclosed in [SpotlightCardGroup])
/// - Accessibility reduced motion support
class SpotlightCardTile extends StatefulWidget {
  final Widget child;
  final String? id;
  final Color? accentColor;
  final double maxTiltAngle; // radians
  final double hoverScale;
  final BorderRadius? borderRadius;
  final bool enableTilt;
  final bool enableSpotlight;
  final bool enableShimmer;
  final bool enableAccentLine;
  final Duration duration;
  final VoidCallback? onTap;

  const SpotlightCardTile({
    super.key,
    required this.child,
    this.id,
    this.accentColor,
    this.maxTiltAngle = 0.08, // ~4.5 degrees
    this.hoverScale = 1.02,
    this.borderRadius,
    this.enableTilt = true,
    this.enableSpotlight = true,
    this.enableShimmer = true,
    this.enableAccentLine = true,
    this.duration = const Duration(milliseconds: 250),
    this.onTap,
  });

  @override
  State<SpotlightCardTile> createState() => _SpotlightCardTileState();
}

class _SpotlightCardTileState extends State<SpotlightCardTile>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _tiltController;

  bool _isHovered = false;
  Offset _localPointer = Offset.zero;
  Size _cardSize = Size.zero;

  // Normalized tilt factors (-1.0 to 1.0)
  double _normX = 0.0;
  double _normY = 0.0;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _tiltController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    if (_cardSize == Size.zero) return;

    final local = event.localPosition;
    final centerX = _cardSize.width / 2;
    final centerY = _cardSize.height / 2;

    final normX = ((local.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final normY = ((local.dy - centerY) / centerY).clamp(-1.0, 1.0);

    setState(() {
      _localPointer = local;
      _normX = normX;
      _normY = normY;
    });
  }

  void _onEnter(PointerEvent event) {
    final group = SpotlightCardGroup.of(context);
    group?.setHoveredCard(widget.id ?? hashCode.toString());

    setState(() {
      _isHovered = true;
    });

    if (widget.enableShimmer) {
      _shimmerController.repeat();
    }
  }

  void _onExit(PointerEvent event) {
    final group = SpotlightCardGroup.of(context);
    if (group?.hoveredCardId == (widget.id ?? hashCode.toString())) {
      group?.setHoveredCard(null);
    }

    setState(() {
      _isHovered = false;
      _normX = 0.0;
      _normY = 0.0;
    });

    if (widget.enableShimmer) {
      _shimmerController.stop();
      _shimmerController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isDark = AppTheme.isDarkMode(context);
    final primaryAccent = widget.accentColor ?? AppTheme.primaryOrange;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20);

    // Group focus dimming logic
    final groupState = SpotlightCardGroup.of(context);
    final hoveredCardId = groupState?.hoveredCardId;
    final currentCardId = widget.id ?? hashCode.toString();
    final bool isSiblingHovered =
        hoveredCardId != null && hoveredCardId != currentCardId;

    // Calculate scale and opacity based on hover & sibling status
    double targetScale = 1.0;
    double targetOpacity = 1.0;

    if (!reduceMotion) {
      if (_isHovered) {
        targetScale = widget.hoverScale;
        targetOpacity = 1.0;
      } else if (isSiblingHovered) {
        targetScale = 0.985;
        targetOpacity = 0.78;
      }
    }

    // 3D Transform Matrix
    final Matrix4 tiltMatrix = Matrix4.identity();
    if (!reduceMotion && widget.enableTilt && _isHovered) {
      tiltMatrix.setEntry(3, 2, 0.0012); // Perspective
      tiltMatrix.rotateX(-_normY * widget.maxTiltAngle);
      tiltMatrix.rotateY(_normX * widget.maxTiltAngle);
    }

    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        opacity: targetOpacity,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          scale: targetScale,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: _onEnter,
            onHover: _onHover,
            onExit: _onExit,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: tiltMatrix,
                transformAlignment: Alignment.center,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _cardSize = Size(constraints.maxWidth, constraints.maxHeight);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Card Content
                        widget.child,

                        // Cursor Spotlight Glow Overlay
                        if (widget.enableSpotlight && _isHovered && !reduceMotion)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: effectiveRadius,
                                child: AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: _SpotlightPainter(
                                        pointer: _localPointer,
                                        accentColor: primaryAccent,
                                        isDark: isDark,
                                        shimmerProgress:
                                            _shimmerController.value,
                                        enableShimmer: widget.enableShimmer,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                        // Animated Bottom Accent Line
                        if (widget.enableAccentLine)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                height: _isHovered ? 3.0 : 0.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: effectiveRadius.bottomLeft,
                                    bottomRight: effectiveRadius.bottomRight,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryAccent.withAlpha(20),
                                      primaryAccent,
                                      primaryAccent.withAlpha(20),
                                    ],
                                  ),
                                  boxShadow: _isHovered
                                      ? [
                                          BoxShadow(
                                            color: primaryAccent.withAlpha(120),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for Cursor Radial Spotlight Glow & Diagonal Shimmer Sweep
class _SpotlightPainter extends CustomPainter {
  final Offset pointer;
  final Color accentColor;
  final bool isDark;
  final double shimmerProgress;
  final bool enableShimmer;

  _SpotlightPainter({
    required this.pointer,
    required this.accentColor,
    required this.isDark,
    required this.shimmerProgress,
    required this.enableShimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Radial Cursor Spotlight Glow
    final Rect rect = Offset.zero & size;

    final Paint spotlightPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (pointer.dx / size.width) * 2 - 1,
          (pointer.dy / size.height) * 2 - 1,
        ),
        radius: 0.8,
        colors: [
          accentColor.withAlpha(isDark ? 45 : 30),
          accentColor.withAlpha(isDark ? 15 : 8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, spotlightPaint);

    // 2. Hover Border Glow
    final Paint borderPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (pointer.dx / size.width) * 2 - 1,
          (pointer.dy / size.height) * 2 - 1,
        ),
        radius: 0.6,
        colors: [
          accentColor.withAlpha(isDark ? 160 : 120),
          accentColor.withAlpha(30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRect(rect, borderPaint);

    // 3. Subtle Shimmer Sweep
    if (enableShimmer && shimmerProgress > 0) {
      final double shimmerWidth = size.width * 0.4;
      final double translateX =
          (size.width + shimmerWidth * 2) * shimmerProgress - shimmerWidth;

      final Paint shimmerPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Colors.white.withAlpha(isDark ? 25 : 40),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(translateX, 0, shimmerWidth, size.height));

      canvas.drawRect(rect, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return pointer != oldDelegate.pointer ||
        shimmerProgress != oldDelegate.shimmerProgress ||
        isDark != oldDelegate.isDark;
  }
}
