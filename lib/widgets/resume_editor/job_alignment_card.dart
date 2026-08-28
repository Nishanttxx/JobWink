import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

import '../../models/resume_type.dart';

class JobAlignmentCard extends StatelessWidget {
  final TextEditingController targetJobTitleController;
  final TextEditingController jobDescriptionController;
  final bool isAnalyzingKeywords;
  final double jobMatchScore;
  final ResumeType selectedResumeType;
  final ValueChanged<ResumeType>? onSelectResumeType;
  final ResumeFocusCriteriaResult? criteriaValidation;
  final VoidCallback? onChanged;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;

  const JobAlignmentCard({
    super.key,
    required this.targetJobTitleController,
    required this.jobDescriptionController,
    this.isAnalyzingKeywords = false,
    required this.jobMatchScore,
    this.selectedResumeType = ResumeType.experience,
    this.onSelectResumeType,
    this.criteriaValidation,
    this.onChanged,
    this.matchedKeywords = const [],
    this.missingKeywords = const [],
  });

  IconData _getResumeTypeIcon(ResumeType type) {
    switch (type) {
      case ResumeType.experience:
        return Icons.work_history_rounded;
      case ResumeType.project:
        return Icons.folder_special_rounded;
      case ResumeType.hybrid:
        return Icons.dashboard_customize_rounded;
      case ResumeType.fresher:
        return Icons.school_rounded;
    }
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
                  Icons.track_changes_rounded,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Targeted Job Description Alignment',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Job Title Field
          Text(
            'Job Description Title',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: targetJobTitleController,
            onChanged: (_) => onChanged?.call(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
            decoration: _inputDecoration(
              context,
              'e.g. Senior Software Engineer',
            ),
          ),
          const SizedBox(height: 12),

          // Job Description Textarea (REQUIRED)
          Row(
            children: [
              Text(
                'Job Description',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              Text(
                ' *',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(Required for AI tailoring)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getMutedTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: jobDescriptionController,
            maxLines: 4,
            onChanged: (_) => onChanged?.call(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.getTextColor(context),
            ),
            decoration: _inputDecoration(
              context,
              'Paste target job requirements, responsibilities, or bullet points here...',
              isError: jobDescriptionController.text.trim().isEmpty,
            ),
          ),
          if (jobDescriptionController.text.trim().isEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Job Description is required to tailor your resume and identify relevant keywords.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Resume Format Options Selection
          Text(
            'Target Resume Structure / Type',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.getMutedTextColor(context),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth > 520;
              return GridView.count(
                crossAxisCount: useGrid ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: useGrid ? 3.0 : 3.8,
                children: ResumeType.values.map((type) {
                  final isSelected = selectedResumeType == type;
                  return InkWell(
                    onTap: () => onSelectResumeType?.call(type),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryOrange.withValues(alpha: 0.14)
                            : (isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryOrange
                              : (isDarkMode ? const Color(0xFF30363D) : const Color(0xFFCBD5E1)),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getResumeTypeIcon(type),
                            size: 20,
                            color: isSelected ? AppTheme.primaryOrange : const Color(0xFF8B949E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  type.displayName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.getTextColor(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  type.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.getMutedTextColor(context),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  type.criteriaSummary,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.primaryOrange
                                        : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryOrange),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (criteriaValidation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: criteriaValidation!.isValid
                    ? const Color(0xFF10B981).withValues(alpha: 0.10)
                    : const Color(0xFFEF4444).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: criteriaValidation!.isValid
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : const Color(0xFFEF4444).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    criteriaValidation!.isValid
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: criteriaValidation!.isValid
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      criteriaValidation!.isValid
                          ? 'Focus criteria satisfied (${criteriaValidation!.experienceCount} Experiences, ${criteriaValidation!.projectCount} Projects)'
                          : criteriaValidation!.fullMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: criteriaValidation!.isValid
                            ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, {bool isError = false}) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.all(12),
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: AppTheme.getMutedTextColor(context).withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isError
              ? Colors.amber.withValues(alpha: 0.8)
              : (isDarkMode ? const Color(0xFF30363D) : const Color(0xFFCBD5E1)),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isError ? Colors.amber : AppTheme.primaryOrange,
          width: 1.5,
        ),
      ),
    );
  }
}
