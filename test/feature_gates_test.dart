import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/app/feature_gates.dart';
import 'package:lunanest/domain/models.dart';

void main() {
  const free = Sound(id: 'a', title: 'A', categoryId: 'rain', assetPath: 'a.wav');
  const flagged = Sound(id: 'b', title: 'B', categoryId: 'rain', assetPath: 'b.wav', premium: true);

  test('launch state: nothing is locked, nothing paid', () {
    const g = FeatureGates.launch;
    expect(g.soundLocked(free, false), isFalse);
    expect(g.soundLocked(flagged, false), isFalse);
    expect(g.maxLayers(false), g.maxLayers(true));
    expect(g.maxSavedMixes(false), g.maxSavedMixes(true));
    expect(g.maxDownloads(false), g.maxDownloads(true));
    expect(g.hasPaidBenefits, isFalse);
  });

  test('enabling lockPremiumSounds only affects sounds flagged premium', () {
    const g = FeatureGates(lockPremiumSounds: true);
    expect(g.soundLocked(free, false), isFalse);
    expect(g.soundLocked(flagged, false), isTrue);
    expect(g.soundLocked(flagged, true), isFalse);
    expect(g.hasPaidBenefits, isTrue);
  });

  test('lower free limits make Premium meaningful', () {
    const g = FeatureGates(freeMaxLayers: 3);
    expect(g.maxLayers(false), 3);
    expect(g.maxLayers(true), 6);
    expect(g.hasPaidBenefits, isTrue);
  });

  test('mixLocked follows the sounds in the mix', () {
    const catalog = Catalog(categories: [], sounds: [free, flagged], presets: []);
    const onlyFree = Mix(id: '1', name: 'f', layers: [MixLayer('a', 1)]);
    const withFlagged = Mix(id: '2', name: 'p', layers: [MixLayer('a', 1), MixLayer('b', 1)]);
    const g = FeatureGates(lockPremiumSounds: true);
    expect(g.mixLocked(onlyFree, catalog, false), isFalse);
    expect(g.mixLocked(withFlagged, catalog, false), isTrue);
    expect(FeatureGates.launch.mixLocked(withFlagged, catalog, false), isFalse);
  });

  test('catalog ships with every sound free', () {
    // Guards the "keep all sounds free" rule for the bundled catalog.json (see catalog_free_test for the file check).
    expect(FeatureGates.launch.lockPremiumSounds, isFalse);
  });
}
