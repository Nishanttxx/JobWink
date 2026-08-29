import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jobwink/screens/privacy_policy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('PrivacyPolicyScreen renders all required legal sections cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyPolicyScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Title & Date
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Last Updated: August 27, 2026'), findsOneWidget);

    // Verify Critical Sections
    expect(find.text('1. Information We Collect'), findsOneWidget);
    expect(find.text('2. How We Use Your Information'), findsOneWidget);
    expect(find.text('3. Artificial Intelligence (AI) Processing'), findsOneWidget);
    expect(find.text('4. Authentication & Security'), findsOneWidget);
    expect(find.text('5. Data Storage & Retention'), findsOneWidget);
    expect(find.text('6. Third-Party Service Providers & Data Sharing'), findsOneWidget);
    expect(find.text('7. Cookies & Local Storage'), findsOneWidget);
    expect(find.text('8. Third-Party External Links'), findsOneWidget);
    expect(find.text('9. Security Measures'), findsOneWidget);
    expect(find.text('10. User Rights & Data Requests'), findsOneWidget);
    expect(find.text('11. Changes to This Privacy Policy'), findsOneWidget);
    expect(find.text('12. Contact Information'), findsOneWidget);

    // Verify Official Contact Section
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
  });
}
