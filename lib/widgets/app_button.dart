import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AppButtonStyle { primary, secondary, outline, danger }

/// Standardized App Button enforcing consistent height, typography, padding,
/// border radius, and loading/disabled states across all screens.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44.0,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44.0,
  }) : style = AppButtonStyle.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44.0,
  }) : style = AppButtonStyle.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44.0,
  }) : style = AppButtonStyle.outline;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height = 44.0,
  }) : style = AppButtonStyle.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bgColor;
    Color textColor;
    Border? border;

    switch (widget.style) {
      case AppButtonStyle.primary:
        bgColor = AppTheme.primaryOrange;
        textColor = Colors.white;
        border = null;
        break;
      case AppButtonStyle.secondary:
        bgColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        textColor = AppTheme.getTextColor(context);
        border = Border.all(color: AppTheme.getBorderColor(context));
        break;
      case AppButtonStyle.outline:
        bgColor = Colors.transparent;
        textColor = _isHovered ? AppTheme.primaryOrange : AppTheme.getTextColor(context);
        border = Border.all(
          color: _isHovered ? AppTheme.primaryOrange : AppTheme.getBorderColor(context),
        );
        break;
      case AppButtonStyle.danger:
        bgColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        border = null;
        break;
    }

    if (isDisabled) {
      bgColor = bgColor.withValues(alpha: 0.5);
      textColor = textColor.withValues(alpha: 0.6);
    }

    final buttonWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _isHovered && !isDisabled && widget.style == AppButtonStyle.primary
              ? AppTheme.primaryOrange.withValues(alpha: 0.9)
              : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: _isHovered && !isDisabled && widget.style == AppButtonStyle.primary
              ? [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: isDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }

    return buttonWidget;
  }
}
