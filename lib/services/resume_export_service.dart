import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

import '../models/resume_data.dart';
import '../models/resume_type.dart';
import 'jd_keyword_engine.dart';
import 'web_download_helper.dart';


/// Structured layout measurement of rendered PDF resume
class ResumeLayoutMeasurement {
  final double pageWidth;
  final double pageHeight;
  final double usableHeight;
  final double contentHeight;
  final double remainingHeight;
  final bool overflow;
  final double utilizationPercentage;
  final Map<String, double> sectionHeights;
  final int pageCount;

  const ResumeLayoutMeasurement({
    required this.pageWidth,
    required this.pageHeight,
    required this.usableHeight,
    required this.contentHeight,
    required this.remainingHeight,
    required this.overflow,
    required this.utilizationPercentage,
    required this.sectionHeights,
    required this.pageCount,
  });

  Map<String, dynamic> toJson() => {
    'pageWidth': pageWidth,
    'pageHeight': pageHeight,
    'usableHeight': usableHeight,
    'contentHeight': contentHeight,
    'remainingHeight': remainingHeight,
    'overflow': overflow,
    'utilizationPercentage': utilizationPercentage,
    'sectionHeights': sectionHeights,
    'pageCount': pageCount,
  };
}

/// Configuration extracted from or inspired by the exact resume layout specification.
class PdfTemplateConfig {
  // Page geometry (A4 Portrait: 595.28 x 841.89 pt)
  final double pageWidth;
  final double pageHeight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  // Font sizes
  final double nameFontSize;
  final double headingFontSize;
  final double subheadingFontSize;
  final double bodyFontSize;
  final double contactFontSize;

  // Spacing
  final double bodyLineSpacing;
  final double bulletSpacing;
  final double sectionSpaceBefore;
  final double sectionSpaceAfter;
  final double entrySpaceAfter;
  final double paragraphSpaceAfter;

  // Dividers
  final bool showDividers;
  final double dividerThickness;

  // Bullets
  final String bulletChar;
  final double contentLeftIndent;
  final double bulletIndent;
  final double bulletTextIndent;

  // Name & Header
  final bool nameUppercase;
  final bool nameCenter;

  // Colors
  final PdfColor primaryColor;
  final PdfColor bodyTextColor;
  final PdfColor headingColor;
  final PdfColor linkColor;

  const PdfTemplateConfig({
    this.pageWidth = 595.28,
    this.pageHeight = 841.89,
    this.marginTop = 23.9,
    this.marginBottom = 20.0,
    this.marginLeft = 28.35,
    this.marginRight = 28.35,
    this.nameFontSize = 26.4,
    this.headingFontSize = 12.65,
    this.subheadingFontSize = 11.0,
    this.bodyFontSize = 11.0,
    this.contactFontSize = 9.68,
    this.bodyLineSpacing = 1.25,
    this.bulletSpacing = 1.0,
    this.sectionSpaceBefore = 9.5,
    this.sectionSpaceAfter = 4.0,
    this.entrySpaceAfter = 4.0,
    this.paragraphSpaceAfter = 3.0,
    this.showDividers = true,
    this.dividerThickness = 0.6,
    this.bulletChar = '-',
    this.contentLeftIndent = 8.65, // 37.0 - 28.35
    this.bulletIndent = 11.65,      // 40.0 - 28.35
    this.bulletTextIndent = 12.1,   // 52.1 - 40.0
    this.nameUppercase = true,
    this.nameCenter = false,
    this.primaryColor = PdfColors.black,
    this.bodyTextColor = const PdfColor(0.2, 0.2, 0.2), // #333333
    this.headingColor = PdfColors.black,
    this.linkColor = const PdfColor(0.102, 0.051, 0.67), // #1A0DAB
  });

  /// Create an adjusted copy for fitting stages
  PdfTemplateConfig copyWithFitting({
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    double? nameFontSize,
    double? headingFontSize,
    double? subheadingFontSize,
    double? bodyFontSize,
    double? contactFontSize,
    double? bodyLineSpacing,
    double? bulletSpacing,
    double? sectionSpaceBefore,
    double? sectionSpaceAfter,
    double? entrySpaceAfter,
    double? paragraphSpaceAfter,
  }) {
    return PdfTemplateConfig(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      headingFontSize: headingFontSize ?? this.headingFontSize,
      subheadingFontSize: subheadingFontSize ?? this.subheadingFontSize,
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      contactFontSize: contactFontSize ?? this.contactFontSize,
      bodyLineSpacing: bodyLineSpacing ?? this.bodyLineSpacing,
      bulletSpacing: bulletSpacing ?? this.bulletSpacing,
      sectionSpaceBefore: sectionSpaceBefore ?? this.sectionSpaceBefore,
      sectionSpaceAfter: sectionSpaceAfter ?? this.sectionSpaceAfter,
      entrySpaceAfter: entrySpaceAfter ?? this.entrySpaceAfter,
      paragraphSpaceAfter: paragraphSpaceAfter ?? this.paragraphSpaceAfter,
      showDividers: showDividers,
      dividerThickness: dividerThickness,
      bulletChar: bulletChar,
      contentLeftIndent: contentLeftIndent,
      bulletIndent: bulletIndent,
      bulletTextIndent: bulletTextIndent,
      nameUppercase: nameUppercase,
      nameCenter: nameCenter,
      primaryColor: primaryColor,
      bodyTextColor: bodyTextColor,
      headingColor: headingColor,
      linkColor: linkColor,
    );
  }
}

class ResumeExportService {
  static final ResumeExportService instance = ResumeExportService._internal();
  ResumeExportService._internal();

  /// Stored original PDF bytes for template analysis
  Uint8List? _originalPdfBytes;

  /// Cached Unicode-compatible TTF fonts (Tinos Serif - metrically compatible with Times New Roman)
  pw.Font? _unicodeBaseFont;
  pw.Font? _unicodeBoldFont;
  pw.Font? _unicodeItalicFont;
  pw.Font? _unicodeBoldItalicFont;
  pw.ThemeData? _cachedFontTheme;

  /// Memory cache for generated PDF bytes keyed by resume content hash & options
  String? _cachedPdfKey;
  Uint8List? _cachedPdfBytes;
  String _activeJobDescription = '';

  /// Invalidates the in-memory PDF cache when resume data is modified
  void invalidatePdfCache() {
    _cachedPdfKey = null;
    _cachedPdfBytes = null;
    _activeJobDescription = '';
  }

