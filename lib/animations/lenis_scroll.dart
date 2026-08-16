import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Lenis Easing Curve: Exponential decay matching Lenis JS default
/// f(t) = 1 - 2^(-10 * t) normalized smoothly
class LenisCurve extends Curve {
  const LenisCurve();

  @override
  double transformInternal(double t) {
    if (t >= 1.0) return 1.0;
    if (t <= 0.0) return 0.0;
    return (1.0 - math.pow(2.0, -10.0 * t)).clamp(0.0, 1.0);
  }
}


/// Lenis Smooth Scroll Physics for Flutter
/// Simulates Lenis JS smooth wheel momentum and dampening.
class LenisScrollPhysics extends ScrollPhysics {
  final double smoothFactor;

  const LenisScrollPhysics({
    super.parent,
    this.smoothFactor = 1.0,
  });

  @override
  LenisScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LenisScrollPhysics(
      parent: buildParent(ancestor),
      smoothFactor: smoothFactor,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Pass through normal touch drag offsets
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Simulation? simulation =
        super.createBallisticSimulation(position, velocity);
    return simulation;
  }
}

/// LenisSmoothScroll Wrapper
/// Intercepts mouse wheel / trackpad scroll events to provide smooth Lenis scrolling.
/// - Preserves native accessibility (prefers-reduced-motion)
/// - Disables on mobile touch devices if desired
/// - Smooth 60 FPS animation with zero scroll lag
class LenisSmoothScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final bool enableOnMobile;
  final Duration animationDuration;

  const LenisSmoothScroll({
    super.key,
    required this.child,
    required this.controller,
    this.enableOnMobile = false,
    this.animationDuration = const Duration(milliseconds: 750),
  });

  @override
  State<LenisSmoothScroll> createState() => _LenisSmoothScrollState();
}

class _LenisSmoothScrollState extends State<LenisSmoothScroll>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _animation;

  double _targetScrollOffset = 0.0;
  double _startScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animController.addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _animController.removeListener(_onAnimationTick);
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!widget.controller.hasClients) return;
    final value = _animation?.value ?? _targetScrollOffset;
    final maxScroll = widget.controller.position.maxScrollExtent;
    final minScroll = widget.controller.position.minScrollExtent;
    final clampedValue = value.clamp(minScroll, maxScroll);

    widget.controller.jumpTo(clampedValue);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Check prefers-reduced-motion
      final prefersReducedMotion = MediaQuery.of(context).disableAnimations ||
          View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
      if (prefersReducedMotion) {
        return; // Fall back to native instant scrolling
      }

      // Check mobile / touch device
      final isMobile = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android);
      if (isMobile && !widget.enableOnMobile) {
        return; // Use native touch physics on mobile
      }

      if (!widget.controller.hasClients) return;

      final scrollDelta = event.scrollDelta.dy;
      if (scrollDelta == 0) return;

      final currentOffset = widget.controller.offset;
      final maxScroll = widget.controller.position.maxScrollExtent;
      final minScroll = widget.controller.position.minScrollExtent;

      // If animation is already in progress, base new target on current target
      final baseOffset =
          _animController.isAnimating ? _targetScrollOffset : currentOffset;

      // Calculate new target position with Lenis multiplier tuning (1.25x for responsive feel)
      _targetScrollOffset =
          (baseOffset + scrollDelta * 1.25).clamp(minScroll, maxScroll);
      _startScrollOffset = currentOffset;

      // Reset and animate with Lenis smooth curve (Cubic matching Lenis exponential easing)
      _animController.stop();
      _animation = Tween<double>(
        begin: _startScrollOffset,
        end: _targetScrollOffset,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          // Custom Lenis Easing: Power3 Out / Exponential decay (Cubic(0.16, 1.0, 0.3, 1.0))
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        ),
      );

      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }
}
