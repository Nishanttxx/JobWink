import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';

/// React Bits-equivalent Shuffle text animation widget for Flutter.
/// Provides high-performance character-shuffling / matrix scramble animation
/// triggered on viewport entry and hover, optimized for zero layout thrashing.
class Shuffle extends StatefulWidget {
  final String text;
  final String shuffleDirection; // "right" or "left"
  final double duration; // Duration in seconds per character shuffle
  final String animationMode; // "evenodd", "random", or "linear"
  final int shuffleTimes; // Number of scramble cycles per character
  final String ease; // "power3.out"
  final double stagger; // Stagger delay in seconds per character
  final double threshold; // Visibility threshold (0.0 to 1.0)
  final bool triggerOnce;
  final bool triggerOnHover;
  final bool respectReducedMotion;

  // Typography & Styling
  final TextStyle? style;
  final TextAlign textAlign;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const Shuffle({
    super.key,
    required this.text,
    this.shuffleDirection = "right",
    this.duration = 0.35,
    this.animationMode = "evenodd",
    this.shuffleTimes = 1,
    this.ease = "power3.out",
    this.stagger = 0.03,
    this.threshold = 0.1,
    this.triggerOnce = true,
    this.triggerOnHover = true,
    this.respectReducedMotion = true,
    this.style,
    this.textAlign = TextAlign.center,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  @override
  State<Shuffle> createState() => _ShuffleState();
}

class _ShuffleState extends State<Shuffle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasTriggered = false;
  final Random _random = Random();

  static const String _scrambleChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _calculateTotalDuration(),
    );
  }

  @override
  void didUpdateWidget(Shuffle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.duration != widget.duration ||
        oldWidget.stagger != widget.stagger ||
        oldWidget.style != widget.style ||
        oldWidget.fontSize != widget.fontSize) {
      _controller.duration = _calculateTotalDuration();
      if (_hasTriggered) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _calculateTotalDuration() {
    final charCount = widget.text.replaceAll('\n', '').length;
    final totalStagger = (charCount > 0 ? charCount - 1 : 0) * widget.stagger;
    final totalSeconds = totalStagger + widget.duration + 0.1;
    return Duration(milliseconds: (totalSeconds * 1000).round());
  }

  void _triggerAnimation() {
    if (widget.respectReducedMotion &&
        MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
      return;
    }
    _controller.forward(from: 0.0);
  }

  double _getCharDelay(int index, int totalChars) {
    int effectiveIndex = index;
    if (widget.shuffleDirection == "left") {
      effectiveIndex = totalChars - 1 - index;
    }

    if (widget.animationMode == "evenodd") {
      final isEven = effectiveIndex % 2 == 0;
      final groupIndex = effectiveIndex ~/ 2;
      final evenCount = (totalChars + 1) ~/ 2;

      if (isEven) {
        return groupIndex * widget.stagger;
      } else {
        return (evenCount + groupIndex) * widget.stagger * 0.75;
      }
    }

    return effectiveIndex * widget.stagger;
  }

  Curve _getCurve() {
    switch (widget.ease.toLowerCase()) {
      case 'power3.out':
      case 'power3out':
        return GsapEasings.power3Out;
      case 'expo.out':
      case 'expoout':
        return GsapEasings.expoOut;
      case 'power4.out':
      case 'power4out':
        return GsapEasings.power4Out;
      default:
        return GsapEasings.power3Out;
    }
  }

  String _getRandomChar() {
    return _scrambleChars[_random.nextInt(_scrambleChars.length)];
  }

  String _buildScrambledText(double currentElapsedSec, double totalDurationSec) {
    final buffer = StringBuffer();
    int charIndex = 0;
    final totalChars = widget.text.replaceAll('\n', '').length;

    for (int i = 0; i < widget.text.length; i++) {
      final char = widget.text[i];
      if (char == '\n' || char == ' ') {
        buffer.write(char);
        continue;
      }

      final startDelaySec = _getCharDelay(charIndex, totalChars);
      final endSec = startDelaySec + widget.duration;
      charIndex++;

      if (currentElapsedSec < startDelaySec) {
        buffer.write(_hasTriggered ? char : _getRandomChar());
      } else if (currentElapsedSec >= startDelaySec && currentElapsedSec < endSec) {
        buffer.write(_getRandomChar());
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ??
        widget.style?.color ??
        AppTheme.getTextColor(context);

    final effectiveFontSize = widget.fontSize ?? widget.style?.fontSize ?? 40.0;

    final TextStyle baseStyle = (widget.style ??
            GoogleFonts.syne(
              fontSize: effectiveFontSize,
              fontWeight: widget.fontWeight ?? FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ))
        .copyWith(
      color: effectiveColor,
      fontSize: effectiveFontSize,
      fontWeight: widget.fontWeight ?? widget.style?.fontWeight ?? FontWeight.w900,
    );

    final curve = _getCurve();
    final totalDurationSec = (_controller.duration?.inMilliseconds ?? 1000) / 1000.0;

    final childWidget = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isCompleted = _controller.isCompleted;
        final displayText = isCompleted || (!_controller.isAnimating && _hasTriggered)
            ? widget.text
            : (!_controller.isAnimating && !_hasTriggered)
                ? widget.text
                : _buildScrambledText(
                    curve.transform(_controller.value) * totalDurationSec,
                    totalDurationSec,
                  );

        Widget textWidget = Text(
          displayText,
          style: baseStyle,
          textAlign: widget.textAlign,
        );

        if (widget.triggerOnHover && kIsWeb) {
          textWidget = MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _triggerAnimation(),
            child: textWidget,
          );
        }

        return textWidget;
      },
    );

    return VisibilityDetector(
      key: Key('shuffle_${widget.text.hashCode}_${widget.text.length}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.threshold) {
          if (!_hasTriggered) {
            _hasTriggered = true;
            _triggerAnimation();
          }
        } else if (info.visibleFraction < 0.02) {
          if (!widget.triggerOnce) {
            _hasTriggered = false;
          }
        }
      },
      child: childWidget,
    );
  }
}
