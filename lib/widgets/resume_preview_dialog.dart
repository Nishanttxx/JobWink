import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/resume_data.dart';
import '../services/resume_export_service.dart';
import '../theme/app_theme.dart';
import '../models/resume_type.dart';

/// Realistic A4 Paper Preview Dialog for JobWink Resumes.
///
/// Displays the ATS-compliant resume rendered on actual A4 sheets
/// (210mm x 297mm) with crisp margins, white paper background,
/// realistic multi-layer drop shadows, and multi-page pagination.
class ResumePreviewDialog extends StatefulWidget {
  final ResumeData resumeData;
  final ValueNotifier<ResumeData>? resumeDataNotifier;
  final ResumeType selectedResumeType;
  final ValueNotifier<ResumeType>? resumeTypeNotifier;
  final Uint8List? originalPdfBytes;
  final List<String> highlightKeywords;
  final VoidCallback onDownload;

  const ResumePreviewDialog({
    super.key,
    required this.resumeData,
    this.resumeDataNotifier,
    this.selectedResumeType = ResumeType.experience,
    this.resumeTypeNotifier,
    this.originalPdfBytes,
    this.highlightKeywords = const [],
    required this.onDownload,
  });

  static Future<void> show(
    BuildContext context, {
    required ResumeData resumeData,
    ValueNotifier<ResumeData>? resumeDataNotifier,
    ResumeType selectedResumeType = ResumeType.experience,
    ValueNotifier<ResumeType>? resumeTypeNotifier,
    Uint8List? originalPdfBytes,
    List<String> highlightKeywords = const [],
    required VoidCallback onDownload,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (dialogCtx) => ResumePreviewDialog(
        resumeData: resumeData,
        resumeDataNotifier: resumeDataNotifier,
        selectedResumeType: selectedResumeType,
        resumeTypeNotifier: resumeTypeNotifier,
        originalPdfBytes: originalPdfBytes,
        highlightKeywords: highlightKeywords,
        onDownload: onDownload,
      ),
    );
  }

  @override
  State<ResumePreviewDialog> createState() => _ResumePreviewDialogState();
}

class _ResumePreviewDialogState extends State<ResumePreviewDialog> {
  final FocusNode _focusNode = FocusNode();
  late ResumeData _currentResumeData;
  late ResumeType _currentResumeType;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentResumeData = widget.resumeDataNotifier?.value ?? widget.resumeData;
    _currentResumeType = widget.resumeTypeNotifier?.value ?? widget.selectedResumeType;

