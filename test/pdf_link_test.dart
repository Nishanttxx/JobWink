import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String _normalizeUrlForLink(String rawUrl) {
  var trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return '';

  trimmed = trimmed.replaceFirst(RegExp(r'^[<\(\[]+'), '').replaceFirst(RegExp(r'[>\)\]]+$'), '');
  trimmed = trimmed.replaceAll(RegExp(r'\.+$'), '').trim();

  if (trimmed.startsWith(RegExp(r'^https?://', caseSensitive: false))) {
    return trimmed;
  }
  return 'https://$trimmed';
}

pw.Widget _buildTextWithLinks(String text, {required double fontSize, required PdfColor color, required PdfColor linkColor, double lineSpacing = 1.0}) {
  final urlRegex = RegExp(r'(https?://[^\s\),>]+|www\.[^\s\),>]+|github\.com/[^\s\),>]+|linkedin\.com/[^\s\),>]+)', caseSensitive: false);

  if (!urlRegex.hasMatch(text)) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize,
        lineSpacing: lineSpacing,
        color: color,
      ),
    );
  }

  final spans = <pw.InlineSpan>[];
  int lastEnd = 0;

  for (final match in urlRegex.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(pw.TextSpan(
        text: text.substring(lastEnd, match.start),
        style: pw.TextStyle(
          fontSize: fontSize,
          lineSpacing: lineSpacing,
          color: color,
        ),
      ));
    }

    final rawUrl = match.group(0)!;
    final dest = _normalizeUrlForLink(rawUrl);

    spans.add(pw.WidgetSpan(
      child: pw.UrlLink(
        destination: dest,
        child: pw.Text(
          rawUrl,
          style: pw.TextStyle(
            fontSize: fontSize,
            lineSpacing: lineSpacing,
            color: linkColor,
          ),
        ),
      ),
    ));

    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(pw.TextSpan(
      text: text.substring(lastEnd),
      style: pw.TextStyle(
        fontSize: fontSize,
        lineSpacing: lineSpacing,
        color: color,
      ),
    ));
  }

  return pw.RichText(
    text: pw.TextSpan(children: spans),
  );
}

void main() {
  test('URL Normalization rules', () {
    expect(_normalizeUrlForLink('https://linkedin.com/in/test'), 'https://linkedin.com/in/test');
    expect(_normalizeUrlForLink('http://example.com/path?query=1#frag'), 'http://example.com/path?query=1#frag');
    expect(_normalizeUrlForLink('www.example.com'), 'https://www.example.com');
    expect(_normalizeUrlForLink('linkedin.com/in/nishant-arya-838168321'), 'https://linkedin.com/in/nishant-arya-838168321');
    expect(_normalizeUrlForLink('github.com/Nishanttxx'), 'https://github.com/Nishanttxx');
    expect(_normalizeUrlForLink('example.com/demo'), 'https://example.com/demo');
    expect(_normalizeUrlForLink('(https://example.com)'), 'https://example.com');
    expect(_normalizeUrlForLink('https://example.com.'), 'https://example.com');
  });

  test('Text with links rendering in PDF', () async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            _buildTextWithLinks(
              'Normal bullet without link Computer Science and Engineering',
              fontSize: 10,
              color: PdfColors.black,
              linkColor: PdfColors.blue,
            ),
            _buildTextWithLinks(
              'Developed system live at https://myproject.com with high throughput.',
              fontSize: 10,
              color: PdfColors.black,
              linkColor: PdfColors.blue,
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    expect(bytes, isNotNull);
    final pdfString = String.fromCharCodes(bytes);
    expect(pdfString.contains('https://myproject.com'), isTrue);
  });
}
