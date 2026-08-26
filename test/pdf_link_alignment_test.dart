import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate PDF with TextSpan annotation', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.RichText(
            text: pw.TextSpan(
              children: [
                const pw.TextSpan(text: 'Visit my GitHub: '),
                pw.TextSpan(
                  text: 'https://github.com/user/project',
                  style: const pw.TextStyle(color: PdfColors.blue),
                  annotation: pw.AnnotationUrl('https://github.com/user/project'),
                ),
                const pw.TextSpan(text: ' for details.'),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, isTrue);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
