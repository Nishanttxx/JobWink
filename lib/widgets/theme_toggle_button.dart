import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Reusable, compact, accessible Dark/Light mode toggle switch.
class ThemeToggleButton extends StatelessWidget {
  final double width;
  final double height;

  const ThemeToggleButton({
    super.key,
    this.width = 58,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, mode, _) {
        final isDarkMode = AppTheme.isDarkMode(context);
        final trackBg = isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFE5E7EB);
        final thumbBg = isDarkMode ? const Color(0xFF2D313E) : Colors.white;
        final borderColor = isDarkMode ? const Color(0xFF373B49) : const Color(0xFFD1D5DB);
        final tooltipMsg = isDarkMode ? 'Switch to light mode' : 'Switch to dark mode';

        return Tooltip(
          message: tooltipMsg,
          child: Semantics(
            toggled: isDarkMode,
            button: true,
            label: tooltipMsg,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => ThemeService.instance.toggleTheme(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: width,
                  height: height,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: trackBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sun & Moon icons positioned on opposite sides of track
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Icon(
                              Icons.light_mode_rounded,
                              size: 13,
                              color: isDarkMode ? Colors.white38 : const Color(0xFFF59E0B),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              Icons.dark_mode_rounded,
                              size: 13,
                              color: isDarkMode ? const Color(0xFF818CF8) : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      // Sliding thumb indicator
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: height - 6,
                          height: height - 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: thumbBg,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              size: 11,
                              color: isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
