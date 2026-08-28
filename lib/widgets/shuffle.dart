import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../animations/gsap_timeline.dart';
import '../theme/app_theme.dart';

/// React Bits-equivalent Shuffle text animation widget for Flutter.
/// Provides character-shuffling / matrix scramble animation triggered on viewport entry and hover.
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

  final Map<String, double> _charWidthCache = {};

  double _measureCharWidth(String char, TextStyle style) {
    return _charWidthCache.putIfAbsent(char, () {
      final textPainter = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return textPainter.width;
    });
  }

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
      _charWidthCache.clear();
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
        MediaQuery.of(context).accessibleNavigation) {
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
              height: 1.05,
              letterSpacing: -0.5,
            ))
        .copyWith(
      color: effectiveColor,
      fontSize: effectiveFontSize,
      fontWeight: widget.fontWeight ?? widget.style?.fontWeight ?? FontWeight.w900,
    );

    final lines = widget.text.split('\n');
    final totalDurationSec = _controller.duration!.inMilliseconds / 1000.0;
    final curve = _getCurve();

    final childWidget = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = curve.transform(_controller.value);
        final currentElapsedSec = progress * totalDurationSec;

        int globalCharIndex = 0;
        final totalChars = widget.text.replaceAll('\n', '').length;

        final List<Widget> lineWidgets = [];

        for (int l = 0; l < lines.length; l++) {
          final line = lines[l];
          final List<InlineSpan> spans = [];

          final List<String> words = line.split(' ');

          for (int w = 0; w < words.length; w++) {
            final word = words[w];

            if (word.isEmpty) {
              if (w < words.length - 1) {
                globalCharIndex++;
                spans.add(TextSpan(text: ' ', style: baseStyle));
              }
              continue;
            }

            final List<Widget> wordCharWidgets = [];

            for (int c = 0; c < word.length; c++) {
              final char = word[c];
              final charIndex = globalCharIndex++;

              final startDelaySec = _getCharDelay(charIndex, totalChars);
              final endSec = startDelaySec + widget.duration;

              String displayChar = char;

              if (currentElapsedSec < startDelaySec) {
                displayChar = _hasTriggered ? char : _getRandomChar();
              } else if (currentElapsedSec >= startDelaySec &&
                  currentElapsedSec < endSec) {
                displayChar = _getRandomChar();
              } else {
                displayChar = char;
              }

              final charWidth = _measureCharWidth(char, baseStyle);

              wordCharWidgets.add(
                SizedBox(
                  width: charWidth > 0 ? charWidth : 12.0,
                  child: Text(
                    displayChar,
                    textAlign: TextAlign.center,
                    style: baseStyle,
                  ),
                ),
              );
            }

            // Wrap characters of the word into an atomic inline Row so Flutter line breaker never splits words
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: wordCharWidgets,
                ),
              ),
            );

            if (w < words.length - 1) {
              globalCharIndex++;
              spans.add(TextSpan(text: ' ', style: baseStyle));
            }
          }

          lineWidgets.add(
            Text.rich(
              TextSpan(children: spans),
              textAlign: widget.textAlign,
            ),
          );
        }

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.textAlign == TextAlign.left
              ? CrossAxisAlignment.start
              : widget.textAlign == TextAlign.right
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.center,
          children: lineWidgets,
        );

        if (widget.triggerOnHover) {
          content = MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _triggerAnimation(),
            child: content,
          );
        }

        return content;
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
