import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'app_sidebar.dart';
import 'theme_toggle_button.dart';

/// Single global layout shell wrapping ALL authenticated screens in JobWink.
/// Ensures identical Navbar, Sidebar, spacing, alignment, and responsiveness.
class AppLayout extends StatefulWidget {
  final Widget child;
  final int activeIndex;
  final String title;

  // CV Studio Sub-navigation & Actions
  final int activeSubSectionIndex;
  final Function(int subIndex)? onSubSectionSelected;
  final Map<String, int>? sectionCounts;
  final VoidCallback? onResumePreview;
  final VoidCallback? onGenerate;
  final VoidCallback? onAtsScore;
  final VoidCallback? onUploadResume;

  const AppLayout({
    super.key,
    required this.child,
    required this.activeIndex,
    this.title = 'JobWink',
    this.activeSubSectionIndex = 0,
    this.onSubSectionSelected,
    this.sectionCounts,
    this.onResumePreview,
    this.onGenerate,
    this.onAtsScore,
    this.onUploadResume,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleTabSelected(int index, String route) {
    if (index == widget.activeIndex) return;
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.getBgColor(context),
      drawer: !isDesktop
          ? Drawer(
              child: AppSidebar(
                activeIndex: widget.activeIndex,
                onTabSelected: _handleTabSelected,
                activeSubSectionIndex: widget.activeSubSectionIndex,
                onSubSectionSelected: (subIndex) {
                  if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  widget.onSubSectionSelected?.call(subIndex);
                },
                sectionCounts: widget.sectionCounts,
                onResumePreview: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  widget.onResumePreview?.call();
                },
                onGenerate: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  widget.onGenerate?.call();
                },
                onAtsScore: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  widget.onAtsScore?.call();
                },
                onUploadResume: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                    Navigator.pop(context);
                  }
                  widget.onUploadResume?.call();
                },
              ),
            )
          : null,
      body: Row(
        children: [
          // 1. Desktop Persistent Sidebar (Identical across all routes)
          if (isDesktop)
            AppSidebar(
              activeIndex: widget.activeIndex,
              onTabSelected: _handleTabSelected,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
              activeSubSectionIndex: widget.activeSubSectionIndex,
              onSubSectionSelected: widget.onSubSectionSelected,
              sectionCounts: widget.sectionCounts,
              onResumePreview: widget.onResumePreview,
              onGenerate: widget.onGenerate,
              onAtsScore: widget.onAtsScore,
              onUploadResume: widget.onUploadResume,
            ),

          // 2. Main Page Content Shell
          Expanded(
            child: Column(
              children: [
                // Global Top Navbar (Identical across all routes)
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.getBorderColor(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Mobile Drawer Toggle Button & Brand Indicator
                      if (!isDesktop) ...[
                        IconButton(
                          icon: Icon(Icons.menu, color: AppTheme.getTextColor(context)),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          tooltip: 'Open Menu',
                        ),
                        Text(
                          'JobWink',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.home_rounded, color: AppTheme.getTextColor(context), size: 20),
                          tooltip: 'Go to Home',
                          onPressed: () => Navigator.pushNamed(context, '/landing'),
                        ),
                        const SizedBox(width: 4),
                        const ThemeToggleButton(),
                      ],

                      // Desktop Navigation Links
                      if (isDesktop) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _NavbarButton(
                                  label: 'Resume Tailoring',
                                  icon: Icons.tune_rounded,
                                  isActive: widget.activeIndex == 2 || widget.activeIndex == 0,
                                  onTap: () => _handleTabSelected(2, '/cv-studio'),
                                ),
                                const SizedBox(width: 6),
                                _NavbarButton(
                                  label: 'Swipe Matcher',
                                  icon: Icons.swipe_rounded,
                                  isActive: widget.activeIndex == 1,
                                  onTap: () => _handleTabSelected(1, '/matcher'),
                                ),
                                const SizedBox(width: 6),
                                _NavbarButton(
                                  label: 'Job Prediction',
                                  icon: Icons.analytics_rounded,
                                  isActive: widget.activeIndex == 3,
                                  onTap: () => _handleTabSelected(3, '/job-prediction'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _NavbarButton(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          isActive: false,
                          onTap: () => Navigator.pushNamed(context, '/landing'),
                        ),
                        const SizedBox(width: 6),
                        _NavbarButton(
                          label: 'Resume History',
                          icon: Icons.history_rounded,
                          isActive: widget.activeIndex == 5,
                          onTap: () => _handleTabSelected(5, '/history'),
                        ),
                        const SizedBox(width: 12),
                        const ThemeToggleButton(),
                      ],
                    ],
                  ),
                ),

                // Page Body Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavbarButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavbarButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavbarButton> createState() => _NavbarButtonState();
}

class _NavbarButtonState extends State<_NavbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryOrange;
    final defaultColor = AppTheme.getMutedTextColor(context);
    final hoveredColor = AppTheme.getTextColor(context);

    return Tooltip(
      message: widget.label == 'Home' ? 'Go to Home' : widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: widget.isActive
                      ? activeColor
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive
                      ? activeColor
                      : _isHovered
                          ? hoveredColor
                          : defaultColor,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
                    color: widget.isActive
                        ? activeColor
                        : _isHovered
                            ? hoveredColor
                            : defaultColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
