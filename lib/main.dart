import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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

  final engine = AudioEngine(
    localPathFor: downloads.localPath,
    initialMasterVolume: store.masterVolume,
    soundVolumes: store.soundVolumes,
    onPrefsChanged: (master, volumes) {
      store.saveMasterVolume(master);
      store.saveSoundVolumes(volumes);
    },
  );
  final artUri = await _prepareMediaArt();
  final handler = await AudioService.init<LunaAudioHandler>(
    builder: () => LunaAudioHandler(engine, artUri: artUri),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.lunanest.lunanest.playback',
      androidNotificationChannelName: 'LunaNest playback',
      androidNotificationIcon: 'drawable/ic_stat_luna', // branded monochrome moon (added by tool/patch_platforms.py)
      notificationColor: Color(0xFF6A4FD0),
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

/// Copies the bundled artwork to app storage once so the system media notification
/// and lock screen can load it from a file:// URI. Returns null if anything fails
/// (playback works without artwork).
Future<Uri?> _prepareMediaArt() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final f = File('${dir.path}/media_art.png');
    if (!f.existsSync()) {
      final data = await rootBundle.load('assets/branding/media_art.png');
      await f.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return f.uri;
  } catch (_) {
    return null;
  }
}
