import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'app_sidebar.dart';

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
                onSubSectionSelected: widget.onSubSectionSelected,
                sectionCounts: widget.sectionCounts,
                onResumePreview: widget.onResumePreview,
                onGenerate: widget.onGenerate,
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
                      // Mobile Drawer Toggle Button
                      if (!isDesktop)
                        IconButton(
                          icon: Icon(Icons.menu, color: AppTheme.getTextColor(context)),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          tooltip: 'Open Menu',
                        ),

                      // Brand Logo / Page Context Indicator
                      Row(
                        children: [
                          if (!isDesktop) ...[
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
                          ],
                          Text(
                            widget.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getTextColor(context),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Top Navbar Navigation Links (Desktop & Tablet)
                      if (isDesktop) ...[
                        _NavbarButton(
                          label: 'Resume Tailoring',
                          icon: Icons.tune_rounded,
                          isActive: widget.activeIndex == 2,
                          onTap: () => _handleTabSelected(2, '/cv-studio'),
                        ),
                        const SizedBox(width: 8),
                        _NavbarButton(
                          label: 'Swipe Matcher',
                          icon: Icons.swipe_rounded,
                          isActive: widget.activeIndex == 1,
                          onTap: () => _handleTabSelected(1, '/matcher'),
                        ),
                        const SizedBox(width: 8),
                        _NavbarButton(
                          label: 'Job Prediction',
                          icon: Icons.analytics_rounded,
                          isActive: widget.activeIndex == 3,
                          onTap: () => _handleTabSelected(3, '/job-prediction'),
                        ),
                      ],
                      const Spacer(),
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
    return MouseRegion(
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
                    ? AppTheme.primaryOrange
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
                    ? AppTheme.primaryOrange
                    : _isHovered
                        ? Colors.white
                        : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
                  color: widget.isActive
                      ? AppTheme.primaryOrange
                      : _isHovered
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
