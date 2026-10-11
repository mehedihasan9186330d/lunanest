import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../data/local_store.dart';
import '../domain/models.dart';
import '../services/audio/audio_engine.dart';
import '../services/audio/audio_handler.dart';
import '../services/billing/billing_service.dart';
import '../services/downloads/download_manager.dart';

// Provided via overrides in main().
final storeProvider = Provider<LocalStore>((ref) => throw UnimplementedError('storeProvider'));
final audioHandlerProvider = Provider<LunaAudioHandler>((ref) => throw UnimplementedError('audioHandlerProvider'));
final downloadsProvider =
    ChangeNotifierProvider<DownloadManager>((ref) => throw UnimplementedError('downloadsProvider'));
final billingProvider = ChangeNotifierProvider<BillingService>((ref) => throw UnimplementedError('billingProvider'));

final engineProvider = ChangeNotifierProvider<AudioEngine>((ref) => ref.watch(audioHandlerProvider).engine);

final catalogProvider = FutureProvider<Catalog>((ref) => CatalogRepository.load());

final isPremiumProvider = Provider<bool>((ref) => ref.watch(billingProvider).isPremium);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._store) : super(_store.settings);
  final LocalStore _store;
  void update(AppSettings s) {
    state = s;
    _store.saveSettings(s);
  }

  void setTheme(ThemeMode m) => update(state.copyWith(themeMode: m));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier(ref.watch(storeProvider)));

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._store) : super(_store.favorites);
  final LocalStore _store;
  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    _store.saveFavorites(next);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) => FavoritesNotifier(ref.watch(storeProvider)));

class RecentsNotifier extends StateNotifier<List<String>> {
  RecentsNotifier(this._store) : super(_store.recents);
  final LocalStore _store;
  void add(String id) {
    final next = [id, ...state.where((e) => e != id)].take(12).toList();
    state = next;
    _store.saveRecents(next);
  }
}

final recentsProvider =
    StateNotifierProvider<RecentsNotifier, List<String>>((ref) => RecentsNotifier(ref.watch(storeProvider)));

class MixesNotifier extends StateNotifier<List<Mix>> {
  MixesNotifier(this._store) : super(_store.mixes);
  final LocalStore _store;

  void _save(List<Mix> next) {
    state = next;
    _store.saveMixes(next);
  }

  void add(Mix m) => _save([...state, m]);
  void rename(String id, String name) => _save([for (final m in state) m.id == id ? m.copyWith(name: name) : m]);
  void remove(String id) => _save(state.where((m) => m.id != id).toList());
}

final mixesProvider =
    StateNotifierProvider<MixesNotifier, List<Mix>>((ref) => MixesNotifier(ref.watch(storeProvider)));
