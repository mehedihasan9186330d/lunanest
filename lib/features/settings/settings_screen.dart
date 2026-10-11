import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final premium = ref.watch(isPremiumProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(
          leading: Icon(premium ? Icons.verified : Icons.workspace_premium_outlined),
          title: Text(premium ? 'LunaNest Premium' : 'Go Premium'),
          subtitle: Text(premium ? 'Active' : 'More sounds, mixes and offline downloads'),
          onTap: () => context.push('/premium'),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore purchases'),
          onTap: () async {
            final found = await ref.read(billingProvider).restore();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(found ? 'Premium restored.' : 'No active subscription found, or subscriptions are not available.')));
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('Appearance', style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setTheme(s.first),
          ),
        ),
        ListTile(
          title: Text('Sleep timer fade-out: ${settings.fadeSeconds} s'),
          subtitle: Slider(
            min: 3,
            max: 60,
            divisions: 57,
            value: settings.fadeSeconds.toDouble().clamp(3, 60).toDouble(),
            label: '${settings.fadeSeconds} s',
            onChanged: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(fadeSeconds: v.round())),
          ),
        ),
        const Divider(),
        ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy Policy'), onTap: () => context.go('/settings/privacy')),
        ListTile(leading: const Icon(Icons.description_outlined), title: const Text('Terms of Use'), onTap: () => context.go('/settings/terms')),
        ListTile(leading: const Icon(Icons.support_agent), title: const Text('Contact support'), onTap: () => context.go('/settings/support')),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'), onTap: () => context.go('/settings/about')),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
              'Privacy: LunaNest has no accounts, ads or analytics. Favorites, mixes and settings stay on this device. '
              'If subscriptions are enabled, purchase status is handled by Google Play / the App Store and RevenueCat.'),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
          title: const Text('Erase all local data'),
          subtitle: const Text('Favorites, mixes, settings and downloads'),
          onTap: () => _confirmErase(context, ref),
        ),
      ]),
    );
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all local data?'),
        content: const Text('This removes favorites, saved mixes, settings and downloaded audio from this device. It does not cancel a subscription.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Erase')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(engineProvider).stop();
    await ref.read(downloadsProvider).deleteAll();
    await ref.read(storeProvider).clearAll();
    ref.invalidate(settingsProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(recentsProvider);
    ref.invalidate(mixesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local data erased.')));
    }
  }
}
