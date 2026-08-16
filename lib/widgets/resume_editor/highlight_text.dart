import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/jd_keyword_engine.dart';
import '../../theme/app_theme.dart';



/// A widget that renders text with visual darkening/emphasis applied to matched
/// job keywords based on priority (High, Medium, Low).
///
/// **Crucial Rule**: The original [text] string is never altered or mutated.
/// Highlighting is purely a visual rendering layer using [RichText] and [TextSpan].
class HighlightText extends StatelessWidget {
  final String text;
  final List<JobKeyword>? jobKeywords;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;

  const HighlightText({
    super.key,
    required this.text,
    this.jobKeywords,
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

    // If text is empty or no matched keywords exist, render plain text.
    if (text.trim().isEmpty || jobKeywords == null || jobKeywords!.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final matchedKeywords = jobKeywords!.where((k) => k.matched).toList();
    if (matchedKeywords.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    // Map keywords to their priority ('high', 'medium', 'low')
    final Map<String, String> priorityMap = {};
    for (final kw in matchedKeywords) {
      final key = kw.keyword.toLowerCase().trim();
      if (key.isNotEmpty) {
        final p = kw.priority.toLowerCase().trim();
        if (!priorityMap.containsKey(key) || p == 'high' || (p == 'medium' && priorityMap[key] == 'low')) {
          priorityMap[key] = p;
        }
      }
    }

    // Sort keywords by length descending so longer multi-word phrases match first
    final sortedKeys = priorityMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    if (sortedKeys.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    // Build regex pattern matching any of the sorted keywords with word boundaries
    final escapedKeys = sortedKeys.map(RegExp.escape).join('|');
    final regExp = RegExp('\\b($escapedKeys)\\b', caseSensitive: false);

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
      final keyLower = matchedWord.toLowerCase().trim();
      final priority = priorityMap[keyLower] ?? 'low';

      // Dynamic visual darkening & emphasis based on priority
      TextStyle highlightedStyle;
      if (priority == 'high') {
        highlightedStyle = baseStyle.copyWith(
          fontWeight: FontWeight.w800,
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          decoration: TextDecoration.underline,
          decorationColor: AppTheme.primaryOrange.withValues(alpha: 0.6),
          decorationThickness: 2.0,
        );
      } else if (priority == 'medium') {
        highlightedStyle = baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
        );
      } else {
        highlightedStyle = baseStyle.copyWith(
          fontWeight: FontWeight.w600,
        );
      }

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
