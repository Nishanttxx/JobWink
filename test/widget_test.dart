import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:jobwink/main.dart';
import 'package:jobwink/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('Landing page smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const JobwinkApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));

    // Verify that Jobwink title exists
    expect(find.text('Jobwink'), findsWidgets);
  });
}
