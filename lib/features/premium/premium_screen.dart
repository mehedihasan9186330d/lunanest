import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show Package;
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../services/billing/billing_service.dart';
import '../common/ui_helpers.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});
  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _buy(Package p) async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingProvider).purchase(p);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.success:
        _toast('Welcome to Premium!');
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        _toast('Your purchase is pending. Premium unlocks when it completes.');
      case PurchaseOutcome.failed:
        _toast('The purchase could not be completed. You were not charged.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final found = await ref.read(billingProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(found ? 'Premium restored.' : 'No active subscription found for this store account.');
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(billingProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('LunaNest Premium'),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Icon(Icons.nightlight_round, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Sleep deeper with more sounds', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const _Benefit(Icons.library_music, 'Expanded premium sound library'),
          const _Benefit(Icons.layers, 'Up to 6 layers per mix and more presets'),
          const _Benefit(Icons.save_alt, 'Save up to 50 custom mixes'),
          const _Benefit(Icons.download_for_offline, 'Unlimited offline downloads'),
          const SizedBox(height: 8),
          Text('Free always includes core sounds, the sleep timer, favorites, and all accessibility and privacy controls.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          if (billing.isPremium)
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('You have Premium'),
                subtitle: const Text('Thank you for supporting LunaNest.'),
                trailing: TextButton(onPressed: _manage, child: const Text('Manage')),
              ),
            )
          else
            ..._offers(billing),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: _busy ? null : _restore, child: const Text('Restore purchases'))),
          const SizedBox(height: 8),
          Text(
            'Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. '
            'Payment is charged to your Google Play or Apple ID account at confirmation. Manage or cancel any time in your '
            'store account settings. Prices are shown by the store in your local currency.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () => context.go('/settings/terms'), child: const Text('Terms of Use')),
            TextButton(onPressed: () => context.go('/settings/privacy'), child: const Text('Privacy Policy')),
          ]),
        ]),
      ),
    );
  }

  List<Widget> _offers(BillingService billing) {
    switch (billing.status) {
      case BillingStatus.unconfigured:
        return const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Subscriptions are not configured in this build, so purchases are unavailable. '
                  'Everything in the free plan works normally.'),
            ),
          ),
        ];
      case BillingStatus.loading:
        return const [Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))];
      case BillingStatus.error:
      case BillingStatus.ready:
        if (!billing.hasProducts) {
          return [
            EmptyState(
              icon: Icons.cloud_off,
              title: 'Subscription options unavailable',
              message: billing.error ?? 'Please check your connection and try again.',
              actionLabel: 'Try again',
              onAction: billing.refreshOfferings,
            ),
          ];
        }
        return [
          if (billing.annual != null) _OfferCard(package: billing.annual!, label: 'Annual', highlight: true, busy: _busy, onBuy: _buy),
          if (billing.monthly != null) _OfferCard(package: billing.monthly!, label: 'Monthly', highlight: false, busy: _busy, onBuy: _buy),
        ];
    }
  }

  Future<void> _manage() async {
    final uri = Uri.parse(Theme.of(context).platform == TargetPlatform.iOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _toast('Open your store account to manage subscriptions.');
    }
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.package, required this.label, required this.highlight, required this.busy, required this.onBuy});
  final Package package;
  final String label;
  final bool highlight;
  final bool busy;
  final Future<void> Function(Package) onBuy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = package.storeProduct.priceString; // real, localized store price
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? scheme.primary : scheme.outlineVariant, width: highlight ? 2 : 1),
        color: scheme.surface,
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(label == 'Annual' ? '$price per year' : '$price per month'),
          ]),
        ),
        FilledButton(onPressed: busy ? null : () => onBuy(package), child: const Text('Subscribe')),
      ]),
    );
  }
}
