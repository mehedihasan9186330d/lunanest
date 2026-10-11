import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/audio_math.dart';
import '../../domain/models.dart';

typedef LocalPathLookup = String? Function(String soundId);

enum LayerStatus { loading, ready, error }

class ActiveLayer {
  ActiveLayer(this.sound, this.volume, this.player);
  final Sound sound;
  double volume;
  final AudioPlayer player;
  LayerStatus status = LayerStatus.loading;
  String? error;
  double applied = 0; // gain currently sent to the player (smoothed)
  StreamSubscription<PlaybackEvent>? sub;
}

/// Multi-layer audio engine: one looping [AudioPlayer] per layer with independent,
/// smoothed gain. Used for single sounds (1 layer) and mixes (N layers).
///
/// Mixing is done by the OS audio stack (each player renders to the shared output),
/// so the engine does gain staging (headroom) rather than sample-level mixing.
/// Sample-accurate sync between layers is NOT guaranteed; for ambient loops this is
/// inaudible, but verify on devices (see docs/TESTING.md).
class AudioEngine extends ChangeNotifier {
  AudioEngine({required this.localPathFor});

  final LocalPathLookup localPathFor;

  static const hardLayerLimit = 6;

  final Map<String, ActiveLayer> _layers = {};
  AudioSession? _session;
  final List<StreamSubscription<dynamic>> _subs = [];

  double _master = 0.8;
  bool _playing = false;
  double _fade = 1.0; // pause/resume fade
  double _timerFactor = 1.0; // sleep-timer fade
  double _duck = 1.0; // other app asked us to lower volume
  bool _resumeAfterInterruption = false;
  String? lastError;
  bool _disposed = false;

  Timer? _smoothTimer;
  Timer? _pauseTimer;
  Timer? _timerTicker;
  DateTime? _timerEnd;
  Duration _timerTotal = Duration.zero;
  Duration _timerFade = Duration.zero;
  int _lastNotifiedSecs = -1;

  // ---- public state ----
  List<ActiveLayer> get layers => _layers.values.toList(growable: false);
  bool get hasLayers => _layers.isNotEmpty;
  bool get isPlaying => _playing;
  double get masterVolume => _master;
  bool get isLoading => _layers.values.any((l) => l.status == LayerStatus.loading);
  bool get hasError => _layers.values.any((l) => l.status == LayerStatus.error);
  bool containsSound(String id) => _layers.containsKey(id);

  String? get nowPlayingTitle {
    if (_layers.isEmpty) return null;
    if (_layers.length == 1) return _layers.values.first.sound.title;
    return 'Mix · ${_layers.length} sounds';
  }

  String? get nowPlayingSubtitle {
    if (_layers.length <= 1) return null;
    return _layers.values.map((l) => l.sound.title).join(', ');
  }

  bool get timerActive => _timerEnd != null;
  Duration get timerTotal => _timerTotal;
  Duration? get timerRemaining {
    final end = _timerEnd;
    if (end == null) return null;
    final r = end.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  // ---- lifecycle ----
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    _session = session;
    _subs.add(session.interruptionEventStream.listen(_onInterruption));
    _subs.add(session.becomingNoisyEventStream.listen((_) => pause(immediate: true)));
  }

