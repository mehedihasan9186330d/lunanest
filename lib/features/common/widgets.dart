import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/category_style.dart';
import '../../domain/models.dart';
import 'ui_helpers.dart';

/// Rounded gradient tile with the category icon. Decorative artwork placeholder
/// until licensed nature photography/illustrations are added.
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

class SoundTile extends ConsumerWidget {
  const SoundTile({super.key, required this.sound, this.onTap, this.trailing});
  final Sound sound;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(isPremiumProvider);
    final locked = sound.premium && !premium;
    final isFav = ref.watch(favoritesProvider).contains(sound.id);
    final engine = ref.watch(engineProvider);
    final active = engine.containsSound(sound.id);
    final offline = ref.watch(downloadsProvider).isDownloaded(sound.id);
    final category = ref.watch(catalogProvider).valueOrNull?.category(sound.categoryId)?.title ?? '';
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${sound.title}${locked ? ', Premium' : ''}${active ? ', playing' : ''}',
      excludeSemantics: true,
      onTap: onTap ?? () => playAndOpen(context, ref, sound),
      child: ListTile(
        minVerticalPadding: 10,
        leading: GradientIcon(categoryId: sound.categoryId),
        title: Text(sound.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          category,
          if (sound.premium) 'Premium',
          if (offline) 'Offline',
        ].where((e) => e.isNotEmpty).join(' · ')),
        selected: active,
        selectedColor: theme.colorScheme.primary,
        onTap: onTap ?? () => playAndOpen(context, ref, sound),
        trailing: trailing ??
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (locked) const Icon(Icons.lock_outline, size: 20),
              IconButton(
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(sound.id),
              ),
            ]),
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
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (trailing != null) trailing!,
        ]),
      );
}
