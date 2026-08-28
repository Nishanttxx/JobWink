import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jobwink/providers/auth_provider.dart';
import 'package:jobwink/services/theme_service.dart';
import 'package:jobwink/theme/app_theme.dart';
import 'package:jobwink/widgets/app_layout.dart';
import 'package:jobwink/widgets/theme_toggle_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.instance.init();
  });

  group('Dashboard Navigation & Theme Toggle Tests', () {
    test('ThemeService toggles and persists theme mode', () async {
      SharedPreferences.setMockInitialValues({'user_theme_mode': 'dark'});
      await ThemeService.instance.init();

      expect(ThemeService.instance.isDarkMode, isTrue);
      expect(ThemeService.instance.themeModeNotifier.value, equals(ThemeMode.dark));

      // Toggle from Dark to Light
      await ThemeService.instance.toggleTheme();
      expect(ThemeService.instance.isDarkMode, isFalse);
      expect(ThemeService.instance.themeModeNotifier.value, equals(ThemeMode.light));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_theme_mode'), equals('light'));

      // Toggle from Light to Dark
      await ThemeService.instance.toggleTheme();
      expect(ThemeService.instance.isDarkMode, isTrue);
      expect(ThemeService.instance.themeModeNotifier.value, equals(ThemeMode.dark));
      expect(prefs.getString('user_theme_mode'), equals('dark'));
    });

    testWidgets('ThemeToggleButton renders with accessible semantics and toggles on click', (tester) async {
      SharedPreferences.setMockInitialValues({'user_theme_mode': 'dark'});
      await ThemeService.instance.init();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: Center(
              child: ThemeToggleButton(),
            ),
          ),
        ),
      );

      // Verify accessible toggle widget is present
      expect(find.byType(ThemeToggleButton), findsOneWidget);
      expect(find.byTooltip('Switch to light mode'), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byType(ThemeToggleButton));
      await tester.pumpAndSettle();

      expect(ThemeService.instance.isDarkMode, isFalse);
    });

    testWidgets('AppLayout desktop navbar renders Home button and ThemeToggleButton', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        AuthProviderScope(
          authProvider: auth,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const AppLayout(
              activeIndex: 2,
              title: 'Resume Tailoring',
              child: Center(child: Text('Dashboard Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Home button is rendered in the desktop navbar
      expect(find.text('Home'), findsWidgets);
      expect(find.byType(ThemeToggleButton), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
    });

    testWidgets('AppLayout mobile renders drawer with Home button and mobile navbar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        AuthProviderScope(
          authProvider: auth,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const AppLayout(
              activeIndex: 2,
              title: 'Resume Tailoring',
              child: Center(child: Text('Mobile Dashboard')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mobile navbar has Open Menu (hamburger) and ThemeToggleButton
      expect(find.byTooltip('Open Menu'), findsOneWidget);
      expect(find.byType(ThemeToggleButton), findsOneWidget);

      // Open drawer
      final menuButton = find.byTooltip('Open Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Inside drawer sidebar, Home menu item is present
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
