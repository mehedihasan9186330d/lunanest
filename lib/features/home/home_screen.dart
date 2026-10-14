import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/category_style.dart';
import '../../domain/models.dart';
import '../../services/audio/audio_engine.dart';
import '../../ui/glass_card.dart';
import '../../ui/reveal.dart';
import '../../ui/scene_kind.dart';
import '../../ui/scene_view.dart';
import '../common/ui_helpers.dart';
import '../common/widgets.dart';
import '../routine/bedtime_routine.dart';
import '../timer/timer_sheet.dart';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Good night';
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

List<SceneLayer> sceneLayersFromEngine(List<ActiveLayer> layers) => [
      for (final l in layers) SceneLayer(sceneForSound(l.sound), (0.35 + 0.65 * l.volume).clamp(0.0, 1.0).toDouble()),
    ];

List<SceneLayer> sceneLayersFromMix(Mix m, Catalog c) => [
      for (final l in m.layers)
        if (c.sound(l.soundId) != null)
          SceneLayer(sceneForSound(c.sound(l.soundId)!), (0.35 + 0.65 * l.volume).clamp(0.0, 1.0).toDouble()),
    ];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CatalogBuilder(builder: (context, catalog) {
          final recents = ref.watch(recentsProvider).map(catalog.sound).whereType<Sound>().take(4).toList();
          final favs = ref.watch(favoritesProvider).map(catalog.sound).whereType<Sound>().take(4).toList();
          final premium = ref.watch(isPremiumProvider);
          var i = 0;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            Reveal(
              index: i++,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_greeting(), style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('What will help you rest tonight?', style: theme.textTheme.bodyMedium),
                    ]),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Sleep timer',
                    icon: const Icon(Icons.bedtime_outlined),
                    onPressed: () => showTimerSheet(context),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Reveal(index: i++, child: _HeroCard(catalog: catalog)),
            const SizedBox(height: 12),
            Reveal(index: i++, child: BedtimeCard(catalog: catalog)),
            Reveal(index: i++, child: const SectionHeader('Tonight’s mixes')),
            Reveal(
              index: i++,
              child: SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: catalog.presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final m = catalog.presets[idx];
                    return _MixCard(mix: m, catalog: catalog, locked: ref.watch(featureGatesProvider).mixLocked(m, catalog, premium));
                  },
                ),
              ),
            ),
            Reveal(index: i++, child: const SectionHeader('Sounds for sleep')),
            Reveal(
              index: i++,
              child: SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: catalog.sounds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) => SoundCard(sound: catalog.sounds[idx]),
                ),
              ),
            ),
            if (recents.isNotEmpty) ...[
              const SectionHeader('Recently played'),
              for (final s in recents) SoundTile(sound: s),
            ],
            const SectionHeader('Browse by mood'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                for (final c in catalog.categories) _CategoryCard(category: c),
              ],
            ),
            if (favs.isNotEmpty) ...[
              const SectionHeader('Your favorites'),
              for (final s in favs) SoundTile(sound: s),
            ],
          ]);
        }),
      ),
    );
  }
}

/// Top card: "Now playing" when audio is active, otherwise tonight's featured mix.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.catalog});
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final premium = ref.watch(isPremiumProvider);
    final playing = engine.hasLayers;

    final Mix? featured = (!playing && catalog.presets.isNotEmpty)
        ? catalog.presets.firstWhere(
            (m) => !ref.watch(featureGatesProvider).mixLocked(m, catalog, premium),
            orElse: () => catalog.presets.first,
          )
        : null;

    final List<SceneLayer> layers = playing
        ? sceneLayersFromEngine(engine.layers)
        : (featured != null ? sceneLayersFromMix(featured, catalog) : const <SceneLayer>[]);
    final firstCat = playing
        ? engine.layers.first.sound.categoryId
        : (featured != null ? (catalog.sound(featured.layers.first.soundId)?.categoryId ?? '') : '');
    final colors = CategoryStyle.of(firstCat).colors;
    final title = playing ? (engine.nowPlayingTitle ?? '') : (featured?.name ?? 'LunaNest');
    final eyebrow = playing ? (engine.isPlaying ? 'NOW PLAYING' : 'PAUSED') : 'TONIGHT’S PICK';

    return Semantics(
      button: true,
      label: '$eyebrow, $title',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 210,
          child: Stack(fit: StackFit.expand, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
            SceneView(layers: layers, animate: !playing || engine.isPlaying),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC070B24)],
                  stops: [0.25, 1],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    if (playing) {
                      context.push('/player');
                    } else if (featured != null) {
                      playMixAndOpen(context, ref, featured, catalog);
                    }
                  },
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: IgnorePointer(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(eyebrow, style: const TextStyle(color: Color(0xFFD9D2FF), fontSize: 12, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300, height: 1.1)),
                  const SizedBox(height: 4),
                  Text(playing ? 'Tap to open the player' : 'Tap to start',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MixCard extends ConsumerWidget {
  const _MixCard({required this.mix, required this.catalog, required this.locked});
  final Mix mix;
  final Catalog catalog;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstCat = catalog.sound(mix.layers.first.soundId)?.categoryId ?? '';
    final colors = CategoryStyle.of(firstCat).colors;
    return Semantics(
      button: true,
      label: '${mix.name}, layered mix${locked ? ', Premium' : ''}',
      excludeSemantics: true,
      onTap: () => playMixAndOpen(context, ref, mix, catalog),
      child: SizedBox(
        width: 210,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(fit: StackFit.expand, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
            SceneView(layers: sceneLayersFromMix(mix, catalog), animate: false, seedTime: 4.0),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB0070B24)],
                  stops: [0.3, 1],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: () => playMixAndOpen(context, ref, mix, catalog)),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: IgnorePointer(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(mix.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                  const Text('Layered mix', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ),
            if (locked)
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(Icons.lock_outline, color: Colors.white70, size: 18),
              ),
          ]),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final SoundCategory category;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.id);
    return Semantics(
      button: true,
      label: category.title,
      excludeSemantics: true,
      onTap: () => context.go('/explore/category/${category.id}'),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () => context.go('/explore/category/${category.id}'),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: style.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Icon(style.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
            ]),
          ),
        ]),
      ),
    );
  }
}
