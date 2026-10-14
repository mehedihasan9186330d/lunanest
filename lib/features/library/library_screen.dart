import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/playback_actions.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../domain/models.dart';
import '../common/ui_helpers.dart';
import '../common/widgets.dart';
import '../mixer/mixer_screen.dart' show promptForText;

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: const TabBar(tabs: [Tab(text: 'Favorites'), Tab(text: 'My mixes'), Tab(text: 'Offline')]),
        ),
        body: const TabBarView(children: [_FavoritesTab(), _MixesTab(), _DownloadsTab()]),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CatalogBuilder(builder: (context, catalog) {
      final favs = ref.watch(favoritesProvider).map(catalog.sound).whereType<Sound>().toList();
      if (favs.isEmpty) {
        return const EmptyState(icon: Icons.favorite_border, title: 'No favorites yet', message: 'Tap the heart on any sound to keep it here.');
      }
      return ListView(children: [for (final s in favs) SoundTile(sound: s)]);
    });
  }
}

class _MixesTab extends ConsumerWidget {
  const _MixesTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixes = ref.watch(mixesProvider);
    final max = ref.watch(playbackActionsProvider).maxSavedMixes;
    return CatalogBuilder(builder: (context, catalog) {
      if (mixes.isEmpty) {
        return EmptyState(
          icon: Icons.layers_outlined,
          title: 'No saved mixes',
          message: 'Build a mix in the Mixer and save it here.',
          actionLabel: 'Open mixer',
          onAction: () => context.go('/mixer'),
        );
      }
      return ListView(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('${mixes.length} of $max saved', style: Theme.of(context).textTheme.bodySmall)),
        for (final m in mixes)
          ListTile(
            leading: const Icon(Icons.layers),
            title: Text(m.name),
            subtitle: Text(m.layers.map((l) => catalog.sound(l.soundId)?.title ?? 'Unavailable sound').join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => playMixAndOpen(context, ref, m, catalog),
            trailing: PopupMenuButton<String>(
              tooltip: 'Mix options',
              onSelected: (v) async {
                if (v == 'rename') {
                  final name = await promptForText(context, title: 'Rename mix', initial: m.name, confirm: 'Rename');
                  if (name != null && name.trim().isNotEmpty) ref.read(mixesProvider.notifier).rename(m.id, name.trim());
                } else {
                  ref.read(mixesProvider.notifier).remove(m.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
      ]);
    });
  }
}

class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dm = ref.watch(downloadsProvider);
    return CatalogBuilder(builder: (context, catalog) {
      final downloadable = catalog.sounds.where((s) => s.canDownload).toList();
      return ListView(children: [
        ListTile(
          leading: const Icon(Icons.sd_storage_outlined),
          title: Text('Offline storage: ${formatBytes(dm.totalBytes)}'),
          subtitle: Text('${dm.downloadedCount} downloaded'),
          trailing: dm.downloadedCount > 0
              ? TextButton(onPressed: dm.deleteAll, child: const Text('Delete all'))
              : null,
        ),
        const Divider(height: 1),
        if (downloadable.isEmpty)
          const SizedBox(
            height: 320,
            child: EmptyState(
              icon: Icons.cloud_off,
              title: 'No downloadable sounds in this build',
              message: 'The bundled sounds already play without internet. Streamed sounds with offline licenses will appear here.',
            ),
          ),
        for (final s in downloadable) _DownloadRow(sound: s),
      ]);
    });
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.sound});
  final Sound sound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dm = ref.watch(downloadsProvider);
    final p = dm.progress(sound.id);
    final done = dm.isDownloaded(sound.id);
    Widget trailing;
    if (p != null && !p.failed) {
      trailing = Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 28, height: 28, child: CircularProgressIndicator(value: p.fraction, strokeWidth: 3)),
        IconButton(tooltip: 'Cancel download', icon: const Icon(Icons.close), onPressed: () => dm.cancel(sound.id)),
      ]);
    } else if (p != null && p.failed) {
      trailing = TextButton(
        onPressed: () {
          dm.dismissError(sound.id);
          dm.download(sound);
        },
        child: const Text('Retry'),
      );
    } else if (done) {
      trailing = IconButton(tooltip: 'Delete download', icon: const Icon(Icons.delete_outline), onPressed: () => dm.delete(sound.id));
    } else {
      trailing = IconButton(
        tooltip: 'Download for offline',
        icon: const Icon(Icons.download),
        onPressed: () {
          final actions = ref.read(playbackActionsProvider);
          if (ref.read(featureGatesProvider).soundLocked(sound, ref.read(isPremiumProvider))) {
            showGateMessage(context, GateResult.needsPremium);
          } else if (dm.downloadedCount >= actions.maxDownloads) {
            showGateMessage(context, GateResult.layerLimit);
          } else {
            dm.download(sound);
          }
        },
      );
    }
    return ListTile(
      leading: GradientIcon(categoryId: sound.categoryId, size: 44),
      title: Text(sound.title),
      subtitle: Text(p?.failed == true ? (p!.error ?? 'Download failed') : (done ? 'Available offline' : 'Streams online')),
      trailing: trailing,
    );
  }
}
