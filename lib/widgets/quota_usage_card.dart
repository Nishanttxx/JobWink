import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/resume_limit_service.dart';

class QuotaUsageCard extends StatefulWidget {
  final VoidCallback? onOpenAdminDashboard;

  const QuotaUsageCard({
    super.key,
    this.onOpenAdminDashboard,
  });

  @override
  State<QuotaUsageCard> createState() => _QuotaUsageCardState();
}

class _QuotaUsageCardState extends State<QuotaUsageCard> {
  bool _isLoading = true;
  int _dailyLimit = 4;
  int _usedToday = 0;
  int _remaining = 4;

  @override
  void initState() {
    super.initState();
    _loadQuotaInfo();
  }

  Future<void> _loadQuotaInfo() async {
    setState(() => _isLoading = true);
    try {
      final usage = await ResumeLimitService.instance.getUserResumeUsage();

      if (mounted) {
        setState(() {
          _dailyLimit = (usage['daily_limit'] as num? ?? 4).toInt();
          _usedToday = (usage['resumes_generated_today'] as num? ?? 0).toInt();
          _remaining = (usage['remaining'] as num? ?? (_dailyLimit - _usedToday)).toInt();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final progress = _dailyLimit > 0 ? (_usedToday / _dailyLimit).clamp(0.0, 1.0) : 0.0;
    final isExhausted = _remaining <= 0;

    final cardBg = isDarkMode ? const Color(0xFF161B22) : Colors.white;
    final borderColor = isExhausted
        ? const Color(0xFFEF4444)
        : (isDarkMode ? const Color(0xFF30363D) : const Color(0xFFE2E8F0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isExhausted ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isExhausted
                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isExhausted
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : AppTheme.primaryOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExhausted ? Icons.lock_clock_outlined : Icons.bolt_rounded,
                      color: isExhausted ? const Color(0xFFEF4444) : AppTheme.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Resume Quota',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Server-side atomic rate limit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.getMutedTextColor(context),

                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadQuotaInfo,
                tooltip: 'Refresh Quota',
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppTheme.getMutedTextColor(context),

                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 6,
              color: AppTheme.primaryOrange,
              backgroundColor: Color(0xFF21262D),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExhausted ? 'Quota Limit Reached' : 'Generations Remaining Today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isExhausted ? const Color(0xFFEF4444) : AppTheme.getTextColor(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExhausted
                        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExhausted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                  child: Text(
                    '$_usedToday / $_dailyLimit Used ($_remaining Left)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isExhausted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                color: isExhausted
                    ? const Color(0xFFEF4444)
                    : (progress > 0.75 ? Colors.amber : const Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isExhausted
                  ? 'You have used all $_dailyLimit generations for today. Limit will automatically reset tomorrow.'
                  : 'Every user starts with $_dailyLimit free resume generations per day. Standard users can request higher limits from admins.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isExhausted ? const Color(0xFFFCA5A5) : AppTheme.getMutedTextColor(context),

                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
