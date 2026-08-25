import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_match.dart';
import '../providers/auth_provider.dart';
import '../services/demo_service.dart';
import '../services/job_service.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_banner.dart';
import '../widgets/demo_upsell_dialog.dart';
import '../widgets/page_container.dart';

class SwipeMatcherScreen extends StatefulWidget {
  const SwipeMatcherScreen({super.key});

  @override
  State<SwipeMatcherScreen> createState() => _SwipeMatcherScreenState();
}

class _SwipeMatcherScreenState extends State<SwipeMatcherScreen> with SingleTickerProviderStateMixin {
  // Pre-initialize with fast queue so UI renders instantly (0ms delay)
  List<JobMatch> _jobQueue = [];
  bool _isRefreshing = false;
  int _currentIndex = 0;
  final List<JobMatch> _savedJobs = [];
  final List<JobMatch> _passedJobs = [];

  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0.0;

  late AnimationController _swipeAnimController;
  late Animation<Offset> _cardOffsetAnimation;
  late Animation<double> _cardRotationAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _swipeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _cardOffsetAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_swipeAnimController);
    _cardRotationAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_swipeAnimController);

    _swipeAnimController.addListener(() {
      setState(() {
        _cardOffset = _cardOffsetAnimation.value;
        _cardRotation = _cardRotationAnimation.value;
      });
    });

    _loadJobsInstant();
  }

  @override
  void dispose() {
    _swipeAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadJobsInstant({bool forceRefresh = false}) async {
    if (_isRefreshing) return;

    // Load instantly from service cache or fast fallback
    final initialJobs = await JobService.instance.fetchLatest48hJobs(forceRefresh: forceRefresh);
    
    if (mounted) {
      setState(() {
        _jobQueue = initialJobs;
        _currentIndex = 0;
        _isRefreshing = false;
      });
    }
  }

  void _handleSwipe(bool isRight) async {
    if (_currentIndex >= _jobQueue.length) return;

    final auth = AuthProviderScope.read(context);
    if (isRight && !auth.isAuthenticated && DemoService.instance.isDemoMode) {
      final proceed = await DemoUpsellDialog.show(
        context,
        actionTitle: 'Save Job Application',
        description:
            'Create a free account to save matches to your application tracker, track status, and apply directly.',
      );
      if (!proceed) return;
    }

    if (!mounted) return;

    final job = _jobQueue[_currentIndex];

    // Non-blocking fire-and-forget swipe logging
    JobService.instance.recordSwipeAction(
      jobId: job.id,
      isRightSwipe: isRight,
    );

    final String? targetUrl = job.applyUrl ?? job.jobUrl;
    final bool hasPortalUrl = isRight && targetUrl != null && targetUrl.isNotEmpty && targetUrl.startsWith('http');

    setState(() {
      if (isRight) {
        _savedJobs.add(job);
      } else {
        _passedJobs.add(job);
      }
      _currentIndex++;
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: hasPortalUrl ? 2500 : 1200),
        backgroundColor: isRight ? const Color(0xFF10B981) : AppTheme.getSurfaceColor(context),
        content: Text(
          isRight
              ? (hasPortalUrl
                  ? 'Saved "${job.jobTitle}"! Redirecting to job portal... 🚀'
                  : 'Saved "${job.jobTitle}"! 🎉')
              : 'Passed on "${job.jobTitle}"',
          style: GoogleFonts.plusJakartaSans(
            color: isRight ? Colors.white : AppTheme.getTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (isRight && targetUrl != null && targetUrl.isNotEmpty && targetUrl.startsWith('http')) {
      try {
        final uri = Uri.parse(targetUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching job portal URL: $e');
      }
    }
  }

  void _animateAndSwipe(bool isRight) {
    if (_isAnimating || _currentIndex >= _jobQueue.length) return;
    _isAnimating = true;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isRight ? (screenWidth > 600 ? 700.0 : 450.0) : (screenWidth > 600 ? -700.0 : -450.0);
    final targetRotation = isRight ? 0.35 : -0.35;

    _cardOffsetAnimation = Tween<Offset>(
      begin: _cardOffset,
      end: Offset(targetX, _cardOffset.dy + 35.0),
    ).animate(CurvedAnimation(
      parent: _swipeAnimController,
      curve: Curves.easeOutCubic,
    ));

    _cardRotationAnimation = Tween<double>(
      begin: _cardRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _swipeAnimController,
      curve: Curves.easeOutCubic,
    ));

    _swipeAnimController.forward(from: 0.0).then((_) {
      _handleSwipe(isRight);
      _cardOffset = Offset.zero;
      _cardRotation = 0.0;
      _isAnimating = false;
      _swipeAnimController.reset();
    });
  }

  void _showSavedJobsModal(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bookmark_added, color: AppTheme.primaryOrange, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Saved Job Applications (${_savedJobs.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_savedJobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No saved jobs yet. Swipe right on jobs to add them here!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _savedJobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final job = _savedJobs[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1B1E26) : const Color(0xFFF8FAF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.getBorderColor(context)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobTitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${job.companyName} • ${job.location}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppTheme.getMutedTextColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${job.matchPercentage.toInt()}% Match',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                            if (job.applyUrl != null && job.applyUrl!.startsWith('http')) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryOrange, size: 18),
                                tooltip: 'Apply Official',
                                onPressed: () async {
                                  final uri = Uri.parse(job.applyUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDarkMode = AppTheme.isDarkMode(context);

    return Column(
      children: [
        const DemoBanner(),
        Expanded(
          child: PageContainer(
            maxWidth: 1200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Swipe Job Matcher ⚡',
                  subtitle: 'Instant 48-hour feed. Swipe right to save high-matching roles.',
                  action: GestureDetector(
                    onTap: () => _showSavedJobsModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_outlined, color: AppTheme.primaryOrange, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Saved (${_savedJobs.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Centered Cards and Actions Section
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: isDesktop ? 620 : double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Main Interactive Card Stack View
                        if (_currentIndex < _jobQueue.length)
                          _buildInteractiveCard(context, isDesktop, isDarkMode)
                        else
                          _buildCompletedState(context, isDarkMode),

                        const SizedBox(height: 28),

                        // Action Buttons Row (Pass / Refresh / Save) Centered Directly Under Card
                        if (_currentIndex < _jobQueue.length)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pass Button (Left)
                              Tooltip(
                                message: 'Pass (Swipe Left)',
                                child: IconButton.filled(
                                  onPressed: () => _animateAndSwipe(false),
                                  icon: const Icon(Icons.close_rounded, size: 28),
                                  iconSize: 28,
                                  style: IconButton.styleFrom(
                                    backgroundColor: isDarkMode ? const Color(0xFF262933) : const Color(0xFFF1F5F9),
                                    foregroundColor: const Color(0xFFEF4444),
                                    padding: const EdgeInsets.all(18),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Instant Refresh Stack Button
                              Tooltip(
                                message: 'Refresh Feed',
                                child: IconButton.filled(
                                  onPressed: () => _loadJobsInstant(forceRefresh: true),
                                  icon: const Icon(Icons.refresh_rounded, size: 22),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.getSurfaceColor(context),
                                    foregroundColor: AppTheme.getMutedTextColor(context),
                                    padding: const EdgeInsets.all(14),
                                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Save Button (Right)
                              Tooltip(
                                message: 'Save & Apply (Swipe Right)',
                                child: IconButton.filled(
                                  onPressed: () => _animateAndSwipe(true),
                                  icon: const Icon(Icons.favorite_rounded, size: 28),
                                  iconSize: 28,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.primaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(18),
                                    elevation: 6,
                                    shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveCard(BuildContext context, bool isDesktop, bool isDarkMode) {
    final currentJob = _jobQueue[_currentIndex];
    final nextJob = (_currentIndex + 1 < _jobQueue.length) ? _jobQueue[_currentIndex + 1] : null;
    final dragProgress = (_cardOffset.dx.abs() / 250.0).clamp(0.0, 1.0);

    return SizedBox(
      width: isDesktop ? 620 : double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
      children: [
        // Stacked Background Card (3D Deck Effect with smooth scaling during drag)
        if (nextJob != null)
          Transform.translate(
            offset: Offset(0, 14 - (8 * dragProgress)),
            child: Transform.scale(
              scale: 0.94 + (0.06 * dragProgress),
              child: Opacity(
                opacity: 0.6 + (0.4 * dragProgress),
                child: _buildCardContent(context, nextJob, isDesktop, isDarkMode),
              ),
            ),
          ),

        // Foreground Active Drag Card
        GestureDetector(
          onPanUpdate: (details) {
            if (_isAnimating) return;
            setState(() {
              _cardOffset += details.delta;
              _cardRotation = (_cardOffset.dx / 320.0).clamp(-0.4, 0.4);
            });
          },
          onPanEnd: (details) {
            if (_isAnimating) return;

            final vx = details.velocity.pixelsPerSecond.dx;
            final dx = _cardOffset.dx;

            if (dx > 110 || vx > 600) {
              _animateAndSwipe(true);
            } else if (dx < -110 || vx < -600) {
              _animateAndSwipe(false);
            } else {
              _isAnimating = true;
              _cardOffsetAnimation = Tween<Offset>(
                begin: _cardOffset,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _swipeAnimController,
                curve: Curves.easeOutBack,
              ));

              _cardRotationAnimation = Tween<double>(
                begin: _cardRotation,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: _swipeAnimController,
                curve: Curves.easeOutBack,
              ));

              _swipeAnimController.forward(from: 0.0).then((_) {
                _cardOffset = Offset.zero;
                _cardRotation = 0.0;
                _isAnimating = false;
                _swipeAnimController.reset();
              });
            }
          },
          child: Transform.translate(
            offset: _cardOffset,
            child: Transform.rotate(
              angle: _cardRotation,
              child: Stack(
                children: [
                  _buildCardContent(context, currentJob, isDesktop, isDarkMode),

                  // LIKE Stamp Overlay
                  if (_cardOffset.dx > 15)
                    Positioned(
                      top: 32,
                      left: 32,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Opacity(
                          opacity: (_cardOffset.dx / 100).clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF10B981), width: 3.5),
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF10B981).withValues(alpha: 0.18),
                            ),
                            child: Text(
                              'LIKE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // PASS Stamp Overlay
                  if (_cardOffset.dx < -15)
                    Positioned(
                      top: 32,
                      right: 32,
                      child: Transform.rotate(
                        angle: 0.2,
                        child: Opacity(
                          opacity: (-_cardOffset.dx / 100).clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFEF4444), width: 3.5),
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                            ),
                            child: Text(
                              'PASS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFEF4444),
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCardContent(BuildContext context, JobMatch job, bool isDesktop, bool isDarkMode) {
    return Container(
      width: isDesktop ? 620 : double.infinity,
      constraints: const BoxConstraints(minHeight: 480),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row: Platform Badge + Posted Time + Match Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.getPrimaryLightColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.getPrimaryBorderColor(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.work_outline, size: 13, color: AppTheme.primaryOrange),
                        const SizedBox(width: 5),
                        Text(
                          job.platformSource,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 48h Time Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      job.timeAgoString,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              // Match Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 5),
                    Text(
                      '${job.matchPercentage.toStringAsFixed(0)}% Match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Job Title & Company
          Text(
            job.jobTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                job.companyName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.location_on_outlined, size: 14, color: AppTheme.getMutedTextColor(context)),
              const SizedBox(width: 4),
              Text(
                job.location,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Salary Range Pill & Direct Apply Link
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '💰 Salary: ${job.salaryRange}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
              if (job.applyUrl != null && job.applyUrl!.startsWith('http')) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse(job.applyUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new, size: 12, color: AppTheme.primaryOrange),
                        const SizedBox(width: 4),
                        Text(
                          'Apply Official',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            job.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.getBodyFont(
              fontSize: 14,
              color: AppTheme.getTextColor(context).withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Matching Skills Chips
          Text(
            'Matching Master Resume Skills:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: job.matchingSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Text(
                  '✓ $skill',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.primaryOrange, size: 64),
          const SizedBox(height: 16),
          Text(
            'All 48-hour job matches reviewed!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have reviewed all latest roles from Jooble, Adzuna, Ashby, and Crawl4AI. Automated background updates refresh every 48 hours.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadJobsInstant(forceRefresh: true),
            icon: const Icon(Icons.replay),
            label: const Text('Reload Latest 48h Queue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
