import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standardized App Card enforcing consistent border radius, surface colors,
/// padding, borders, and hover effects across all feature screens.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;
  final bool enableHover;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 16.0,
    this.enableHover = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final effectiveBg = widget.backgroundColor ?? AppTheme.getSurfaceColor(context);
    final effectiveBorder = widget.border ??
        Border.all(
          color: _isHovered
              ? AppTheme.primaryOrange.withValues(alpha: 0.4)
              : AppTheme.getBorderColor(context),
          width: 1,
        );

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: effectiveBorder,
        boxShadow: widget.enableHover && _isHovered
            ? [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null || widget.enableHover) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: widget.onTap != null
            ? GestureDetector(
                onTap: widget.onTap,
                child: cardContent,
              )
            : cardContent,
      );
    }

    return cardContent;
  }
}
