import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class DownloadSectionCard extends StatelessWidget {
  final VoidCallback onDownloadPdf;
  final VoidCallback onDownloadDocx;
  final VoidCallback onDownloadTxt;
  final bool isGenerating;

  const DownloadSectionCard({
    super.key,
    required this.onDownloadPdf,
    required this.onDownloadDocx,
    required this.onDownloadTxt,
    this.isGenerating = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (format) {
        if (format == 'pdf') onDownloadPdf();
        if (format == 'docx') onDownloadDocx();
        if (format == 'txt') onDownloadTxt();
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      color: const Color(0xFF161B22),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppTheme.primaryOrange),
              const SizedBox(width: 10),
              Text(
                'Download PDF Document (.pdf)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'docx',
          child: Row(
            children: [
              const Icon(Icons.description_rounded, size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              Text(
                'Download Word Document (.docx)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'txt',
          child: Row(
            children: [
              const Icon(Icons.text_snippet_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Text(
                'Download Plain Text File (.txt)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGenerating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.file_download_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                isGenerating ? 'Generating File...' : 'Download Tailored Resume (PDF, DOCX)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
