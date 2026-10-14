import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/category_style.dart';
import '../../ui/scene_view.dart';
import '../home/home_screen.dart' show sceneLayersFromEngine;

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: 'Mixer'),
            NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ]),
    );
  }
}

/// Floating mini-player with a live scene thumbnail and a sleep-timer progress bar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final title = engine.nowPlayingTitle;
    if (title == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remaining = engine.timerRemaining;
    final total = engine.timerTotal;
    final progress = (remaining != null && total > Duration.zero)
        ? (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0).toDouble()
        : null;
    final style = CategoryStyle.of(engine.layers.first.sound.categoryId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Semantics(
        container: true,
        label: 'Mini player, $title, ${engine.isPlaying ? 'playing' : 'paused'}. Double tap to open the player.',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: scheme.surface.withAlpha(238),
            child: InkWell(
              onTap: () => context.push('/player'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: scheme.primary.withAlpha(60)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(fit: StackFit.expand, children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: style.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                            ),
                            SceneView(layers: sceneLayersFromEngine(engine.layers), animate: engine.isPlaying),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                          Text(
                            engine.hasError
                                ? 'Problem playing a sound'
                                : engine.isLoading
                                    ? 'Loading…'
                                    : remaining != null
                                        ? 'Fading out in ${remaining.inMinutes + 1} min'
                                        : (engine.isPlaying ? 'Playing' : 'Paused'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ]),
                      ),
                      IconButton(
                        iconSize: 34,
                        tooltip: engine.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(engine.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: scheme.primary),
                        onPressed: () => engine.isPlaying ? engine.pause() : engine.play(),
                      ),
                      IconButton(tooltip: 'Stop', icon: const Icon(Icons.stop_rounded), onPressed: engine.stop),
                    ]),
                  ),
                  if (progress != null)
                    LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: scheme.primary.withAlpha(30)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
