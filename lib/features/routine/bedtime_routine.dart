import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/playback_actions.dart';
import '../../domain/models.dart';
import '../../ui/glass_card.dart';
import '../common/ui_helpers.dart';

/// Finds the routine's mix among built-in presets and the user's saved mixes.
Mix? _findMix(String id, Catalog catalog, List<Mix> saved) {
  for (final m in catalog.presets) {
    if (m.id == id) return m;
  }
  for (final m in saved) {
    if (m.id == id) return m;
  }
  return null;
}

/// Starts the routine's mix and its sleep timer together.
Future<void> startRoutine(BuildContext context, WidgetRef ref, BedtimeRoutine r, Catalog catalog) async {
  final mix = _findMix(r.mixId, catalog, ref.read(mixesProvider));
  if (mix == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The mix in your routine no longer exists. Please choose another.')));
    return;
  }
  final result = await ref.read(playbackActionsProvider).playMix(mix, catalog);
  if (!context.mounted) return;
  if (result != GateResult.ok) {
    showGateMessage(context, result);
    return;
  }
  final engine = ref.read(engineProvider);
  if (engine.hasLayers) {
    engine.startTimer(Duration(minutes: r.minutes), Duration(seconds: ref.read(settingsProvider).fadeSeconds));
  }
  context.push('/player');
}

Future<void> showRoutineSheet(BuildContext context, Catalog catalog) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoutineSheet(catalog: catalog),
    );

/// Home card: one-tap bedtime routine (a mix + a sleep timer).
class BedtimeCard extends ConsumerWidget {
  const BedtimeCard({super.key, required this.catalog});
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(routineProvider);
    final saved = ref.watch(mixesProvider);
    final theme = Theme.of(context);
    final mix = routine == null ? null : _findMix(routine.mixId, catalog, saved);

    if (routine == null || mix == null) {
      return GlassCard(
        onTap: () => showRoutineSheet(context, catalog),
        child: Row(children: [
          Icon(Icons.nights_stay_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(routine == null ? 'Set up a bedtime routine' : 'Choose a mix for your routine', style: theme.textTheme.titleMedium),
              Text('Start a mix and a sleep timer together, in one tap.', style: theme.textTheme.bodySmall),
            ]),
          ),
          const Icon(Icons.chevron_right),
        ]),
      );
    }
    return GlassCard(
      child: Row(children: [
        Icon(Icons.nights_stay, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bedtime routine', style: theme.textTheme.bodySmall),
            Text(mix.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${routine.minutes} min sleep timer', style: theme.textTheme.bodySmall),
          ]),
        ),
        IconButton(tooltip: 'Edit bedtime routine', icon: const Icon(Icons.edit_outlined), onPressed: () => showRoutineSheet(context, catalog)),
        FilledButton(onPressed: () => startRoutine(context, ref, routine, catalog), child: const Text('Start')),
      ]),
    );
  }
}

class _RoutineSheet extends ConsumerStatefulWidget {
  const _RoutineSheet({required this.catalog});
  final Catalog catalog;
  @override
  ConsumerState<_RoutineSheet> createState() => _RoutineSheetState();
}

class _RoutineSheetState extends ConsumerState<_RoutineSheet> {
  static const presets = [15, 30, 45, 60, 90];
  String? _mixId;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final r = ref.read(routineProvider);
    _mixId = r?.mixId;
    _minutes = r?.minutes ?? ref.read(settingsProvider).defaultTimerMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(mixesProvider);
    final premium = ref.watch(isPremiumProvider);
    final gates = ref.watch(featureGatesProvider);
    final theme = Theme.of(context);
    final options = <Mix>[...widget.catalog.presets, ...saved];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), shrinkWrap: true, children: [
          Text('Bedtime routine', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Pick a mix and a timer. One tap on Home starts both.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text('Mix', style: theme.textTheme.titleSmall),
          for (final m in options)
            Builder(builder: (context) {
              final locked = gates.mixLocked(m, widget.catalog, premium);
              final selected = m.id == _mixId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? theme.colorScheme.primary : null),
                title: Text(m.name),
                subtitle: Text(m.isPreset ? 'Preset' : 'Saved mix'),
                trailing: locked ? const Icon(Icons.lock_outline) : null,
                enabled: !locked,
                selected: selected,
                onTap: () => setState(() => _mixId = m.id),
              );
            }),
          const SizedBox(height: 12),
          Text('Sleep timer', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in presets)
              ChoiceChip(label: Text('$m min'), selected: _minutes == m, onSelected: (_) => setState(() => _minutes = m)),
          ]),
          Slider(
            min: 1,
            max: 240,
            divisions: 239,
            value: _minutes.clamp(1, 240).toDouble(),
            label: '$_minutes min',
            semanticFormatterCallback: (v) => '${v.round()} minutes',
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          Center(child: Text('$_minutes minutes', style: theme.textTheme.bodySmall)),
          const SizedBox(height: 12),
          Row(children: [
            if (ref.read(routineProvider) != null)
              TextButton(
                onPressed: () {
                  ref.read(routineProvider.notifier).set(null);
                  Navigator.pop(context);
                },
                child: const Text('Remove routine'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _mixId == null
                  ? null
                  : () {
                      ref.read(routineProvider.notifier).set(BedtimeRoutine(mixId: _mixId!, minutes: _minutes));
                      Navigator.pop(context);
                    },
              child: const Text('Save routine'),
            ),
          ]),
        ]),
      ),
    );
  }
}