  void _onInterruption(AudioInterruptionEvent e) {
    if (e.begin) {
      switch (e.type) {
        case AudioInterruptionType.duck:
          _duck = 0.3;
          _kick();
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_playing) {
            _resumeAfterInterruption = true;
            pause(immediate: true);
          }
      }
    } else {
      switch (e.type) {
        case AudioInterruptionType.duck:
          _duck = 1.0;
          _kick();
        case AudioInterruptionType.pause:
          if (_resumeAfterInterruption) {
            _resumeAfterInterruption = false;
            play();
          }
        case AudioInterruptionType.unknown:
          _resumeAfterInterruption = false;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _smoothTimer?.cancel();
    _pauseTimer?.cancel();
    _timerTicker?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    for (final l in _layers.values) {
      l.sub?.cancel();
      l.player.dispose();
    }
    _layers.clear();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---- transport ----
  Future<void> play() async {
    if (_layers.isEmpty) return;
    final ok = await _session?.setActive(true) ?? true;
    if (!ok) {
      lastError = 'Another app is using the audio output.';
      _notify();
      return;
    }
    lastError = null;
    _pauseTimer?.cancel();
    _playing = true;
    _fade = 1.0;
    for (final l in _layers.values) {
      if (l.status == LayerStatus.ready) _startLayer(l);
    }
    _kick();
    _notify();
  }

  void _startLayer(ActiveLayer l) {
    l.applied = 0;
    unawaited(l.player.setVolume(0));
    unawaited(l.player.play().catchError((Object e) => _layerFailed(l, e)));
  }

  Future<void> pause({bool immediate = false}) async {
    if (!_playing) return;
    _playing = false;
    _fade = 0.0;
    _pauseTimer?.cancel();
    if (immediate) {
      _haltPlayers();
    } else {
      _kick();
      _pauseTimer = Timer(const Duration(milliseconds: 450), () {
        if (!_playing) _haltPlayers();
      });
    }
    _notify();
  }

  void _haltPlayers() {
    for (final l in _layers.values) {
      l.applied = 0;
      unawaited(l.player.setVolume(0));
      unawaited(l.player.pause());
    }
  }

  /// Releases every player and the audio session (ends the foreground service).
  Future<void> stop() async {
    cancelTimer();
    _playing = false;
    _pauseTimer?.cancel();
    _smoothTimer?.cancel();
    _smoothTimer = null;
    await _clearLayers();
    _fade = 1.0;
    _resumeAfterInterruption = false;
    try {
      await _session?.setActive(false);
    } catch (_) {}
    _notify();
  }

  Future<void> _clearLayers() async {
    final old = _layers.values.toList();
    _layers.clear();
    for (final l in old) {
      await _disposeLayer(l);
    }
  }

  Future<void> _disposeLayer(ActiveLayer l) async {
    await l.sub?.cancel();
    try {
      await l.player.dispose();
    } catch (_) {}
  }

  // ---- layers ----
  Future<void> playSingle(Sound s) async {
    if (_layers.length == 1 && _layers.containsKey(s.id)) {
      if (!_playing) await play();
      return;
    }
    await _clearLayers();
    final loading = addLayer(s, volume: 0.8, maxLayers: hardLayerLimit);
    await play();
    await loading;
  }

  Future<void> loadMix(List<MapEntry<Sound, double>> items) async {
    await _clearLayers();
    final futures = [for (final e in items) addLayer(e.key, volume: e.value, maxLayers: hardLayerLimit)];
    await play();
    await Future.wait(futures);
  }

  /// Returns false when the layer limit is reached.
  Future<bool> addLayer(Sound sound, {double volume = 0.7, int maxLayers = 3}) async {
    if (_layers.containsKey(sound.id)) return true;
    if (_layers.length >= maxLayers.clamp(1, hardLayerLimit)) return false;
    final player = AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
    final layer = ActiveLayer(sound, volume.clamp(0.0, 1.0).toDouble(), player);
    _layers[sound.id] = layer;
    layer.sub = player.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) => _layerFailed(layer, e));
    _notify();
    try {
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0);
      await _loadSource(layer);
      if (_layers[sound.id] != layer) {
        await _disposeLayer(layer); // removed while loading
        return true;
      }
      layer.status = LayerStatus.ready;
      if (_playing) _startLayer(layer);
      _kick();
    } catch (e) {
      if (_layers[sound.id] == layer) _layerFailed(layer, e);
    }
    _notify();
    return true;
  }

  Future<void> _loadSource(ActiveLayer l) async {
    final s = l.sound;
    final local = localPathFor(s.id);
    if (local != null && File(local).existsSync()) {
      await l.player.setFilePath(local);
      return;
    }
    if (s.assetPath != null) {
      await l.player.setAsset(s.assetPath!);
      return;
    }
    final url = s.url;
    if (url != null) {
      Object? err;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await l.player.setUrl(url);
          return;
        } catch (e) {
          err = e;
          await Future<void>.delayed(Duration(seconds: 1 << attempt));
        }
      }
      throw err ?? StateError('Unable to load audio');
    }
    throw StateError('No audio source for ${s.id}');
  }

  void _layerFailed(ActiveLayer l, Object e) {
    l.status = LayerStatus.error;
    l.error = 'Could not play "${l.sound.title}". Check your connection and try again.';
    if (kDebugMode) debugPrint('Layer ${l.sound.id} failed: $e');
    _notify();
  }

  Future<void> retryLayer(String id) async {
    final l = _layers[id];
    if (l == null || l.status != LayerStatus.error) return;
    l.status = LayerStatus.loading;
    l.error = null;
    _notify();
    try {
      await _loadSource(l);
      l.status = LayerStatus.ready;
      if (_playing) _startLayer(l);
      _kick();
    } catch (e) {
      _layerFailed(l, e);
    }
    _notify();
  }

  Future<void> removeLayer(String id) async {
    final l = _layers.remove(id);
    if (l == null) return;
    await _disposeLayer(l);
    if (_layers.isEmpty) {
      await stop();
    } else {
      _kick();
      _notify();
    }
  }

  void setLayerVolume(String id, double v) {
    final l = _layers[id];
    if (l == null) return;
    l.volume = v.clamp(0.0, 1.0).toDouble();
    _kick();
    _notify();
  }

  void setMasterVolume(double v) {
    _master = v.clamp(0.0, 1.0).toDouble();
    _kick();
    _notify();
  }

  // ---- gain smoothing (prevents clicks and abrupt jumps) ----
  void _kick() {
    _smoothTimer ??= Timer.periodic(const Duration(milliseconds: 40), (_) => _smoothStep());
  }

  void _smoothStep() {
    final readyCount = _layers.values.where((l) => l.status == LayerStatus.ready).length;
    var moving = false;
    for (final l in _layers.values) {
      final target = l.status == LayerStatus.ready
          ? targetGain(
              layerVolume: l.volume,
              master: _master,
              layerCount: readyCount,
              fade: _fade,
              timer: _timerFactor,
              duck: _duck)
          : 0.0;
      final diff = target - l.applied;
      if (diff.abs() < 0.003) {
        if (l.applied != target) {
          l.applied = target;
          unawaited(l.player.setVolume(target));
        }
        continue;
      }
      l.applied += diff * 0.22;
      unawaited(l.player.setVolume(l.applied.clamp(0.0, 1.0).toDouble()));
      moving = true;
    }
    if (!moving) {
      _smoothTimer?.cancel();
      _smoothTimer = null;
    }
  }

  // ---- sleep timer ----
  void startTimer(Duration total, Duration fade) {
    if (_layers.isEmpty || total <= Duration.zero) return;
    cancelTimer();
    _timerTotal = total;
    _timerFade = fade > total ? total : fade;
    _timerEnd = DateTime.now().add(total);
    _timerTicker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _notify();
  }

  void cancelTimer() {
    _timerTicker?.cancel();
    _timerTicker = null;
    final wasActive = _timerEnd != null;
    _timerEnd = null;
    _timerFactor = 1.0;
    _lastNotifiedSecs = -1;
    if (wasActive) {
      _kick();
      _notify();
    }
  }

  void _tick() {
    final remaining = timerRemaining;
    if (remaining == null) return;
    if (remaining <= Duration.zero) {
      unawaited(stop()); // fade finished: release everything cleanly
      return;
    }
    final f = timerFadeFactor(remaining, _timerFade);
    final fading = f != _timerFactor;
    _timerFactor = f;
    if (fading) _kick();
    final secs = remaining.inSeconds;
    if (secs != _lastNotifiedSecs || fading) {
      _lastNotifiedSecs = secs;
      _notify();
    }
  }
}
