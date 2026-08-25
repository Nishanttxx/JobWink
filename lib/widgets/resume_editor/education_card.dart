import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/resume_data.dart';
import '../../services/jd_keyword_engine.dart';
import '../../theme/app_theme.dart';
import 'highlight_text.dart';


class EducationCard extends StatelessWidget {
  final List<EducationEntry> education;
  final List<JobKeyword>? jobKeywords;
  final VoidCallback onAddEducation;
  final Function(int index) onEditEducation;
  final Function(int index) onDeleteEducation;

  const EducationCard({
    super.key,
    required this.education,
    this.jobKeywords,
    required this.onAddEducation,
    required this.onEditEducation,
    required this.onDeleteEducation,
  });

  String _formatDates(EducationEntry edu) {
    final start = edu.startDate.replaceAll(RegExp(r'[\s\-–—]+$'), '').trim();
    final end = edu.endDate.replaceAll(RegExp(r'^[\s\-–—]+'), '').trim();
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }
    return start.isNotEmpty ? start : end;
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Education',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddEducation,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryOrange),
                label: Text(
                  '+ Add Education',
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

          if (education.isEmpty)
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
                'No education added yet. Click "+ Add Education" to add your qualifications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;
                if (isWide && education.length >= 2) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: education.length,
                    itemBuilder: (context, index) {
                      return _buildEduItem(context, education[index], index);
                    },
                  );
                } else {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: education.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildEduItem(context, education[index], index);
                    },
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEduItem(BuildContext context, EducationEntry edu, int index) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final dateStr = _formatDates(edu);

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
                child: HighlightText(
                  text: edu.degree.isNotEmpty ? edu.degree : 'Degree',
                  jobKeywords: jobKeywords,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => onEditEducation(index),
                icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primaryOrange),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(2),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => onDeleteEducation(index),
                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            edu.institution.isNotEmpty ? edu.institution : 'Institution',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.getMutedTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${edu.fieldOfStudy.isNotEmpty ? '${edu.fieldOfStudy} • ' : ''}$dateStr',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
