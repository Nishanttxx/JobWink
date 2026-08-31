import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ShapeGridDirection { diagonal, horizontal, vertical }

enum ShapeGridShape { square, circle }

/// A high-performance ShapeGrid background component.
/// Renders a subtle geometric grid of shapes (squares/circles)
/// with theme-adaptive borders and ambient background movement.
class ShapeGridBackground extends StatefulWidget {
  final double speed;
  final double squareSize;
  final ShapeGridDirection direction;
  final ShapeGridShape shape;
  final Color? borderColor;

  const ShapeGridBackground({
    super.key,
    this.speed = 0.5,
    this.squareSize = 45.0,
    this.direction = ShapeGridDirection.diagonal,
    this.shape = ShapeGridShape.square,
    this.borderColor,
    int? hoverTrailAmount,
    Color? hoverFillColor,
    ValueNotifier<Offset?>? mousePositionNotifier,
  });

  @override
  State<ShapeGridBackground> createState() => _ShapeGridBackgroundState();
}

class _ShapeGridBackgroundState extends State<ShapeGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final defaultBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    // On mobile or reduced motion, render a static grid
    if (isMobile || reduceMotion) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _ShapeGridPainter(
            animationValue: 0.0,
            speed: widget.speed,
            squareSize: widget.squareSize,
            direction: widget.direction,
            shape: widget.shape,
            borderColor: defaultBorderColor,
          ),
          size: Size.infinite,
        ),
      );
    }

    return RepaintBoundary(
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

  _ShapeGridPainter({
    required this.animationValue,
    required this.speed,
    required this.squareSize,
    required this.direction,
    required this.shape,
    required this.borderColor,
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

    // Draw Grid Lines efficiently using batched Path
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
        oldDelegate.borderColor != borderColor;
  }
}
