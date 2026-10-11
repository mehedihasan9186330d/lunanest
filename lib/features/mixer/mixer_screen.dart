import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/playback_actions.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../domain/models.dart';
import '../../services/audio/audio_engine.dart';
import '../common/ui_helpers.dart';
import '../common/widgets.dart';
import '../timer/timer_sheet.dart';

class MixerScreen extends ConsumerWidget {
  const MixerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final actions = ref.watch(playbackActionsProvider);
    ref.watch(isPremiumProvider); // rebuild limits when entitlement changes
    final layers = engine.layers;
    final remaining = engine.timerRemaining;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mixer'),
        actions: [
          IconButton(
            tooltip: 'Sleep timer',
            icon: Icon(remaining == null ? Icons.bedtime_outlined : Icons.bedtime),
            onPressed: () => showTimerSheet(context),
          ),
        ],
      ),
      body: CatalogBuilder(builder: (context, catalog) {
        return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          Text('Layer up to ${actions.maxLayers} sounds. Each has its own volume.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (layers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(icon: Icons.tune, title: 'Your mix is empty', message: 'Add a sound, or start from a preset below.'),
            )
          else ...[
            for (final l in layers) _LayerCard(layer: l),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.volume_up),
              const SizedBox(width: 8),
              const Text('Master'),
              Expanded(
                child: Slider(
                  value: engine.masterVolume,
                  onChanged: engine.setMasterVolume,
                  semanticFormatterCallback: (v) => 'Master volume ${(v * 100).round()} percent',
                ),
              ),
            ]),
            if (remaining != null) Text('Sleep timer: ${formatDuration(remaining)} left', style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add sound'),
              onPressed: () => _pickSound(context, ref, catalog),
            ),
            if (layers.isNotEmpty) ...[
              OutlinedButton.icon(
                icon: Icon(engine.isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(engine.isPlaying ? 'Pause' : 'Play'),
                onPressed: () => engine.isPlaying ? engine.pause() : engine.play(),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save mix'),
                onPressed: () => _saveMix(context, ref, layers),
              ),
            ],
          ]),
          const SectionHeader('Presets'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in catalog.presets)
              ActionChip(
                avatar: Icon(catalog.mixNeedsPremium(m) && !ref.watch(isPremiumProvider) ? Icons.lock_outline : Icons.layers, size: 18),
                label: Text(m.name),
                onPressed: () async {
                  final r = await ref.read(playbackActionsProvider).playMix(m, catalog);
                  if (context.mounted) showGateMessage(context, r);
                },
              ),
          ]),
        ]);
      }),
    );
  }

  Future<void> _pickSound(BuildContext context, WidgetRef ref, Catalog catalog) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => Consumer(builder: (context, ref, _) {
          final engine = ref.watch(engineProvider);
          final available = catalog.sounds.where((s) => !engine.containsSound(s.id)).toList();
          return ListView(controller: controller, children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Add a sound', style: Theme.of(context).textTheme.titleLarge)),
            if (available.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Every sound is already in your mix.')),
            for (final s in available)
              SoundTile(
                sound: s,
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () async {
                  final r = await ref.read(playbackActionsProvider).addToMix(s);
                  if (!sheetContext.mounted) return;
                  if (r == GateResult.ok) {
                    Navigator.of(sheetContext).pop();
                  } else {
                    Navigator.of(sheetContext).pop();
                    if (context.mounted) showGateMessage(context, r);
                  }
                },
              ),
          ]);
        }),
      ),
    );
  }

  Future<void> _saveMix(BuildContext context, WidgetRef ref, List<ActiveLayer> layers) async {
    final actions = ref.read(playbackActionsProvider);
    final saved = ref.read(mixesProvider);
    if (saved.length >= actions.maxSavedMixes) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('You can save up to ${actions.maxSavedMixes} mixes on your plan.'),
          action: SnackBarAction(label: 'See Premium', onPressed: () => context.push('/premium')),
        ));
      return;
    }
    final name = await promptForText(context, title: 'Name your mix', initial: 'My mix ${saved.length + 1}', confirm: 'Save');
    if (name == null || name.trim().isEmpty) return;
    ref.read(mixesProvider.notifier).add(Mix(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name.trim(),
          layers: [for (final l in layers) MixLayer(l.sound.id, l.volume)],
        ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mix saved to Library.')));
    }
  }
}

class _LayerCard extends ConsumerWidget {
  const _LayerCard({required this.layer});
  final ActiveLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(engineProvider);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Row(children: [
          GradientIcon(categoryId: layer.sound.categoryId, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(layer.sound.title, style: theme.textTheme.titleSmall)),
          if (layer.status == LayerStatus.loading)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          if (layer.status == LayerStatus.error)
            TextButton(onPressed: () => engine.retryLayer(layer.sound.id), child: const Text('Retry')),
          IconButton(
            tooltip: 'Remove ${layer.sound.title}',
            icon: const Icon(Icons.close),
            onPressed: () => engine.removeLayer(layer.sound.id),
          ),
        ]),
        Slider(
          value: layer.volume,
          onChanged: (v) => engine.setLayerVolume(layer.sound.id, v),
          semanticFormatterCallback: (v) => '${layer.sound.title} volume ${(v * 100).round()} percent',
        ),
      ]),
    );
  }
}

Future<String?> promptForText(BuildContext context, {required String title, String initial = '', String confirm = 'OK'}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, maxLength: 40, textCapitalization: TextCapitalization.sentences),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(confirm)),
      ],
    ),
  );
}
