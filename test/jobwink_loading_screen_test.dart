import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jobwink/main.dart';
import 'package:jobwink/providers/auth_provider.dart';
import 'package:jobwink/widgets/jobwink_loading_screen.dart';

class _MockInitializingAuthController extends AuthController {
  bool _initializing = true;

  @override
  bool get isInitializing => _initializing;

  @override
  bool get isAuthenticated => false;

  @override
  AuthStatus get status =>
      _initializing ? AuthStatus.initializing : AuthStatus.unauthenticated;

  void completeInit() {
    _initializing = false;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('JobWink Loading / Splash Screen Tests', () {
    testWidgets('1. JobwinkLoadingScreen renders logo, brand title, and subtle indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JobwinkLoadingScreen(),
        ),
      );

      // Verify widget elements
      expect(find.byType(JobwinkLoadingScreen), findsOneWidget);
      expect(find.text('JobWink'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);

      // Verify entrance animation progression
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(JobwinkLoadingScreen), findsOneWidget);
    });

    testWidgets('2. JobwinkLoadingScreen is responsive on Mobile screen sizes (320, 360, 375, 390, 412, 430px)', (WidgetTester tester) async {
      const mobileWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0];

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: JobwinkLoadingScreen(),
          ),
        );

        expect(find.byType(JobwinkLoadingScreen), findsOneWidget);
        expect(find.text('JobWink'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify no overflow errors
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(milliseconds: 300));
      }

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('3. JobwinkLoadingScreen renders on Desktop screen sizes (1024, 1280, 1440px+)', (WidgetTester tester) async {
      const desktopWidths = [1024.0, 1280.0, 1440.0, 1920.0];

      for (final width in desktopWidths) {
        tester.view.physicalSize = Size(width * 1.5, 900 * 1.5);
        tester.view.devicePixelRatio = 1.5;

        await tester.pumpWidget(
          const MaterialApp(
            home: JobwinkLoadingScreen(),
          ),
        );

        expect(find.byType(JobwinkLoadingScreen), findsOneWidget);
        expect(find.text('JobWink'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify no overflow errors
        expect(tester.takeException(), isNull);

        await tester.pump(const Duration(milliseconds: 300));
      }

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('4. AppRootGate displays JobwinkLoadingScreen during auth initialization and transitions to LandingPage', (WidgetTester tester) async {
      final mockController = _MockInitializingAuthController();

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: mockController,
          builder: (context, _) => AuthProviderScope(
            authProvider: mockController,
            child: MaterialApp(
              key: UniqueKey(),
              home: const AppRootGate(),
            ),
          ),
        ),
      );

      // 1. While auth is initializing, JobwinkLoadingScreen is actively rendered
      expect(find.byType(JobwinkLoadingScreen), findsOneWidget);
      expect(find.byType(LandingPage), findsNothing);

      // 2. Complete session resolution
      mockController.completeInit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Transitions immediately to LandingPage once initialized
      expect(find.byType(LandingPage), findsOneWidget);
      expect(find.byType(JobwinkLoadingScreen), findsNothing);

      // 4. Advance time to complete entrance timers before tearing down
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());

      mockController.dispose();
    });

    testWidgets('5. Animation lifecycle handles dispose without memory leaks', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JobwinkLoadingScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Remove loading screen from widget tree
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(JobwinkLoadingScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
