import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/app_layout.dart';
import '../widgets/page_container.dart';

/// User Profile screen — view and edit profile fields, sign out.
///
/// Route: `/profile`
/// Protected: only reachable when authenticated (enforced in route generator).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _linkedinCtrl;
  late TextEditingController _githubCtrl;

  bool _editing = false;
  bool _isSaving = false;
  String? _saveError;
  bool _saveSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = AuthProviderScope.read(context).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _locationCtrl = TextEditingController(text: user?.location ?? '');
    _linkedinCtrl = TextEditingController(text: user?.linkedinUrl ?? '');
    _githubCtrl = TextEditingController(text: user?.githubUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
      _saveSuccess = false;
    });

    final auth = AuthProviderScope.read(context);
    final success = await auth.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      location:
          _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      linkedinUrl:
          _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
      githubUrl:
          _githubCtrl.text.trim().isEmpty ? null : _githubCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _editing = !success;
        _saveSuccess = success;
        _saveError = success ? null : auth.errorMessage;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
        child: AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Sign out?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextColor(context),
            ),
          ),
          content: Text(
            'You will be returned to the home screen.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.getMutedTextColor(context))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text('Sign Out',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await AuthProviderScope.read(context).signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthProviderScope.of(context);
    final user = auth.currentUser;

    return AppLayout(
      activeIndex: 4,
      title: 'My Profile',
      child: PageContainer(
        maxWidth: 800,
        child: Column(
          children: [
            PageHeader(
              title: 'My Profile',
              subtitle: 'Manage your personal details, career links, and account preferences.',
              action: !_editing
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryOrange),
                      tooltip: 'Edit Profile',
                      onPressed: () => setState(() {
                        _editing = true;
                        _saveSuccess = false;
                      }),
                    )
                  : null,
            ),
                // ── Avatar & Identity ──────────────────────────────────────
                UserProfileCard(user: user),
                const SizedBox(height: 24),

                // ── Success / Error banner ─────────────────────────────────
                if (_saveSuccess) ...[
                  _StatusBanner(
                    message: 'Profile updated successfully!',
                    isSuccess: true,
                  ),
                  const SizedBox(height: 16),
                ] else if (_saveError != null) ...[
                  _StatusBanner(message: _saveError!, isSuccess: false),
                  const SizedBox(height: 16),
                ],

                // ── Profile Form ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppTheme.getBorderColor(context)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(title: 'Personal Information'),
                        const SizedBox(height: 16),
                        _ProfileField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'John Doe',
                          icon: Icons.person_outline_rounded,
                          enabled: _editing,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name cannot be empty'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          hint: '+1 (555) 000-0000',
                          icon: Icons.phone_outlined,
                          enabled: _editing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          controller: _locationCtrl,
                          label: 'Location',
                          hint: 'City, Country',
                          icon: Icons.location_on_outlined,
                          enabled: _editing,
                        ),
                        const SizedBox(height: 24),

                        _SectionTitle(title: 'Online Presence'),
                        const SizedBox(height: 16),
                        _ProfileField(
                          controller: _linkedinCtrl,
                          label: 'LinkedIn URL',
                          hint: 'https://linkedin.com/in/yourname',
                          icon: Icons.link_rounded,
                          enabled: _editing,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          controller: _githubCtrl,
                          label: 'GitHub URL',
                          hint: 'https://github.com/yourname',
                          icon: Icons.code_rounded,
                          enabled: _editing,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 24),

                        // Read-only email (from Supabase auth, cannot be changed here)
                        _ProfileField(
                          controller: TextEditingController(
                              text: user?.email ?? ''),
                          label: 'Email Address',
                          hint: '',
                          icon: Icons.email_outlined,
                          enabled: false,
                          suffix: const Tooltip(
                            message:
                                'Email cannot be changed from the app.',
                            child: Icon(Icons.info_outline_rounded,
                                size: 16, color: Colors.grey),
                          ),
                        ),

                        // ── Action Buttons ────────────────────────────────
                        if (_editing) ...[
                          const SizedBox(height: 28),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => setState(() {
                                          _editing = false;
                                          _saveError = null;
                                        }),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color:
                                          AppTheme.getBorderColor(context)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: Text('Cancel',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getMutedTextColor(
                                            context))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryOrange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text('Save Changes',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Danger Zone ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextColor(context),
                          )),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded,
                              size: 18, color: Color(0xFFEF4444)),
                          label: Text('Sign Out',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEF4444))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFEF4444), width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------



class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.getMutedTextColor(context),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.validator,
    this.suffix,
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
          enabled: enabled,
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
            prefixIcon: Icon(icon,
                size: 18, color: AppTheme.getMutedTextColor(context)),
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled
                ? AppTheme.getInputBgColor(context)
                : AppTheme.getBorderColor(context).withValues(alpha: 0.3),
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
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppTheme.getBorderColor(context)
                        .withValues(alpha: 0.5))),
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

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isSuccess;
  const _StatusBanner({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFDC2626);
    final bgColor =
        isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final borderColor =
        isSuccess ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5);
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