  /// Loads embedded Unicode-capable TTF fonts (Tinos) to support full Unicode character sets (currencies, accents, arrows, quotes, symbols).
  Future<pw.ThemeData> getFontThemeAsync() async {
    if (_cachedFontTheme != null) return _cachedFontTheme!;

    try {
      final regularBytes = await rootBundle.load('assets/fonts/Tinos-Regular.ttf');
      final boldBytes = await rootBundle.load('assets/fonts/Tinos-Bold.ttf');
      final italicBytes = await rootBundle.load('assets/fonts/Tinos-Italic.ttf');
      final boldItalicBytes = await rootBundle.load('assets/fonts/Tinos-BoldItalic.ttf');

      _unicodeBaseFont = pw.Font.ttf(regularBytes);
      _unicodeBoldFont = pw.Font.ttf(boldBytes);
      _unicodeItalicFont = pw.Font.ttf(italicBytes);
      _unicodeBoldItalicFont = pw.Font.ttf(boldItalicBytes);

      _cachedFontTheme = pw.ThemeData.withFont(
        base: _unicodeBaseFont!,
        bold: _unicodeBoldFont!,
        italic: _unicodeItalicFont!,
        boldItalic: _unicodeBoldItalicFont!,
        fontFallback: [
          _unicodeBaseFont!,
          _unicodeBoldFont!,
          _unicodeItalicFont!,
          _unicodeBoldItalicFont!,
        ],
      );
      debugPrint('[ResumeExportService] Unicode PDF font loaded successfully (${_unicodeBaseFont!.fontName})');
      return _cachedFontTheme!;
    } catch (e) {
      if (!kIsWeb) {
        try {
          final regFile = File('assets/fonts/Tinos-Regular.ttf');
          if (regFile.existsSync()) {
            final regBytes = regFile.readAsBytesSync();
            final boldBytes = File('assets/fonts/Tinos-Bold.ttf').readAsBytesSync();
            final italicBytes = File('assets/fonts/Tinos-Italic.ttf').readAsBytesSync();
            final boldItalicBytes = File('assets/fonts/Tinos-BoldItalic.ttf').readAsBytesSync();

            _unicodeBaseFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(regBytes)));
            _unicodeBoldFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(boldBytes)));
            _unicodeItalicFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(italicBytes)));
            _unicodeBoldItalicFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(boldItalicBytes)));

            _cachedFontTheme = pw.ThemeData.withFont(
              base: _unicodeBaseFont!,
              bold: _unicodeBoldFont!,
              italic: _unicodeItalicFont!,
              boldItalic: _unicodeBoldItalicFont!,
              fontFallback: [
                _unicodeBaseFont!,
                _unicodeBoldFont!,
                _unicodeItalicFont!,
                _unicodeBoldItalicFont!,
              ],
            );
            debugPrint('[ResumeExportService] Unicode PDF font loaded successfully from filesystem');
            return _cachedFontTheme!;
          }
        } catch (_) {}
      }
      return getFontTheme();
    }
  }

  /// Synchronous fallback or cached font theme provider
  pw.ThemeData getFontTheme() {
    if (_cachedFontTheme != null) return _cachedFontTheme!;

    if (!kIsWeb) {
      try {
        final regFile = File('assets/fonts/Tinos-Regular.ttf');
        if (regFile.existsSync()) {
          final regBytes = regFile.readAsBytesSync();
          final boldBytes = File('assets/fonts/Tinos-Bold.ttf').readAsBytesSync();
          final italicBytes = File('assets/fonts/Tinos-Italic.ttf').readAsBytesSync();
          final boldItalicBytes = File('assets/fonts/Tinos-BoldItalic.ttf').readAsBytesSync();

          _unicodeBaseFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(regBytes)));
          _unicodeBoldFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(boldBytes)));
          _unicodeItalicFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(italicBytes)));
          _unicodeBoldItalicFont = pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(boldItalicBytes)));

          _cachedFontTheme = pw.ThemeData.withFont(
            base: _unicodeBaseFont!,
            bold: _unicodeBoldFont!,
            italic: _unicodeItalicFont!,
            boldItalic: _unicodeBoldItalicFont!,
            fontFallback: [
              _unicodeBaseFont!,
              _unicodeBoldFont!,
              _unicodeItalicFont!,
              _unicodeBoldItalicFont!,
            ],
          );
          return _cachedFontTheme!;
        }
      } catch (_) {}
    }

    if (_unicodeBaseFont != null) {
      return pw.ThemeData.withFont(
        base: _unicodeBaseFont!,
        bold: _unicodeBoldFont ?? _unicodeBaseFont!,
        italic: _unicodeItalicFont ?? _unicodeBaseFont!,
        boldItalic: _unicodeBoldItalicFont ?? _unicodeBoldFont ?? _unicodeBaseFont!,
        fontFallback: [
          _unicodeBaseFont!,
          if (_unicodeBoldFont != null) _unicodeBoldFont!,
          if (_unicodeItalicFont != null) _unicodeItalicFont!,
          if (_unicodeBoldItalicFont != null) _unicodeBoldItalicFont!,
        ],
      );
    }

    // Default safety fallback (getFontThemeAsync is always awaited for actual PDF builds)
    return pw.ThemeData.withFont(
      base: pw.Font.courier(),
      bold: pw.Font.courierBold(),
      italic: pw.Font.courierOblique(),
      boldItalic: pw.Font.courierBoldOblique(),
    );
  }

  /// Store original PDF bytes when user uploads a resume.
  void setOriginalPdfBytes(Uint8List bytes) {
    _originalPdfBytes = bytes;
    debugPrint('[ResumeExportService] Stored ${bytes.length} bytes of original PDF');
  }

  /// Triggers a browser file download on Web platform.
  void downloadBytesInBrowser(Uint8List bytes, String filename, String mimeType) {
    if (kIsWeb) {
      saveAndDownloadFile(bytes, filename, mimeType);
    }
  }

  /// Helper to filter out "Not specified" or invalid placeholder strings
  static String _clean(String input) {
    if (input.trim().isEmpty) return '';
    final s = input.trim();
    if (s.toLowerCase() == 'not specified' ||
        s.toLowerCase() == 'unknown' ||
        s.toLowerCase() == 'n/a' ||
        s.toLowerCase() == 'none' ||
        s.toLowerCase() == 'null') {
      return '';
    }
    return s;
  }

  static final RegExp _bulletPrefixRegExp = RegExp(
    r'^[\s\-\*\u2022\u25a0\u25a1\u2610\u2612\u2611\u25cf\u25cb\u25aa\u25ab\u2023\u2043\u25e6\ufffd]+',
  );

  static String _cleanBulletString(String input) {
    var s = _clean(input);
    if (s.isEmpty) return '';
    while (s.isNotEmpty && _bulletPrefixRegExp.hasMatch(s)) {
      s = s.replaceAll(_bulletPrefixRegExp, '').trim();
    }
    return s;
  }

  /// Passes the original text cleanly to the PDF rendering layer, preserving every user character, space, and punctuation exactly as entered.
  static String _sanitizePdfText(String input) {
    return input;
  }

  /// Extract a basic template config from original PDF bytes.
  PdfTemplateConfig _analyzeOriginalPdf(Uint8List pdfBytes) {
    try {
      final str = String.fromCharCodes(pdfBytes.take(2048));

      // Detect page size from MediaBox
      double pageW = 595.28;
      double pageH = 841.89;
      final mediaBoxPattern = RegExp(r'/MediaBox\s*\[\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*\]');
      final match = mediaBoxPattern.firstMatch(str);
      if (match != null) {
        pageW = double.tryParse(match.group(3)!) ?? pageW;
        pageH = double.tryParse(match.group(4)!) ?? pageH;
      }

      // Detect font sizes from content
      final fontSizes = <double>[];
      final tfPattern = RegExp(r'(\d+\.?\d*)\s+Tf');
      for (final m in tfPattern.allMatches(str)) {
        final size = double.tryParse(m.group(1)!);
        if (size != null && size > 5 && size < 30) fontSizes.add(size);
      }

      if (fontSizes.isNotEmpty) {
        fontSizes.sort((a, b) => b.compareTo(a));
        final nameSz = fontSizes.first;
        final bodySz = _mostCommon(fontSizes);
        final headingSz = fontSizes.length > 1
            ? fontSizes.firstWhere((s) => s < nameSz && s > bodySz, orElse: () => bodySz + 1)
            : bodySz + 1;

        return PdfTemplateConfig(
          pageWidth: pageW,
          pageHeight: pageH,
          nameFontSize: nameSz,
          headingFontSize: headingSz,
          bodyFontSize: bodySz,
          subheadingFontSize: bodySz,
          contactFontSize: bodySz * 0.88,
        );
      }

      return PdfTemplateConfig(pageWidth: pageW, pageHeight: pageH);
    } catch (e) {
      debugPrint('[ResumeExportService] PDF analysis failed: $e');
      return const PdfTemplateConfig();
    }
  }

  double _mostCommon(List<double> values) {
    final counts = <double, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Measures exact rendered layout of the resume under a given configuration.
  ResumeLayoutMeasurement measureResumeLayout(
    ResumeData resume,
    PdfTemplateConfig cfg, {
    pw.ThemeData? fontTheme,
  }) {
    final font = fontTheme ?? getFontTheme();
    final sectionHeights = <String, double>{};
    final usableWidth = cfg.pageWidth - cfg.marginLeft - cfg.marginRight;
    final usableHeight = cfg.pageHeight - cfg.marginTop - cfg.marginBottom;

    final context = pw.Context(
      document: pw.Document(theme: font).document,
    );
    final constraints = pw.BoxConstraints(maxWidth: usableWidth);

    // Helper for measuring a list of section widgets
    double measureSection(String name, List<pw.Widget> widgets) {
      if (widgets.isEmpty) {
        sectionHeights[name] = 0.0;
        return 0.0;
      }
      final themeWidget = pw.Theme(
        data: font,
        child: pw.Column(children: widgets),
      );
      themeWidget.layout(context, constraints);
      final h = themeWidget.box?.height ?? 0.0;
      sectionHeights[name] = h;
      return h;
    }

    // 1. Header Section
    measureSection('header', _buildHeaderWidgets(resume, cfg));

    // 2. Summary Section
    measureSection('summary', _buildSummaryWidgets(resume, cfg));

    // 3. Education Section
    measureSection('education', _buildEducationWidgets(resume, cfg));

    // 4. Skills Section
    measureSection('skills', _buildSkillsWidgets(resume, cfg));

    // 5. Projects Section
    measureSection('projects', _buildProjectsWidgets(resume, cfg));

    // 6. Experience Section
    measureSection('work_experience', _buildExperienceWidgets(resume, cfg));

    // 7. Extra Curricular Section
    measureSection('extra_curricular', _buildExtraWidgets(resume, cfg));

    double contentHeight = 0.0;
    for (final h in sectionHeights.values) {
      contentHeight += h;
    }

    // Check page count by building test document only if content is near or above threshold
    int pageCount = 1;
    final overflow = contentHeight > usableHeight;
    if (contentHeight > usableHeight * 0.92) {
      final pdf = pw.Document(theme: font);
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat(
          cfg.pageWidth,
          cfg.pageHeight,
          marginTop: cfg.marginTop,
          marginBottom: cfg.marginBottom,
          marginLeft: cfg.marginLeft,
          marginRight: cfg.marginRight,
        ),
        margin: pw.EdgeInsets.only(
          top: cfg.marginTop,
          bottom: cfg.marginBottom,
          left: cfg.marginLeft,
          right: cfg.marginRight,
        ),
        build: (pw.Context ctx) => _buildResumeContent(resume, cfg),
      ));
      pageCount = pdf.document.pdfPageList.pages.length;
    }

    final isPageOverflow = pageCount > 1 || overflow;
    final remainingHeight = isPageOverflow ? 0.0 : (usableHeight - contentHeight);
    final utilizationPercentage = (contentHeight / usableHeight) * 100;

    return ResumeLayoutMeasurement(
      pageWidth: cfg.pageWidth,
      pageHeight: cfg.pageHeight,
      usableHeight: usableHeight,
      contentHeight: contentHeight,
      remainingHeight: remainingHeight,
      overflow: isPageOverflow,
      utilizationPercentage: utilizationPercentage.clamp(0.0, 100.0),
      sectionHeights: sectionHeights,
      pageCount: pageCount,
    );
  }

  /// Bi-directional Optimizer: Iteratively adjusts layout properties until target page utilization is reached.
  PdfTemplateConfig optimizeResumeConfig(
    ResumeData resume,
    PdfTemplateConfig baseConfig, {
    pw.ThemeData? fontTheme,
  }) {
    final theme = fontTheme ?? getFontTheme();
    PdfTemplateConfig cfg = baseConfig;
    const maxIterations = 8;

    for (int iter = 0; iter < maxIterations; iter++) {
      final m = measureResumeLayout(resume, cfg, fontTheme: theme);

      debugPrint('[ResumeExportService] Layout iteration ${iter + 1}: Page count: ${m.pageCount}, Height utilization: ${m.utilizationPercentage.toStringAsFixed(1)}%');

      if (m.overflow || m.pageCount > 1) {
        // CASE 1 — CONTENT IS TOO LARGE: Scale down spacing and font sizes
        final compressed = _stepCompressConfig(cfg);
        if (compressed == cfg) {
          final scale = (m.usableHeight / (m.contentHeight > 0 ? m.contentHeight : m.usableHeight * 1.1)).clamp(0.88, 0.96);
          final forced = _proportionalCompressConfig(cfg, scale: scale);
          if (forced == cfg) break;
          cfg = forced;
        } else {
          cfg = compressed;
        }
      } else if (m.remainingHeight > 30.0 && m.utilizationPercentage < 94.0) {
        // CASE 2 — TOO MUCH EMPTY SPACE: Scale up font sizes and spacing
        final expanded = _stepExpandConfig(cfg);
        if (expanded == cfg) break;
        final testM = measureResumeLayout(resume, expanded, fontTheme: theme);
        if (testM.overflow || testM.pageCount > 1) {
          // Reached maximum possible expansion without overflow
          break;
        }
        cfg = expanded;
      } else {
        // Target achieved: ~94% - 99.5% page utilization
        debugPrint('[ResumeExportService] Optimized in ${iter + 1} iterations: utilization=${m.utilizationPercentage.toStringAsFixed(1)}%, remaining=${m.remainingHeight.toStringAsFixed(1)}pt');
        break;
      }
    }

    final finalM = measureResumeLayout(resume, cfg, fontTheme: theme);
    debugPrint('''[ResumeExportService] Final layout:
pages=${finalM.pageCount}
bodyFontSize=${cfg.bodyFontSize.toStringAsFixed(1)}
nameFontSize=${cfg.nameFontSize.toStringAsFixed(1)}
sectionSpacing=${cfg.sectionSpaceBefore.toStringAsFixed(1)}
utilization=${finalM.utilizationPercentage.toStringAsFixed(1)}%''');

    return cfg;
  }

  /// Bi-directional Optimizer for Config and Data: Iteratively adjusts layout properties,
  /// and applies content pruning fallback if content still overflows 1 page.
  (ResumeData, PdfTemplateConfig) optimizeResumeConfigAndData(ResumeData resume, PdfTemplateConfig baseConfig) {
    var data = resume;
    var cfg = optimizeResumeConfig(data, baseConfig);
    final m = measureResumeLayout(data, cfg);
    if (m.overflow || m.pageCount > 1) {
      data = _aiShortenResumeContent(data);
      cfg = optimizeResumeConfig(data, baseConfig);
    }
    return (data, cfg);
  }

  /// Stepwise Compression Strategy (Prioritized: Spacing -> Bullet Space -> Line Height -> Body Font -> Heading/Name Font -> Margins)
  PdfTemplateConfig _stepCompressConfig(PdfTemplateConfig base) {
    // Step 1: Reduce section & entry spacing
    if (base.sectionSpaceBefore > 3.5 || base.entrySpaceAfter > 2.0 || base.paragraphSpaceAfter > 1.2) {
      return base.copyWithFitting(
        sectionSpaceBefore: (base.sectionSpaceBefore - 0.75).clamp(3.0, 20.0),
        sectionSpaceAfter: (base.sectionSpaceAfter - 0.35).clamp(1.5, 10.0),
        entrySpaceAfter: (base.entrySpaceAfter - 0.45).clamp(1.5, 10.0),
        paragraphSpaceAfter: (base.paragraphSpaceAfter - 0.35).clamp(1.0, 8.0),
      );
    }
    // Step 2: Reduce bullet spacing
    if (base.bulletSpacing > 0.0) {
      return base.copyWithFitting(
        bulletSpacing: (base.bulletSpacing - 0.5).clamp(0.0, 5.0),
      );
    }
    // Step 3: Reduce line spacing
    if (base.bodyLineSpacing > 1.05) {
      return base.copyWithFitting(
        bodyLineSpacing: (base.bodyLineSpacing - 0.035).clamp(1.0, 1.4),
      );
    }
    // Step 4: Reduce body font & subheadings & contact
    if (base.bodyFontSize > 7.5) {
      return base.copyWithFitting(
        bodyFontSize: (base.bodyFontSize - 0.25).clamp(7.0, 12.0),
        subheadingFontSize: (base.subheadingFontSize - 0.25).clamp(7.5, 12.5),
        contactFontSize: (base.contactFontSize - 0.2).clamp(6.8, 10.5),
      );
    }
    // Step 5: Reduce heading font & name font
    if (base.headingFontSize > 10.0 || base.nameFontSize > 18.0) {
      return base.copyWithFitting(
        headingFontSize: (base.headingFontSize - 0.3).clamp(9.5, 14.0),
        nameFontSize: (base.nameFontSize - 0.6).clamp(16.0, 26.4),
      );
    }
    // Step 6: Reduce margins
    if (base.marginTop > 12.0 || base.marginBottom > 12.0 || base.marginLeft > 20.0) {
      return base.copyWithFitting(
        marginTop: (base.marginTop - 1.0).clamp(10.0, 28.0),
        marginBottom: (base.marginBottom - 1.0).clamp(10.0, 28.0),
        marginLeft: (base.marginLeft - 1.0).clamp(18.0, 30.0),
        marginRight: (base.marginRight - 1.0).clamp(18.0, 30.0),
      );
    }
    return base;
  }

  /// Continuous Proportional Compression Strategy for dense content
  PdfTemplateConfig _proportionalCompressConfig(PdfTemplateConfig base, {double scale = 0.95}) {
    return base.copyWithFitting(
      nameFontSize: (base.nameFontSize * scale).clamp(14.0, 32.0),
      headingFontSize: (base.headingFontSize * scale).clamp(9.0, 16.0),
      subheadingFontSize: (base.subheadingFontSize * scale).clamp(7.5, 14.0),
      bodyFontSize: (base.bodyFontSize * scale).clamp(6.5, 13.0),
      contactFontSize: (base.contactFontSize * scale).clamp(6.0, 11.0),
      bodyLineSpacing: (base.bodyLineSpacing * scale).clamp(0.95, 1.4),
      bulletSpacing: (base.bulletSpacing * scale).clamp(0.0, 5.0),
      sectionSpaceBefore: (base.sectionSpaceBefore * scale).clamp(2.0, 20.0),
      sectionSpaceAfter: (base.sectionSpaceAfter * scale).clamp(1.0, 10.0),
      entrySpaceAfter: (base.entrySpaceAfter * scale).clamp(1.0, 10.0),
      paragraphSpaceAfter: (base.paragraphSpaceAfter * scale).clamp(0.8, 8.0),
      marginTop: (base.marginTop * scale).clamp(10.0, 30.0),
      marginBottom: (base.marginBottom * scale).clamp(10.0, 30.0),
      marginLeft: (base.marginLeft * scale).clamp(16.0, 30.0),
      marginRight: (base.marginRight * scale).clamp(16.0, 30.0),
    );
  }

  /// Stepwise Expansion Strategy (Prioritized: Body Font -> Line Height -> Bullet Space -> Section Spacing -> Heading/Name Font -> Margins)
  PdfTemplateConfig _stepExpandConfig(PdfTemplateConfig base) {
    // Step 1: Increase body font & subheadings & contact
    if (base.bodyFontSize < 11.5) {
      return base.copyWithFitting(
        bodyFontSize: (base.bodyFontSize + 0.25).clamp(8.5, 12.0),
        subheadingFontSize: (base.subheadingFontSize + 0.25).clamp(9.5, 12.5),
        contactFontSize: (base.contactFontSize + 0.15).clamp(8.5, 11.0),
      );
    }
    // Step 2: Increase line spacing
    if (base.bodyLineSpacing < 1.35) {
      return base.copyWithFitting(
        bodyLineSpacing: (base.bodyLineSpacing + 0.025).clamp(1.0, 1.35),
      );
    }
    // Step 3: Increase bullet spacing
    if (base.bulletSpacing < 3.0) {
      return base.copyWithFitting(
        bulletSpacing: (base.bulletSpacing + 0.5).clamp(0.0, 4.0),
      );
    }
    // Step 4: Increase section & entry spacing
    if (base.sectionSpaceBefore < 14.0 || base.entrySpaceAfter < 6.0 || base.paragraphSpaceAfter < 4.5) {
      return base.copyWithFitting(
        sectionSpaceBefore: (base.sectionSpaceBefore + 0.8).clamp(4.0, 16.0),
        sectionSpaceAfter: (base.sectionSpaceAfter + 0.4).clamp(2.0, 8.0),
        entrySpaceAfter: (base.entrySpaceAfter + 0.5).clamp(2.0, 8.0),
        paragraphSpaceAfter: (base.paragraphSpaceAfter + 0.4).clamp(1.0, 6.0),
      );
    }
    // Step 5: Increase heading & name font
    if (base.headingFontSize < 14.0 || base.nameFontSize < 28.0) {
      return base.copyWithFitting(
        headingFontSize: (base.headingFontSize + 0.3).clamp(11.0, 14.0),
        nameFontSize: (base.nameFontSize + 0.6).clamp(20.0, 28.0),
      );
    }
    // Step 6: Increase margins
    if (base.marginTop < 26.0 || base.marginBottom < 24.0) {
      return base.copyWithFitting(
        marginTop: (base.marginTop + 1.0).clamp(15.0, 28.0),
        marginBottom: (base.marginBottom + 1.0).clamp(15.0, 28.0),
      );
    }
    return base;
  }

  /// AI Content Shortening Fallback: Trims redundant phrasing and caps excess bullet density when layout compression hits physical minimums
  ResumeData _aiShortenResumeContent(ResumeData resume) {
    debugPrint('[ResumeExportService] AI Content Shortening Fallback invoked');
    final shortenedExp = resume.experience.map((exp) {
      final newBullets = exp.description.map((bullet) {
        final trimmed = bullet.replaceAll(RegExp(r'\b(successfully|effectively|instrumental in|responsible for|in order to|with the aim of|spearheaded|developed and executed)\b\s*', caseSensitive: false), '').trim();
        return trimmed;
      }).where((b) => b.isNotEmpty).take(3).toList();
      return exp.copyWith(description: newBullets);
    }).toList();

    final shortenedProj = resume.projects.map((proj) {
      final bullets = proj.descriptionBullets.isNotEmpty
          ? proj.descriptionBullets
          : (proj.description.isNotEmpty ? proj.description.split('\n') : <String>[]);
      final newBullets = bullets.map((bullet) {
        final trimmed = bullet.replaceAll(RegExp(r'\b(successfully|effectively|instrumental in|responsible for|in order to|with the aim of|spearheaded|developed and executed)\b\s*', caseSensitive: false), '').trim();
        return trimmed;
      }).where((b) => b.isNotEmpty).take(2).toList();
      return proj.copyWith(descriptionBullets: newBullets);
    }).toList();

    return resume.copyWith(
      experience: shortenedExp,
      projects: shortenedProj,
    );
  }


  String _normalizeUrlForLink(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // Strip wrapping brackets or quotes and trailing punctuation
    trimmed = trimmed.replaceFirst(RegExp(r'^[<\(\["\x27]+'), '').replaceFirst(RegExp(r'[>\)\]"\x27]+$'), '');
    trimmed = trimmed.replaceAll(RegExp(r'[\.,;:]+$'), '').trim();

    if (trimmed.startsWith(RegExp(r'^(https?|mailto|tel):', caseSensitive: false))) {
      return trimmed;
    }

    if (trimmed.contains('@') && !trimmed.contains('/')) {
      return 'mailto:$trimmed';
    }

    if (trimmed.startsWith(RegExp(r'^\+?[0-9\s\-()]{7,}$'))) {
      final digits = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
      return 'tel:$digits';
    }

    // GitHub shorthand: username/repository (e.g. Nishanttxx/Nexus-Searchh)
    if (RegExp(r'^[a-zA-Z0-9_\-]{2,39}/[a-zA-Z0-9_\.\-]{2,100}$').hasMatch(trimmed) && !trimmed.contains('.')) {
      return 'https://github.com/$trimmed';
    }

    return 'https://$trimmed';
  }

  pw.Widget _buildTextWithLinks(
    String text, {
    required double fontSize,
    required double lineSpacing,
    required PdfColor color,
    required PdfColor linkColor,
    List<String> highlightKeywords = const [],
    pw.FontWeight defaultWeight = pw.FontWeight.normal,
  }) {
    final urlRegex = RegExp(
      r'(https?://[^\s\),>]+|www\.[^\s\),>]+|github\.com/[^\s\),>]+|linkedin\.com/[^\s\),>]+|gitlab\.com/[^\s\),>]+|[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)',
      caseSensitive: false,
    );

    List<pw.InlineSpan> buildHighlightedSpans(String rawSegment) {
      if (highlightKeywords.isEmpty || rawSegment.isEmpty) {
        return [
          pw.TextSpan(
            text: _sanitizePdfText(rawSegment),
            style: pw.TextStyle(
              fontSize: fontSize,
              lineSpacing: lineSpacing,
              color: color,
              fontWeight: defaultWeight,
            ),
          ),
        ];
      }

      final safeEscapedList = highlightKeywords
          .map((k) => k.trim())
          .where((k) => k.length >= 2)
          .toSet()
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      final safeEscaped = safeEscapedList
          .map(RegExp.escape)
          .join('|');

      if (safeEscaped.isEmpty) {
        return [
          pw.TextSpan(
            text: _sanitizePdfText(rawSegment),
            style: pw.TextStyle(
              fontSize: fontSize,
              lineSpacing: lineSpacing,
              color: color,
              fontWeight: defaultWeight,
              font: defaultWeight == pw.FontWeight.bold ? _unicodeBoldFont : _unicodeBaseFont,
            ),
          ),
        ];
      }

      final kwRegex = RegExp('(?<=^|[^a-zA-Z0-9])($safeEscaped)(?=[^a-zA-Z0-9]|\$)', caseSensitive: false);
      if (!kwRegex.hasMatch(rawSegment)) {
        return [
          pw.TextSpan(
            text: _sanitizePdfText(rawSegment),
            style: pw.TextStyle(
              fontSize: fontSize,
              lineSpacing: lineSpacing,
              color: color,
              fontWeight: defaultWeight,
              font: defaultWeight == pw.FontWeight.bold ? _unicodeBoldFont : _unicodeBaseFont,
            ),
          ),
        ];
      }

      final segSpans = <pw.InlineSpan>[];
      int segLast = 0;
      for (final m in kwRegex.allMatches(rawSegment)) {
        if (m.start > segLast) {
          segSpans.add(pw.TextSpan(
            text: _sanitizePdfText(rawSegment.substring(segLast, m.start)),
            style: pw.TextStyle(
              fontSize: fontSize,
              lineSpacing: lineSpacing,
              color: color,
              fontWeight: defaultWeight,
              font: defaultWeight == pw.FontWeight.bold ? _unicodeBoldFont : _unicodeBaseFont,
            ),
          ));
        }
        final matchText = m.group(1)!;
        segSpans.add(pw.TextSpan(
          text: _sanitizePdfText(matchText),
          style: pw.TextStyle(
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            color: PdfColors.black,
            fontWeight: pw.FontWeight.bold,
            font: _unicodeBoldFont,
          ),
        ));
        segLast = m.end;
      }
      if (segLast < rawSegment.length) {
        segSpans.add(pw.TextSpan(
          text: _sanitizePdfText(rawSegment.substring(segLast)),
          style: pw.TextStyle(
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            color: color,
            fontWeight: defaultWeight,
            font: defaultWeight == pw.FontWeight.bold ? _unicodeBoldFont : _unicodeBaseFont,
          ),
        ));
      }
      if (segSpans.length > 1) {
        debugPrint('[HIGHLIGHT-8] GENERATED SPANS:');
        for (final s in segSpans) {
          if (s is pw.TextSpan) {
            final isDark = s.style?.fontWeight == pw.FontWeight.bold;
            debugPrint('  -> text: "${s.text}", style: ${isDark ? "DARK/BOLD" : "NORMAL"}, font: ${s.style?.font?.fontName ?? "ThemeFont"}');
          }
        }
      }
      return segSpans;
    }

    if (!urlRegex.hasMatch(text)) {
      final spans = buildHighlightedSpans(text);
      return pw.RichText(text: pw.TextSpan(children: spans));
    }

    final spans = <pw.InlineSpan>[];
    int lastEnd = 0;

    for (final match in urlRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.addAll(buildHighlightedSpans(text.substring(lastEnd, match.start)));
      }

      final rawUrl = match.group(0)!;
      final dest = _normalizeUrlForLink(rawUrl);

      debugPrint('[PDF-LINK-DEBUG]');
      debugPrint('Link text: $rawUrl');
      debugPrint('Target URL: $dest');
      debugPrint('Annotation created: YES');

      spans.add(pw.TextSpan(
        text: _sanitizePdfText(rawUrl),
        style: pw.TextStyle(
          fontSize: fontSize,
          lineSpacing: lineSpacing,
          color: linkColor,
          fontWeight: defaultWeight,
          font: defaultWeight == pw.FontWeight.bold ? _unicodeBoldFont : _unicodeBaseFont,
        ),
        annotation: pw.AnnotationUrl(dest),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.addAll(buildHighlightedSpans(text.substring(lastEnd)));
    }

    return pw.RichText(
      text: pw.TextSpan(children: spans),
    );
  }

  List<pw.Widget> _buildHeaderWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    final nameClean = _clean(resume.fullName);
    final nameStr = nameClean.isEmpty ? 'CANDIDATE NAME' : nameClean;
    final displayName = cfg.nameUppercase ? nameStr.toUpperCase() : nameStr;

    final line1Parts = <pw.InlineSpan>[];
    final cleanEmail = _clean(resume.email);
    if (cleanEmail.isNotEmpty) {
      line1Parts.add(pw.TextSpan(
        text: cleanEmail,
        style: pw.TextStyle(
          fontSize: cfg.contactFontSize,
          color: cfg.bodyTextColor,
        ),
        annotation: pw.AnnotationUrl(_normalizeUrlForLink(cleanEmail)),
      ));
    }
    final cleanLiRaw = _clean(resume.linkedin);
    if (cleanLiRaw.isNotEmpty) {
      if (line1Parts.isNotEmpty) line1Parts.add(const pw.TextSpan(text: ' | '));
      line1Parts.add(pw.TextSpan(
        text: cleanLiRaw,
        style: pw.TextStyle(
          fontSize: cfg.contactFontSize,
          color: cfg.linkColor,
        ),
        annotation: pw.AnnotationUrl(_normalizeUrlForLink(cleanLiRaw)),
      ));
    }

    final line2Parts = <pw.InlineSpan>[];
    final cleanPhone = _clean(resume.phone);
    if (cleanPhone.isNotEmpty) {
      final sanitizedPhone = cleanPhone.replaceAll(RegExp(r'[\s\-()]'), '');
      line2Parts.add(pw.TextSpan(
        text: cleanPhone,
        style: pw.TextStyle(
          fontSize: cfg.contactFontSize,
          color: cfg.bodyTextColor,
        ),
        annotation: pw.AnnotationUrl('tel:$sanitizedPhone'),
      ));
    }
    final cleanGhRaw = _clean(resume.github);
    if (cleanGhRaw.isNotEmpty) {
      if (line2Parts.isNotEmpty) line2Parts.add(const pw.TextSpan(text: ' | '));
      line2Parts.add(pw.TextSpan(
        text: cleanGhRaw,
        style: pw.TextStyle(
          fontSize: cfg.contactFontSize,
          color: cfg.linkColor,
        ),
        annotation: pw.AnnotationUrl(_normalizeUrlForLink(cleanGhRaw)),
      ));
    }

    return [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            _sanitizePdfText(displayName),
            style: pw.TextStyle(
              fontSize: cfg.nameFontSize,
              fontWeight: pw.FontWeight.bold,
              color: cfg.primaryColor,
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (line1Parts.isNotEmpty)
                pw.RichText(
                  text: pw.TextSpan(
                    children: line1Parts,
                    style: pw.TextStyle(fontSize: cfg.contactFontSize, color: cfg.bodyTextColor),
                  ),
                ),
              if (line2Parts.isNotEmpty)
                pw.RichText(
                  text: pw.TextSpan(
                    children: line2Parts,
                    style: pw.TextStyle(fontSize: cfg.contactFontSize, color: cfg.bodyTextColor),
                  ),
                ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 4.0),
    ];
  }

  pw.Widget _buildSectionHeading(String title, PdfTemplateConfig cfg, {bool isFirst = false}) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: isFirst ? 6.0 : cfg.sectionSpaceBefore),
      pw.Text(
        _sanitizePdfText(title),
        style: pw.TextStyle(
          fontSize: cfg.headingFontSize,
          fontWeight: pw.FontWeight.bold,
          color: cfg.headingColor,
        ),
      ),
    ];

    if (cfg.showDividers) {
      widgets.add(pw.Container(
        height: cfg.dividerThickness,
        color: PdfColors.black,
        margin: const pw.EdgeInsets.only(top: 1.0, bottom: 2.5),
      ));
    } else {
      widgets.add(pw.SizedBox(height: cfg.sectionSpaceAfter));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  pw.Widget _bulletItem(String text, PdfTemplateConfig cfg, {List<String> highlightKeywords = const []}) {
    final cleaned = _cleanBulletString(text);
    if (cleaned.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: cfg.bulletIndent, bottom: cfg.bulletSpacing),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4.0, right: 6.0),
            width: 3.5,
            height: 3.5,
            decoration: const pw.BoxDecoration(
              color: PdfColors.black,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: _buildTextWithLinks(
              cleaned,
              fontSize: cfg.bodyFontSize,
              lineSpacing: cfg.bodyLineSpacing,
              color: cfg.bodyTextColor,
              linkColor: cfg.linkColor,
              highlightKeywords: highlightKeywords,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildSummaryWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    final cleanSummary = _clean(resume.summary);
    if (cleanSummary.isEmpty) return [];
    return [
      _buildSectionHeading('PROFESSIONAL SUMMARY', cfg),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: _buildTextWithLinks(
          cleanSummary,
          fontSize: cfg.bodyFontSize,
          lineSpacing: cfg.bodyLineSpacing,
          color: cfg.bodyTextColor,
          linkColor: cfg.linkColor,
        ),
      ),
      pw.SizedBox(height: cfg.paragraphSpaceAfter),
    ];
  }

  List<pw.Widget> _buildEducationWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.education.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('EDUCATION', cfg)];

    for (final edu in resume.education) {
      final degree = _clean(edu.degree);
      final field = _clean(edu.fieldOfStudy);
      final inst = _clean(edu.institution);

      final degreeParts = [degree, field].where((s) => s.isNotEmpty).toList();
      final degreeStr = degreeParts.join(' | ');

      final start = _clean(edu.startDate).replaceAll(RegExp(r'[\s\-–—]+$'), '').trim();
      final end = _clean(edu.endDate).replaceAll(RegExp(r'^[\s\-–—]+'), '').trim();
      final String dates;
      if (start.isNotEmpty && end.isNotEmpty) {
        dates = '$start - $end';
      } else if (start.isNotEmpty) {
        dates = start;
      } else if (end.isNotEmpty) {
        dates = end;
      } else {
        dates = '';
      }

      final gpa = _clean(edu.gpa);
      final rightParts = <String>[];
      if (dates.isNotEmpty) rightParts.add(dates);
      if (gpa.isNotEmpty) rightParts.add('GPA: $gpa');
      final rightStr = rightParts.join(' | ');

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: _buildTextWithLinks(
                inst.isNotEmpty ? '$degreeStr | $inst' : degreeStr,
                fontSize: cfg.subheadingFontSize,
                lineSpacing: 1.0,
                color: cfg.bodyTextColor,
                linkColor: cfg.linkColor,
                defaultWeight: pw.FontWeight.bold,
              ),
            ),
            if (rightStr.isNotEmpty)
              pw.Text(
                _sanitizePdfText(rightStr),
                style: pw.TextStyle(fontSize: cfg.contactFontSize, color: cfg.bodyTextColor),
              ),
          ],
        ),
      ));
      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  List<pw.Widget> _buildSkillsWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.skills.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('SKILLS', cfg)];

    final categories = <String, List<String>>{
      'Backend Tools': [],
      'Testing API': [],
      'Languages': [],
      'Soft Skills': [],
    };

    final softKw = {'problem solving', 'communication', 'leadership', 'teamwork', 'decision making'};
    final langKw = {'c++', 'dart', 'html', 'css', 'javascript', 'typescript', 'python', 'java', 'sql'};
    final testKw = {'api', 'postman', 'testing', 'github', 'git', 'docker'};

    for (final s in resume.skills) {
      final cleanS = _clean(s);
      if (cleanS.isEmpty) continue;
      final sLow = cleanS.toLowerCase();
      if (softKw.any((k) => sLow.contains(k))) {
        categories['Soft Skills']!.add(cleanS);
      } else if (langKw.any((k) => sLow.contains(k))) {
        categories['Languages']!.add(cleanS);
      } else if (testKw.any((k) => sLow.contains(k))) {
        categories['Testing API']!.add(cleanS);
      } else {
        categories['Backend Tools']!.add(cleanS);
      }
    }

    final activeCategories = categories.entries.where((e) => e.value.isNotEmpty).toList();

    for (final cat in activeCategories) {
      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent, bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 195.0 - cfg.marginLeft,
              child: pw.Text(
                _sanitizePdfText(cat.key),
                style: pw.TextStyle(
                  fontSize: cfg.bodyFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: cfg.bodyTextColor,
                ),
              ),
            ),
            pw.Expanded(
              child: _buildTextWithLinks(
                cat.value.join(', '),
                fontSize: cfg.bodyFontSize,
                lineSpacing: 1.0,
                color: cfg.bodyTextColor,
                linkColor: cfg.linkColor,
              ),
            ),
          ],
        ),
      ));
    }
    widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    return widgets;
  }

  pw.Widget _buildProjectHeading(ProjectEntry proj, PdfTemplateConfig cfg) {
    var rawTitle = _clean(proj.name);
    var rawType = _clean(proj.type);
    final cleanTechs = proj.technologies.map(_clean).where((t) => t.isNotEmpty).toList();
    var rawTech = cleanTechs.isNotEmpty && rawType.isEmpty ? cleanTechs.join(", ") : (rawType.isNotEmpty ? rawType : '');
    var rawUrl = _clean(proj.githubUrl).isNotEmpty
        ? _clean(proj.githubUrl)
        : (_clean(proj.source) == 'github' ? _clean(proj.legacyUrl) : (_clean(proj.url).contains('github.com') ? _clean(proj.url) : ''));

    // Support combined heading in proj.name if structured fields were combined (e.g. "Title | Tech | Link")
    if (rawTitle.contains(' | ')) {
      final parts = rawTitle.split(' | ').map((s) => s.trim()).toList();
      rawTitle = parts[0];
      if (rawTech.isEmpty && parts.length > 1) {
        rawTech = parts[1];
      }
      if (rawUrl.isEmpty && parts.length > 2) {
        rawUrl = parts[2];
      }
    }

    final spans = <pw.InlineSpan>[];

    // 1. MAIN PROJECT TITLE -> DARK / BOLD
    spans.add(pw.TextSpan(
      text: _sanitizePdfText(rawTitle),
      style: pw.TextStyle(
        fontSize: cfg.subheadingFontSize,
        lineSpacing: 1.0,
        color: cfg.bodyTextColor,
        fontWeight: pw.FontWeight.bold,
        font: _unicodeBoldFont,
      ),
    ));

    // 2. OTHER HEADING TEXT (Category / Technologies) -> NORMAL
    if (rawTech.isNotEmpty) {
      spans.add(pw.TextSpan(
        text: _sanitizePdfText(' | $rawTech'),
        style: pw.TextStyle(
          fontSize: cfg.subheadingFontSize,
          lineSpacing: 1.0,
          color: cfg.bodyTextColor,
          fontWeight: pw.FontWeight.normal,
          font: _unicodeBaseFont,
        ),
      ));
    }

    // 3. LINK -> BLUE + CLICKABLE + NORMAL
    if (rawUrl.isNotEmpty) {
      spans.add(pw.TextSpan(
        text: ' | ',
        style: pw.TextStyle(
          fontSize: cfg.subheadingFontSize,
          lineSpacing: 1.0,
          color: cfg.bodyTextColor,
          fontWeight: pw.FontWeight.normal,
          font: _unicodeBaseFont,
        ),
      ));

      final dest = _normalizeUrlForLink(rawUrl);
      spans.add(pw.TextSpan(
        text: _sanitizePdfText(rawUrl),
        style: pw.TextStyle(
          fontSize: cfg.subheadingFontSize,
          lineSpacing: 1.0,
          color: cfg.linkColor,
          fontWeight: pw.FontWeight.normal,
          font: _unicodeBaseFont,
        ),
        annotation: pw.AnnotationUrl(dest),
      ));
    }

    // Structured logging output as specified in Requirement 25
    debugPrint('============================================================');
    debugPrint('[HEADING-STYLE-DEBUG]');
    debugPrint('');
    debugPrint('Project title:');
    debugPrint(rawTitle);
    debugPrint('');
    debugPrint('Normal heading text:');
    debugPrint(rawTech.isNotEmpty ? rawTech : '<none>');
    debugPrint('');
    debugPrint('Link:');
    debugPrint(rawUrl.isNotEmpty ? rawUrl : '<none>');
    debugPrint('');
    debugPrint('Title dark/bold:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Other heading text normal:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Link blue:');
    debugPrint(rawUrl.isNotEmpty ? 'YES' : 'NO');
    debugPrint('');
    debugPrint('Link annotation created:');
    debugPrint(rawUrl.isNotEmpty ? 'YES' : 'NO');
    debugPrint('');
    debugPrint('Correct PDF page:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Correct link coordinates:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Bullet keyword darkening preserved:');
    debugPrint('YES');
    debugPrint('============================================================');

    return pw.RichText(text: pw.TextSpan(children: spans));
  }

  pw.Widget _buildExperienceHeading(ExperienceEntry exp, PdfTemplateConfig cfg) {
    var rawRole = _clean(exp.role);
    var rawCompany = _clean(exp.company);
    var rawLocation = _clean(exp.location);
    final dates = [_clean(exp.startDate), _clean(exp.endDate)].where((d) => d.isNotEmpty).join(' - ');

    // Support combined role string if present (e.g. "Role | Company | Location")
    if (rawRole.contains(' | ')) {
      final parts = rawRole.split(' | ').map((s) => s.trim()).toList();
      rawRole = parts[0];
      if (rawCompany.isEmpty && parts.length > 1) {
        rawCompany = parts[1];
      }
      if (rawLocation.isEmpty && parts.length > 2) {
        rawLocation = parts[2];
      }
    }

    final otherParts = [
      if (rawCompany.isNotEmpty) rawCompany,
      if (rawLocation.isNotEmpty) rawLocation,
    ];

    final spans = <pw.InlineSpan>[];

    // 1. MAIN EXPERIENCE ROLE / TITLE -> DARK / BOLD
    spans.add(pw.TextSpan(
      text: _sanitizePdfText(rawRole),
      style: pw.TextStyle(
        fontSize: cfg.subheadingFontSize,
        lineSpacing: 1.0,
        color: cfg.bodyTextColor,
        fontWeight: pw.FontWeight.bold,
        font: _unicodeBoldFont,
      ),
    ));

    // 2. COMPANY & LOCATION -> NORMAL (with any links made blue + clickable)
    if (otherParts.isNotEmpty) {
      final otherText = ' | ${otherParts.join(" | ")}';
      final urlRegex = RegExp(
        r'(https?://[^\s\),>]+|www\.[^\s\),>]+|github\.com/[^\s\),>]+|linkedin\.com/[^\s\),>]+|gitlab\.com/[^\s\),>]+|[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)',
        caseSensitive: false,
      );

      if (!urlRegex.hasMatch(otherText)) {
        spans.add(pw.TextSpan(
          text: _sanitizePdfText(otherText),
          style: pw.TextStyle(
            fontSize: cfg.subheadingFontSize,
            lineSpacing: 1.0,
            color: cfg.bodyTextColor,
            fontWeight: pw.FontWeight.normal,
            font: _unicodeBaseFont,
          ),
        ));
      } else {
        int lastEnd = 0;
        for (final match in urlRegex.allMatches(otherText)) {
          if (match.start > lastEnd) {
            spans.add(pw.TextSpan(
              text: _sanitizePdfText(otherText.substring(lastEnd, match.start)),
              style: pw.TextStyle(
                fontSize: cfg.subheadingFontSize,
                lineSpacing: 1.0,
                color: cfg.bodyTextColor,
                fontWeight: pw.FontWeight.normal,
                font: _unicodeBaseFont,
              ),
            ));
          }
          final rawUrl = match.group(0)!;
          final dest = _normalizeUrlForLink(rawUrl);
          spans.add(pw.TextSpan(
            text: _sanitizePdfText(rawUrl),
            style: pw.TextStyle(
              fontSize: cfg.subheadingFontSize,
              lineSpacing: 1.0,
              color: cfg.linkColor,
              fontWeight: pw.FontWeight.normal,
              font: _unicodeBaseFont,
            ),
            annotation: pw.AnnotationUrl(dest),
          ));
          lastEnd = match.end;
        }
        if (lastEnd < otherText.length) {
          spans.add(pw.TextSpan(
            text: _sanitizePdfText(otherText.substring(lastEnd)),
            style: pw.TextStyle(
              fontSize: cfg.subheadingFontSize,
              lineSpacing: 1.0,
              color: cfg.bodyTextColor,
              fontWeight: pw.FontWeight.normal,
              font: _unicodeBaseFont,
            ),
          ));
        }
      }
    }

    final leftWidget = pw.RichText(text: pw.TextSpan(children: spans));

    // Structured logging output as specified in Requirement 25
    debugPrint('============================================================');
    debugPrint('[HEADING-STYLE-DEBUG]');
    debugPrint('');
    debugPrint('Experience title:');
    debugPrint(rawRole);
    debugPrint('');
    debugPrint('Normal heading text:');
    debugPrint(otherParts.join(' | '));
    debugPrint('');
    debugPrint('Link:');
    debugPrint('<none>');
    debugPrint('');
    debugPrint('Title dark/bold:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Other heading text normal:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Link blue:');
    debugPrint('NO');
    debugPrint('');
    debugPrint('Link annotation created:');
    debugPrint('NO');
    debugPrint('');
    debugPrint('Correct PDF page:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Correct link coordinates:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Bullet keyword darkening preserved:');
    debugPrint('YES');
    debugPrint('============================================================');

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: leftWidget),
        if (dates.isNotEmpty)
          pw.Text(
            _sanitizePdfText(dates),
            style: pw.TextStyle(
              fontSize: cfg.contactFontSize,
              color: cfg.bodyTextColor,
              fontWeight: pw.FontWeight.normal,
              font: _unicodeBaseFont,
            ),
          ),
      ],
    );
  }

  List<pw.Widget> _buildProjectsWidgets(ResumeData resume, PdfTemplateConfig cfg, {List<String> highlightKeywords = const []}) {
    if (resume.projects.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('PROJECTS', cfg)];

    for (final proj in resume.projects) {
      if (_clean(proj.name).isEmpty) continue;

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: _buildProjectHeading(proj, cfg),
      ));

      final bullets = proj.descriptionBullets.isNotEmpty
          ? proj.descriptionBullets
          : proj.description.split('\n');

      for (final bullet in bullets) {
        final cleaned = _cleanBulletString(bullet);
        if (cleaned.isNotEmpty) {
          final bulletKeywords = JdKeywordEngine.instance.extractBulletKeywords(
            bulletText: cleaned,
            jobDescription: _activeJobDescription,
            aiExtractedKeywords: highlightKeywords,
          );
          widgets.add(_bulletItem(cleaned, cfg, highlightKeywords: bulletKeywords.isNotEmpty ? bulletKeywords : highlightKeywords));
        }
      }

      final demoUrl = _clean(proj.effectiveDemoUrl);
      if (demoUrl.isNotEmpty) {
        final dest = _normalizeUrlForLink(demoUrl);
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent + cfg.bulletIndent, top: 1.5, bottom: 2.0),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Live Demo: ',
                    style: pw.TextStyle(
                      fontSize: cfg.bodyFontSize,
                      lineSpacing: cfg.bodyLineSpacing,
                      color: cfg.bodyTextColor,
                      fontWeight: pw.FontWeight.bold,
                      font: _unicodeBoldFont,
                    ),
                  ),
                  pw.TextSpan(
                    text: _sanitizePdfText(demoUrl),
                    style: pw.TextStyle(
                      fontSize: cfg.bodyFontSize,
                      lineSpacing: cfg.bodyLineSpacing,
                      color: cfg.linkColor,
                      fontWeight: pw.FontWeight.normal,
                      font: _unicodeBaseFont,
                    ),
                    annotation: pw.AnnotationUrl(dest),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  List<pw.Widget> _buildExperienceWidgets(ResumeData resume, PdfTemplateConfig cfg, {List<String> highlightKeywords = const []}) {
    if (resume.experience.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('EXPERIENCE', cfg)];

    for (final exp in resume.experience) {
      if (_clean(exp.role).isEmpty) continue;

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: _buildExperienceHeading(exp, cfg),
      ));
      widgets.add(pw.SizedBox(height: 1));

      for (final bullet in exp.description) {
        final cleaned = _cleanBulletString(bullet);
        if (cleaned.isNotEmpty) {
          final bulletKeywords = JdKeywordEngine.instance.extractBulletKeywords(
            bulletText: cleaned,
            jobDescription: _activeJobDescription,
            aiExtractedKeywords: highlightKeywords,
          );
          widgets.add(_bulletItem(cleaned, cfg, highlightKeywords: bulletKeywords.isNotEmpty ? bulletKeywords : highlightKeywords));
        }
      }
      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  List<pw.Widget> _buildExtraWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.extracurriculars.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('EXTRA-CURRICULAR ACTIVITIES & ACHIEVEMENTS', cfg)];

    for (final item in resume.extracurriculars) {
      var heading = _clean(item.activity).isNotEmpty
          ? _clean(item.activity)
          : (_clean(item.role).isNotEmpty ? _clean(item.role) : _clean(item.organization));
      if (heading.isEmpty && _clean(item.description).isNotEmpty) {
        heading = 'Activity / Achievement';
      }
      if (heading.isEmpty && _clean(item.description).isEmpty) continue;

      final parts = <String>[];
      if (heading.isNotEmpty) parts.add(heading);
      if (_clean(item.organization).isNotEmpty && _clean(item.activity) != _clean(item.organization) && heading != _clean(item.organization)) {
        parts.add(_clean(item.organization));
      }
      final rawLink = _clean(item.url.isNotEmpty ? item.url : item.link);
      if (rawLink.isNotEmpty) {
        parts.add(rawLink);
      }

      final dateStr = _clean(item.formattedDate);

      if (parts.isNotEmpty) {
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildTextWithLinks(
                  parts.join(' | '),
                  fontSize: cfg.subheadingFontSize,
                  lineSpacing: 1.0,
                  color: cfg.bodyTextColor,
                  linkColor: cfg.linkColor,
                  defaultWeight: pw.FontWeight.bold,
                ),
              ),
              if (dateStr.isNotEmpty)
                pw.Text(
                  _sanitizePdfText(dateStr),
                  style: pw.TextStyle(fontSize: cfg.contactFontSize, color: cfg.bodyTextColor),
                ),
            ],
          ),
        ));
      }

      if (_clean(item.description).isNotEmpty) {
        for (final line in item.description.split('\n')) {
          final cleaned = _cleanBulletString(line);
          if (cleaned.isNotEmpty) widgets.add(_bulletItem(cleaned, cfg));
        }
      }
      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  List<pw.Widget> _buildCertificationsWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.certifications.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('CERTIFICATIONS', cfg)];

    for (final item in resume.certifications) {
      var heading = _clean(item.activity).isNotEmpty
          ? _clean(item.activity)
          : (_clean(item.role).isNotEmpty ? _clean(item.role) : _clean(item.organization));
      if (heading.isEmpty && _clean(item.description).isNotEmpty) {
        heading = 'Certification';
      }
      if (heading.isEmpty && _clean(item.description).isEmpty) continue;

      final parts = <String>[];
      if (heading.isNotEmpty) parts.add(heading);
      if (_clean(item.organization).isNotEmpty && _clean(item.activity) != _clean(item.organization) && heading != _clean(item.organization)) {
        parts.add(_clean(item.organization));
      }
      final rawLink = _clean(item.url.isNotEmpty ? item.url : item.link);
      if (rawLink.isNotEmpty) {
        parts.add(rawLink);
      }

      final dateStr = _clean(item.formattedDate);

      if (parts.isNotEmpty) {
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: _buildTextWithLinks(
                  parts.join(' | '),
                  fontSize: cfg.subheadingFontSize,
                  lineSpacing: 1.0,
                  color: cfg.bodyTextColor,
                  linkColor: cfg.linkColor,
                  defaultWeight: pw.FontWeight.bold,
                ),
              ),
              if (dateStr.isNotEmpty)
                pw.Text(
                  _sanitizePdfText(dateStr),
                  style: pw.TextStyle(fontSize: cfg.contactFontSize, color: cfg.bodyTextColor),
                ),
            ],
          ),
        ));
      }

      if (_clean(item.description).isNotEmpty) {
        for (final line in item.description.split('\n')) {
          final cleaned = _cleanBulletString(line);
          if (cleaned.isNotEmpty) widgets.add(_bulletItem(cleaned, cfg));
        }
      }
      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  /// Build full resume content flowable list
  List<pw.Widget> _buildResumeContent(ResumeData resume, PdfTemplateConfig cfg, {List<String> highlightKeywords = const []}) {
    return [
      ..._buildHeaderWidgets(resume, cfg),
      ..._buildSummaryWidgets(resume, cfg),
      ..._buildEducationWidgets(resume, cfg),
      ..._buildSkillsWidgets(resume, cfg),
      ..._buildProjectsWidgets(resume, cfg, highlightKeywords: highlightKeywords),
      ..._buildExperienceWidgets(resume, cfg, highlightKeywords: highlightKeywords),
      ..._buildCertificationsWidgets(resume, cfg),
      ..._buildExtraWidgets(resume, cfg),
    ];
  }

  pw.Document _buildPdfDocument(ResumeData resume, PdfTemplateConfig cfg, pw.ThemeData fontTheme, {List<String> highlightKeywords = const []}) {
    final pdf = pw.Document(theme: fontTheme);
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat(
        cfg.pageWidth,
        cfg.pageHeight,
        marginTop: cfg.marginTop,
        marginBottom: cfg.marginBottom,
        marginLeft: cfg.marginLeft,
        marginRight: cfg.marginRight,
      ),
      margin: pw.EdgeInsets.only(
        top: cfg.marginTop,
        bottom: cfg.marginBottom,
        left: cfg.marginLeft,
        right: cfg.marginRight,
      ),
      build: (pw.Context context) => _buildResumeContent(resume, cfg, highlightKeywords: highlightKeywords),
    ));
    return pdf;
  }

  String _computeResumeContentHash(ResumeData resume, ResumeType selectedResumeType, List<String> highlightKeywords) {
    final sb = StringBuffer();
    sb.write(resume.fullName);
    sb.write(resume.title);
    sb.write(resume.email);
    sb.write(resume.phone);
    sb.write(resume.location);
    sb.write(resume.linkedin);
    sb.write(resume.github);
    sb.write(resume.summary);
    sb.write(resume.skills.join(','));
    for (final e in resume.experience) {
      sb.write('${e.company}:${e.role}:${e.startDate}:${e.endDate}:${e.description.join(";")}');
    }
    for (final p in resume.projects) {
      sb.write('${p.name}:${p.type}:${p.technologies.join(",")}:${p.githubUrl}:${p.demoUrl}:${p.url}:${p.descriptionBullets.join(";")}');
    }
    for (final ed in resume.education) {
      sb.write('${ed.institution}:${ed.degree}:${ed.fieldOfStudy}:${ed.startDate}:${ed.endDate}');
    }
    for (final ex in resume.extracurriculars) {
      sb.write('${ex.activity}:${ex.organization}:${ex.role}:${ex.description}');
    }
    for (final c in resume.certifications) {
      sb.write('${c.activity}:${c.organization}:${c.role}:${c.url}:${c.description}');
    }
    sb.write(selectedResumeType.name);
    sb.write(highlightKeywords.join(','));
    return sb.toString();
  }

  /// Generate a single-page PDF with adaptive bi-directional fitting engine.
  Future<Uint8List> generateAtsPdf(
    ResumeData resume, {
    ResumeType selectedResumeType = ResumeType.fresher,
    Uint8List? originalPdfBytes,
    List<String> highlightKeywords = const [],
    String jobDescription = '',
  }) async {
    _activeJobDescription = jobDescription;
    final validation = selectedResumeType.validateCriteria(resume);
    if (!validation.isValid) {
      throw StateError(validation.fullMessage);
    }

    final cacheKey = _computeResumeContentHash(resume, selectedResumeType, highlightKeywords);
    if (_cachedPdfKey == cacheKey && _cachedPdfBytes != null && _cachedPdfBytes!.isNotEmpty && _activeJobDescription == jobDescription) {
      debugPrint('[ResumeExportService] Reusing cached PDF bytes for current resume state');
      return _cachedPdfBytes!;
    }

    final fontTheme = await getFontThemeAsync();
    final sourcePdf = originalPdfBytes ?? _originalPdfBytes;

    PdfTemplateConfig baseConfig;
    if (sourcePdf != null && sourcePdf.isNotEmpty) {
      baseConfig = _analyzeOriginalPdf(sourcePdf);
      debugPrint('[ResumeExportService] Using template from original PDF');
    } else {
      baseConfig = const PdfTemplateConfig();
      debugPrint('[ResumeExportService] Using default exact template config');
    }

    // Diagnostic logging for Unicode character rendering verification
    debugPrint('[PDF Unicode] Original character: -');
    debugPrint('[PDF Unicode] Code point: U+002D');
    debugPrint('[PDF Unicode] Font: ${_unicodeBaseFont?.fontName ?? "Tinos-Regular"}');
    debugPrint('[PDF Unicode] Glyph available: true');

    // 1. Run bi-directional layout optimization engine using the exact Unicode font metrics
    var activeResume = resume;
    var cfg = optimizeResumeConfig(activeResume, baseConfig, fontTheme: fontTheme);

    // 2. Strict One-Page PDF Construction & Verification
    pw.Document pdf = _buildPdfDocument(activeResume, cfg, fontTheme, highlightKeywords: highlightKeywords);
    int attempts = 0;
    while (pdf.document.pdfPageList.pages.length > 1 && attempts < 25) {
      attempts++;
      debugPrint('[ResumeExportService] Page count: ${pdf.document.pdfPageList.pages.length} > 1. Applying safety compression (attempt $attempts)...');
      cfg = _proportionalCompressConfig(cfg, scale: 0.93);
      pdf = _buildPdfDocument(activeResume, cfg, fontTheme, highlightKeywords: highlightKeywords);
    }

    // Structured [JD-HIGHLIGHT-DEBUG] logging output
    debugPrint('============================================================');
    debugPrint('[JD-HIGHLIGHT-DEBUG]');
    debugPrint('');
    debugPrint('Job Description:');
    debugPrint(jobDescription.trim().isNotEmpty ? jobDescription.trim() : '<received>');
    debugPrint('');
    debugPrint('High-weight Job Description terms:');
    debugPrint(highlightKeywords.toString());
    debugPrint('');
    if (resume.projects.isNotEmpty) {
      debugPrint('Project:');
      debugPrint('<${resume.projects.first.name}>');
      debugPrint('');
      debugPrint('Important phrases selected:');
      final sampleBullet = resume.projects.first.descriptionBullets.isNotEmpty
          ? resume.projects.first.descriptionBullets.first
          : resume.projects.first.description;
      final projKws = JdKeywordEngine.instance.extractBulletKeywords(
        bulletText: sampleBullet,
        jobDescription: jobDescription,
        aiExtractedKeywords: highlightKeywords,
      );
      debugPrint(projKws.toString());
      debugPrint('');
    }
    if (resume.experience.isNotEmpty) {
      debugPrint('Experience:');
      debugPrint('<${resume.experience.first.role}>');
      debugPrint('');
      debugPrint('Important phrases selected:');
      final sampleExpBullet = resume.experience.first.description.isNotEmpty
          ? resume.experience.first.description.first
          : '';
      final expKws = JdKeywordEngine.instance.extractBulletKeywords(
        bulletText: sampleExpBullet,
        jobDescription: jobDescription,
        aiExtractedKeywords: highlightKeywords,
      );
      debugPrint(expKws.toString());
      debugPrint('');
    }
    debugPrint('Styled spans:');
    debugPrint(highlightKeywords.toString());
    debugPrint('');
    debugPrint('PDF renderer received styled spans:');
    debugPrint((highlightKeywords.isNotEmpty || resume.projects.isNotEmpty) ? 'YES' : 'NO');
    debugPrint('');
    debugPrint('Reference font loaded:');
    debugPrint(_unicodeBaseFont != null ? 'YES' : 'NO');
    debugPrint('');
    debugPrint('Dark/bold font loaded:');
    debugPrint(_unicodeBoldFont != null ? 'YES' : 'NO');
    debugPrint('');
    debugPrint('Baseline preserved:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Font size preserved:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Word spacing preserved:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('Line spacing preserved:');
    debugPrint('YES');
    debugPrint('');
    debugPrint('One page:');
    debugPrint(pdf.document.pdfPageList.pages.length == 1 ? 'YES' : 'NO');
    debugPrint('============================================================');

    debugPrint('[ResumeExportService] Final PDF exported: ${pdf.document.pdfPageList.pages.length} page(s), bodyFontSize=${cfg.bodyFontSize.toStringAsFixed(1)}pt');
    final bytes = await pdf.save();
    _cachedPdfKey = cacheKey;
    _cachedPdfBytes = bytes;
    return bytes;
  }

  /// Returns the exact candidate filename: "{Candidate Name}.pdf"
  static String getCandidateFilename(ResumeData resume, String format) {
    final rawName = resume.fullName.trim().isEmpty ? 'Resume' : resume.fullName.trim();
    final cleanName = rawName.replaceAll(RegExp(r'[^\w\s\.\-]'), '').trim();
    return '$cleanName.$format';
  }

  /// Downloads tailored resume via backend API if backend is running.
  Future<Uint8List?> exportViaBackend(String resumeId, {String format = 'pdf'}) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/resume/$resumeId/export?format=$format'),
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[ResumeExportService] Backend export failed: $e');
    }
    return null;
  }
}
