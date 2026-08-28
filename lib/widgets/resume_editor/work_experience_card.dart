import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/resume_data.dart';
import '../../services/jd_keyword_engine.dart';
import '../../theme/app_theme.dart';
import 'highlight_text.dart';


class WorkExperienceCard extends StatelessWidget {
  final List<ExperienceEntry> experiences;
  final List<JobKeyword>? jobKeywords;
  final VoidCallback onAddExperience;
  final Function(int index) onEditExperience;
  final Function(int index) onDeleteExperience;

  const WorkExperienceCard({
    super.key,
    required this.experiences,
    this.jobKeywords,
    required this.onAddExperience,
    required this.onEditExperience,
    required this.onDeleteExperience,
  });

  String _formatDates(ExperienceEntry exp) {
    if (exp.startDate.isEmpty && exp.endDate.isEmpty) return '';
    if (exp.startDate.isNotEmpty && exp.endDate.isNotEmpty) {
      return '${exp.startDate} - ${exp.endDate}';
    }
    return exp.startDate.isNotEmpty ? exp.startDate : exp.endDate;
  }

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
                      Icons.work_outline_rounded,
                      color: AppTheme.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Work Experience',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onAddExperience,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
                label: Text(
                  'Add Work Experience',
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

          if (experiences.isEmpty)
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
                'No work experience added yet. Click "+ Add Work Experience" to add one.',
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
              itemCount: experiences.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final exp = experiences[index];
                return _buildExperienceItem(context, exp, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem(BuildContext context, ExperienceEntry exp, int index) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final dateStr = _formatDates(exp);

    return Container(
      padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.role.isNotEmpty ? exp.role : 'Job Title',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exp.company}${dateStr.isNotEmpty ? ' • $dateStr' : ''}${exp.location.isNotEmpty ? ' • ${exp.location}' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => onEditExperience(index),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryOrange),
                    tooltip: 'Edit Experience',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onDeleteExperience(index),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    tooltip: 'Delete Experience',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ],
          ),
          if (exp.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...exp.description.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: HighlightText(
                        text: bullet,
                        jobKeywords: jobKeywords,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 1.4,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
