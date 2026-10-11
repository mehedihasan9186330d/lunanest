import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/domain/models.dart';

void main() {
  const json = '''
  {"categories":[{"id":"rain","title":"Rain"}],
   "sounds":[
     {"id":"a","title":"A","category":"rain","asset":"assets/audio/a.wav"},
     {"id":"b","title":"B","category":"rain","url":"https://example.com/b.mp3","offlineAllowed":true,"premium":true},
     {"id":"ghost","title":"Ghost","category":"rain"}
   ],
   "presets":[
     {"id":"p1","name":"Ok","layers":[{"soundId":"a","volume":0.5}]},
     {"id":"p2","name":"Broken","layers":[{"soundId":"missing","volume":0.5}]}
   ]}''';

  test('catalog drops entries with no audio source (no fake playable items)', () {
    final c = Catalog.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(c.sounds.map((s) => s.id), ['a', 'b']);
  });

  test('presets referencing missing sounds are dropped', () {
    final c = Catalog.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(c.presets.map((p) => p.id), ['p1']);
  });

  test('download eligibility requires https url and license flag', () {
    final c = Catalog.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(c.sound('a')!.canDownload, isFalse);
    expect(c.sound('b')!.canDownload, isTrue);
    expect(const Sound(id: 'x', title: 'x', categoryId: 'c', url: 'http://insecure/x.mp3', offlineAllowed: true).canDownload, isFalse);
  });

  test('mixNeedsPremium', () {
    final c = Catalog.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(c.mixNeedsPremium(const Mix(id: 'm', name: 'm', layers: [MixLayer('b', 1)])), isTrue);
    expect(c.mixNeedsPremium(const Mix(id: 'm', name: 'm', layers: [MixLayer('a', 1)])), isFalse);
  });

  test('Mix and AppSettings JSON round-trip', () {
    const m = Mix(id: '1', name: 'Night', layers: [MixLayer('a', 0.25), MixLayer('b', 1.0)]);
    final back = Mix.fromJson(jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(back.name, 'Night');
    expect(back.layers.length, 2);
    expect(back.layers.first.volume, 0.25);

    const s = AppSettings(themeMode: ThemeMode.system, fadeSeconds: 33, defaultTimerMinutes: 45, onboardingDone: true);
    final s2 = AppSettings.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(s2.themeMode, ThemeMode.system);
    expect(s2.fadeSeconds, 33);
    expect(s2.onboardingDone, isTrue);
  });
}
