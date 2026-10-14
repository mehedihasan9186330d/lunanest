import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../services/audio/notification_permission.dart';
import 'feature_gates.dart';
import 'providers.dart';

enum GateResult { ok, needsPremium, layerLimit }

/// All user-initiated playback goes through here so free/premium limits are
/// enforced in one place (UI never decides entitlement on its own).
class PlaybackActions {
  PlaybackActions(this._ref);
  final Ref _ref;

  bool get _premium => _ref.read(isPremiumProvider);
  FeatureGates get _gates => _ref.read(featureGatesProvider);
  int get maxLayers => _gates.maxLayers(_premium);
  int get maxSavedMixes => _gates.maxSavedMixes(_premium);
  int get maxDownloads => _gates.maxDownloads(_premium);

  Future<GateResult> playSound(Sound s) async {
    if (_gates.soundLocked(s, _premium)) return GateResult.needsPremium;
    final engine = _ref.read(engineProvider);
    await engine.playSingle(s);
    unawaited(NotificationPermission.ensureRequested(_ref.read(storeProvider)));
    _ref.read(recentsProvider.notifier).add(s.id);
    return GateResult.ok;
  }

  Future<GateResult> addToMix(Sound s) async {
    if (_gates.soundLocked(s, _premium)) return GateResult.needsPremium;
    final engine = _ref.read(engineProvider);
    final ok = await engine.addLayer(s, volume: engine.volumeFor(s.id), maxLayers: maxLayers);
    if (!ok) return GateResult.layerLimit;
    if (!engine.isPlaying) await engine.play();
    unawaited(NotificationPermission.ensureRequested(_ref.read(storeProvider)));
    _ref.read(recentsProvider.notifier).add(s.id);
    return GateResult.ok;
  }

  Future<GateResult> playMix(Mix m, Catalog catalog) async {
    if (_gates.mixLocked(m, catalog, _premium)) return GateResult.needsPremium;
    final items = <MapEntry<Sound, double>>[];
    for (final l in m.layers) {
      final s = catalog.sound(l.soundId);
      if (s != null) items.add(MapEntry(s, l.volume));
    }
    if (items.isEmpty) return GateResult.ok;
    if (items.length > maxLayers) return GateResult.layerLimit;
    await _ref.read(engineProvider).loadMix(items);
    unawaited(NotificationPermission.ensureRequested(_ref.read(storeProvider)));
    return GateResult.ok;
  }
}

final playbackActionsProvider = Provider<PlaybackActions>((ref) => PlaybackActions(ref));
