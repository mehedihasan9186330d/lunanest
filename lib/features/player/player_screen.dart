import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/category_style.dart';
import '../../core/format.dart';
import '../../services/audio/audio_engine.dart';
import '../common/ui_helpers.dart';
import '../timer/timer_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(engineProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final theme = Theme.of(context);

    if (engine.isPlaying && !reduceMotion) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      _breath.stop();
    }

    final layers = engine.layers;
    final first = layers.isEmpty ? null : layers.first;
    final style = CategoryStyle.of(first?.sound.categoryId ?? '');
    final remaining = engine.timerRemaining;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Close player', icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => context.pop()),
        title: const Text('Now playing'),
        actions: [
          if (layers.length == 1 && first != null)
            Consumer(builder: (context, ref, _) {
              final fav = ref.watch(favoritesProvider).contains(first.sound.id);
              return IconButton(
                tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
                icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(first.sound.id),
              );
            }),
        ],
      ),
      body: layers.isEmpty
          ? const EmptyState(icon: Icons.music_note, title: 'Nothing playing', message: 'Pick a sound from Home or Explore.')
          : SafeArea(
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _breath,
                    builder: (context, child) => Transform.scale(scale: 0.96 + 0.08 * _breath.value, child: child),
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: style.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: style.colors.first.withAlpha(90), blurRadius: 40)],
                      ),
                      child: Icon(layers.length > 1 ? Icons.layers : style.icon, size: 96, color: Colors.white.withAlpha(220)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(engine.nowPlayingTitle ?? '', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                if (engine.nowPlayingSubtitle != null)
                  Text(engine.nowPlayingSubtitle!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Center(child: _StatusLine(engine: engine)),
                const SizedBox(height: 16),
                for (final l in layers.where((l) => l.status == LayerStatus.error))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(l.error ?? 'Playback error'),
                      trailing: TextButton(onPressed: () => engine.retryLayer(l.sound.id), child: const Text('Retry')),
                    ),
                  ),
                Center(
                  child: IconButton.filled(
                    iconSize: 56,
                    tooltip: engine.isPlaying ? 'Pause' : 'Play',
                    icon: Icon(engine.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () => engine.isPlaying ? engine.pause() : engine.play(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  const Icon(Icons.volume_down),
                  Expanded(
                    child: Slider(
                      value: engine.masterVolume,
                      onChanged: engine.setMasterVolume,
                      semanticFormatterCallback: (v) => 'Master volume ${(v * 100).round()} percent',
                    ),
                  ),
                  const Icon(Icons.volume_up),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bedtime_outlined),
                      label: Text(remaining == null ? 'Sleep timer' : formatDuration(remaining)),
                      onPressed: () => showTimerSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.tune),
                      label: const Text('Mixer'),
                      onPressed: () {
                        context.pop();
                        context.go('/mixer');
                      },
                    ),
                  ),
                ]),
              ]),
            ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.engine});
  final AudioEngine engine;
  @override
  Widget build(BuildContext context) {
    String text;
    if (engine.hasError) {
      text = 'Problem playing a sound';
    } else if (engine.isLoading) {
      text = 'Loading…';
    } else {
      text = engine.isPlaying ? 'Playing' : 'Paused';
    }
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}
