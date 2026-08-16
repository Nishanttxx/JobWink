import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/demo_service.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import 'auth_modal.dart';

class HeaderNav extends StatefulWidget {
  final Function(String section)? onNavClick;
  const HeaderNav({super.key, this.onNavClick});

  @override
  State<HeaderNav> createState() => _HeaderNavState();
}

class _HeaderNavState extends State<HeaderNav> {
  String? _hoveredItem;
  late final StreamSubscription<AuthState> _authSubscription;
  User? _currentUser;
  bool _isMobileMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _currentUser = SupabaseService.instance.currentUser;
    _authSubscription =
        SupabaseService.instance.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _handleMobileNav(String sectionKey) {
    setState(() {
      _isMobileMenuOpen = false;
    });
    widget.onNavClick?.call(sectionKey);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final isDarkMode = AppTheme.isDarkMode(context);
    final textPrimaryColor = AppTheme.getTextColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.getHeaderBgColor(context),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.getBorderColor(context),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: 12,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Row: Brand Logo (Left) & Actions (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Logo & Brand Name
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => widget.onNavClick?.call('hero'),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5722),
                                    Color(0xFFFF9800)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5722)
                                        .withAlpha(76),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.description_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'JobWink',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: textPrimaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Actions (Theme Toggle, Auth / Dashboard CTAs)
                    Row(
                      children: [
                        // Dark / Light Mode Toggle Button
                        _buildThemeToggleButton(context, isDarkMode),
                        const SizedBox(width: 10),

                        if (!isMobile) ...[
                          if (_currentUser != null) ...[
                            // User Profile Chip
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/dashboard'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.getPrimaryLightColor(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppTheme.getPrimaryBorderColor(
                                            context)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            AppTheme.primaryOrange,
                                        child: Text(
                                          (_currentUser!.email ?? 'U')[0]
                                              .toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _currentUser!.userMetadata?[
                                                'full_name'] ??
                                            _currentUser!.email ??
                                            'User',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Sign Out
                            OutlinedButton(
                              onPressed: () async {
                                DemoService.instance.exitDemoMode();
                                await SupabaseService.instance.signOut();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/', (route) => false);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimaryColor,
                                side: BorderSide(
                                    color: AppTheme.getBorderColor(context)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                              ),
                              child: Text(
                                'Sign Out',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Log In
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => AuthModal.show(context,
                                    onSuccess: () {
                                  Navigator.pushNamed(context, '/dashboard');
                                }),
                                child: Text(
                                  'Log In',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Get Started / Dashboard CTA
                            ElevatedButton(
                              onPressed: () {
                                if (_currentUser == null &&
                                    Supabase.instance.client.auth.currentUser ==
                                        null) {
                                  DemoService.instance.enterDemoMode();
                                }
                                Navigator.pushNamed(context, '/dashboard');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          // Mobile Hamburger Menu Icon
                          IconButton(
                            icon: Icon(
                              _isMobileMenuOpen
                                  ? Icons.close_rounded
                                  : Icons.menu_rounded,
                              color: textPrimaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isMobileMenuOpen = !_isMobileMenuOpen;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Center Navigation Links (Desktop Only)
                if (!isMobile)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _navLink('Features', 'features'),
                        const SizedBox(width: 24),
                        _navLink('How It Works', 'steps'),
                        const SizedBox(width: 24),
                        _navLink('ATS Score', 'preview'),
                        const SizedBox(width: 24),
                        _navLink('Job Prediction', 'ai'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Mobile Expanded Overlay Menu
        if (isMobile && _isMobileMenuOpen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.getSurfaceColor(context),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.getBorderColor(context),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _mobileMenuItem('Features', 'features'),
                const SizedBox(height: 14),
                _mobileMenuItem('How It Works', 'steps'),
                const SizedBox(height: 14),
                _mobileMenuItem('ATS Score', 'preview'),
                const SizedBox(height: 14),
                _mobileMenuItem('Job Prediction', 'ai'),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                if (_currentUser != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isMobileMenuOpen = false);
                        Navigator.pushNamed(context, '/dashboard');
                      },
                      icon: const Icon(Icons.dashboard_rounded, size: 16),
                      label: Text(
                        'Dashboard',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isMobileMenuOpen = false);
                            AuthModal.show(context, onSuccess: () {
                              Navigator.pushNamed(context, '/dashboard');
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimaryColor,
                            side: BorderSide(
                                color: AppTheme.getBorderColor(context)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _isMobileMenuOpen = false);
                            if (Supabase.instance.client.auth.currentUser ==
                                null) {
                              DemoService.instance.enterDemoMode();
                            }
                            Navigator.pushNamed(context, '/dashboard');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Get Started',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _mobileMenuItem(String label, String key) {
    return GestureDetector(
      onTap: () => _handleMobileNav(key),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextColor(context),
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton(BuildContext context, bool isDarkMode) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ThemeService.instance.toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E1F24)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF3F3F46)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 14,
                color: isDarkMode
                    ? const Color(0xFFFACC15)
                    : const Color(0xFF4B5563),
              ),
              const SizedBox(width: 4),
              Text(
                isDarkMode ? 'Light' : 'Dark',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, String sectionKey) {
    final isHovered = _hoveredItem == sectionKey;
    final textPrimaryColor = AppTheme.getTextColor(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItem = sectionKey),
      onExit: (_) => setState(() => _hoveredItem = null),
      child: GestureDetector(
        onTap: () => widget.onNavClick?.call(sectionKey),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
            color: isHovered ? AppTheme.primaryOrange : textPrimaryColor,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
