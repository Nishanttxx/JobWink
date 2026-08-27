import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/models/resume_data.dart';
import 'package:jobwink/widgets/resume_preview_dialog.dart';

void main() {
  testWidgets('ResumePreviewDialog renders cleanly', (WidgetTester tester) async {
    final testResume = ResumeData(
      fullName: 'Nishant Arya',
      email: 'test-user@example.com',
      phone: '+91 9876543210',
      summary: 'Experienced software engineer.',
      skills: ['Flutter', 'Dart', 'Python'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResumePreviewDialog(
            resumeData: testResume,
            onDownload: () {},
          ),
        ),
      ),
    );

    expect(find.text('Resume Preview'), findsOneWidget);
    expect(find.text('Download Resume'), findsOneWidget);
  });
}