    widget.resumeDataNotifier?.addListener(_onResumeDataChanged);
    widget.resumeTypeNotifier?.addListener(_onResumeTypeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant ResumePreviewDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resumeDataNotifier != oldWidget.resumeDataNotifier) {
      oldWidget.resumeDataNotifier?.removeListener(_onResumeDataChanged);
      widget.resumeDataNotifier?.addListener(_onResumeDataChanged);
      _currentResumeData = widget.resumeDataNotifier?.value ?? widget.resumeData;
    }
    if (widget.resumeTypeNotifier != oldWidget.resumeTypeNotifier) {
      oldWidget.resumeTypeNotifier?.removeListener(_onResumeTypeChanged);
      widget.resumeTypeNotifier?.addListener(_onResumeTypeChanged);
      _currentResumeType = widget.resumeTypeNotifier?.value ?? widget.selectedResumeType;
    }
  }

  void _onResumeDataChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted && widget.resumeDataNotifier != null) {
        setState(() {
          _currentResumeData = widget.resumeDataNotifier!.value;
        });
      }
    });
  }

  void _onResumeTypeChanged() {
    if (mounted && widget.resumeTypeNotifier != null) {
      setState(() {
        _currentResumeType = widget.resumeTypeNotifier!.value;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.resumeDataNotifier?.removeListener(_onResumeDataChanged);
    widget.resumeTypeNotifier?.removeListener(_onResumeTypeChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    final dialogWidth = isMobile ? size.width * 0.96 : (size.width * 0.85).clamp(650.0, 960.0);
    final dialogHeight = isMobile ? size.height * 0.94 : (size.height * 0.90).clamp(600.0, 920.0);

    final filename = ResumeExportService.getCandidateFilename(_currentResumeData, 'pdf');

    final bool hasResume = _currentResumeData.hasUsableData ||
        (widget.originalPdfBytes != null && widget.originalPdfBytes!.isNotEmpty);
    final validation = _currentResumeType.validateCriteria(_currentResumeData);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF13151C) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── 1. Modal Header Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1B1E26) : const Color(0xFFF1F5F9),
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Resume Preview',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: (!hasResume
                                          ? AppTheme.primaryOrange
                                          : (!validation.isValid
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF10B981)))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  !hasResume
                                      ? 'NO RESUME UPLOADED'
                                      : (!validation.isValid ? 'CRITERIA NOT MET' : 'A4 • PAPER PREVIEW'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: !hasResume
                                        ? AppTheme.primaryOrange
                                        : (!validation.isValid
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasResume ? filename : 'No resume uploaded yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.getMutedTextColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Close Icon Button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close (Esc)',
                      style: IconButton.styleFrom(
                        hoverColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Realistic A4 Paper Canvas ──
              Expanded(
                child: Container(
                  color: isDarkMode ? const Color(0xFF141720) : const Color(0xFFE2E8F0),
                  child: !hasResume
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.upload_file_rounded,
                                    size: 56,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Please upload a resume',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No resume has been uploaded yet. Upload a resume file or enter details in the editor to preview your live A4 document.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.getMutedTextColor(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : !validation.isValid
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.assignment_late_outlined,
                                        size: 56,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Meet the criteria to build your resume.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.getTextColor(context),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (validation.detailMessage != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        validation.detailMessage!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: AppTheme.getMutedTextColor(context),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.getSurfaceColor(context),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.getBorderColor(context)),
                                      ),
                                      child: Text(
                                        '${_currentResumeType.displayName} Focus • Current: ${validation.experienceCount} Exp, ${validation.projectCount} Projects',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.getMutedTextColor(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : PdfPreview(
                              key: ValueKey('${_currentResumeData.hashCode}_${_currentResumeType.name}_${widget.highlightKeywords.length}'),
                              build: (PdfPageFormat format) async {
                                return await ResumeExportService.instance.generateAtsPdf(
                                  _currentResumeData,
                                  selectedResumeType: _currentResumeType,
                                  originalPdfBytes: widget.originalPdfBytes,
                                  highlightKeywords: widget.highlightKeywords,
                                );
                              },
                          // Pure paper presentation: disable fake browser UI & toolbars
                          allowPrinting: false,
                          allowSharing: false,
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          actions: const [],
                          pdfFileName: filename,
                          initialPageFormat: PdfPageFormat.a4,
                          pageFormats: const {'A4': PdfPageFormat.a4},
                          maxPageWidth: isMobile ? (dialogWidth * 0.90) : 660.0,
                          // Backdrop canvas color
                          scrollViewDecoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF141720) : const Color(0xFFE2E8F0),
                          ),
                          // Authentic A4 Paper Sheet Styling
                          pdfPreviewPageDecoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                            boxShadow: [
                              // Deep ambient drop shadow for realistic paper elevation
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.50 : 0.16),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                              // Soft contact shadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDarkMode ? 0.30 : 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          previewPageMargin: EdgeInsets.symmetric(
                            vertical: isMobile ? 18 : 28,
                            horizontal: isMobile ? 10 : 20,
                          ),
                          loadingWidget: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: AppTheme.primaryOrange),
                                const SizedBox(height: 16),
                                Text(
                                  'Rendering A4 resume preview...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onError: (context, error) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Unable to generate preview',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.toString(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.getMutedTextColor(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() {}),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryOrange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // ── 3. Modal Footer Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1B1E26) : const Color(0xFFF1F5F9),
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A4 Standard (210 × 297 mm)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getMutedTextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: AppTheme.getBorderColor(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: (hasResume && validation.isValid)
                          ? () {
                              Navigator.of(context).pop();
                              widget.onDownload();
                            }
                          : null,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        'Download Resume',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
