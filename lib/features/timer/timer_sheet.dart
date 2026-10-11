import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';

Future<void> showTimerSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TimerSheet(),
    );

class _TimerSheet extends ConsumerStatefulWidget {
  const _TimerSheet();
  @override
  ConsumerState<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends ConsumerState<_TimerSheet> {
  static const presets = [5, 10, 15, 30, 45, 60, 90];
  late int _minutes;
  late double _fade;
  bool _custom = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _minutes = s.defaultTimerMinutes;
    _fade = s.fadeSeconds.toDouble();
    _custom = !presets.contains(_minutes);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(engineProvider);
    final remaining = engine.timerRemaining;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sleep timer', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          if (!engine.hasLayers)
            Text('Start a sound first, then set the timer.', style: theme.textTheme.bodyMedium)
          else if (remaining != null) ...[
            const SizedBox(height: 12),
            Center(child: Text(formatDuration(remaining), style: theme.textTheme.displaySmall, semanticsLabel: '${remaining.inMinutes} minutes remaining')),
            Center(child: Text('until sound fades out', style: theme.textTheme.bodySmall)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: engine.cancelTimer, child: const Text('Cancel timer')),
            ),
            const Divider(height: 32),
          ],
          Text('Duration', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in presets)
              ChoiceChip(
                label: Text('$m min'),
                selected: !_custom && _minutes == m,
                onSelected: (_) => setState(() {
                  _custom = false;
                  _minutes = m;
                }),
              ),
            ChoiceChip(
              label: Text(_custom ? 'Custom · $_minutes min' : 'Custom'),
              selected: _custom,
              onSelected: (_) => setState(() => _custom = true),
            ),
          ]),
          if (_custom) ...[
            Slider(
              min: 1,
              max: 240,
              divisions: 239,
              value: _minutes.clamp(1, 240).toDouble(),
              label: '$_minutes min',
              semanticFormatterCallback: (v) => '${v.round()} minutes',
              onChanged: (v) => setState(() => _minutes = v.round()),
            ),
          ],
          const SizedBox(height: 16),
          Text('Fade-out: ${_fade.round()} seconds', style: theme.textTheme.titleSmall),
          Slider(
            min: 3,
            max: 60,
            divisions: 57,
            value: _fade,
            label: '${_fade.round()} s',
            onChanged: (v) => setState(() => _fade = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: const Icon(Icons.bedtime),
              label: Text(remaining == null ? 'Start timer' : 'Restart timer'),
              onPressed: engine.hasLayers
                  ? () {
                      final settings = ref.read(settingsProvider);
                      ref.read(settingsProvider.notifier).update(
                          settings.copyWith(defaultTimerMinutes: _minutes, fadeSeconds: _fade.round()));
                      engine.startTimer(Duration(minutes: _minutes), Duration(seconds: _fade.round()));
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
          ),
        ]),
      ),
    );
  }
}
