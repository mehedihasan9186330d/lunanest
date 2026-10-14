import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/data/local_store.dart';
import 'package:lunanest/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
  });

  test('bedtime routine persists and can be removed', () async {
    expect(store.routine, isNull);
    await store.saveRoutine(const BedtimeRoutine(mixId: 'preset_rainy_night', minutes: 45));
    expect(store.routine!.mixId, 'preset_rainy_night');
    expect(store.routine!.minutes, 45);
    await store.saveRoutine(null);
    expect(store.routine, isNull);
  });

  test('volume preferences persist', () async {
    expect(store.masterVolume, 0.8);
    await store.saveMasterVolume(0.35);
    await store.saveSoundVolumes({'gentle_rain': 0.5, 'fireplace': 0.9});
    expect(store.masterVolume, 0.35);
    expect(store.soundVolumes['fireplace'], 0.9);
  });

  test('corrupt routine/volume data falls back safely', () async {
    SharedPreferences.setMockInitialValues({'bedtime_routine': '{nope', 'sound_volumes': '[1,2'});
    final s = LocalStore(await SharedPreferences.getInstance());
    expect(s.routine, isNull);
    expect(s.soundVolumes, isEmpty);
  });

  test('notification permission is asked at most once', () async {
    expect(store.notificationPermissionAsked, isFalse);
    await store.setNotificationPermissionAsked();
    expect(store.notificationPermissionAsked, isTrue);
  });

  test('bundled catalog.json: every sound is free and has audio', () {
    final c = jsonDecode(File('assets/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    for (final s in c['sounds'] as List) {
      final m = s as Map<String, dynamic>;
      expect(m['premium'], isFalse, reason: '${m['id']} must stay free');
      expect(m['asset'] != null || m['url'] != null, isTrue, reason: '${m['id']} needs an audio source');
    }
  });
}
