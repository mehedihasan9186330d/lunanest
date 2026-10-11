import 'package:audio_service/audio_service.dart';
import 'audio_engine.dart';

/// Bridges [AudioEngine] to the OS: notification, lock-screen controls and
/// the Android foreground service (provided by audio_service).
class LunaAudioHandler extends BaseAudioHandler {
  LunaAudioHandler(this.engine) {
    engine.addListener(_sync);
    _sync();
  }

  final AudioEngine engine;
  bool? _lastPlaying;
  bool? _lastHasLayers;
  String? _lastTitle;

  void _sync() {
    final hasLayers = engine.hasLayers;
    final playing = engine.isPlaying;
    final title = engine.nowPlayingTitle;

    if (title != _lastTitle) {
      _lastTitle = title;
      mediaItem.add(title == null
          ? null
          : MediaItem(
              id: 'lunanest:${title.hashCode}',
              title: title,
              album: 'LunaNest',
              artist: engine.nowPlayingSubtitle ?? 'Sleep & Relax',
            ));
    }

    if (playing != _lastPlaying || hasLayers != _lastHasLayers) {
      _lastPlaying = playing;
      _lastHasLayers = hasLayers;
      playbackState.add(PlaybackState(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1],
        processingState: hasLayers ? AudioProcessingState.ready : AudioProcessingState.idle,
        playing: playing,
      ));
    }
  }

  @override
  Future<void> play() => engine.play();

  @override
  Future<void> pause() => engine.pause();

  @override
  Future<void> stop() async {
    await engine.stop();
    await super.stop();
  }
}
