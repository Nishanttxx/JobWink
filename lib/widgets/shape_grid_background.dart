import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ShapeGridDirection { diagonal, horizontal, vertical }

enum ShapeGridShape { square, circle }

/// A reusable React Bits ShapeGrid animated canvas background component.
/// Renders a continuously moving grid of geometric shapes (squares/circles)
/// with subtle theme-adaptive borders, cell hover highlight, fading hover trail,
/// and responsive canvas sizing.
class ShapeGridBackground extends StatefulWidget {
  final double speed;
  final double squareSize;
  final ShapeGridDirection direction;
  final ShapeGridShape shape;
  final int hoverTrailAmount;
  final Color? borderColor;
  final Color? hoverFillColor;
  final ValueNotifier<Offset?>? mousePositionNotifier;

  const ShapeGridBackground({
    super.key,
    this.speed = 0.5,
    this.squareSize = 45.0,
    this.direction = ShapeGridDirection.diagonal,
    this.shape = ShapeGridShape.square,
    this.hoverTrailAmount = 5,
    this.borderColor,
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

  // Cell hover opacities and trail tracking
  final Map<String, double> _cellOpacities = {};
  String? _currentHoverKey;
  final List<String> _trailKeys = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(_updateCellOpacities);
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
    _controller.removeListener(_updateCellOpacities);
    widget.mousePositionNotifier?.removeListener(_onNotifierPositionChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onNotifierPositionChanged() {
    if (mounted) {
      setState(() {
        _localMousePosition = widget.mousePositionNotifier?.value;
      });
    }
  }

  void _onHover(PointerEvent event) {
    setState(() {
      _localMousePosition = event.localPosition;
    });
  }

  void _onHoverExit(PointerEvent event) {
    setState(() {
      _localMousePosition = null;
    });
  }

  void _updateCellOpacities() {
    final double animVal = _controller.value;
    final double squareSize = widget.squareSize;
    final double totalOffset = animVal * squareSize * 10.0 * (widget.speed * 0.4);

    double offsetX = 0.0;
    double offsetY = 0.0;

    switch (widget.direction) {
      case ShapeGridDirection.diagonal:
        offsetX = totalOffset % squareSize;
        offsetY = totalOffset % squareSize;
        break;
      case ShapeGridDirection.horizontal:
        offsetX = totalOffset % squareSize;
        offsetY = 0.0;
        break;
      case ShapeGridDirection.vertical:
        offsetX = 0.0;
        offsetY = totalOffset % squareSize;
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

    // Determine target opacity for each key
    final Map<String, double> targetOpacities = {};

    if (_currentHoverKey != null) {
      targetOpacities[_currentHoverKey!] = 1.0;
    }

    for (int i = 0; i < _trailKeys.length; i++) {
      final String key = _trailKeys[i];
      final double target = (1.0 - ((i + 1) / (widget.hoverTrailAmount + 1))).clamp(0.0, 1.0);
      if (!targetOpacities.containsKey(key)) {
        targetOpacities[key] = target;
      }
    }

    // Smoothly interpolate active cell opacities toward target
    final List<String> keysToUpdate = {
      ..._cellOpacities.keys,
      ...targetOpacities.keys,
    }.toList();

    for (final key in keysToUpdate) {
      final double currentOpacity = _cellOpacities[key] ?? 0.0;
      final double targetOpacity = targetOpacities[key] ?? 0.0;
      final double nextOpacity = currentOpacity + (targetOpacity - currentOpacity) * 0.20;

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

    final defaultBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    final defaultHoverFillColor = widget.hoverFillColor ??
        (isDark
            ? AppTheme.primaryOrange.withValues(alpha: 0.25)
            : AppTheme.primaryOrange.withValues(alpha: 0.16));

    return MouseRegion(
      onHover: _onHover,
      onExit: _onHoverExit,
      opaque: false,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ShapeGridPainter(
              animationValue: _controller.value,
              speed: widget.speed,
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
    );
  }
}

class _ShapeGridPainter extends CustomPainter {
  final double animationValue;
  final double speed;
  final double squareSize;
  final ShapeGridDirection direction;
  final ShapeGridShape shape;
  final Color borderColor;
  final Color hoverFillColor;
  final Map<String, double> cellOpacities;

  _ShapeGridPainter({
    required this.animationValue,
    required this.speed,
    required this.squareSize,
    required this.direction,
    required this.shape,
    required this.borderColor,
    required this.hoverFillColor,
    required this.cellOpacities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double totalOffset = animationValue * squareSize * 10.0 * (speed * 0.4);
    double offsetX = 0.0;
    double offsetY = 0.0;

    switch (direction) {
      case ShapeGridDirection.diagonal:
        offsetX = totalOffset % squareSize;
        offsetY = totalOffset % squareSize;
        break;
      case ShapeGridDirection.horizontal:
        offsetX = totalOffset % squareSize;
        offsetY = 0.0;
        break;
      case ShapeGridDirection.vertical:
        offsetX = 0.0;
        offsetY = totalOffset % squareSize;
        break;
    }

    final int cols = (size.width / squareSize).ceil() + 2;
    final int rows = (size.height / squareSize).ceil() + 2;

    final double startX = -offsetX;
    final double startY = -offsetY;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = startX + (c * squareSize);
        final double y = startY + (r * squareSize);
        final Rect cellRect = Rect.fromLTWH(x, y, squareSize, squareSize);
        final String cellKey = '$c,$r';
        final double alpha = cellOpacities[cellKey] ?? 0.0;

        // Draw Cell Hover Highlight Fill if opacity > 0
        if (alpha > 0.005) {
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

        // Draw Cell Grid Border
        if (shape == ShapeGridShape.square) {
          canvas.drawRect(cellRect, borderPaint);
        } else {
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
    return true;
  }
}
