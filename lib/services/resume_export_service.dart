import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

import '../models/resume_data.dart';
import '../models/resume_type.dart';
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
      marginLeft: marginLeft,
      marginRight: marginRight,
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

  static final List<String> _unsupportedGlyphs = [
    '•', '◦', '▪', '▫', '■', '□', '☐', '☒', '☑', '●', '○', '‣', '⁃',
    '\u2022', '\u25a0', '\u25a1', '\u2610', '\u2612', '\u2611', '\u25cf',
    '\u25cb', '\u25aa', '\u25ab', '\u2023', '\u2043', '\u25e6', '\ufffd',
  ];

  static String _cleanBulletString(String input) {
    var s = _clean(input);
    if (s.isEmpty) return '';
    while (s.isNotEmpty && _bulletPrefixRegExp.hasMatch(s)) {
      s = s.replaceAll(_bulletPrefixRegExp, '').trim();
    }
    return s;
  }

  /// Sanitizes text for standard PDF rendering.
  static String _sanitizePdfText(String input) {
    var s = _clean(input);
    if (s.isEmpty) return '';
    for (final glyph in _unsupportedGlyphs) {
      s = s.replaceAll(glyph, '');
    }
    return s
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('…', '...');
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
  ResumeLayoutMeasurement measureResumeLayout(ResumeData resume, PdfTemplateConfig cfg) {
    final sectionHeights = <String, double>{};
    final usableWidth = cfg.pageWidth - cfg.marginLeft - cfg.marginRight;
    final usableHeight = cfg.pageHeight - cfg.marginTop - cfg.marginBottom;

    final fontTheme = pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

    final context = pw.Context(
      document: pw.Document(theme: fontTheme).document,
    );
    final constraints = pw.BoxConstraints(maxWidth: usableWidth);

    // Helper for measuring a list of section widgets
    double measureSection(String name, List<pw.Widget> widgets) {
      if (widgets.isEmpty) {
        sectionHeights[name] = 0.0;
        return 0.0;
      }
      final themeWidget = pw.Theme(
        data: fontTheme,
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

    // Check page count by building test document
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
      build: (pw.Context ctx) => _buildResumeContent(resume, cfg),
    ));

    final pageCount = pdf.document.pdfPageList.pages.length;
    final overflow = pageCount > 1 || contentHeight > usableHeight;
    final remainingHeight = overflow ? 0.0 : (usableHeight - contentHeight);
    final utilizationPercentage = (contentHeight / usableHeight) * 100;

    return ResumeLayoutMeasurement(
      pageWidth: cfg.pageWidth,
      pageHeight: cfg.pageHeight,
      usableHeight: usableHeight,
      contentHeight: contentHeight,
      remainingHeight: remainingHeight,
      overflow: overflow,
      utilizationPercentage: utilizationPercentage.clamp(0.0, 100.0),
      sectionHeights: sectionHeights,
      pageCount: pageCount,
    );
  }

  /// Bi-directional Optimizer: Iteratively adjusts layout properties until target page utilization is reached.
  PdfTemplateConfig optimizeResumeConfig(ResumeData resume, PdfTemplateConfig baseConfig) {
    PdfTemplateConfig cfg = baseConfig;
    const maxIterations = 20;

    for (int iter = 0; iter < maxIterations; iter++) {
      final m = measureResumeLayout(resume, cfg);

      if (m.overflow) {
        // CASE A: Content overflows onto Page 2 -> COMPRESS layout
        final compressed = _stepCompressConfig(cfg);
        if (compressed == cfg) break; // reached min bounds
        cfg = compressed;
      } else if (m.remainingHeight > 35.0) {
        // CASE B: Unnecessary empty space at bottom (> 35 pt remaining) -> EXPAND layout
        final expanded = _stepExpandConfig(cfg);
        if (expanded == cfg) break; // reached max bounds
        cfg = expanded;
      } else {
        // Target achieved: 95% - 99% page utilization (remaining space <= 35 pt and no overflow)
        debugPrint('[ResumeExportService] Optimized in $iter iterations: utilization=${m.utilizationPercentage.toStringAsFixed(1)}%, remaining=${m.remainingHeight.toStringAsFixed(1)}pt');
        break;
      }
    }

    return cfg;
  }

  /// Bi-directional Optimizer for Config and Data: Iteratively adjusts layout properties,
  /// and applies content pruning fallback if content still overflows 1 page.
  (ResumeData, PdfTemplateConfig) optimizeResumeConfigAndData(ResumeData resume, PdfTemplateConfig baseConfig) {
    var data = resume;
    var cfg = baseConfig;
    for (int i = 0; i < 3; i++) {
      cfg = optimizeResumeConfig(data, cfg);
      final m = measureResumeLayout(data, cfg);
      if (!m.overflow) break;
      data = _aiShortenResumeContent(data);
    }
    cfg = optimizeResumeConfig(data, cfg);
    return (data, cfg);
  }



  /// Stepwise Compression Strategy (Prioritized: Spacing -> Bullet Space -> Line Height -> Body Font -> Heading/Name Font -> Margins)
  PdfTemplateConfig _stepCompressConfig(PdfTemplateConfig base) {
    if (base.sectionSpaceBefore > 4.0 || base.entrySpaceAfter > 2.0 || base.paragraphSpaceAfter > 1.0) {
      return base.copyWithFitting(
        sectionSpaceBefore: (base.sectionSpaceBefore - 0.5).clamp(4.0, 20.0),
        sectionSpaceAfter: (base.sectionSpaceAfter - 0.3).clamp(2.0, 10.0),
        entrySpaceAfter: (base.entrySpaceAfter - 0.4).clamp(2.0, 10.0),
        paragraphSpaceAfter: (base.paragraphSpaceAfter - 0.3).clamp(1.0, 8.0),
      );
    } else if (base.bulletSpacing > 0.0) {
      return base.copyWithFitting(
        bulletSpacing: (base.bulletSpacing - 0.5).clamp(0.0, 5.0),
      );
    } else if (base.bodyLineSpacing > 1.05) {
      return base.copyWithFitting(
        bodyLineSpacing: (base.bodyLineSpacing - 0.03).clamp(1.0, 1.4),
      );
    } else if (base.bodyFontSize > 8.0) {
      return base.copyWithFitting(
        bodyFontSize: (base.bodyFontSize - 0.2).clamp(8.0, 11.5),
        subheadingFontSize: (base.subheadingFontSize - 0.2).clamp(9.0, 12.0),
        contactFontSize: (base.contactFontSize - 0.15).clamp(8.0, 10.5),
      );

    } else if (base.headingFontSize > 11.0 || base.nameFontSize > 20.0) {
      return base.copyWithFitting(
        headingFontSize: (base.headingFontSize - 0.2).clamp(11.0, 14.0),
        nameFontSize: (base.nameFontSize - 0.4).clamp(20.0, 26.4),
      );
    } else if (base.marginTop > 15.0 || base.marginBottom > 15.0) {
      return base.copyWithFitting(
        marginTop: (base.marginTop - 1.0).clamp(15.0, 28.0),
        marginBottom: (base.marginBottom - 1.0).clamp(15.0, 28.0),
      );
    }
    return base;
  }

  /// Stepwise Expansion Strategy (Prioritized: Body Font -> Line Height -> Bullet Space -> Section Spacing -> Heading/Name Font -> Margins)
  PdfTemplateConfig _stepExpandConfig(PdfTemplateConfig base) {
    if (base.bodyFontSize < 11.5) {
      return base.copyWithFitting(
        bodyFontSize: (base.bodyFontSize + 0.2).clamp(8.5, 11.5),
        subheadingFontSize: (base.subheadingFontSize + 0.2).clamp(9.5, 12.0),
        contactFontSize: (base.contactFontSize + 0.15).clamp(8.5, 10.5),
      );
    } else if (base.bodyLineSpacing < 1.35) {
      return base.copyWithFitting(
        bodyLineSpacing: (base.bodyLineSpacing + 0.02).clamp(1.0, 1.35),
      );
    } else if (base.bulletSpacing < 4.0) {
      return base.copyWithFitting(
        bulletSpacing: (base.bulletSpacing + 0.5).clamp(0.0, 5.0),
      );
    } else if (base.sectionSpaceBefore < 14.0 || base.entrySpaceAfter < 6.0 || base.paragraphSpaceAfter < 5.0) {
      return base.copyWithFitting(
        sectionSpaceBefore: (base.sectionSpaceBefore + 0.8).clamp(4.0, 16.0),
        entrySpaceAfter: (base.entrySpaceAfter + 0.5).clamp(2.0, 8.0),
        paragraphSpaceAfter: (base.paragraphSpaceAfter + 0.5).clamp(1.0, 6.0),
      );
    } else if (base.headingFontSize < 14.0 || base.nameFontSize < 26.4) {
      return base.copyWithFitting(
        headingFontSize: (base.headingFontSize + 0.3).clamp(11.0, 14.0),
        nameFontSize: (base.nameFontSize + 0.5).clamp(20.0, 26.4),
      );
    } else if (base.marginTop < 28.0 || base.marginBottom < 25.0) {
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


  List<pw.Widget> _buildHeaderWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    final nameClean = _clean(resume.fullName);
    final nameStr = nameClean.isEmpty ? 'NISHANT ARYA' : nameClean;
    final displayName = cfg.nameUppercase ? nameStr.toUpperCase() : nameStr;

    final line1Parts = <pw.InlineSpan>[];
    final cleanEmail = _clean(resume.email);
    if (cleanEmail.isNotEmpty) {
      line1Parts.add(pw.TextSpan(text: _sanitizePdfText(cleanEmail)));
    }
    final cleanLiRaw = _clean(resume.linkedin);
    if (cleanLiRaw.isNotEmpty) {
      if (line1Parts.isNotEmpty) line1Parts.add(const pw.TextSpan(text: ' | '));
      final cleanLi = cleanLiRaw.replaceAll(RegExp(r'https?://(www\.)?'), '');
      line1Parts.add(pw.TextSpan(
        text: _sanitizePdfText(cleanLi),
        style: pw.TextStyle(color: cfg.linkColor),
      ));
    }

    final line2Parts = <pw.InlineSpan>[];
    final cleanPhone = _clean(resume.phone);
    if (cleanPhone.isNotEmpty) {
      line2Parts.add(pw.TextSpan(text: _sanitizePdfText(cleanPhone)));
    }
    final cleanGhRaw = _clean(resume.github);
    if (cleanGhRaw.isNotEmpty) {
      if (line2Parts.isNotEmpty) line2Parts.add(const pw.TextSpan(text: ' | '));
      final cleanGh = cleanGhRaw.replaceAll(RegExp(r'https?://(www\.)?'), '');
      line2Parts.add(pw.TextSpan(
        text: _sanitizePdfText(cleanGh),
        style: pw.TextStyle(color: cfg.linkColor),
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

  pw.Widget _bulletItem(String text, PdfTemplateConfig cfg) {
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
            child: pw.Text(
              _sanitizePdfText(cleaned),
              style: pw.TextStyle(
                fontSize: cfg.bodyFontSize,
                lineSpacing: cfg.bodyLineSpacing,
                color: cfg.bodyTextColor,
              ),
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
        child: pw.Text(
          _sanitizePdfText(cleanSummary),
          style: pw.TextStyle(
            fontSize: cfg.bodyFontSize,
            lineSpacing: cfg.bodyLineSpacing,
            color: cfg.bodyTextColor,
          ),
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

      var degreeStr = degree;
      if (field.isNotEmpty) {
        degreeStr = degree.isNotEmpty ? '$degree in $field' : field;
      }

      final dates = [_clean(edu.startDate), _clean(edu.endDate)].where((d) => d.isNotEmpty).join(' – ');

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    if (degreeStr.isNotEmpty)
                      pw.TextSpan(
                        text: _sanitizePdfText('$degreeStr | '),
                        style: pw.TextStyle(
                          fontSize: cfg.subheadingFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: cfg.bodyTextColor,
                        ),
                      ),
                    if (inst.isNotEmpty)
                      pw.TextSpan(
                        text: _sanitizePdfText(inst),
                        style: pw.TextStyle(
                          fontSize: cfg.bodyFontSize,
                          color: cfg.bodyTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            pw.Text(
              _sanitizePdfText([dates, if (_clean(edu.gpa).isNotEmpty) 'GPA: ${_clean(edu.gpa)}'].where((s) => s.isNotEmpty).join(' | ')),
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
              child: pw.Text(
                _sanitizePdfText(cat.value.join(', ')),
                style: pw.TextStyle(
                  fontSize: cfg.bodyFontSize,
                  color: cfg.bodyTextColor,
                ),
              ),
            ),
          ],
        ),
      ));
    }
    widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    return widgets;
  }

  List<pw.Widget> _buildProjectsWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.projects.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('PROJECTS', cfg)];

    for (final proj in resume.projects) {
      final title = _clean(proj.name);
      if (title.isEmpty) continue;
      final typeStr = _clean(proj.type).isNotEmpty ? ' (${_clean(proj.type)})' : '';
      final cleanTechs = proj.technologies.map(_clean).where((t) => t.isNotEmpty).toList();
      final techStr = cleanTechs.isNotEmpty ? ' | ${cleanTechs.join(", ")}' : '';
      final cleanUrl = _clean(proj.url).replaceAll(RegExp(r'https?://(www\.)?'), '');

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: _sanitizePdfText('$title$typeStr$techStr'),
                style: pw.TextStyle(
                  fontSize: cfg.subheadingFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: cfg.bodyTextColor,
                ),
              ),
              if (cleanUrl.isNotEmpty) ...[
                const pw.TextSpan(text: ' | '),
                pw.TextSpan(
                  text: _sanitizePdfText(cleanUrl),
                  style: pw.TextStyle(
                    fontSize: cfg.subheadingFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: cfg.linkColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ));

      final bullets = proj.descriptionBullets.isNotEmpty
          ? proj.descriptionBullets
          : proj.description.split('\n');

      for (final bullet in bullets) {
        final cleaned = _cleanBulletString(bullet);
        if (cleaned.isNotEmpty) widgets.add(_bulletItem(cleaned, cfg));
      }
      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  List<pw.Widget> _buildExperienceWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.experience.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('EXPERIENCE', cfg)];

    for (final exp in resume.experience) {
      final title = _clean(exp.role);
      if (title.isEmpty) continue;
      final dates = [_clean(exp.startDate), _clean(exp.endDate)].where((d) => d.isNotEmpty).join(' – ');
      final titleCompanyLoc = [
        title,
        if (_clean(exp.company).isNotEmpty) _clean(exp.company),
        if (_clean(exp.location).isNotEmpty) _clean(exp.location),
      ].join(' | ');

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                _sanitizePdfText(titleCompanyLoc),
                style: pw.TextStyle(
                  fontSize: cfg.subheadingFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: cfg.bodyTextColor,
                ),
              ),
            ),
            if (dates.isNotEmpty)
              pw.Text(
                _sanitizePdfText(dates),
                style: pw.TextStyle(fontSize: cfg.contactFontSize, color: cfg.bodyTextColor),
              ),
          ],
        ),
      ));
      widgets.add(pw.SizedBox(height: 1));
      for (final bullet in exp.description) {
        final cleaned = _cleanBulletString(bullet);
        if (cleaned.isNotEmpty) widgets.add(_bulletItem(cleaned, cfg));
      }
      widgets.add(pw.SizedBox(height: cfg.entrySpaceAfter));
    }
    return widgets;
  }

  List<pw.Widget> _buildExtraWidgets(ResumeData resume, PdfTemplateConfig cfg) {
    if (resume.extracurriculars.isEmpty) return [];
    final widgets = <pw.Widget>[_buildSectionHeading('CERTIFICATIONS & EXTRA-CURRICULAR ACTIVITIES', cfg)];

    for (final item in resume.extracurriculars) {
      var heading = _clean(item.activity).isNotEmpty
          ? _clean(item.activity)
          : (_clean(item.role).isNotEmpty ? _clean(item.role) : _clean(item.organization));
      if (heading.isEmpty && _clean(item.description).isNotEmpty) {
        heading = 'Certification / Activity';
      }
      if (heading.isEmpty) continue;

      final parts = <String>[heading];
      if (_clean(item.organization).isNotEmpty && _clean(item.activity) != _clean(item.organization) && heading != _clean(item.organization)) {
        parts.add(_clean(item.organization));
      }

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(left: cfg.contentLeftIndent),
        child: pw.Text(
          _sanitizePdfText(parts.join(' | ')),
          style: pw.TextStyle(
            fontSize: cfg.subheadingFontSize,
            fontWeight: pw.FontWeight.bold,
            color: cfg.bodyTextColor,
          ),
        ),
      ));

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
  List<pw.Widget> _buildResumeContent(ResumeData resume, PdfTemplateConfig cfg) {
    return [
      ..._buildHeaderWidgets(resume, cfg),
      ..._buildSummaryWidgets(resume, cfg),
      ..._buildEducationWidgets(resume, cfg),
      ..._buildSkillsWidgets(resume, cfg),
      ..._buildProjectsWidgets(resume, cfg),
      ..._buildExperienceWidgets(resume, cfg),
      ..._buildExtraWidgets(resume, cfg),
    ];
  }

  /// Helper to return font theme for PDF export
  pw.ThemeData getFontTheme() {
    return pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );
  }

  /// Generate a single-page PDF with adaptive bi-directional fitting engine.
  Future<Uint8List> generateAtsPdf(
    ResumeData resume, {
    ResumeType selectedResumeType = ResumeType.experience,
    Uint8List? originalPdfBytes,
  }) async {
    final sourcePdf = originalPdfBytes ?? _originalPdfBytes;


    PdfTemplateConfig baseConfig;
    if (sourcePdf != null && sourcePdf.isNotEmpty) {
      baseConfig = _analyzeOriginalPdf(sourcePdf);
      debugPrint('[ResumeExportService] Using template from original PDF');
    } else {
      baseConfig = const PdfTemplateConfig();
      debugPrint('[ResumeExportService] Using default exact template config');
    }

    // 1. Run bi-directional optimization engine
    var activeResume = resume;
    var cfg = optimizeResumeConfig(activeResume, baseConfig);
    var measurement = measureResumeLayout(activeResume, cfg);

    // 2. If after maximum compression iterations content still overflows, call AI content shortening
    if (measurement.overflow) {
      activeResume = _aiShortenResumeContent(activeResume);
      cfg = optimizeResumeConfig(activeResume, baseConfig);
    }

    final fontTheme = pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
      italic: pw.Font.timesItalic(),
      boldItalic: pw.Font.timesBoldItalic(),
    );

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
      build: (pw.Context context) => _buildResumeContent(activeResume, cfg),
    ));

    return await pdf.save();
  }

  /// Returns the exact candidate filename: "{Candidate Name}.pdf"
  static String getCandidateFilename(ResumeData resume, String format) {
    final rawName = resume.fullName.trim().isEmpty ? 'Nishant Arya' : resume.fullName.trim();
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
