import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A React-style MaskedHeading widget in Flutter using CustomPainter.
/// Renders text acting as an image mask over [src] with continuous 60fps
/// pan, zoom, and shimmer shader animation across all platforms.
class MaskedHeading extends StatefulWidget {
  final String text;
  final String src;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign textAlign;
  final TextStyle? style;

  const MaskedHeading({
    super.key,
    required this.text,
    required this.src,
    this.fontSize,
    this.fontWeight,
    this.textAlign = TextAlign.center,
    this.style,
  });

  @override
  State<MaskedHeading> createState() => _MaskedHeadingState();
}

class _MaskedHeadingState extends State<MaskedHeading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  ui.Image? _loadedImage;
  ImageStreamListener? _streamListener;
  ImageStream? _imageStream;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant MaskedHeading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }
    super.dispose();
  }

  void _loadImage() {
    final List<ImageProvider> providers = [
      _resolveImageProvider(widget.src),
      const AssetImage('assets/images/hero.jpg'),
      const NetworkImage('/hero.jpg'),
      const NetworkImage('/assets/images/hero.jpg'),
    ];

    int attempt = 0;

    void tryNextProvider() {
      if (attempt >= providers.length) {
        return;
      }

      try {
        final ImageProvider provider = providers[attempt++];
        final ImageStream stream =
            provider.resolve(const ImageConfiguration());

        _streamListener = ImageStreamListener(
          (ImageInfo info, bool synchronousCall) {
            if (mounted) {
              setState(() {
                _loadedImage = info.image;
              });
            }
          },
          onError: (dynamic error, StackTrace? stackTrace) {
            tryNextProvider();
          },
        );

        _imageStream?.removeListener(_streamListener!);
        _imageStream = stream;
        _imageStream!.addListener(_streamListener!);
      } catch (_) {
        tryNextProvider();
      }
    }

    tryNextProvider();
  }

  ImageProvider _resolveImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    String cleanPath = path;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (kIsWeb) {
      return NetworkImage('/$cleanPath');
    }

    if (cleanPath.startsWith('assets/')) {
      return AssetImage(cleanPath);
    }

    return AssetImage('assets/images/$cleanPath');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final isTablet = screenWidth >= 650 && screenWidth < 980;

    final defaultFontSize = isDesktop
        ? 58.0
        : (isTablet ? 42.0 : 32.0);

    final textStyle = widget.style ??
        GoogleFonts.plusJakartaSans(
          fontSize: widget.fontSize ?? defaultFontSize,
          fontWeight: widget.fontWeight ?? FontWeight.w900,
          letterSpacing: -1.2,
          height: 1.1,
        );

    final isDark = AppTheme.isDarkMode(context);

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth > 0
                ? constraints.maxWidth
                : double.infinity;

            final TextPainter measurementPainter = TextPainter(
              text: TextSpan(text: widget.text, style: textStyle),
              textAlign: widget.textAlign,
              textDirection: TextDirection.ltr,
            );
            measurementPainter.layout(maxWidth: maxWidth);

            final double textHeight = measurementPainter.height;

            return SizedBox(
              width: maxWidth,
              height: textHeight,
              child: CustomPaint(
                painter: _MaskedHeadingPainter(
                  text: widget.text,
                  textStyle: textStyle,
                  textAlign: widget.textAlign,
                  loadedImage: _loadedImage,
                  animValue: _animController.value,
                  isDark: isDark,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MaskedHeadingPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final ui.Image? loadedImage;
  final double animValue;
  final bool isDark;

  _MaskedHeadingPainter({
    required this.text,
    required this.textStyle,
    required this.textAlign,
    required this.loadedImage,
    required this.animValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Rect bounds = Offset.zero & size;
    final Paint maskPaint = Paint();

    if (loadedImage != null &&
        loadedImage!.width > 0 &&
        loadedImage!.height > 0) {
      final double scaleX = size.width / loadedImage!.width;
      final double scaleY = size.height / loadedImage!.height;
      final double baseScale = math.max(scaleX, scaleY);

      // Continuous 60fps pan and zoom motion
      final double currentScale =
          baseScale * (1.12 + 0.08 * math.sin(animValue * math.pi * 2));
      final double panX = math.sin(animValue * math.pi * 2) * 50.0;
      final double panY = math.cos(animValue * math.pi * 2) * 25.0;

      final Matrix4 matrix = Matrix4.identity()
        ..scaleByDouble(currentScale, currentScale, 1.0, 1.0)
        ..translateByDouble(panX, panY, 0.0, 0.0);

      maskPaint.shader = ui.ImageShader(
        loadedImage!,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        matrix.storage,
      );
    } else {
      // Vibrant fallback animated gradient
      final gradientColors = isDark
          ? [
              const Color(0xFFFF6B00),
              const Color(0xFFFF9E00),
              const Color(0xFFFF4500),
              const Color(0xFFD81B60),
            ]
          : [
              const Color(0xFFE65100),
              const Color(0xFFFF6B00),
              const Color(0xFFC2185B),
              const Color(0xFF7B1FA2),
            ];

      final double shift = math.sin(animValue * math.pi * 2) * 0.5;
      maskPaint.shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment(-1.0 + shift, -1.0),
        end: Alignment(1.0 + shift, 1.0),
      ).createShader(bounds);
    }

    // Strip color property so foreground maskPaint is applied to glyphs
    final TextStyle shaderStyle = TextStyle(
      fontFamily: textStyle.fontFamily,
      fontFamilyFallback: textStyle.fontFamilyFallback,
      fontSize: textStyle.fontSize,
      fontWeight: textStyle.fontWeight,
      fontStyle: textStyle.fontStyle,
      letterSpacing: textStyle.letterSpacing,
      wordSpacing: textStyle.wordSpacing,
      height: textStyle.height,
      foreground: maskPaint,
    );

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: shaderStyle,
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );

    tp.layout(maxWidth: size.width);

    final double offsetY = math.max(0.0, (size.height - tp.height) / 2);
    double offsetX = 0.0;

    if (textAlign == TextAlign.center) {
      offsetX = math.max(0.0, (size.width - tp.width) / 2);
    } else if (textAlign == TextAlign.right) {
      offsetX = math.max(0.0, size.width - tp.width);
    }

    tp.paint(canvas, Offset(offsetX, offsetY));
  }

  @override
  bool shouldRepaint(covariant _MaskedHeadingPainter oldDelegate) {
    return true;
  }
}
