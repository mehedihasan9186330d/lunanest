import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'providers.dart';

enum GateResult { ok, needsPremium, layerLimit }

/// All user-initiated playback goes through here so free/premium limits are
/// enforced in one place (UI never decides entitlement on its own).
class PlaybackActions {
  PlaybackActions(this._ref);
  final Ref _ref;

  bool get _premium => _ref.read(isPremiumProvider);
  int get maxLayers => _premium ? 6 : 3;
  int get maxSavedMixes => _premium ? 50 : 3;
  int get maxDownloads => _premium ? 1000 : 3;

  Future<GateResult> playSound(Sound s) async {
    if (s.premium && !_premium) return GateResult.needsPremium;
    final engine = _ref.read(engineProvider);
    await engine.playSingle(s);
    _ref.read(recentsProvider.notifier).add(s.id);
    return GateResult.ok;
  }

  Future<GateResult> addToMix(Sound s) async {
    if (s.premium && !_premium) return GateResult.needsPremium;
    final engine = _ref.read(engineProvider);
    final ok = await engine.addLayer(s, maxLayers: maxLayers);
    if (!ok) return GateResult.layerLimit;
    if (!engine.isPlaying) await engine.play();
    _ref.read(recentsProvider.notifier).add(s.id);
    return GateResult.ok;
  }

  Future<GateResult> playMix(Mix m, Catalog catalog) async {
    if (catalog.mixNeedsPremium(m) && !_premium) return GateResult.needsPremium;
    final items = <MapEntry<Sound, double>>[];
    for (final l in m.layers) {
      final s = catalog.sound(l.soundId);
      if (s != null) items.add(MapEntry(s, l.volume));
    }
    if (items.isEmpty) return GateResult.ok;
    if (items.length > maxLayers) return GateResult.layerLimit;
    await _ref.read(engineProvider).loadMix(items);
    return GateResult.ok;
  }
}

final playbackActionsProvider = Provider<PlaybackActions>((ref) => PlaybackActions(ref));
