import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/category_style.dart';
import '../../core/format.dart';
import '../../services/audio/audio_engine.dart';
import '../../ui/glass_card.dart';
import '../../ui/night_sky.dart';
import '../../ui/scene_view.dart';
import '../../ui/timer_ring.dart';
import '../common/ui_helpers.dart';
import '../home/home_screen.dart' show sceneLayersFromEngine;
import '../timer/timer_sheet.dart';

/// Now Playing: a full-screen animated scene that matches the sound (or, for a mix,
/// all of its layers blended by volume), with controls in a glass panel.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The player is always dark and opaque (own sky), regardless of app theme.
    return NightSky(
      animate: false,
      forceDark: true,
      child: Theme(data: buildDarkTheme(), child: const _PlayerBody()),
    );
  }
}

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final theme = Theme.of(context);
    final layers = engine.layers;
    final remaining = engine.timerRemaining;
    final total = engine.timerTotal;

    return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(tooltip: 'Close player', icon: const Icon(Icons.keyboard_arrow_down, size: 30), onPressed: () => context.pop()),
            title: const Text('Now playing'),
            actions: [
              if (layers.length == 1)
                Consumer(builder: (context, ref, _) {
                  final id = layers.first.sound.id;
                  final fav = ref.watch(favoritesProvider).contains(id);
                  return IconButton(
                    tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggle(id),
                  );
                }),
            ],
          ),
          body: layers.isEmpty
              ? const EmptyState(icon: Icons.music_note, title: 'Nothing playing', message: 'Pick a sound from Home or Explore.')
              : Stack(fit: StackFit.expand, children: [
                  Positioned.fill(child: SceneView(layers: sceneLayersFromEngine(layers), animate: engine.isPlaying)),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00070B24), Color(0x00070B24), Color(0xE6070B24)],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, c) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: c.maxHeight - 16),
                          child: IntrinsicHeight(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              const Spacer(),
                              Text(engine.nowPlayingTitle ?? '',
                                  style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white), textAlign: TextAlign.center),
                              if (engine.nowPlayingSubtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(engine.nowPlayingSubtitle!,
                                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                                ),
                              const SizedBox(height: 6),
                              Center(child: _StatusLine(engine: engine)),
                              const SizedBox(height: 14),
                              for (final l in layers.where((l) => l.status == LayerStatus.error))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: GlassCard(
                                    child: Row(children: [
                                      const Icon(Icons.error_outline),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(l.error ?? 'Playback error')),
                                      TextButton(onPressed: () => engine.retryLayer(l.sound.id), child: const Text('Retry')),
                                    ]),
                                  ),
                                ),
                              GlassCard(
                                radius: 28,
                                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  if (layers.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: [
                                        for (final l in layers)
                                          Chip(
                                            avatar: Icon(CategoryStyle.of(l.sound.categoryId).icon,
                                                size: 16, color: CategoryStyle.of(l.sound.categoryId).accent),
                                            label: Text(l.sound.title),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                      ]),
                                    ),
                                  _PlayButton(engine: engine),
                                  const SizedBox(height: 14),
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
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Expanded(
                                      child: remaining == null
                                          ? OutlinedButton.icon(
                                              icon: const Icon(Icons.bedtime_outlined),
                                              label: const Text('Sleep timer'),
                                              onPressed: () => showTimerSheet(context),
                                            )
                                          : Semantics(
                                              button: true,
                                              label: 'Sleep timer, ${formatDuration(remaining)} remaining. Double tap to change.',
                                              excludeSemantics: true,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(60),
                                                onTap: () => showTimerSheet(context),
                                                child: Center(
                                                  child: TimerRing(
                                                    size: 92,
                                                    stroke: 6,
                                                    progress: total > Duration.zero ? remaining.inMilliseconds / total.inMilliseconds : 0,
                                                    child: Text(formatDuration(remaining), style: theme.textTheme.titleSmall),
                                                  ),
                                                ),
                                              ),
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
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.engine});
  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: engine.isPlaying ? 'Pause' : 'Play',
      excludeSemantics: true,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withAlpha(engine.isPlaying ? 110 : 50), blurRadius: 28, spreadRadius: 2)],
        ),
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => engine.isPlaying ? engine.pause() : engine.play(),
            child: Icon(engine.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 48, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.engine});
  final AudioEngine engine;
  @override
  Widget build(BuildContext context) {
    final String text;
    if (engine.hasError) {
      text = 'Problem playing a sound';
    } else if (engine.isLoading) {
      text = 'Loading…';
    } else {
      text = engine.isPlaying ? 'Playing' : 'Paused';
    }
    return Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70));
  }
}
