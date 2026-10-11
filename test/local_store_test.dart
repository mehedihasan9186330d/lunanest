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

  test('favorites persist', () async {
    await store.saveFavorites({'a', 'b'});
    expect(store.favorites, {'a', 'b'});
  });

  test('mixes persist and corrupt entries are skipped', () async {
    await store.saveMixes(const [Mix(id: '1', name: 'One', layers: [MixLayer('a', 0.4)])]);
    expect(store.mixes.single.name, 'One');
    SharedPreferences.setMockInitialValues({'mixes': ['not json']});
    final s2 = LocalStore(await SharedPreferences.getInstance());
    expect(s2.mixes, isEmpty);
  });

  test('settings default and persist', () async {
    expect(store.settings.fadeSeconds, 20);
    await store.saveSettings(const AppSettings(fadeSeconds: 45));
    expect(store.settings.fadeSeconds, 45);
  });

  test('clearAll erases everything', () async {
    await store.saveFavorites({'a'});
    await store.clearAll();
    expect(store.favorites, isEmpty);
  });
}
