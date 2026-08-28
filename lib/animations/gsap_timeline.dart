import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Custom Easing curves inspired by GSAP
class GsapEasings {
  /// Equivalent to GSAP's power3.out - Apple / Linear signature easing curve
  static const Cubic power3Out = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Equivalent to GSAP's power4.out - Ultra smooth heavy deceleration
  static const Cubic power4Out = Cubic(0.25, 1.0, 0.5, 1.0);

  /// Equivalent to GSAP's expo.out - Fast acceleration, long smooth landing
  static const Cubic expoOut = Cubic(0.19, 1.0, 0.22, 1.0);
}

/// A ScrollTrigger wrapper that triggers animations when entering the viewport.
class GsapScrollTrigger extends StatefulWidget {
  final Widget child;
  final String triggerKey;
  final double visibilityThreshold;
  final VoidCallback? onEnter;
  final VoidCallback? onLeave;
  final bool triggerOnce;

  const GsapScrollTrigger({
    super.key,
    required this.child,
    required this.triggerKey,
    this.visibilityThreshold = 0.12,
    this.onEnter,
    this.onLeave,
    this.triggerOnce = true,
  });

  @override
  State<GsapScrollTrigger> createState() => _GsapScrollTriggerState();
}

class _GsapScrollTriggerState extends State<GsapScrollTrigger> {
  bool _hasTriggered = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('gsap_trigger_${widget.triggerKey}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.visibilityThreshold) {
          if (!_hasTriggered) {
            if (mounted) {
              setState(() {
                _hasTriggered = true;
              });
              widget.onEnter?.call();
            }
          }
        } else if (info.visibleFraction == 0.0 || info.visibleFraction < 0.05) {
          if (_hasTriggered && !widget.triggerOnce) {
            if (mounted) {
              setState(() {
                _hasTriggered = false;
              });
              widget.onLeave?.call();
            }
          }
        }
      },
      child: widget.child,
    );
  }
}

/// Staggered Reveal Animation Component powered by GSAP-style timelines
class GsapStaggeredReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int totalItems;
  final Duration duration;
  final Duration baseDelay;
  final Duration staggerDelay;
  final Offset initialOffset;
  final bool isTriggered;
  final Curve curve;

  const GsapStaggeredReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.totalItems = 1,
    this.duration = const Duration(milliseconds: 650),
    this.baseDelay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 90),
    this.initialOffset = const Offset(0, 24),
    this.isTriggered = true,
    this.curve = GsapEasings.power3Out,
  });

  @override
  State<GsapStaggeredReveal> createState() => _GsapStaggeredRevealState();
}

class _GsapStaggeredRevealState extends State<GsapStaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _translation;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _translation = Tween<Offset>(
      begin: widget.initialOffset,
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(curved);

    if (widget.isTriggered) {
      _startTimeline();
    }
  }

  @override
  void didUpdateWidget(GsapStaggeredReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTriggered && widget.isTriggered) {
      _startTimeline();
    } else if (oldWidget.isTriggered && !widget.isTriggered) {
      _resetTimeline();
    }
  }

  void _startTimeline() {
    final totalDelay =
        widget.baseDelay + (widget.staggerDelay * widget.index);
    Future.delayed(totalDelay, () {
      if (mounted && widget.isTriggered) {
        _controller.forward(from: 0.0);
      }
    });
  }

  void _resetTimeline() {
    if (mounted) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect prefers-reduced-motion
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          if (_controller.isCompleted) {
            return child!;
          }
          return Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: _translation.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Interactive Card Hover Component providing subtle scaling (1.02-1.03x)
/// and elevation shadow transition over 200-300ms ease-out.
class HoverCardTile extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final Duration duration;
  final Curve curve;
  final List<BoxShadow>? hoverShadow;
  final BorderRadius? borderRadius;

  const HoverCardTile({
    super.key,
    required this.child,
    this.hoverScale = 1.025,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    this.hoverShadow,
    this.borderRadius,
  });

  @override
  State<HoverCardTile> createState() => _HoverCardTileState();
}

class _HoverCardTileState extends State<HoverCardTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (mounted && !_isHovered) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted && _isHovered) setState(() => _isHovered = false);
        },
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          transform: Matrix4.diagonal3Values(
            reduceMotion || !_isHovered ? 1.0 : widget.hoverScale,
            reduceMotion || !_isHovered ? 1.0 : widget.hoverScale,
            1.0,
          ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
            boxShadow: _isHovered
                ? (widget.hoverShadow ?? [
                    BoxShadow(
                      color: Colors.black.withAlpha(24),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ])
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
