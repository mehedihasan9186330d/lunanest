import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

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

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final title = engine.nowPlayingTitle;
    if (title == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final remaining = engine.timerRemaining;
    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: () => context.push('/player'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.primary.withAlpha(50)))),
          child: Row(children: [
            Icon(engine.hasError ? Icons.error_outline : Icons.graphic_eq, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  engine.isLoading
                      ? 'Loading…'
                      : remaining != null
                          ? 'Sleep timer · ${remaining.inMinutes + 1} min left'
                          : (engine.isPlaying ? 'Playing' : 'Paused'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
            IconButton(
              iconSize: 32,
              tooltip: engine.isPlaying ? 'Pause' : 'Play',
              icon: Icon(engine.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
              onPressed: () => engine.isPlaying ? engine.pause() : engine.play(),
            ),
            IconButton(tooltip: 'Stop', icon: const Icon(Icons.stop), onPressed: engine.stop),
          ]),
        ),
      ),
    );
  }
}
