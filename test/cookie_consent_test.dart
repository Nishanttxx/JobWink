import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jobwink/services/cookie_consent_service.dart';
import 'package:jobwink/widgets/cookie_consent_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CookieConsentService.instance.init();
    await CookieConsentService.instance.resetConsent();
  });

  group('Cookie Consent System Tests', () {
    testWidgets('Cookie banner appears when user enters for the first time (undecided)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CookieConsentWrapper(
            child: Scaffold(body: Text('Main Application Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cookies'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text
                .toPlainText()
                .contains('We use cookies and similar technologies to provide essential website functionality')),
        findsOneWidget,
      );
      expect(find.text('Accept All Cookies'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Main Application Content'), findsOneWidget);
    });

    testWidgets('Clicking Accept All Cookies saves choice and removes banner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CookieConsentWrapper(
            child: Scaffold(body: Text('Main Application Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept All Cookies'));
      await tester.pumpAndSettle();

      expect(CookieConsentService.instance.isAccepted, isTrue);
      expect(find.text('Cookies'), findsNothing);
      expect(find.text('Main Application Content'), findsOneWidget);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cookie_consent_status'), 'accepted');
    });

    testWidgets('Clicking Reject blocks application usage and presents requirement message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CookieConsentWrapper(
            child: Scaffold(body: Text('Main Application Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(CookieConsentService.instance.isRejected, isTrue);
      expect(find.text('Cookie Consent Required'), findsOneWidget);
      expect(find.textContaining('JobWink requires essential cookies and local storage technologies to operate'), findsOneWidget);

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cookie_consent_status'), 'rejected');

      // User can accept from the blocked view to restore access
      await tester.tap(find.text('Accept All Cookies'));
      await tester.pumpAndSettle();

      expect(CookieConsentService.instance.isAccepted, isTrue);
      expect(find.text('Cookie Consent Required'), findsNothing);
      expect(find.text('Main Application Content'), findsOneWidget);
    });
  });
}
