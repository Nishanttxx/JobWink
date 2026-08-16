import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Full-page screen where a user enters their email to receive a
/// password-reset link. Accessible via `/forgot-password`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = AuthProviderScope.read(context);
    final success = await auth.forgotPassword(email: _emailCtrl.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = success;
        if (!success) _errorMessage = auth.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getSurfaceColor(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: AppTheme.getTextColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Forgot Password',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextColor(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _emailSent ? _buildSuccessView() : _buildFormView(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
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
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppTheme.primaryOrange,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Reset your password',
            style: AppTheme.getDisplayFont(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email address you used to create your account. We\'ll send you a link to reset your password.',
            style: AppTheme.getBodyFont(
              fontSize: 14,
              color: AppTheme.getMutedTextColor(context),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 32),

          // Error banner
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],

          // Email field
          _AuthTextField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 24),

          // Submit button
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
                      'Send Reset Link',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Back to sign in
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                '← Back to Sign In',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: Color(0xFF10B981), size: 34),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          style: AppTheme.getDisplayFont(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a password-reset link to\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: AppTheme.getBodyFont(
            fontSize: 14,
            color: AppTheme.getMutedTextColor(context),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Didn\'t receive it? Check your spam folder or tap below to resend.',
          textAlign: TextAlign.center,
          style: AppTheme.getBodyFont(
            fontSize: 13,
            color: AppTheme.getMutedTextColor(context),
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => setState(() => _emailSent = false),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryOrange),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: Text(
            'Resend Email',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryOrange),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
              context, '/', (r) => false),
          child: Text(
            '← Back to Home',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets (private to this file)
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

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
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
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.getMutedTextColor(context)
                    .withValues(alpha: 0.6)),
            prefixIcon:
                Icon(icon, size: 18, color: AppTheme.getMutedTextColor(context)),
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
                borderSide:
                    const BorderSide(color: Color(0xFFEF4444))),
          ),
        ),
      ],
    );
  }
}
