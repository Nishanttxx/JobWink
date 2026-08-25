import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Inspect Tinos TTF Font Glyphs & Character Map', () async {
    final regBytes = File('assets/fonts/Tinos-Regular.ttf').readAsBytesSync();
    final ttfBase = pw.Font.ttf(Uint8List.fromList(regBytes).buffer.asByteData());

    final charsToTest = [
      '-', // U+002D Hyphen-Minus
      '–', // U+2013 En Dash
      '—', // U+2014 Em Dash
      '―', // U+2015 Horizontal Bar
      '‒', // U+2012 Figure Dash
      '‐', // U+2010 Hyphen
      '‑', // U+2011 Non-Breaking Hyphen
      '−', // U+2212 Minus Sign
      '­', // U+00AD Soft Hyphen
      '•', // U+2022 Bullet
      '|', // U+007C Vertical Line
      ' ', // U+00A0 Non-Breaking Space
      ' ', // U+202F Narrow No-Break Space
      '‌', // U+200C Zero-width Non-Joiner
      '‍', // U+200D Zero-width Joiner
      '‎', // U+200E Left-To-Right Mark
      '‏', // U+200F Right-To-Left Mark
      '\uF02D', // Private Use Area
    ];

    for (final ch in charsToTest) {
      final code = ch.codeUnitAt(0);
      final hex = code.toRadixString(16).toUpperCase().padLeft(4, '0');
      try {
        final doc = pw.Document();
        doc.addPage(pw.Page(
          theme: pw.ThemeData.withFont(base: ttfBase),
          build: (ctx) => pw.Text('Test $ch Test', style: pw.TextStyle(font: ttfBase)),
        ));
        final bytes = await doc.save();
        debugPrint('Char "$ch" (U+$hex): SUCCESS (${bytes.length} bytes)');
      } catch (e) {
        debugPrint('Char "$ch" (U+$hex): FAILED -> $e');
      }
    }
  });
}
