import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/services/ai_service.dart';

void main() {
  test('Test PDF text extraction on NNM23ME008_RESUME.pdf', () async {
    final file = File(r'C:\Users\na623\Downloads\NNM23ME008_RESUME.pdf');
    expect(file.existsSync(), isTrue);
    final bytes = await file.readAsBytes();

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'NNM23ME008_RESUME.pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
    expect(text.contains('ARUN SINGH'), isTrue);
    expect(text.contains('Mechanical Engineering'), isTrue);
  });

  test('Test PDF text extraction on NISHANT ARYA (4).pdf', () async {
    final file = File(r'C:\Users\na623\Downloads\NISHANT ARYA (4).pdf');
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'NISHANT ARYA (4).pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
    expect(RegExp(r'NISHANT\s+ARYA', caseSensitive: false).hasMatch(text), isTrue);
  });

  test('Test PDF text extraction on Nishant Arya.pdf', () async {
    final file = File(r'C:\Users\na623\Downloads\Nishant Arya.pdf');
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();

    final text = await AIService.extractTextFromBytesAsyncStatic(bytes, fileName: 'Nishant Arya.pdf');

    expect(text.trim().isNotEmpty, isTrue);
    expect(AIService.validateExtractedText(text), isTrue);
  });
}
