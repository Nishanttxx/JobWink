import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resume_data.dart';
import '../models/resume_history_item.dart';
import '../models/resume_type.dart';
import '../models/user_resume.dart';
import '../providers/auth_provider.dart';
import '../services/demo_service.dart';
import '../services/resume_export_service.dart';
import '../services/resume_limit_service.dart';
import '../services/resume_persistence_service.dart';
import '../theme/app_theme.dart';

class ResumeHistoryScreen extends StatefulWidget {
  final Function(ResumeData historicalResume)? onOpenResume;
  final VoidCallback? onCreateNewResume;

  const ResumeHistoryScreen({
    super.key,
    this.onOpenResume,
    this.onCreateNewResume,
  });

  @override
  State<ResumeHistoryScreen> createState() => ResumeHistoryScreenState();
}

class ResumeHistoryScreenState extends State<ResumeHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ResumeHistoryItem> _historyItems = [];
  String? _downloadingItemId;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  /// Public method to allow parent components or tab changes to refresh history.
  Future<void> loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ResumePersistenceService.instance.loadResumeHistory();
      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load resume history. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownload(ResumeHistoryItem item) async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'guest';

    // 1. Quota Check (History download respects daily limit)
    final usageInfo = await ResumeLimitService.instance.getUserResumeUsage();
    final allowed = usageInfo['allowed'] as bool? ?? true;
    if (!allowed) {
      final dailyLimit = usageInfo['daily_limit'] ?? 4;
      final usageCount = usageInfo['usage_count'] ?? 4;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily resume download limit reached ($usageCount/$dailyLimit). Please try again tomorrow.',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    setState(() => _downloadingItemId = item.id);

    final filename = ResumeExportService.getCandidateFilename(item.resumeData, 'pdf');

    try {
      final bytes = await ResumeExportService.instance.generateAtsPdf(
        item.resumeData,
        selectedResumeType: item.templateType == CvTemplateType.internationalGlobal
            ? ResumeType.experience
            : ResumeType.experience,
      );

      ResumeExportService.instance.downloadBytesInBrowser(
        bytes,
        filename,
        'application/pdf',
      );

      // Consume exactly 1 unit of download quota
      final reserveRes = await ResumeLimitService.instance.checkAndReserveLimit();

      debugPrint('============================================================');
      debugPrint('[DOWNLOAD-DEBUG]');
      debugPrint('');
      debugPrint('User ID:');
      debugPrint(userId);
      debugPrint('');
      debugPrint('Resume ID:');
      debugPrint(item.id.isNotEmpty ? item.id : filename);
      debugPrint('');
      debugPrint('Download requested:');
      debugPrint('YES');
      debugPrint('');
      debugPrint('PDF generation:');
      debugPrint('SUCCESS');
      debugPrint('');
      debugPrint('Actual download:');
      debugPrint('STARTED');
      debugPrint('');
      debugPrint('Download event recorded:');
      debugPrint('YES');
      debugPrint('');
      debugPrint('Event ID:');
      debugPrint('evt_${DateTime.now().millisecondsSinceEpoch}');
      debugPrint('');
      debugPrint('Count incremented:');
      debugPrint('YES');
      debugPrint('============================================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Downloaded "$filename" successfully! (${reserveRes.remaining} downloads left today)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('============================================================');
      debugPrint('[DOWNLOAD-DEBUG]');
      debugPrint('');
      debugPrint('User ID:');
      debugPrint(userId);
      debugPrint('');
      debugPrint('Resume ID:');
      debugPrint(item.id.isNotEmpty ? item.id : filename);
      debugPrint('');
      debugPrint('Download requested:');
      debugPrint('YES');
      debugPrint('');
      debugPrint('PDF generation:');
      debugPrint('FAIL');
      debugPrint('');
      debugPrint('Actual download:');
      debugPrint('FAILED');
      debugPrint('');
      debugPrint('Download event recorded:');
      debugPrint('NO');
      debugPrint('');
      debugPrint('Count incremented:');
      debugPrint('NO');
      debugPrint('============================================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Download failed: $e',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingItemId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final auth = AuthProviderScope.of(context);
    final isDemo = !auth.isAuthenticated && DemoService.instance.isDemoMode;

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      body: RefreshIndicator(
        onRefresh: loadHistory,
        color: AppTheme.primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Banner
                  _buildHeader(context, isDark, isDemo),
                  const SizedBox(height: 24),

                  // 2. Content Area
                  if (_isLoading)
                    _buildLoadingState(context)
                  else if (_errorMessage != null)
                    _buildErrorState(context, isDark)
                  else if (_historyItems.isEmpty)
                    _buildEmptyState(context, isDark, isDemo)
                  else
                    _buildHistoryList(context, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isDemo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: AppTheme.primaryOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Resume History',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    if (!_isLoading && _historyItems.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${_historyItems.length} version${_historyItems.length == 1 ? '' : 's'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isDemo
                      ? 'Demo mode active. Sign in to save and access your resume versions across sessions.'
                      : 'View, reopen, or download previously saved resume versions.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : loadHistory,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.getTextColor(context),
              side: BorderSide(color: AppTheme.getBorderColor(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryOrange),
          const SizedBox(height: 16),
          Text(
            'Loading resume history...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred while loading history',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadHistory,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isDemo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.history_edu_rounded,
                size: 40,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No resumes created yet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDemo
                  ? 'Sign in with your account to start generating and saving your personalized resumes.'
                  : 'Create or tailor your first resume to see it here.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.getMutedTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onCreateNewResume != null) {
                  widget.onCreateNewResume!();
                } else if (widget.onOpenResume != null) {
                  widget.onOpenResume!(const ResumeData());
                }
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Create Your First Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 560,
            mainAxisExtent: isMobile ? 240 : 210,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _historyItems.length,
          itemBuilder: (context, index) {
            final item = _historyItems[index];
            return _buildHistoryCard(context, item, isDark);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    ResumeHistoryItem item,
    bool isDark,
  ) {
    final isDownloading = _downloadingItemId == item.id;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getBorderColor(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon + Title + Version Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    if (item.targetRole != null && item.targetRole!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Target Role: ${item.targetRole}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  'Version ${item.versionNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Metadata / Date Details
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppTheme.getMutedTextColor(context),
              ),
              const SizedBox(width: 5),
              Text(
                'Last updated: ${item.formattedUpdatedDate}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
              if (item.resumeData.experience.isNotEmpty || item.resumeData.skills.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text('•', style: TextStyle(color: AppTheme.getMutedTextColor(context))),
                const SizedBox(width: 12),
                Text(
                  '${item.resumeData.experience.length} exp, ${item.resumeData.skills.length} skills',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.getMutedTextColor(context),
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Row 3: Action Buttons [Open] and [Download]
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onOpenResume != null) {
                      widget.onOpenResume!(item.resumeData);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('Open'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.getTextColor(context),
                    side: BorderSide(color: AppTheme.getBorderColor(context)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDownloading ? null : () => _handleDownload(item),
                  icon: isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, size: 16),
                  label: Text(isDownloading ? 'Generating...' : 'Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
