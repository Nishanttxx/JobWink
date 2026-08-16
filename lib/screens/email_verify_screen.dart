import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Shown immediately after a new user signs up, while their email is
/// awaiting confirmation.
///
/// - Listens to [AuthProvider] status; auto-navigates to `/dashboard` when
///   [AuthStatus.authenticated] fires (user confirmed their email).
/// - Provides a "Resend Email" button with cool-down feedback.
///
/// Route: `/verify-email`
class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  bool _resending = false;
  bool _resent = false;
  String? _resentError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to auth changes; navigate once email is confirmed.
    final auth = AuthProviderScope.of(context);
    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/dashboard', (r) => false);
        }
      });
    }
  }

  Future<void> _resend() async {
    final auth = AuthProviderScope.read(context);
    final email = auth.pendingVerificationEmail;
    if (email == null) return;

    setState(() {
      _resending = true;
      _resent = false;
      _resentError = null;
    });

    final success = await auth.resendVerificationEmail(email: email);
    if (mounted) {
      setState(() {
        _resending = false;
        _resent = success;
        _resentError = success ? null : auth.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    final email = auth.pendingVerificationEmail ?? '';

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated envelope icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        color: AppTheme.primaryOrange,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Verify your email',
                    style: AppTheme.getDisplayFont(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  if (email.isNotEmpty) ...[
                    Text(
                      'We sent a confirmation link to',
                      textAlign: TextAlign.center,
                      style: AppTheme.getBodyFont(
                        fontSize: 14,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    'Click the link in the email to activate your account. After confirming, you\'ll be signed in automatically.',
                    textAlign: TextAlign.center,
                    style: AppTheme.getBodyFont(
                      fontSize: 13,
                      color: AppTheme.getMutedTextColor(context),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Status after resend
                  if (_resent) ...[
                    _StatusBanner(
                      message: 'Email resent! Check your inbox.',
                      isSuccess: true,
                    ),
                    const SizedBox(height: 16),
                  ] else if (_resentError != null) ...[
                    _StatusBanner(
                      message: _resentError!,
                      isSuccess: false,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Resend button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _resending ? null : _resend,
                      icon: _resending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        _resending ? 'Sending…' : 'Resend Verification Email',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to home / sign in
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (r) => false),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getMutedTextColor(context),
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
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isSuccess;
  const _StatusBanner({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFDC2626);
    final bgColor = isSuccess
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFEF2F2);
    final borderColor = isSuccess
        ? const Color(0xFF6EE7B7)
        : const Color(0xFFFCA5A5);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(children: [
        Icon(
          isSuccess
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}
