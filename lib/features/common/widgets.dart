import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/category_style.dart';
import '../../domain/models.dart';
import '../../ui/glass_card.dart';
import '../../ui/rand.dart';
import '../../ui/scene_kind.dart';
import '../../ui/scene_view.dart';
import 'ui_helpers.dart';

/// Rounded gradient tile with the category icon (used in simple lists).
class GradientIcon extends StatelessWidget {
  const GradientIcon({super.key, required this.categoryId, this.size = 52});
  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = CategoryStyle.of(categoryId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(colors: s.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(s.icon, color: Colors.white.withAlpha(230), size: size * 0.5),
    );
  }
}

/// Static scene thumbnail for a sound (a frozen frame of its animated scene).
class SceneThumb extends StatelessWidget {
  const SceneThumb({super.key, required this.sound, this.size = 56});
  final Sound sound;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(sound.categoryId);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(fit: StackFit.expand, children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: style.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          SceneView(
            layers: [SceneLayer(sceneForSound(sound))],
            animate: false,
            seedTime: 2.0 + 4 * hash01(sound.id.hashCode & 0xffff, 1),
          ),
        ]),
      ),
    );
  }
}

/// Large artwork card for horizontal "sound" rows.
class SoundCard extends ConsumerWidget {
  const SoundCard({super.key, required this.sound, this.width = 148, this.height = 180});
  final Sound sound;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = CategoryStyle.of(sound.categoryId);
    final locked = ref.watch(featureGatesProvider).soundLocked(sound, ref.watch(isPremiumProvider));
    final fav = ref.watch(favoritesProvider).contains(sound.id);
    final active = ref.watch(engineProvider).containsSound(sound.id);
    return Semantics(
      button: true,
      label: '${sound.title}${locked ? ', Premium' : ''}${active ? ', playing' : ''}',
      excludeSemantics: true,
      onTap: () => playAndOpen(context, ref, sound),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(fit: StackFit.expand, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: style.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
            SceneView(
              layers: [SceneLayer(sceneForSound(sound))],
              animate: false,
              seedTime: 2.0 + 4 * hash01(sound.id.hashCode & 0xffff, 1),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x00000000), Color(0xB0070B24)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(sound.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2)),
                if (active)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('Playing', style: TextStyle(color: Color(0xFFD9D2FF), fontSize: 12)),
                  ),
              ]),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: () => playAndOpen(context, ref, sound)),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: locked
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                    )
                  : IconButton(
                      tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
                      icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: Colors.white70, size: 20),
                      onPressed: () => ref.read(favoritesProvider.notifier).toggle(sound.id),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class SoundTile extends ConsumerWidget {
  const SoundTile({super.key, required this.sound, this.onTap, this.trailing});
  final Sound sound;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(isPremiumProvider);
    final locked = ref.watch(featureGatesProvider).soundLocked(sound, premium);
    final isFav = ref.watch(favoritesProvider).contains(sound.id);
    final engine = ref.watch(engineProvider);
    final active = engine.containsSound(sound.id);
    final offline = ref.watch(downloadsProvider).isDownloaded(sound.id);
    final category = ref.watch(catalogProvider).valueOrNull?.category(sound.categoryId)?.title ?? '';
    final theme = Theme.of(context);
    void tap() {
      final custom = onTap;
      if (custom != null) {
        custom();
      } else {
        playAndOpen(context, ref, sound);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Semantics(
        button: true,
        label: '${sound.title}${locked ? ', Premium' : ''}${active ? ', playing' : ''}',
        excludeSemantics: true,
        onTap: tap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onTap: tap,
          child: Row(children: [
            SceneThumb(sound: sound, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sound.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(color: active ? theme.colorScheme.primary : null)),
                const SizedBox(height: 2),
                Text(
                  [category, if (locked) 'Premium', if (offline) 'Offline', if (active) 'Playing']
                      .where((e) => e.isNotEmpty)
                      .join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ]),
            ),
            trailing ??
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (locked) const Icon(Icons.lock_outline, size: 20),
                  IconButton(
                    tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggle(sound.id),
                  ),
                ]),
          ]),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (trailing != null) trailing!,
        ]),
      );
}
