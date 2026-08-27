import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_image_helper.dart';
import 'report_bug_modal.dart';

class AppSidebar extends StatefulWidget {
  final int activeIndex;
  final Function(int index, String route)? onTabSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  // CV Studio Sub-navigation & Actions
  final int activeSubSectionIndex;
  final Function(int subIndex)? onSubSectionSelected;
  final Map<String, int>? sectionCounts;
  final VoidCallback? onResumePreview;
  final VoidCallback? onGenerate;
  final VoidCallback? onAtsScore;
  final VoidCallback? onUploadResume;

  const AppSidebar({
    super.key,
    required this.activeIndex,
    this.onTabSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.activeSubSectionIndex = 0,
    this.onSubSectionSelected,
    this.sectionCounts,
    this.onResumePreview,
    this.onGenerate,
    this.onAtsScore,
    this.onUploadResume,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const List<_SidebarItemData> _navItems = [];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final auth = AuthProviderScope.of(context);
    final user = auth.currentUser;
    final initials = user?.initials ?? 'U';
    final name = user?.displayName ?? (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'User');

    final sidebarWidth = widget.isCollapsed ? 76.0 : 285.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        border: Border(
          right: BorderSide(
            color: AppTheme.getBorderColor(context),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.03),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Sidebar Brand Header & Collapse Button
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 12 : 20,
              vertical: 20,
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.isCollapsed)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Job',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Wink',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryOrange,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryOrange,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.isCollapsed && widget.onToggleCollapse != null)
                  IconButton(
                    onPressed: widget.onToggleCollapse,
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    tooltip: 'Collapse Sidebar',
                    color: AppTheme.getMutedTextColor(context),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 16),

          // 2. Navigation Items List
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 8 : 14),
              children: [
                if (!widget.isCollapsed && _navItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 8),
                    child: Text(
                      'MAIN NAVIGATION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getMutedTextColor(context),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                if (_navItems.isNotEmpty)
                  ..._navItems.map((item) {
                    final isActive = widget.activeIndex == item.index;
                    return _SidebarNavItemButton(
                      item: item,
                      isActive: isActive,
                      isCollapsed: widget.isCollapsed,
                      onTap: () {
                        if (widget.onTabSelected != null) {
                          widget.onTabSelected!(item.index, item.route);
                        } else {
                          Navigator.pushReplacementNamed(context, item.route);
                        }
                      },
                    );
                  }),

                // If inside Resume Tailoring / CV Studio (activeIndex == 2), render Profile Sub-Sections with live counts & actions
                if (widget.activeIndex == 2) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, indent: 8, endIndent: 8),
                  const SizedBox(height: 16),

                  if (!widget.isCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 8),
                      child: Text(
                        'PROFILE SECTIONS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getMutedTextColor(context),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),

                  _buildSubNavButton(
                    context: context,
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    subIndex: 0,
                    count: null,
                  ),
                  _buildSubNavButton(
                    context: context,
                    label: 'Education',
                    icon: Icons.school_outlined,
                    subIndex: 1,
                    count: widget.sectionCounts?['education'],
                  ),
                  _buildSubNavButton(
                    context: context,
                    label: 'Skills',
                    icon: Icons.psychology_outlined,
                    subIndex: 2,
                    count: widget.sectionCounts?['skills'],
                  ),
                  _buildSubNavButton(
                    context: context,
                    label: 'Projects',
                    icon: Icons.folder_special_outlined,
                    subIndex: 3,
                    count: widget.sectionCounts?['projects'],
                  ),
                  _buildSubNavButton(
                    context: context,
                    label: 'Experience',
                    icon: Icons.work_outline_rounded,
                    subIndex: 4,
                    count: widget.sectionCounts?['experience'],
                  ),
                  _buildSubNavButton(
                    context: context,
                    label: 'Extracurriculars',
                    icon: Icons.interests_outlined,
                    subIndex: 5,
                    count: widget.sectionCounts?['extracurriculars'],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, indent: 8, endIndent: 8),
                  const SizedBox(height: 16),

                  // Sidebar Actions: Generate Resume, ATS Score
                  if (widget.isCollapsed) ...[
                    _SidebarActionButton(
                      label: 'Generate Resume',
                      icon: Icons.auto_awesome,
                      isPrimary: true,
                      isCollapsed: true,
                      onTap: () {
                        if (widget.onGenerate != null) {
                          widget.onGenerate!();
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    _SidebarActionButton(
                      label: 'ATS Score',
                      icon: Icons.analytics_outlined,
                      isPrimary: false,
                      isActive: widget.activeSubSectionIndex == 7 || widget.activeIndex == 4,
                      isCollapsed: true,
                      onTap: () {
                        if (widget.onAtsScore != null) {
                          widget.onAtsScore!();
                        } else if (widget.onSubSectionSelected != null) {
                          widget.onSubSectionSelected!(7);
                        }
                      },
                    ),
                  ] else ...[
                    _SidebarActionButton(
                      label: 'Generate Resume',
                      icon: Icons.auto_awesome,
                      isPrimary: true,
                      onTap: () {
                        if (widget.onGenerate != null) {
                          widget.onGenerate!();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _SidebarActionButton(
                      label: 'ATS Score',
                      icon: Icons.analytics_outlined,
                      isPrimary: false,
                      isActive: widget.activeSubSectionIndex == 7 || widget.activeIndex == 4,
                      onTap: () {
                        if (widget.onAtsScore != null) {
                          widget.onAtsScore!();
                        } else if (widget.onSubSectionSelected != null) {
                          widget.onSubSectionSelected!(7);
                        }
                      },
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                if (!widget.isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 8),
                    child: Text(
                      'SUPPORT & ACCOUNT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getMutedTextColor(context),
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),

                // Resume History Menu Item
                _SidebarCustomActionButton(
                  label: 'Resume History',
                  icon: Icons.history_rounded,
                  isCollapsed: widget.isCollapsed,
                  accentColor: AppTheme.primaryOrange,
                  onTap: () {
                    if (widget.onTabSelected != null) {
                      widget.onTabSelected!(5, '/history');
                    } else {
                      Navigator.pushNamed(context, '/history');
                    }
                  },
                ),

                // Report Bug Menu Item
                _SidebarCustomActionButton(
                  label: 'Report Bug',
                  icon: Icons.bug_report_outlined,
                  isCollapsed: widget.isCollapsed,
                  accentColor: const Color(0xFFEF4444),
                  onTap: () => ReportBugModal.show(context),
                ),

                // My Profile Menu Item
                _SidebarCustomActionButton(
                  label: 'My Profile',
                  icon: Icons.person_outline_rounded,
                  isCollapsed: widget.isCollapsed,
                  accentColor: const Color(0xFF3B82F6),
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),

                // Admin Dashboard Menu Item (Exposed STRICTLY to na6236786@gmail.com)
                if (auth.isAdmin)
                  _SidebarCustomActionButton(
                    label: 'Admin Dashboard',
                    icon: Icons.admin_panel_settings_rounded,
                    isCollapsed: widget.isCollapsed,
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.pushNamed(context, '/admin'),
                  ),
              ],
            ),
          ),

          // 3. User Profile Footer
          Container(
            padding: EdgeInsets.all(widget.isCollapsed ? 8 : 14),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              border: Border(
                top: BorderSide(
                  color: AppTheme.getBorderColor(context),
                  width: 1.0,
                ),
              ),
            ),
            child: widget.isCollapsed
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                          ),
                          child: ClipOval(
                            child: AvatarImageHelper.buildAvatarImage(
                              avatarUrl: user?.avatarUrl,
                              initials: initials,
                              width: 36,
                              height: 36,
                              fallbackBuilder: (context, initVal) => Center(
                                child: Text(
                                  initVal,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => ThemeService.instance.toggleTheme(),
                        icon: Icon(
                          isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 18,
                        ),
                        tooltip: 'Toggle Theme',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryOrange,
                          ),
                          child: ClipOval(
                            child: AvatarImageHelper.buildAvatarImage(
                              avatarUrl: user?.avatarUrl,
                              initials: initials,
                              width: 36,
                              height: 36,
                              fallbackBuilder: (context, initVal) => Center(
                                child: Text(
                                  initVal,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF8B949E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: Color(0xFF8B949E),
                        ),
                        onSelected: (val) async {
                          if (val == 'admin') {
                            Navigator.pushNamed(context, '/admin');
                          } else if (val == 'history') {
                            if (widget.onTabSelected != null) {
                              widget.onTabSelected!(5, '/history');
                            } else {
                              Navigator.pushNamed(context, '/history');
                            }
                          } else if (val == 'profile') {
                            Navigator.pushNamed(context, '/profile');
                          } else if (val == 'logout') {
                            await auth.signOut();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          if (auth.isAdmin)
                            const PopupMenuItem(
                              value: 'admin',
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, size: 16, color: Color(0xFF8B5CF6)),
                                  SizedBox(width: 8),
                                  Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'history',
                            child: Row(
                              children: [
                                Icon(Icons.history_rounded, size: 16, color: AppTheme.primaryOrange),
                                SizedBox(width: 8),
                                Text('Resume History'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 16),
                                SizedBox(width: 8),
                                Text('Profile Settings'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                                SizedBox(width: 8),
                                Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubNavButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int subIndex,
    int? count,
  }) {
    final isActive = widget.activeSubSectionIndex == subIndex;
    final isDarkMode = AppTheme.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          if (widget.onSubSectionSelected != null) {
            widget.onSubSectionSelected!(subIndex);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12 : 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive
                ? AppTheme.primaryOrange.withValues(alpha: isDarkMode ? 0.20 : 0.12)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryOrange.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? AppTheme.primaryOrange
                    : AppTheme.getMutedTextColor(context),
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primaryOrange
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                ),
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryOrange
                          : (isDarkMode
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItemData {
  final String label;
  final String route;
  final IconData icon;
  final int index;

  const _SidebarItemData({
    required this.label,
    required this.route,
    required this.icon,
    required this.index,
  });
}

class _SidebarNavItemButton extends StatefulWidget {
  final _SidebarItemData item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarNavItemButton({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarNavItemButton> createState() => _SidebarNavItemButtonState();
}

class _SidebarNavItemButtonState extends State<_SidebarNavItemButton> {
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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isActive
                ? AppTheme.primaryOrange.withValues(alpha: isDarkMode ? 0.22 : 0.12)
                : _isHovered
                    ? (isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04))
                    : Colors.transparent,
            border: Border.all(
              color: widget.isActive
                  ? AppTheme.primaryOrange.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: widget.isActive
                    ? AppTheme.primaryOrange
                    : _isHovered
                        ? AppTheme.getTextColor(context)
                        : AppTheme.getMutedTextColor(context),
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  widget.item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w500,
                    color: widget.isActive
                        ? AppTheme.primaryOrange
                        : _isHovered
                            ? AppTheme.getTextColor(context)
                            : AppTheme.getMutedTextColor(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarCustomActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isCollapsed;
  final Color accentColor;
  final VoidCallback onTap;

  const _SidebarCustomActionButton({
    required this.label,
    required this.icon,
    required this.isCollapsed,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SidebarCustomActionButton> createState() => _SidebarCustomActionButtonState();
}

class _SidebarCustomActionButtonState extends State<_SidebarCustomActionButton> {
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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovered
                ? widget.accentColor.withValues(alpha: isDarkMode ? 0.18 : 0.10)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _isHovered ? widget.accentColor : AppTheme.getMutedTextColor(context),
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isHovered ? widget.accentColor : AppTheme.getTextColor(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarActionButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.isActive = false,
    this.isCollapsed = false,
    required this.onTap,
  });

  @override
  State<_SidebarActionButton> createState() => _SidebarActionButtonState();
}

class _SidebarActionButtonState extends State<_SidebarActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    if (widget.isPrimary) {
      final btn = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF8800)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: _isHovered ? 0.45 : 0.25),
                  blurRadius: _isHovered ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: widget.isCollapsed ? 9 : 11,
                    horizontal: widget.isCollapsed ? 0 : 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 16, color: Colors.white),
                      if (!widget.isCollapsed) ...[
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (widget.isCollapsed) {
        return Tooltip(message: widget.label, child: btn);
      }
      return btn;
    }

    final btn = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppTheme.primaryOrange.withValues(alpha: isDarkMode ? 0.22 : 0.12)
              : _isHovered
                  ? (isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isActive
                ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                : (_isHovered
                    ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                    : AppTheme.getBorderColor(context)),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: widget.isCollapsed ? 9 : 10,
                horizontal: widget.isCollapsed ? 0 : 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isActive
                        ? AppTheme.primaryOrange
                        : (_isHovered
                            ? AppTheme.primaryOrange
                            : AppTheme.getTextColor(context)),
                  ),
                  if (!widget.isCollapsed) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
                        color: widget.isActive
                            ? AppTheme.primaryOrange
                            : (_isHovered
                                ? AppTheme.primaryOrange
                                : AppTheme.getTextColor(context)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(message: widget.label, child: btn);
    }
    return btn;
  }
}
