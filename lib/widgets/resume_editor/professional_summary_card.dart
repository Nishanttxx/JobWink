import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ProfessionalSummaryCard extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController summaryController;
  final bool isEnhancing;
  final VoidCallback onAiEnhance;
  final VoidCallback? onChanged;

  const ProfessionalSummaryCard({
    super.key,
    required this.titleController,
    required this.summaryController,
    this.isEnhancing = false,
    required this.onAiEnhance,
    this.onChanged,
  });

  @override
  State<ProfessionalSummaryCard> createState() => _ProfessionalSummaryCardState();
}

class _ProfessionalSummaryCardState extends State<ProfessionalSummaryCard> {
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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Professional Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.isEnhancing ? null : widget.onAiEnhance,
                icon: widget.isEnhancing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(
                  widget.isEnhancing ? 'Enhancing...' : 'AI Enhance Summary',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Resume Success Title Field
          Text(
            'Resume Success Title',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.titleController,
            onChanged: (_) => widget.onChanged?.call(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context),
            ),
            decoration: _inputDecoration(context, 'e.g. Technical Student / AI & Quality Engineering'),
          ),
          const SizedBox(height: 14),

          // Executive Summary Multiline Area
          Text(
            'Executive Summary',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.getMutedTextColor(context),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.summaryController,
            maxLines: 4,
            onChanged: (_) => widget.onChanged?.call(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.getTextColor(context),
            ),
            decoration: _inputDecoration(
              context,
              'Write a high-impact summary highlighting your technical strengths, key skills, and career achievements...',
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
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
          color: isDarkMode ? const Color(0xFF30363D) : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
      ),
    );
  }
}
