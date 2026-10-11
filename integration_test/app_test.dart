import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lunanest/main.dart' as app;

/// Smoke test. Run on a device/emulator:  flutter test integration_test
/// Background playback, lock-screen controls and sleep-timer behavior must be
/// verified manually on real hardware (see docs/TESTING.md).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches, skips onboarding and starts a sound', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Tonight’s mixes'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rain & Thunder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gentle Rain'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Now playing'), findsOneWidget);
  });
}
