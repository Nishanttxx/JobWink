import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Test local Tinos TTF font unicode support', () async {
    final regFile = File('assets/fonts/Tinos-Regular.ttf');
    final boldFile = File('assets/fonts/Tinos-Bold.ttf');
    expect(regFile.existsSync(), isTrue);
    expect(boldFile.existsSync(), isTrue);

    final fontReg = pw.Font.ttf((await regFile.readAsBytes()).buffer.asByteData());
    final fontBold = pw.Font.ttf((await boldFile.readAsBytes()).buffer.asByteData());

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Regular: • bullet | – en-dash | — em-dash | ’ apostrophe | ₹ Rupee | Nishant Arya',
                style: pw.TextStyle(font: fontReg, fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Bold: • bullet | – en-dash | — em-dash | ’ apostrophe | ₹ Rupee | Nishant Arya',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    expect(pdfBytes.length, greaterThan(1000));
  });
}
