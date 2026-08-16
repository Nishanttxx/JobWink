import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Screen shown after the user follows a password-reset deep-link.
///
/// Supabase fires [AuthChangeEvent.passwordRecovery] which puts the user
/// in a temporary authenticated state; this screen completes the flow by
/// calling [AuthProvider.resetPassword].
///
/// Route: `/reset-password`
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _resetSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = AuthProviderScope.read(context);
    final success =
        await auth.resetPassword(newPassword: _passwordCtrl.text.trim());

    if (mounted) {
      if (success) {
        setState(() {
          _isLoading = false;
          _resetSuccess = true;
        });
        // Navigate to dashboard after a brief pause
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/dashboard', (r) => false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = auth.errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getSurfaceColor(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Set New Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextColor(context),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _resetSuccess ? _buildSuccess() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: AppTheme.primaryOrange, size: 30),
          ),
          const SizedBox(height: 24),

          Text(
            'Create a new password',
            style: AppTheme.getDisplayFont(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a strong password that you haven\'t used before.',
            style: AppTheme.getBodyFont(
              fontSize: 14,
              color: AppTheme.getMutedTextColor(context),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 32),

          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],

          // New password
          _PasswordField(
            controller: _passwordCtrl,
            label: 'New Password',
            hint: '••••••••',
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => v == null || v.length < 8
                ? 'Password must be at least 8 characters'
                : null,
          ),
          const SizedBox(height: 16),

          // Confirm password
          _PasswordField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            hint: '••••••••',
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) => v != _passwordCtrl.text
                ? 'Passwords do not match'
                : null,
          ),
          const SizedBox(height: 28),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      'Update Password',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF10B981), size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Password updated!',
          style: AppTheme.getDisplayFont(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your password has been changed successfully. Redirecting you to the dashboard…',
          textAlign: TextAlign.center,
          style: AppTheme.getBodyFont(
            fontSize: 14,
            color: AppTheme.getMutedTextColor(context),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppTheme.primaryOrange),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFDC2626), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFFDC2626),
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color:
                    AppTheme.getMutedTextColor(context).withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.lock_outline_rounded,
                size: 18, color: AppTheme.getMutedTextColor(context)),
            suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppTheme.getMutedTextColor(context)),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppTheme.getInputBgColor(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.getBorderColor(context))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.getBorderColor(context))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppTheme.primaryOrange, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444))),
          ),
        ),
      ],
    );
  }
}
