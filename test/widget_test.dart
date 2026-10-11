import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/app/providers.dart';
import 'package:lunanest/data/local_store.dart';
import 'package:lunanest/domain/models.dart';
import 'package:lunanest/features/common/widgets.dart';
import 'package:lunanest/features/premium/premium_screen.dart';
import 'package:lunanest/services/audio/audio_engine.dart';
import 'package:lunanest/services/billing/billing_service.dart';
import 'package:lunanest/services/downloads/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> harness(Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  const catalog = Catalog(
    categories: [SoundCategory(id: 'rain', title: 'Rain & Thunder')],
    sounds: [
      Sound(id: 'free', title: 'Gentle Rain', categoryId: 'rain', assetPath: 'x.wav'),
      Sound(id: 'pro', title: 'Heavy Rain', categoryId: 'rain', assetPath: 'y.wav', premium: true),
    ],
    presets: [],
  );
  return ProviderScope(
    overrides: [
      storeProvider.overrideWithValue(store),
      catalogProvider.overrideWith((ref) async => catalog),
      engineProvider.overrideWith((ref) => AudioEngine(localPathFor: (_) => null)),
      downloadsProvider.overrideWith((ref) => DownloadManager(store)),
      billingProvider.overrideWith((ref) => BillingService()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('SoundTile shows title and category', (tester) async {
    await tester.pumpWidget(await harness(const SoundTile(
        sound: Sound(id: 'free', title: 'Gentle Rain', categoryId: 'rain', assetPath: 'x.wav'))));
    await tester.pumpAndSettle();
    expect(find.text('Gentle Rain'), findsOneWidget);
    expect(find.text('Rain & Thunder'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('Premium sounds show a lock for free users', (tester) async {
    await tester.pumpWidget(await harness(const SoundTile(
        sound: Sound(id: 'pro', title: 'Heavy Rain', categoryId: 'rain', assetPath: 'y.wav', premium: true))));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('Favorite toggle updates state', (tester) async {
    await tester.pumpWidget(await harness(const SoundTile(
        sound: Sound(id: 'free', title: 'Gentle Rain', categoryId: 'rain', assetPath: 'x.wav'))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  });

  testWidgets('Paywall never unlocks or fakes prices when billing is unconfigured', (tester) async {
    await tester.pumpWidget(await harness(const PremiumScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('not configured'), findsOneWidget);
    expect(find.text('Subscribe'), findsNothing);
    expect(find.text('Restore purchases'), findsOneWidget);
  });
}
