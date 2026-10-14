import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/domain/models.dart';
import 'package:lunanest/ui/rand.dart';
import 'package:lunanest/ui/scene_kind.dart';
import 'package:lunanest/ui/scene_painters.dart';
import 'package:lunanest/ui/scene_view.dart';
import 'package:lunanest/ui/timer_ring.dart';

Sound _s(String id, String cat) => Sound(id: id, title: id, categoryId: cat, assetPath: 'x.wav');

void main() {
  catalogSceneTests();
  test('hash01 stays in [0,1) and is deterministic', () {
    for (var i = 0; i < 500; i++) {
      final v = hash01(i, 3);
      expect(v, greaterThanOrEqualTo(0.0));
      expect(v, lessThan(1.0));
      expect(hash01(i, 3), v);
    }
  });

  test('sounds map to matching scenes', () {
    expect(sceneForSound(_s('gentle_rain', 'rain')).kind, SceneKind.rain);
    expect(sceneForSound(_s('heavy_rain', 'rain')).intensity, greaterThan(sceneForSound(_s('gentle_rain', 'rain')).intensity));
    expect(sceneForSound(_s('distant_thunder', 'rain')).kind, SceneKind.storm);
    expect(sceneForSound(_s('ocean_waves', 'ocean')).kind, SceneKind.ocean);
    expect(sceneForSound(_s('forest_stream', 'nature')).kind, SceneKind.river);
    expect(sceneForSound(_s('night_crickets', 'nature')).kind, SceneKind.forest);
    expect(sceneForSound(_s('fireplace', 'cozy')).kind, SceneKind.fire);
    expect(sceneForSound(_s('pink_noise', 'noise')).kind, SceneKind.noise);
    expect(sceneForSound(_s('soft_wind', 'nature')).kind, SceneKind.wind);
  });

  test('unknown sounds fall back by category', () {
    expect(sceneForSound(_s('new_thing', 'ocean')).kind, SceneKind.ocean);
    expect(sceneForSound(_s('new_thing', 'zzz')).kind, SceneKind.noise);
  });

  test('every scene kind paints without throwing, including lightning frames', () {
    for (final kind in SceneKind.values) {
      for (final t in [0.0, 1.3, 7.05, 7.3, 42.5, 100000.0]) {
        final rec = PictureRecorder();
        final canvas = Canvas(rec);
        paintScene(canvas, const Size(390, 300), t, SceneLayer(SceneSpec(kind, 0.7), 0.8));
        paintScene(canvas, const Size(40, 40), t, SceneLayer(SceneSpec(kind, 0.2), 0.3));
        rec.endRecording();
      }
    }
  });

  testWidgets('SceneView animates and stops cleanly', (tester) async {
    Widget host(bool animate) => MaterialApp(
          home: SizedBox(
            width: 200,
            height: 200,
            child: SceneView(layers: const [SceneLayer(SceneSpec(SceneKind.rain, 0.8))], animate: animate),
          ),
        );
    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(host(false));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TimerRing shows its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TimerRing(progress: 0.4, child: Text('12:00')))));
    expect(find.text('12:00'), findsOneWidget);
  });
}

void catalogSceneTests() {
  test('every catalog sound maps to a scene that fits its category', () {
    final c = jsonDecode(File('assets/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    const allowed = {
      'rain': {SceneKind.rain, SceneKind.storm},
      'ocean': {SceneKind.ocean},
      'nature': {SceneKind.wind, SceneKind.river, SceneKind.forest},
      'noise': {SceneKind.noise},
      'cozy': {SceneKind.fire, SceneKind.noise},
    };
    for (final s in c['sounds'] as List) {
      final m = s as Map<String, dynamic>;
      final sound = Sound(id: m['id'] as String, title: m['title'] as String, categoryId: m['category'] as String, assetPath: m['asset'] as String);
      expect(allowed[sound.categoryId], contains(sceneForSound(sound).kind), reason: '${sound.id} scene does not fit ${sound.categoryId}');
    }
  });
}
