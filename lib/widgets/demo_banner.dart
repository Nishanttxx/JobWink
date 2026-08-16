import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import 'auth_modal.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoService.instance,
      builder: (context, _) {
        final auth = AuthProviderScope.of(context);
        if (auth.isAuthenticated || !DemoService.instance.isDemoMode) {
          return const SizedBox.shrink();
        }

        final isDarkMode = AppTheme.isDarkMode(context);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF3B2A10),
                      const Color(0xFF2A1E0B),
                    ]
                  : [
                      const Color(0xFFFFF3E0),
                      const Color(0xFFFFE0B2),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.visibility_rounded,
                            size: 16,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDarkMode ? Colors.white70 : const Color(0xFF5D4037),
                              ),
                              children: [
                                TextSpan(
                                  text: 'DEMO MODE: ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                                TextSpan(
                                  text: isCompact
                                      ? 'Sample data only. Progress won\'t save.'
                                      : 'You are exploring with sample data. Actions will not persist.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      AuthModal.show(
                        context,
                        isSignUp: true,
                        onSuccess: () {
                          DemoService.instance.exitDemoMode();
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Sign Up Free',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
