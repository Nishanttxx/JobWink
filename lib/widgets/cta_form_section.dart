import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../animations/gsap_timeline.dart';
import '../services/demo_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'custom_badge.dart';
import 'spotlight_card.dart';

class CtaFormSection extends StatefulWidget {
  const CtaFormSection({super.key});

  @override
  State<CtaFormSection> createState() => _CtaFormSectionState();
}

class _CtaFormSectionState extends State<CtaFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUpTab = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isTriggered = false;
  String? _errorMessage;
  String? _successMessage;

  User? _currentUser;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _currentUser = SupabaseService.instance.currentUser;
    _authSub = SupabaseService.instance.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleFormSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (_isSignUpTab) {
        final res = await SupabaseService.instance.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName.isNotEmpty ? fullName : null,
        );
        if (res.session != null) {
          setState(() {
            _successMessage =
                'Account created! Redirecting to Dashboard...';
          });
          if (mounted) {
            DemoService.instance.exitDemoMode();
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          setState(() {
            _successMessage =
                'Account created! Please check your email to verify your account.';
          });
          if (mounted) {
            Navigator.pushNamed(context, '/verify-email');
          }
        }
      } else {
        await SupabaseService.instance.signInWithEmail(
          email: email,
          password: password,
        );
        setState(() {
          _successMessage = 'Successfully logged in! Redirecting to Dashboard...';
        });
        if (mounted) {
          DemoService.instance.exitDemoMode();
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
          () => _errorMessage = 'An unexpected error occurred. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOAuth(OAuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      debugPrint('[AUTH] OAuth started: ${provider.name}');
      await SupabaseService.instance.signInWithOAuth(provider);
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not connect to ${provider.name}.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 950;

    return GsapScrollTrigger(
      triggerKey: 'cta_form_section',
      onEnter: () => setState(() => _isTriggered = true),
      onLeave: () => setState(() => _isTriggered = false),
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1240),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                  vertical: isDesktop ? 90 : 54,
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 12,
                            child: GsapStaggeredReveal(
                              index: 0,
                              isTriggered: _isTriggered,
                              child: _buildLeftCtaContent(context, isDesktop),
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 10,
                            child: GsapStaggeredReveal(
                              index: 1,
                              isTriggered: _isTriggered,
                              initialOffset: const Offset(30, 0),
                              child: SpotlightCardTile(
                                hoverScale: 1.015,
                                borderRadius: BorderRadius.circular(24),
                                accentColor: AppTheme.primaryOrange,
                                child: _currentUser != null
                                    ? _buildAuthenticatedCard(context)
                                    : _buildSignUpCard(context),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          GsapStaggeredReveal(
                            index: 0,
                            isTriggered: _isTriggered,
                            child: _buildLeftCtaContent(context, isDesktop),
                          ),
                          const SizedBox(height: 48),
                          GsapStaggeredReveal(
                            index: 1,
                            isTriggered: _isTriggered,
                            child: SpotlightCardTile(
                              hoverScale: 1.015,
                              borderRadius: BorderRadius.circular(24),
                              accentColor: AppTheme.primaryOrange,
                              child: _currentUser != null
                                  ? _buildAuthenticatedCard(context)
                                  : _buildSignUpCard(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
      ),
    );
  }

  Widget _buildLeftCtaContent(BuildContext context, bool isDesktop) {
    final features = [
      'AI write and optimize your resume instantly',
      'ATS score with real-time improvement tips',
      'Access all professional resume templates',
      'Track all your job applications in one place',
      'Export resumes in PDF and DOCX formats',
      'No credit card required to get started',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomBadge(
          label: 'Free to start',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 20),
        Text(
          'Start building your\nwinning resume today',
          style: AppTheme.getDisplayFont(
            fontSize: isDesktop ? 44 : 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            'Join 50,000+ job seekers who landed their dream job using Jobwink. No credit card required.',
            style: AppTheme.getBodyFont(
              fontSize: 16,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: features.map((feat) => _buildCheckItem(context, feat)).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryLightColor(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.getPrimaryBorderColor(context)),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedCard(BuildContext context) {
    final email = _currentUser?.email ?? 'User';
    final name = _currentUser?.userMetadata?['full_name'] ?? email;
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryOrange,
                child: Text(
                  email[0].toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getPrimaryLightColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getPrimaryBorderColor(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primaryOrange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You are signed in with Supabase Auth! All resume uploads and ATS scans are synced to your user ID.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.getTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Open Resume Builder Dashboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () async {
                await SupabaseService.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.getTextColor(context),
                side: BorderSide(color: AppTheme.getBorderColor(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpCard(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Jobwink',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tab Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : const Color(0xFFF3F2ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isSignUpTab = true;
                      _errorMessage = null;
                      _successMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSignUpTab
                            ? (isDark ? const Color(0xFF2C2D35) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _isSignUpTab
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sign Up Free',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight:
                              _isSignUpTab ? FontWeight.w700 : FontWeight.w600,
                          color: _isSignUpTab
                              ? AppTheme.getTextColor(context)
                              : AppTheme.getMutedTextColor(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isSignUpTab = false;
                      _errorMessage = null;
                      _successMessage = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isSignUpTab
                            ? (isDark ? const Color(0xFF2C2D35) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_isSignUpTab
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Log In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight:
                              !_isSignUpTab ? FontWeight.w700 : FontWeight.w600,
                          color: !_isSignUpTab
                              ? AppTheme.getTextColor(context)
                              : AppTheme.getMutedTextColor(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withAlpha(102)),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withAlpha(102)),
              ),
              child: Text(
                _successMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.green[800],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Input 1: FULL NAME (Sign Up only)
                if (_isSignUpTab) ...[
                  _buildFieldLabel(context, 'FULL NAME'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    context: context,
                    controller: _nameController,
                    hintText: 'John Doe',
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Input 2: EMAIL ADDRESS
                _buildFieldLabel(context, 'EMAIL ADDRESS'),
                const SizedBox(height: 6),
                _buildTextField(
                  context: context,
                  controller: _emailController,
                  hintText: 'you@example.com',
                ),
                const SizedBox(height: 16),

                // Form Input 3: PASSWORD
                _buildFieldLabel(context, 'PASSWORD'),
                const SizedBox(height: 6),
                _buildTextField(
                  context: context,
                  controller: _passwordController,
                  hintText: 'Create a strong password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Submit CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleFormSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isSignUpTab ? 'Get Started Free' : 'Log In to JobWink',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Divider ("or continue with")
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.getBorderColor(context))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.getBorderColor(context))),
            ],
          ),
          const SizedBox(height: 18),

          // Social Buttons Row [Google] [GitHub]
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handleOAuth(OAuthProvider.google),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata_rounded,
                          color: Color(0xFFEA4335), size: 24),
                      const SizedBox(width: 4),
                      Text(
                        'Google',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handleOAuth(OAuthProvider.github),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code_rounded,
                          color: AppTheme.getTextColor(context), size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'GitHub',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'By signing up, you agree to our Terms and Privacy Policy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.getMutedTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.getTextColor(context),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.getTextColor(context),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppTheme.getMutedTextColor(context),
        ),
        filled: true,
        fillColor: AppTheme.getInputFillColor(context),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.getBorderColor(context), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
        ),
      ),
    );
  }
}
