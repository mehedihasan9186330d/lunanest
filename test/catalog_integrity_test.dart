import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/domain/models.dart';

void main() {
  final raw = jsonDecode(File('assets/catalog.json').readAsStringSync()) as Map<String, dynamic>;
  final catalog = Catalog.fromJson(raw);
  final generator = File('tool/generate_audio.py').readAsStringSync();

  test('ids are unique and every sound has a title and category', () {
    final ids = catalog.sounds.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final s in catalog.sounds) {
      expect(s.title.trim(), isNotEmpty);
      expect(catalog.category(s.categoryId), isNotNull, reason: '${s.id} has unknown category');
    }
  });

  test('every category has a rich selection', () {
    const minimums = {'rain': 8, 'ocean': 6, 'nature': 8, 'noise': 6, 'cozy': 5};
    minimums.forEach((cat, min) {
      expect(catalog.inCategory(cat).length, greaterThanOrEqualTo(min), reason: '$cat needs at least $min sounds');
    });
  });

  test('every sound is free, synthesized (CC0) and has a generator entry', () {
    for (final s in catalog.sounds) {
      expect(s.premium, isFalse, reason: '${s.id} must be free');
      expect(s.license, contains('CC0'));
      expect(s.assetPath, 'assets/audio/${s.id}.wav');
      expect(generator.contains('"${s.id}": ('), isTrue, reason: '${s.id} missing from tool/generate_audio.py');
    }
  });

  test('presets only reference sounds that exist', () {
    expect(catalog.presets, isNotEmpty);
    final ids = catalog.sounds.map((s) => s.id).toSet();
    for (final p in raw['presets'] as List) {
      for (final l in (p as Map)['layers'] as List) {
        expect(ids, contains((l as Map)['soundId']));
      }
    }
    // Catalog.fromJson silently drops broken presets, so make sure none were dropped.
    expect(catalog.presets.length, (raw['presets'] as List).length);
  });
}
