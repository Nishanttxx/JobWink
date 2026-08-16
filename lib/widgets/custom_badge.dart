import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData? icon;
  final Color? customBg;
  final Color? customTextColor;

  const CustomBadge({
    super.key,
    required this.label,
    this.isDark = false,
    this.icon,
    this.customBg,
    this.customTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = customBg ??
        (isDark
            ? AppTheme.primaryOrange.withAlpha(30)
            : AppTheme.primaryOrangeLight);

    final textColor = customTextColor ??
        (isDark ? const Color(0xFFFF8A5C) : AppTheme.primaryOrange);

    final borderColor = isDark
        ? AppTheme.primaryOrange.withAlpha(60)
        : AppTheme.primaryOrangeBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
