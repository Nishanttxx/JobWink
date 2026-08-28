import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/resume_data.dart';
import '../../services/jd_keyword_engine.dart';
import '../../theme/app_theme.dart';


class CertificationsCard extends StatelessWidget {
  final List<ExtracurricularEntry> activities;
  final List<JobKeyword>? jobKeywords;
  final VoidCallback onAddActivity;
  final Function(int index) onEditActivity;
  final Function(int index) onDeleteActivity;

  const CertificationsCard({
    super.key,
    required this.activities,
    this.jobKeywords,
    required this.onAddActivity,
    required this.onEditActivity,
    required this.onDeleteActivity,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_membership_rounded,
                      color: AppTheme.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Certifications & Activities',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onAddActivity,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
                label: Text(
                  'Add Certification / Activity',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                'No certifications or activities added yet. Click "Add Certification / Activity" to add items.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildActivityItem(context, activities[index], index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ExtracurricularEntry act, int index) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.activity.isNotEmpty ? act.activity : 'Certification / Activity Title',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    if (act.organization.isNotEmpty || act.role.isNotEmpty || act.formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [
                                if (act.role.isNotEmpty) act.role,
                                if (act.organization.isNotEmpty) act.organization,
                              ].join(' • '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.getMutedTextColor(context),
                              ),
                            ),
                          ),
                          if (act.formattedDate.isNotEmpty)
                            Text(
                              act.formattedDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getMutedTextColor(context),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onEditActivity(index),
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryOrange),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => onDeleteActivity(index),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          if (act.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    act.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 1.3,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (act.url.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.link_rounded, size: 13, color: AppTheme.primaryOrange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    act.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
