import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/category_style.dart';
import '../../domain/models.dart';
import '../common/ui_helpers.dart';
import '../common/widgets.dart';
import '../timer/timer_sheet.dart';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Good night';
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting()),
        actions: [
          IconButton(
            tooltip: 'Sleep timer',
            icon: const Icon(Icons.bedtime_outlined),
            onPressed: () => showTimerSheet(context),
          ),
        ],
      ),
      body: CatalogBuilder(builder: (context, catalog) {
        final recents = ref.watch(recentsProvider).map(catalog.sound).whereType<Sound>().take(4).toList();
        final favs = ref.watch(favoritesProvider).map(catalog.sound).whereType<Sound>().take(4).toList();
        final premium = ref.watch(isPremiumProvider);
        return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          const SectionHeader('Tonight’s mixes'),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: catalog.presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final m = catalog.presets[i];
                final locked = catalog.mixNeedsPremium(m) && !premium;
                final firstCat = catalog.sound(m.layers.first.soundId)?.categoryId ?? '';
                final colors = CategoryStyle.of(firstCat).colors;
                return Semantics(
                  button: true,
                  label: '${m.name}, mix of ${m.layers.length} sounds${locked ? ', Premium' : ''}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => playMixAndOpen(context, ref, m, catalog),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.layers, color: Colors.white70, size: 20),
                          const Spacer(),
                          if (locked) const Icon(Icons.lock_outline, color: Colors.white70, size: 18),
                        ]),
                        const Spacer(),
                        Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('${m.layers.length} sounds', style: const TextStyle(color: Colors.white70)),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
          if (recents.isNotEmpty) ...[
            const SectionHeader('Recently played'),
            for (final s in recents) SoundTile(sound: s),
          ],
          const SectionHeader('Categories'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              for (final c in catalog.categories)
                _CategoryCard(category: c, count: catalog.inCategory(c.id).length),
            ],
          ),
          if (favs.isNotEmpty) ...[
            const SectionHeader('Your favorites'),
            for (final s in favs) SoundTile(sound: s),
          ],
        ]);
      }),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.count});
  final SoundCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category.id);
    return Semantics(
      button: true,
      label: '${category.title}, $count sounds',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('/explore/category/${category.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: style.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Row(children: [
            Icon(style.icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(category.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('$count sounds', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
