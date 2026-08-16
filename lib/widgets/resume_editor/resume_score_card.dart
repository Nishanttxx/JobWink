import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../ats_score_gauge.dart';

class ResumeScoreCard extends StatelessWidget {
  final double score;
  final double expRelevance;
  final double skillMatch;
  final double contentQuality;

  const ResumeScoreCard({
    super.key,
    this.score = 60,
    this.expRelevance = 66,
    this.skillMatch = 66,
    this.contentQuality = 70,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF131720) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Resume Score',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Semicircular Radial Gauge Meter (Matching screenshot: 60/100 Good Score)
          Center(
            child: SizedBox(
              height: 140,
              child: AtsScoreGauge(
                score: score.round(),
                isTriggered: true,
                showProgressBars: false,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Breakdown Progress Bars
          _buildScoreRow(context, 'Experience Relevance', expRelevance),
          const SizedBox(height: 10),
          _buildScoreRow(context, 'Skill Match', skillMatch),
          const SizedBox(height: 10),
          _buildScoreRow(context, 'Content Quality', contentQuality),
        ],
      ),
    );
  }

  Widget _buildScoreRow(BuildContext context, String label, double value) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.getMutedTextColor(context),
              ),
            ),
            Text(
              '${value.round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
          ),
        ),
      ],
    );
  }
}
