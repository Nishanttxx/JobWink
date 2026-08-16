import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/demo_service.dart';
import '../theme/app_theme.dart';
import 'auth_modal.dart';

class DemoUpsellDialog extends StatelessWidget {
  final String actionTitle;
  final String description;

  const DemoUpsellDialog({
    super.key,
    required this.actionTitle,
    required this.description,
  });

  /// Static helper to trigger the dialog easily.
  static Future<bool> show(
    BuildContext context, {
    required String actionTitle,
    required String description,
  }) async {
    final auth = AuthProviderScope.read(context);
    if (auth.isAuthenticated) {
      if (DemoService.instance.isDemoMode) {
        DemoService.instance.exitDemoMode();
      }
      return true;
    }

    // If not in demo mode, allow the operation immediately
    if (!DemoService.instance.isDemoMode) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DemoUpsellDialog(
        actionTitle: actionTitle,
        description: description,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppTheme.getCardBgColor(context),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                '$actionTitle Requires Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.getMutedTextColor(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.getTextColor(context),
                        side: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keep Exploring',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Up Free',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
