import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/local_store.dart';
import 'services/audio/audio_engine.dart';
import 'services/audio/audio_handler.dart';
import 'services/billing/billing_service.dart';
import 'services/downloads/download_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);

  final downloads = DownloadManager(store);
  await downloads.load();

  final engine = AudioEngine(localPathFor: downloads.localPath);
  final handler = await AudioService.init<LunaAudioHandler>(
    builder: () => LunaAudioHandler(engine),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lunanest.lunanest.playback',
      androidNotificationChannelName: 'LunaNest playback',
    ),
  );
  await engine.init();

  // Billing must never block startup: the app is fully usable without it.
  final billing = BillingService();
  unawaited(billing.init());

  runApp(ProviderScope(
    overrides: [
      storeProvider.overrideWithValue(store),
      audioHandlerProvider.overrideWithValue(handler),
      downloadsProvider.overrideWith((ref) => downloads),
      billingProvider.overrideWith((ref) => billing),
    ],
    child: const LunaNestApp(),
  ));
}
