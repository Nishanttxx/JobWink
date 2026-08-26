import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/jd_keyword_engine.dart';
import '../../theme/app_theme.dart';

/// A widget that renders text with visual darkening/emphasis applied to matched
/// high-weight job keywords.
///
/// **Crucial Rule**: The original [text] string is never altered or mutated.
/// Highlighting is purely a visual rendering layer using [RichText] and [TextSpan].
class HighlightText extends StatelessWidget {
  final String text;
  final List<JobKeyword>? jobKeywords;
  final List<String>? matchedKeywords;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;

  const HighlightText({
    super.key,
    required this.text,
    this.jobKeywords,
    this.matchedKeywords,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      height: 1.4,
      color: AppTheme.getTextColor(context),
    );
    final baseStyle = style ?? defaultStyle;

    final targetKeywords = <String>{};
    if (matchedKeywords != null && matchedKeywords!.isNotEmpty) {
      targetKeywords.addAll(matchedKeywords!.map((k) => k.trim()).where((k) => k.length >= 2));
    }
    if (jobKeywords != null && jobKeywords!.isNotEmpty) {
      for (final kw in jobKeywords!) {
        if (kw.matched || kw.priority == 'high' || kw.priority == 'medium') {
          if (kw.keyword.trim().length >= 2) {
            targetKeywords.add(kw.keyword.trim());
          }
        }
      }
    }

    if (text.trim().isEmpty || targetKeywords.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    // Sort keywords by length descending so longer multi-word phrases match first
    final sortedKeys = targetKeywords.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Build regex pattern matching any of the sorted keywords with strict word boundaries
    final escapedKeys = sortedKeys.map(RegExp.escape).join('|');
    final regExp = RegExp('(?<=^|[^a-zA-Z0-9])($escapedKeys)(?=[^a-zA-Z0-9]|\$)', caseSensitive: false);

    final matches = regExp.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final isDarkMode = AppTheme.isDarkMode(context);
    final spans = <TextSpan>[];
    int currentOffset = 0;

    for (final match in matches) {
      // Add non-matching text before keyword
      if (match.start > currentOffset) {
        spans.add(TextSpan(
          text: text.substring(currentOffset, match.start),
          style: baseStyle,
        ));
      }

      final matchedWord = text.substring(match.start, match.end);

      final highlightedStyle = baseStyle.copyWith(
        fontWeight: FontWeight.w800,
        color: isDarkMode ? Colors.white : const Color(0xFF090D16),
      );

      spans.add(TextSpan(
        text: matchedWord,
        style: highlightedStyle,
      ));

      currentOffset = match.end;
    }

    // Add remaining trailing text
    if (currentOffset < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentOffset),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign,
    );
  }
}
