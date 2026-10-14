import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/playback_actions.dart';
import '../../app/providers.dart';
import '../../domain/models.dart';

void showGateMessage(BuildContext context, GateResult r) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  switch (r) {
    case GateResult.ok:
      return;
    case GateResult.needsPremium:
      messenger.showSnackBar(SnackBar(
        content: const Text('This sound is part of LunaNest Premium.'),
        action: SnackBarAction(label: 'See Premium', onPressed: () => context.push('/premium')),
      ));
    case GateResult.layerLimit:
      messenger.showSnackBar(const SnackBar(content: Text('You have reached the maximum number of layers.')));
  }
}

Future<void> playAndOpen(BuildContext context, WidgetRef ref, Sound s, {bool openPlayer = true}) async {
  final r = await ref.read(playbackActionsProvider).playSound(s);
  if (!context.mounted) return;
  if (r != GateResult.ok) {
    showGateMessage(context, r);
    return;
  }
  if (openPlayer) context.push('/player');
}

Future<void> playMixAndOpen(BuildContext context, WidgetRef ref, Mix m, Catalog c) async {
  final r = await ref.read(playbackActionsProvider).playMix(m, c);
  if (!context.mounted) return;
  if (r != GateResult.ok) {
    showGateMessage(context, r);
    return;
  }
  context.push('/player');
}

/// Resolves the catalog and renders loading / error (with retry) states.
class CatalogBuilder extends ConsumerWidget {
  const CatalogBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, Catalog catalog) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(catalogProvider);
    return async.when(
      data: (c) => builder(context, c),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load sounds',
        message: 'Something went wrong reading the sound library.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(catalogProvider),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: t.colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: t.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: t.textTheme.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}
