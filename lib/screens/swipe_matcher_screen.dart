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
  double _scrollPosition = 0.0;
  final ValueNotifier<double> _scrollPositionNotifier = ValueNotifier<double>(0.0);
  double _dragStartX = 0.0;
  double _dragStartScrollPosition = 0.0;

  final List<JobMatch> _savedJobs = [];
  final List<JobMatch> _passedJobs = [];

  late AnimationController _animController;
  late Animation<double> _scrollAnimation;

  VoidCallback? _onAnimationCompletedCallback;
  bool _isProcessingSwipe = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _scrollAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_animController);

    _animController.addListener(() {
      _scrollPosition = _scrollAnimation.value;
      _scrollPositionNotifier.value = _scrollAnimation.value;
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final cb = _onAnimationCompletedCallback;
        _onAnimationCompletedCallback = null;
        if (cb != null) {
          cb();
        } else {
          if (mounted) {
            setState(() {
              _currentIndex = _scrollPosition.round().clamp(0, _jobQueue.isNotEmpty ? _jobQueue.length - 1 : 0);
            });
          }
        }
      }
    });

    _loadJobsInstant();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollPositionNotifier.dispose();
    super.dispose();
  }

  void _animateToPosition(double targetPosition, {VoidCallback? onComplete}) {
    if (_animController.isAnimating) {
      _animController.stop();
    }
    _onAnimationCompletedCallback = onComplete;
    final startPos = _scrollPosition;
    _scrollAnimation = Tween<double>(
      begin: startPos,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic, // power3.out equivalent
    ));
    _animController.forward(from: 0.0);
  }

  Future<void> _loadJobsInstant({bool forceRefresh = false}) async {
    if (_isRefreshing) return;

    final initialJobs = await JobService.instance.fetchLatest48hJobs(forceRefresh: forceRefresh);
    
    if (mounted) {
      setState(() {
        _jobQueue = initialJobs;
        _currentIndex = 0;
        _scrollPosition = 0.0;
        _scrollPositionNotifier.value = 0.0;
        _isRefreshing = false;
        _isProcessingSwipe = false;
      });
    }
  }

  /// Arrow button navigation only: Moves to previous job card without applying or rejecting
  void _navigatePrevious() {
    if (_isProcessingSwipe || _jobQueue.isEmpty) return;
    final current = _scrollPosition.round();
    if (current > 0) {
      _animateToPosition((current - 1).toDouble());
    }
  }

  /// Arrow button navigation only: Moves to next job card without applying or rejecting
  void _navigateNext() {
    if (_isProcessingSwipe || _jobQueue.isEmpty) return;
    final current = _scrollPosition.round();
    if (current < _jobQueue.length - 1) {
      _animateToPosition((current + 1).toDouble());
    }
  }

  /// Opens the Apply URL for a specific job using existing url_launcher mechanism with validation
  Future<void> _openJobApplyUrl(JobMatch job) async {
    String? targetUrl = job.applyUrl ?? job.jobUrl;
    if (targetUrl == null || targetUrl.trim().isEmpty) {
      debugPrint('[SwipeMatcher] No valid apply URL for job: ${job.jobTitle}');
      return;
    }

    targetUrl = targetUrl.trim();
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    try {
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[SwipeMatcher] canLaunchUrl returned false for: $targetUrl');
      }
    } catch (e) {
      debugPrint('[SwipeMatcher] Error launching job URL ($targetUrl): $e');
    }
  }

  /// Handles completion of swipe action (Right = Apply, Left = Reject)
  void _onSwipeActionCompleted({
    required bool isRightSwipe,
    required JobMatch swipedJob,
    required int activeIndex,
  }) {
    if (!mounted) return;

    setState(() {
      if (activeIndex >= 0 && activeIndex < _jobQueue.length && _jobQueue[activeIndex].id == swipedJob.id) {
        _jobQueue.removeAt(activeIndex);
      } else {
        _jobQueue.removeWhere((j) => j.id == swipedJob.id);
      }

      final maxIdx = _jobQueue.isNotEmpty ? _jobQueue.length - 1 : 0;
      _currentIndex = activeIndex.clamp(0, maxIdx);
      _scrollPosition = _currentIndex.toDouble();
      _scrollPositionNotifier.value = _scrollPosition;
    });

    if (isRightSwipe) {
      // 1. Record Apply in database / analytics
      JobService.instance.recordSwipeAction(jobId: swipedJob.id, isRightSwipe: true);
      _savedJobs.add(swipedJob);

      // 2. Feedback SnackBar
      final String? targetUrl = swipedJob.applyUrl ?? swipedJob.jobUrl;
      final bool hasUrl = targetUrl != null && targetUrl.trim().isNotEmpty;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: hasUrl ? 2200 : 1200),
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            hasUrl
                ? 'Applied to "${swipedJob.jobTitle}"! Opening website... 🚀'
                : 'Saved "${swipedJob.jobTitle}"! 🎉',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // 3. Open captured job's Apply website
      if (hasUrl) {
        _openJobApplyUrl(swipedJob);
      }
    } else {
      // LEFT SWIPE = REJECT
      // 1. Record Reject in database / analytics
      JobService.instance.recordSwipeAction(jobId: swipedJob.id, isRightSwipe: false);
      _passedJobs.add(swipedJob);

      // 2. Feedback SnackBar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppTheme.getSurfaceColor(context),
          content: Text(
            'Rejected "${swipedJob.jobTitle}"',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // CRITICAL: Left swipe NEVER opens any URL or browser tab
    }

    _isProcessingSwipe = false;
  }

  void _handlePassAction() {
    if (_isProcessingSwipe || _jobQueue.isEmpty || _currentIndex >= _jobQueue.length) return;
    final activeIdx = _scrollPosition.round().clamp(0, _jobQueue.length - 1);
    final swipedJob = _jobQueue[activeIdx];

    _isProcessingSwipe = true;
    _animateToPosition(
      (activeIdx + 1.0),
      onComplete: () => _onSwipeActionCompleted(
        isRightSwipe: false,
        swipedJob: swipedJob,
        activeIndex: activeIdx,
      ),
    );
  }

  void _handleSaveAction() async {
    if (_isProcessingSwipe || _jobQueue.isEmpty || _currentIndex >= _jobQueue.length) return;
    final activeIdx = _scrollPosition.round().clamp(0, _jobQueue.length - 1);
    final swipedJob = _jobQueue[activeIdx];

    final auth = AuthProviderScope.read(context);
    if (!auth.isAuthenticated && DemoService.instance.isDemoMode) {
      final proceed = await DemoUpsellDialog.show(
        context,
        actionTitle: 'Save Job Application',
        description:
            'Create a free account to save matches to your application tracker, track status, and apply directly.',
      );
      if (!proceed) return;
    }

    if (!mounted) return;

    _isProcessingSwipe = true;
    _animateToPosition(
      (activeIdx - 1.0),
      onComplete: () => _onSwipeActionCompleted(
        isRightSwipe: true,
        swipedJob: swipedJob,
        activeIndex: activeIdx,
      ),
    );
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business_center_rounded, color: AppTheme.primaryOrange, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${job.companyName} • ${job.location}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${job.matchPercentage.toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
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

  Widget _buildCarouselIndicators(BuildContext context, bool isDarkMode) {
    final total = _jobQueue.length;
    final activeIndex = _currentIndex.clamp(0, total > 0 ? total - 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            total > 0 ? 'Reviewing Job ${activeIndex + 1} of $total' : 'Queue Empty',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total.clamp(0, 15), (index) {
                final isActive = index == activeIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryOrange : (isDarkMode ? const Color(0xFF333846) : const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 360;
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
                  subtitle: 'Instant 48-hour feed with 10+ openings. Swipe or use arrows to browse in 3D depth.',
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
                          const SizedBox(width: 8),
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
                const SizedBox(height: 12),

                // Centered Cards and Actions Section
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: isDesktop ? 760 : double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Carousel Progress Dots
                        _buildCarouselIndicators(context, isDarkMode),

                        // Main 3D DepthCarousel View with Desktop Arrow Controls
                        if (_currentIndex < _jobQueue.length)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isDesktop) ...[
                                Tooltip(
                                  message: 'Previous Job (←)',
                                  child: IconButton(
                                    onPressed: _scrollPosition.round() > 0 ? _navigatePrevious : null,
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.getSurfaceColor(context),
                                      foregroundColor: _scrollPosition.round() > 0 ? AppTheme.getTextColor(context) : AppTheme.getMutedTextColor(context).withValues(alpha: 0.2),
                                      padding: const EdgeInsets.all(16),
                                      side: BorderSide(color: AppTheme.getBorderColor(context)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              _buildDepthCarousel(context, isDesktop, isMobile, isDarkMode),
                              if (isDesktop) ...[
                                const SizedBox(width: 16),
                                Tooltip(
                                  message: 'Next Job (→)',
                                  child: IconButton(
                                    onPressed: _scrollPosition.round() < _jobQueue.length - 1 ? _navigateNext : null,
                                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.getSurfaceColor(context),
                                      foregroundColor: _scrollPosition.round() < _jobQueue.length - 1 ? AppTheme.getTextColor(context) : AppTheme.getMutedTextColor(context).withValues(alpha: 0.2),
                                      padding: const EdgeInsets.all(16),
                                      side: BorderSide(color: AppTheme.getBorderColor(context)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          _buildCompletedState(context, isDarkMode),

                        const SizedBox(height: 20),

                        // Action Buttons Row (Previous / Pass / Refresh / Save / Next)
                        if (_currentIndex < _jobQueue.length)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Previous Button
                                  Tooltip(
                                    message: 'Previous',
                                    child: IconButton.filled(
                                      onPressed: _scrollPosition.round() > 0 ? _navigatePrevious : null,
                                      icon: Icon(Icons.arrow_back_rounded, size: isSmallMobile ? 16 : (isMobile ? 18 : 22)),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.getSurfaceColor(context),
                                        foregroundColor: _scrollPosition.round() > 0 ? AppTheme.getTextColor(context) : AppTheme.getMutedTextColor(context).withValues(alpha: 0.2),
                                        padding: EdgeInsets.all(isSmallMobile ? 8 : (isMobile ? 10 : 14)),
                                        side: BorderSide(color: AppTheme.getBorderColor(context)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
                                  // Pass Button (Left)
                                  Tooltip(
                                    message: 'Pass (Swipe Left)',
                                    child: IconButton.filled(
                                      onPressed: _handlePassAction,
                                      icon: Icon(Icons.close_rounded, size: isSmallMobile ? 22 : (isMobile ? 24 : 28)),
                                      style: IconButton.styleFrom(
                                        backgroundColor: isDarkMode ? const Color(0xFF262933) : const Color(0xFFF1F5F9),
                                        foregroundColor: const Color(0xFFEF4444),
                                        padding: EdgeInsets.all(isSmallMobile ? 10 : (isMobile ? 14 : 18)),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
                                  // Instant Refresh Stack Button
                                  Tooltip(
                                    message: 'Refresh Feed (New Random Roles)',
                                    child: IconButton.filled(
                                      onPressed: () => _loadJobsInstant(forceRefresh: true),
                                      icon: Icon(Icons.refresh_rounded, size: isSmallMobile ? 16 : (isMobile ? 18 : 22)),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.getSurfaceColor(context),
                                        foregroundColor: AppTheme.getMutedTextColor(context),
                                        padding: EdgeInsets.all(isSmallMobile ? 8 : (isMobile ? 10 : 14)),
                                        side: BorderSide(color: AppTheme.getBorderColor(context)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
                                  // Save Button (Right)
                                  Tooltip(
                                    message: 'Save & Apply (Swipe Right)',
                                    child: IconButton.filled(
                                      onPressed: _handleSaveAction,
                                      icon: Icon(Icons.favorite_rounded, size: isSmallMobile ? 22 : (isMobile ? 24 : 28)),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.primaryOrange,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.all(isSmallMobile ? 10 : (isMobile ? 14 : 18)),
                                        elevation: 6,
                                        shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isSmallMobile ? 8 : (isMobile ? 12 : 16)),
                                  // Next Button
                                  Tooltip(
                                    message: 'Next',
                                    child: IconButton.filled(
                                      onPressed: _scrollPosition.round() < _jobQueue.length - 1 ? _navigateNext : null,
                                      icon: Icon(Icons.arrow_forward_rounded, size: isSmallMobile ? 16 : (isMobile ? 18 : 22)),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.getSurfaceColor(context),
                                        foregroundColor: _scrollPosition.round() < _jobQueue.length - 1 ? AppTheme.getTextColor(context) : AppTheme.getMutedTextColor(context).withValues(alpha: 0.2),
                                        padding: EdgeInsets.all(isSmallMobile ? 8 : (isMobile ? 10 : 14)),
                                        side: BorderSide(color: AppTheme.getBorderColor(context)),
                                      ),
                                    ),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepthCarousel(BuildContext context, bool isDesktop, bool isMobile, bool isDarkMode) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = isDesktop ? 600.0 : (screenWidth - (isMobile ? 24.0 : 48.0)).clamp(280.0, 600.0);
    final cardHeight = isDesktop ? 520.0 : (MediaQuery.of(context).size.height * 0.58).clamp(440.0, 540.0);
    final total = _jobQueue.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        if (_isProcessingSwipe) return;
        if (_animController.isAnimating) {
          _animController.stop();
        }
        _dragStartX = details.globalPosition.dx;
        _dragStartScrollPosition = _scrollPosition;
      },
      onHorizontalDragUpdate: (details) {
        if (_isProcessingSwipe) return;
        final deltaX = details.globalPosition.dx - _dragStartX;
        final displacement = -deltaX / (cardWidth * 0.72);
        _scrollPosition = (_dragStartScrollPosition + displacement).clamp(
          -0.75,
          (total - 0.25).clamp(0.0, double.infinity),
        );
        _scrollPositionNotifier.value = _scrollPosition;
      },
      onHorizontalDragEnd: (details) {
        if (_isProcessingSwipe) return;
        final deltaX = details.globalPosition.dx - _dragStartX;
        final vx = details.velocity.pixelsPerSecond.dx;
        final activeIdx = _dragStartScrollPosition.round().clamp(0, total - 1);

        if (activeIdx >= total) return;
        final swipedJob = _jobQueue[activeIdx];

        // Sensible horizontal threshold (75px distance or fast flick 380px/s)
        final isRightSwipe = deltaX > 75 || vx > 380;
        final isLeftSwipe = deltaX < -75 || vx < -380;

        if (isRightSwipe) {
          // RIGHT SWIPE = APPLY
          _isProcessingSwipe = true;
          _animateToPosition(
            (activeIdx - 1.0),
            onComplete: () => _onSwipeActionCompleted(
              isRightSwipe: true,
              swipedJob: swipedJob,
              activeIndex: activeIdx,
            ),
          );
        } else if (isLeftSwipe) {
          // LEFT SWIPE = REJECT
          _isProcessingSwipe = true;
          _animateToPosition(
            (activeIdx + 1.0),
            onComplete: () => _onSwipeActionCompleted(
              isRightSwipe: false,
              swipedJob: swipedJob,
              activeIndex: activeIdx,
            ),
          );
        } else {
          // Snap back to center without triggering action
          _animateToPosition(activeIdx.toDouble());
        }
      },
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: ValueListenableBuilder<double>(
          valueListenable: _scrollPositionNotifier,
          builder: (context, currentPos, _) {
            // Calculate visible index window ([-2, +2] around fractional position)
            final minIndex = (currentPos - 2.5).floor().clamp(0, total - 1);
            final maxIndex = (currentPos + 2.5).ceil().clamp(0, total - 1);

            final List<int> visibleIndices = [];
            for (int i = minIndex; i <= maxIndex; i++) {
              visibleIndices.add(i);
            }

            // Sort visible indices descending by distance so furthest cards paint first
            // and the front card (|d| closest to 0) paints last on top.
            visibleIndices.sort((a, b) {
              final distA = (a - currentPos).abs();
              final distB = (b - currentPos).abs();
              return distB.compareTo(distA);
            });

            final activeIndex = currentPos.round().clamp(0, total - 1);
            final dragOffsetFromActive = currentPos - activeIndex;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ...visibleIndices.map((index) {
                  final job = _jobQueue[index];
                  final d = index - currentPos;
                  final absD = d.abs();

                  // 3D Depth Transforms
                  final scale = (1.0 - (0.09 * absD)).clamp(0.72, 1.0);
                  final horizontalSpread = isDesktop ? 50.0 : 32.0;
                  final xOffset = d * horizontalSpread;
                  final yOffset = absD * 8.0;
                  final rotationY = (-d * 0.10).clamp(-0.28, 0.28);
                  final opacity = (1.0 - (0.28 * absD)).clamp(0.0, 1.0);

                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // 3D perspective
                    ..translateByDouble(xOffset, yOffset, -absD * 25.0, 1.0)
                    ..scaleByDouble(scale, scale, 1.0, 1.0)
                    ..rotateY(rotationY);

                  final isFrontCard = absD < 0.5;

                  return Positioned(
                    width: cardWidth,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: matrix,
                      child: Opacity(
                        opacity: opacity,
                        child: IgnorePointer(
                          ignoring: !isFrontCard,
                          child: Stack(
                            children: [
                              _buildCardContent(context, job, isDesktop, isMobile, isDarkMode),

                              // LIKE Stamp Overlay when actively swiping right on front card
                              if (isFrontCard && dragOffsetFromActive < -0.1)
                                Positioned(
                                  top: 24,
                                  left: 24,
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: Opacity(
                                      opacity: (-dragOffsetFromActive * 2.0).clamp(0.0, 1.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFF10B981), width: 3.0),
                                          borderRadius: BorderRadius.circular(12),
                                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                        ),
                                        child: Text(
                                          'LIKE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF10B981),
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // PASS Stamp Overlay when actively swiping left on front card
                              if (isFrontCard && dragOffsetFromActive > 0.1)
                                Positioned(
                                  top: 24,
                                  right: 24,
                                  child: Transform.rotate(
                                    angle: 0.2,
                                    child: Opacity(
                                      opacity: (dragOffsetFromActive * 2.0).clamp(0.0, 1.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFEF4444), width: 3.0),
                                          borderRadius: BorderRadius.circular(12),
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                        ),
                                        child: Text(
                                          'PASS',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 22,
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
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, JobMatch job, bool isDesktop, bool isMobile, bool isDarkMode) {
    return Container(
      width: isDesktop ? 620 : double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 420 : 480),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header Row: Platform Badge + Posted Time + Match Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.getPrimaryLightColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.getPrimaryBorderColor(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.work_outline, size: 12, color: AppTheme.primaryOrange),
                            const SizedBox(width: 4),
                            Text(
                              job.platformSource,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 48h Time Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          job.timeAgoString,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getMutedTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Match Score Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '${job.matchPercentage.toStringAsFixed(0)}% Match',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Job Title & Company
            Text(
              job.jobTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    job.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13 : 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.location_on_outlined, size: 13, color: AppTheme.getMutedTextColor(context)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    job.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.getMutedTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Salary Range Pill & Direct Apply Link
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1F222B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '💰 ${job.salaryRange}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
                if (job.applyUrl != null && job.applyUrl!.trim().isNotEmpty) ...[
                  InkWell(
                    onTap: () => _openJobApplyUrl(job),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new, size: 11, color: AppTheme.primaryOrange),
                          const SizedBox(width: 4),
                          Text(
                            'Apply Official',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
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
            const SizedBox(height: 14),

            // Description
            Text(
              job.description,
              maxLines: isMobile ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.getBodyFont(
                fontSize: 13,
                color: AppTheme.getTextColor(context).withValues(alpha: 0.9),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Matching Skills Chips
            Text(
              'Matching Master Resume Skills:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.matchingSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '✓ $skill',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
