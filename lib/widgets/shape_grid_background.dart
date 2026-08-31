import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ShapeGridDirection { diagonal, horizontal, vertical }

enum ShapeGridShape { square, circle }

/// A high-performance ShapeGrid background component.
/// Renders a subtle geometric grid of shapes (squares/circles)
/// with theme-adaptive borders, interactive orange trail accents,
/// and smooth continuous ambient background movement.
class ShapeGridBackground extends StatefulWidget {
  final double speed;
  final double squareSize;
  final ShapeGridDirection direction;
  final ShapeGridShape shape;
  final Color? borderColor;
  final Color? hoverFillColor;
  final int hoverTrailAmount;
  final ValueNotifier<Offset?>? mousePositionNotifier;

  const ShapeGridBackground({
    super.key,
    this.speed = 0.5,
    this.squareSize = 45.0,
    this.direction = ShapeGridDirection.diagonal,
    this.shape = ShapeGridShape.square,
    this.borderColor,
    this.hoverTrailAmount = 6,
    this.hoverFillColor,
    this.mousePositionNotifier,
  });

  @override
  State<ShapeGridBackground> createState() => _ShapeGridBackgroundState();
}

class _ShapeGridBackgroundState extends State<ShapeGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset? _localMousePosition;
  String? _currentHoverKey;
  final List<String> _trailKeys = [];
  final Map<String, double> _cellOpacities = {};

  @override
  void initState() {
    super.initState();
    final durationMs = (6000 / (widget.speed > 0 ? widget.speed : 0.5)).round().clamp(1000, 30000);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..addListener(_updateCellOpacities)
     ..repeat();

    widget.mousePositionNotifier?.addListener(_onNotifierPositionChanged);
  }

  @override
  void didUpdateWidget(covariant ShapeGridBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mousePositionNotifier != widget.mousePositionNotifier) {
      oldWidget.mousePositionNotifier?.removeListener(_onNotifierPositionChanged);
      widget.mousePositionNotifier?.addListener(_onNotifierPositionChanged);
    }
  }

  @override
  void dispose() {
    widget.mousePositionNotifier?.removeListener(_onNotifierPositionChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNotifierPositionChanged() {
    if (mounted) {
      _localMousePosition = widget.mousePositionNotifier?.value;
    }
  }

  void _onHover(PointerEvent event) {
    _localMousePosition = event.localPosition;
  }

  void _onHoverExit(PointerEvent event) {
    _localMousePosition = null;
  }

  void _updateCellOpacities() {
    // Fast path: If there is no active hover and no lingering trail opacities, skip expensive map iterations
    if (_localMousePosition == null &&
        _currentHoverKey == null &&
        _trailKeys.isEmpty &&
        _cellOpacities.isEmpty) {
      return;
    }

    final double animVal = _controller.value;
    final double squareSize = widget.squareSize;
    if (squareSize <= 0) return;

    final double offset = (animVal * squareSize) % squareSize;
    double offsetX = 0.0;
    double offsetY = 0.0;

    switch (widget.direction) {
      case ShapeGridDirection.diagonal:
        offsetX = offset;
        offsetY = offset;
        break;
      case ShapeGridDirection.horizontal:
        offsetX = offset;
        offsetY = 0.0;
        break;
      case ShapeGridDirection.vertical:
        offsetX = 0.0;
        offsetY = offset;
        break;
    }

    final double startX = -offsetX;
    final double startY = -offsetY;
    final Offset? mousePos = _localMousePosition;

    if (mousePos != null) {
      final double adjustedX = mousePos.dx - startX;
      final double adjustedY = mousePos.dy - startY;

      final int col = (adjustedX / squareSize).floor();
      final int row = (adjustedY / squareSize).floor();
      final String hoverKey = '$col,$row';

      if (_currentHoverKey != hoverKey) {
        if (_currentHoverKey != null) {
          _trailKeys.insert(0, _currentHoverKey!);
          if (_trailKeys.length > widget.hoverTrailAmount) {
            _trailKeys.removeLast();
          }
        }
        _currentHoverKey = hoverKey;
      }
    } else {
      if (_currentHoverKey != null) {
        _trailKeys.insert(0, _currentHoverKey!);
        if (_trailKeys.length > widget.hoverTrailAmount) {
          _trailKeys.removeLast();
        }
        _currentHoverKey = null;
      }
    }

    final Map<String, double> targetOpacities = {};
    if (_currentHoverKey != null) {
      targetOpacities[_currentHoverKey!] = 1.0;
    }

    for (int i = 0; i < _trailKeys.length; i++) {
      final String key = _trailKeys[i];
      final double target =
          (1.0 - ((i + 1) / (widget.hoverTrailAmount + 1))).clamp(0.0, 1.0);
      if (!targetOpacities.containsKey(key)) {
        targetOpacities[key] = target;
      }
    }

    final List<String> keysToUpdate = {
      ..._cellOpacities.keys,
      ...targetOpacities.keys,
    }.toList();

    for (final key in keysToUpdate) {
      final double currentOpacity = _cellOpacities[key] ?? 0.0;
      final double targetOpacity = targetOpacities[key] ?? 0.0;
      final double nextOpacity =
          currentOpacity + (targetOpacity - currentOpacity) * 0.20;

      if (nextOpacity < 0.01 && targetOpacity == 0.0) {
        _cellOpacities.remove(key);
      } else {
        _cellOpacities[key] = nextOpacity.clamp(0.0, 1.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final defaultBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    final defaultHoverFillColor = widget.hoverFillColor ??
        (isDark
            ? AppTheme.primaryOrange.withValues(alpha: 0.25)
            : AppTheme.primaryOrange.withValues(alpha: 0.16));

    if (reduceMotion) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _ShapeGridPainter(
            animationValue: 0.0,
            squareSize: widget.squareSize,
            direction: widget.direction,
            shape: widget.shape,
            borderColor: defaultBorderColor,
            hoverFillColor: defaultHoverFillColor,
            cellOpacities: const {},
          ),
          size: Size.infinite,
        ),
      );
    }

    return MouseRegion(
      onHover: _onHover,
      onExit: _onHoverExit,
      opaque: false,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ShapeGridPainter(
                animationValue: _controller.value,
                squareSize: widget.squareSize,
                direction: widget.direction,
                shape: widget.shape,
                borderColor: defaultBorderColor,
                hoverFillColor: defaultHoverFillColor,
                cellOpacities: Map.unmodifiable(_cellOpacities),
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _ShapeGridPainter extends CustomPainter {
  final double animationValue;
  final double squareSize;
  final ShapeGridDirection direction;
  final ShapeGridShape shape;
  final Color borderColor;
  final Color hoverFillColor;
  final Map<String, double> cellOpacities;

  _ShapeGridPainter({
    required this.animationValue,
    required this.squareSize,
    required this.direction,
    required this.shape,
    required this.borderColor,
    required this.hoverFillColor,
    required this.cellOpacities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || squareSize <= 0) return;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // Mathematical seamless continuous loop:
    // 1 full cycle travels exactly 1.0 * squareSize so animationValue (0.0 -> 1.0)
    // resets with zero visual jump, zero hitch, and 100% continuous motion.
    final double offset = (animationValue * squareSize) % squareSize;
    double offsetX = 0.0;
    double offsetY = 0.0;

    switch (direction) {
      case ShapeGridDirection.diagonal:
        offsetX = offset;
        offsetY = offset;
        break;
      case ShapeGridDirection.horizontal:
        offsetX = offset;
        offsetY = 0.0;
        break;
      case ShapeGridDirection.vertical:
        offsetX = 0.0;
        offsetY = offset;
        break;
    }

    final int cols = (size.width / squareSize).ceil() + 2;
    final int rows = (size.height / squareSize).ceil() + 2;

    final double startX = -offsetX;
    final double startY = -offsetY;

    // 1. Draw Cell Hover Highlight Fill if any active
    if (cellOpacities.isNotEmpty) {
      for (final entry in cellOpacities.entries) {
        final alpha = entry.value;
        if (alpha <= 0.005) continue;
        final coords = entry.key.split(',');
        if (coords.length != 2) continue;
        final c = int.tryParse(coords[0]);
        final r = int.tryParse(coords[1]);
        if (c == null || r == null) continue;
        final double x = startX + (c * squareSize);
        final double y = startY + (r * squareSize);
        final Rect cellRect = Rect.fromLTWH(x, y, squareSize, squareSize);

        final Paint fillPaint = Paint()
          ..color = hoverFillColor.withValues(
            alpha: (hoverFillColor.a * alpha).clamp(0.0, 1.0),
          )
          ..style = PaintingStyle.fill;

        if (shape == ShapeGridShape.square) {
          canvas.drawRect(cellRect.deflate(0.5), fillPaint);
        } else {
          canvas.drawCircle(
            Offset(x + squareSize / 2, y + squareSize / 2),
            (squareSize / 2 - 1) * alpha,
            fillPaint,
          );
        }
      }
    }

    // 2. Draw Grid Lines efficiently using batched Path
    if (shape == ShapeGridShape.square) {
      final double endX = startX + (cols * squareSize);
      final double endY = startY + (rows * squareSize);
      final Path gridPath = Path();

      // Horizontal grid lines
      for (int r = 0; r <= rows; r++) {
        final double y = startY + (r * squareSize);
        gridPath.moveTo(startX, y);
        gridPath.lineTo(endX, y);
      }

      // Vertical grid lines
      for (int c = 0; c <= cols; c++) {
        final double x = startX + (c * squareSize);
        gridPath.moveTo(x, startY);
        gridPath.lineTo(x, endY);
      }

      canvas.drawPath(gridPath, borderPaint);
    } else {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final double x = startX + (c * squareSize);
          final double y = startY + (r * squareSize);
          canvas.drawCircle(
            Offset(x + squareSize / 2, y + squareSize / 2),
            squareSize / 2,
            borderPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeGridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.squareSize != squareSize ||
        oldDelegate.direction != direction ||
        oldDelegate.shape != shape ||
        oldDelegate.cellOpacities != cellOpacities;
  }
}
