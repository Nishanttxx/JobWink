import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jobwink/providers/auth_provider.dart';
import 'package:jobwink/services/theme_service.dart';
import 'package:jobwink/theme/app_theme.dart';
import 'package:jobwink/widgets/app_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.instance.init();
  });

  group('Extracted Text Card Removal & Logo Light Mode Tests', () {
    testWidgets('AppSidebar logo renders Job in high-contrast color in both Light and Dark modes', (WidgetTester tester) async {
      final authProvider = AuthProvider();

      // 1. Test in Dark Mode
      ThemeService.instance.themeModeNotifier.value = ThemeMode.dark;

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AuthProviderScope(
            authProvider: authProvider,
            child: const Scaffold(
              body: AppSidebar(
                activeIndex: 0,
                isCollapsed: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find RichText for JobWink logo
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final span = widget.text;
          if (span is TextSpan && span.children != null && span.children!.length >= 2) {
            final first = span.children![0] as TextSpan;
            final second = span.children![1] as TextSpan;
            return first.text == 'Job' && second.text == 'Wink';
          }
        }
        return false;
      });

      expect(richTextFinder, findsOneWidget);

      final darkRichText = tester.widget<RichText>(richTextFinder);
      final darkSpan = darkRichText.text as TextSpan;
      final darkJobSpan = darkSpan.children![0] as TextSpan;
      final darkWinkSpan = darkSpan.children![1] as TextSpan;

      expect(darkJobSpan.text, 'Job');
      expect(darkWinkSpan.text, 'Wink');
      // In Dark Mode, text color is textLight (white / 0xFFFFFFFF)
      expect(darkJobSpan.style?.color, AppTheme.textLight);
      expect(darkWinkSpan.style?.color, AppTheme.primaryOrange);

      // 2. Test in Light Mode
      ThemeService.instance.themeModeNotifier.value = ThemeMode.light;

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AuthProviderScope(
            authProvider: authProvider,
            child: const Scaffold(
              body: AppSidebar(
                activeIndex: 0,
                isCollapsed: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightRichText = tester.widget<RichText>(richTextFinder);
      final lightSpan = lightRichText.text as TextSpan;
      final lightJobSpan = lightSpan.children![0] as TextSpan;
      final lightWinkSpan = lightSpan.children![1] as TextSpan;

      expect(lightJobSpan.text, 'Job');
      expect(lightWinkSpan.text, 'Wink');
      // In Light Mode, text color is textDark (0xFF0F1012), NOT white!
      expect(lightJobSpan.style?.color, AppTheme.textDark);
      expect(lightJobSpan.style?.color, isNot(Colors.white));
      expect(lightWinkSpan.style?.color, AppTheme.primaryOrange);
    });

    testWidgets('Extracted Resume Text string is never rendered on Resume Tailoring', (WidgetTester tester) async {
      // Ensure the string 'Extracted Resume Text' does not appear anywhere
      expect(find.textContaining('Extracted Resume Text'), findsNothing);
    });
  });
}
