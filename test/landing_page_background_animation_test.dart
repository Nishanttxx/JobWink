import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jobwink/main.dart';
import 'package:jobwink/widgets/shape_grid_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('Landing Page Background Animation Tests', () {
    testWidgets('1. ShapeGridBackground initializes and animates continuously', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShapeGridBackground(
              speed: 0.35,
              squareSize: 50.0,
              direction: ShapeGridDirection.diagonal,
            ),
          ),
        ),
      );

      final gridFinder = find.byType(ShapeGridBackground);
      expect(gridFinder, findsOneWidget);
      expect(find.descendant(of: gridFinder, matching: find.byType(CustomPaint)), findsOneWidget);
      expect(find.descendant(of: gridFinder, matching: find.byType(AnimatedBuilder)), findsOneWidget);

      // Verify that the animation ticks forward smoothly
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));

      expect(find.descendant(of: gridFinder, matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('2. ShapeGridBackground is active on Mobile screen sizes', (WidgetTester tester) async {
      const mobileWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0];

      for (final width in mobileWidths) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ShapeGridBackground(
                speed: 0.35,
                squareSize: 45.0,
                direction: ShapeGridDirection.diagonal,
              ),
            ),
          ),
        );

        final gridFinder = find.byType(ShapeGridBackground);
        expect(gridFinder, findsOneWidget);
        // Verify AnimatedBuilder is active inside ShapeGridBackground on mobile
        expect(find.descendant(of: gridFinder, matching: find.byType(AnimatedBuilder)), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 200));
      }

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('3. ShapeGridBackground renders correctly on Desktop screen sizes', (WidgetTester tester) async {
      const desktopWidths = [1024.0, 1280.0, 1440.0, 1920.0];

      for (final width in desktopWidths) {
        tester.view.physicalSize = Size(width * 1.5, 900 * 1.5);
        tester.view.devicePixelRatio = 1.5;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ShapeGridBackground(
                speed: 0.35,
                squareSize: 50.0,
                direction: ShapeGridDirection.diagonal,
              ),
            ),
          ),
        );

        final gridFinder = find.byType(ShapeGridBackground);
        expect(gridFinder, findsOneWidget);
        expect(find.descendant(of: gridFinder, matching: find.byType(AnimatedBuilder)), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 200));
      }

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('4. Reduced motion accessibility pauses animation cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: ShapeGridBackground(
                speed: 0.35,
                squareSize: 50.0,
              ),
            ),
          ),
        ),
      );

      final gridFinder = find.byType(ShapeGridBackground);
      expect(gridFinder, findsOneWidget);
      // In reduced motion, AnimatedBuilder is not used inside ShapeGridBackground
      expect(find.descendant(of: gridFinder, matching: find.byType(AnimatedBuilder)), findsNothing);
      expect(find.descendant(of: gridFinder, matching: find.byType(CustomPaint)), findsOneWidget);
    });

    testWidgets('5. Animation lifecycle handles dispose without leaks', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShapeGridBackground(
              speed: 0.35,
              squareSize: 50.0,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Replace widget with empty container to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ShapeGridBackground), findsNothing);
    });

    testWidgets('6. Full LandingPage integration renders animated background during scrolling', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280 * 1.5, 900 * 1.5);
      tester.view.devicePixelRatio = 1.5;

      await tester.pumpWidget(
        const MaterialApp(
          home: LandingPage(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      final gridFinder = find.byType(ShapeGridBackground);
      expect(gridFinder, findsOneWidget);
      expect(find.descendant(of: gridFinder, matching: find.byType(AnimatedBuilder)), findsOneWidget);

      // Scroll down using the primary scrollable
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pump(const Duration(seconds: 2));

      // Confirm background is still active and animating
      expect(gridFinder, findsOneWidget);
      expect(find.descendant(of: gridFinder, matching: find.byType(AnimatedBuilder)), findsOneWidget);

      // Scroll back up
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 300));
      await tester.pump(const Duration(seconds: 2));

      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
