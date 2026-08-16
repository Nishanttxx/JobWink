import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DashboardNavBar extends StatelessWidget {
  final String activeRoute;
  final Function(int index, String route)? onTabSelected;

  const DashboardNavBar({
    super.key,
    required this.activeRoute,
    this.onTabSelected,
  });

  static const List<_NavTabItem> _tabs = [
    _NavTabItem(label: 'Overview', route: '/dashboard', icon: Icons.grid_view_rounded),
    _NavTabItem(label: 'Swipe Matcher', route: '/matcher', icon: Icons.swipe_rounded),
    _NavTabItem(label: 'Resume Tailoring', route: '/cv-studio', icon: Icons.tune_rounded),
    _NavTabItem(label: 'Job Prediction', route: '/job-prediction', icon: Icons.analytics_rounded),
  ];


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.isDarkMode(context)
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isActive = activeRoute == tab.route;
          return _NavTabButton(
            tab: tab,
            index: index,
            isActive: isActive,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(index, tab.route);
              } else if (!isActive) {
                Navigator.pushReplacementNamed(context, tab.route);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class _NavTabItem {
  final String label;
  final String route;
  final IconData icon;

  const _NavTabItem({
    required this.label,
    required this.route,
    required this.icon,
  });
}

class _NavTabButton extends StatefulWidget {
  final _NavTabItem tab;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTabButton({
    required this.tab,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTabButton> createState() => _NavTabButtonState();
}

class _NavTabButtonState extends State<_NavTabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.isActive
                ? AppTheme.primaryOrange.withValues(alpha: isDarkMode ? 0.22 : 0.14)
                : _isHovered
                    ? (isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
                    : Colors.transparent,
            border: Border.all(
              color: widget.isActive
                  ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.tab.icon,
                size: 16,
                color: widget.isActive
                    ? AppTheme.primaryOrange
                    : _isHovered
                        ? AppTheme.getTextColor(context)
                        : AppTheme.getMutedTextColor(context),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive
                      ? AppTheme.primaryOrange
                      : _isHovered
                          ? AppTheme.getTextColor(context)
                          : AppTheme.getMutedTextColor(context),
                ),
                child: Text(widget.tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
