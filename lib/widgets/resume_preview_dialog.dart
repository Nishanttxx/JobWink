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

class ResumePreviewDialog extends StatefulWidget {
  final ResumeData resumeData;
  final ValueNotifier<ResumeData>? resumeDataNotifier;
  final ResumeType selectedResumeType;
  final ValueNotifier<ResumeType>? resumeTypeNotifier;
  final Uint8List? originalPdfBytes;
  final VoidCallback onDownload;

  const ResumePreviewDialog({
    super.key,
    required this.resumeData,
    this.resumeDataNotifier,
    this.selectedResumeType = ResumeType.experience,
    this.resumeTypeNotifier,
    this.originalPdfBytes,
    required this.onDownload,
  });

  static Future<void> show(
    BuildContext context, {
    required ResumeData resumeData,
    ValueNotifier<ResumeData>? resumeDataNotifier,
    ResumeType selectedResumeType = ResumeType.experience,
    ValueNotifier<ResumeType>? resumeTypeNotifier,
    Uint8List? originalPdfBytes,
    required VoidCallback onDownload,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogCtx) => ResumePreviewDialog(
        resumeData: resumeData,
        resumeDataNotifier: resumeDataNotifier,
        selectedResumeType: selectedResumeType,
        resumeTypeNotifier: resumeTypeNotifier,
        originalPdfBytes: originalPdfBytes,
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

    final dialogWidth = isMobile ? size.width * 0.95 : (size.width * 0.8).clamp(600.0, 920.0);
    final dialogHeight = isMobile ? size.height * 0.92 : size.height * 0.88;

    final filename = ResumeExportService.getCandidateFilename(_currentResumeData, 'pdf');

    final bool hasResume = _currentResumeData.hasUsableData ||
        (widget.originalPdfBytes != null && widget.originalPdfBytes!.isNotEmpty);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
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
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 4,
                offset: const Offset(0, 10),
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
                        Icons.picture_as_pdf_rounded,
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (hasResume ? const Color(0xFF10B981) : AppTheme.primaryOrange).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hasResume ? 'A4 • EXACT PDF' : 'NO RESUME UPLOADED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: hasResume ? const Color(0xFF10B981) : AppTheme.primaryOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                    // Close Button
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

              // ── 2. Exact A4 Document Viewer Canvas / Empty State ──
              Expanded(
                child: Container(
                  color: isDarkMode ? const Color(0xFF0F1117) : const Color(0xFFE2E8F0),
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
                                  'No resume has been uploaded yet. Upload a resume file or add details in the editor to preview your live A4 document.',
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
                      : PdfPreview(
                          key: ValueKey('${_currentResumeData.hashCode}_${_currentResumeType.name}'),
                          build: (PdfPageFormat format) async {
                            return await ResumeExportService.instance.generateAtsPdf(
                              _currentResumeData,
                              selectedResumeType: _currentResumeType,
                              originalPdfBytes: widget.originalPdfBytes,
                            );
                          },
                          allowPrinting: false,
                          allowSharing: false,
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          maxPageWidth: 720,
                          pdfFileName: filename,
                          previewPageMargin: const EdgeInsets.all(20),
                          initialPageFormat: PdfPageFormat.a4,
                          loadingWidget: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: AppTheme.primaryOrange),
                                const SizedBox(height: 16),
                                Text(
                                  'Generating exact A4 PDF layout...',
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
                    Text(
                      '100% ATS-Compliant A4 Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getMutedTextColor(context),
                      ),
                    ),
                    const Spacer(),
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
                      onPressed: hasResume
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
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
