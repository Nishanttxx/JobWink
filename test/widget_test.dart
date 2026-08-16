import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jobwink/main.dart';
import 'package:jobwink/config/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  });

  testWidgets('Landing page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JobwinkApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that Jobwink title exists
    expect(find.text('Jobwink'), findsWidgets);
  });
}
