import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show Package;
import 'package:url_launcher/url_launcher.dart';

import '../../app/feature_gates.dart';
import '../../app/providers.dart';
import '../../services/billing/billing_service.dart';
import '../../ui/glass_card.dart';
import '../../ui/moon.dart';
import '../common/ui_helpers.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});
  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;

  void _toast(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _buy(Package p) async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingProvider).purchase(p);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.success:
        _toast('Welcome to Premium. Thank you!');
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.pending:
        _toast('Your payment is pending. Premium turns on automatically when it completes.');
      case PurchaseOutcome.notEntitled:
        _toast('The purchase finished but Premium is not active yet. Try “Restore purchases”, or contact support if it persists.');
      case PurchaseOutcome.failed:
        _toast('The purchase could not be completed. You have not been charged.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final found = await ref.read(billingProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(found ? 'Premium restored.' : 'No active subscription found for this store account.');
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

  List<String> _benefits(FeatureGates g) {
    final out = <String>[];
    if (g.lockPremiumSounds) out.add('Access to every premium sound');
    if (g.freeMaxLayers < g.premiumMaxLayers) out.add('Mix up to ${g.premiumMaxLayers} sounds at once');
    if (g.freeMaxSavedMixes < g.premiumMaxSavedMixes) out.add('Save up to ${g.premiumMaxSavedMixes} custom mixes');
    if (g.freeMaxDownloads < g.premiumMaxDownloads) out.add('Unlimited offline downloads');
    if (out.isEmpty) {
      out.add('Support the ongoing development of LunaNest');
      out.add('Be first in line for new Premium features when they launch');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final billing = ref.watch(billingProvider);
    final gates = ref.watch(featureGatesProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('LunaNest Premium'),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
          const Center(child: MoonMark(size: 110)),
          const SizedBox(height: 8),
          Text('Sleep well, your way', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (!gates.hasPaidBenefits)
            GlassCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.favorite, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Every sound and feature in LunaNest is free right now. You do not need Premium to use anything.'),
                ),
              ]),
            ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Premium includes', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final b in _benefits(gates))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b)),
                  ]),
                ),
              const SizedBox(height: 6),
              Text('Accessibility and privacy controls are always free.', style: theme.textTheme.bodySmall),
            ]),
          ),
          const SizedBox(height: 16),
          if (billing.isPremium) _ActiveCard(billing: billing, onManage: _manage) else ..._offers(billing, theme),
          if (billing.expired && !billing.isPremium)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 8),
              child: Text('Your Premium subscription has ended. You can subscribe again at any time.', textAlign: TextAlign.center),
            ),
          Center(child: TextButton(onPressed: _busy ? null : _restore, child: const Text('Restore purchases'))),
          const SizedBox(height: 4),
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

  List<Widget> _offers(BillingService billing, ThemeData theme) {
    switch (billing.status) {
      case BillingStatus.unconfigured:
        return const [
          GlassCard(
            child: Text('Subscriptions are not set up in this build, so purchases are unavailable. Everything works normally without them.'),
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
        final saving = _savingPercent(billing);
        return [
          if (billing.annual != null)
            _OfferCard(
                package: billing.annual!, label: 'Annual', badge: saving != null ? 'Save $saving%' : 'Best value', highlight: true, busy: _busy, onBuy: _buy),
          if (billing.monthly != null)
            _OfferCard(package: billing.monthly!, label: 'Monthly', badge: null, highlight: false, busy: _busy, onBuy: _buy),
          if (_busy) const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator())),
        ];
    }
  }

  /// Computed from the two real store prices; null unless both exist in one currency.
  int? _savingPercent(BillingService b) {
    final m = b.monthly?.storeProduct;
    final a = b.annual?.storeProduct;
    if (m == null || a == null || m.currencyCode != a.currencyCode || m.price <= 0) return null;
    final pct = ((1 - a.price / (m.price * 12)) * 100).round();
    return pct >= 5 ? pct : null;
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.billing, required this.onManage});
  final BillingService billing;
  final VoidCallback onManage;

  String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final exp = billing.expiresAt;
    final String detail;
    if (billing.billingIssue) {
      detail = 'There is a payment problem. Update your payment method in your store account to keep Premium.';
    } else if (!billing.willRenew && exp != null) {
      detail = 'Cancelled. Premium stays active until ${_date(exp)}.';
    } else if (exp != null) {
      detail = 'Renews on ${_date(exp)}.';
    } else {
      detail = 'Thank you for supporting LunaNest.';
    }
    return GlassCard(
      child: Row(children: [
        Icon(billing.billingIssue ? Icons.warning_amber_rounded : Icons.verified, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Premium is active', style: Theme.of(context).textTheme.titleMedium),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        TextButton(onPressed: onManage, child: const Text('Manage')),
      ]),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.package,
    required this.label,
    required this.badge,
    required this.highlight,
    required this.busy,
    required this.onBuy,
  });
  final Package package;
  final String label;
  final String? badge;
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? scheme.primary : scheme.outlineVariant, width: highlight ? 2 : 1),
        color: scheme.surface.withAlpha(180),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text(badge!, style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
            Text(label == 'Annual' ? '$price per year' : '$price per month'),
          ]),
        ),
        FilledButton(onPressed: busy ? null : () => onBuy(package), child: const Text('Subscribe')),
      ]),
    );
  }
}
