import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/env.dart';

enum BillingStatus { unconfigured, loading, ready, error }

enum PurchaseOutcome { success, cancelled, pending, notEntitled, failed }

/// Subscriptions via RevenueCat (wraps Google Play Billing and StoreKit).
///
/// Premium is derived ONLY from RevenueCat's CustomerInfo entitlements (the SDK
/// verifies receipts with the store and caches the last result for offline use).
/// This app never stores its own "isPremium" flag.
///
/// With no API key configured the service stays `unconfigured` and the app runs
/// as a fully usable free app.
class BillingService extends ChangeNotifier {
  BillingStatus status = BillingStatus.unconfigured;
  bool isPremium = false;
  bool expired = false; // had Premium before, no longer active
  bool willRenew = false; // false while active = cancelled, ends at [expiresAt]
  bool billingIssue = false; // payment problem detected by the store
  DateTime? expiresAt;
  Offering? offering;
  String? error;

  Package? get monthly => offering?.monthly;
  Package? get annual => offering?.annual;
  bool get hasProducts => monthly != null || annual != null;

  Future<void> init() async {
    final key = Platform.isAndroid
        ? Env.revenueCatAndroidKey
        : Platform.isIOS
            ? Env.revenueCatIosKey
            : '';
    if (key.isEmpty) {
      status = BillingStatus.unconfigured;
      notifyListeners();
      return;
    }
    status = BillingStatus.loading;
    notifyListeners();
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      Purchases.addCustomerInfoUpdateListener(_apply);
      _apply(await Purchases.getCustomerInfo());
      await refreshOfferings();
      status = BillingStatus.ready;
    } catch (e) {
      status = BillingStatus.error;
      error = 'Subscriptions are temporarily unavailable.';
      if (kDebugMode) debugPrint('Billing init failed: $e');
    }
    notifyListeners();
  }

  Future<void> refreshOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      offering = offerings.current;
      error = null;
    } catch (e) {
      error = 'Could not load subscription options. Check your connection.';
    }
    notifyListeners();
  }

  void _apply(CustomerInfo info) {
    final active = info.entitlements.active[Env.premiumEntitlement];
    final ever = info.entitlements.all[Env.premiumEntitlement];
    isPremium = active != null;
    willRenew = active?.willRenew ?? false;
    billingIssue = active?.billingIssueDetectedAt != null;
    expiresAt = DateTime.tryParse(active?.expirationDate ?? '')?.toLocal();
    expired = active == null && ever != null;
    notifyListeners();
  }

  /// Re-check entitlement + offerings (called when the app returns to the foreground).
  Future<void> refresh() async {
    if (status != BillingStatus.ready) return;
    try {
      _apply(await Purchases.getCustomerInfo());
      if (!hasProducts) await refreshOfferings();
    } catch (_) {
      // Offline: keep the SDK's last known state.
    }
  }

  Future<PurchaseOutcome> purchase(Package p) async {
    try {
      final info = await Purchases.purchasePackage(p);
      _apply(info);
      // Success is only reported when the store-verified entitlement is active.
      return isPremium ? PurchaseOutcome.success : PurchaseOutcome.notEntitled;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return PurchaseOutcome.cancelled;
      if (code == PurchasesErrorCode.paymentPendingError) return PurchaseOutcome.pending;
      error = e.message;
      notifyListeners();
      return PurchaseOutcome.failed;
    }
  }

  /// Returns true if an active entitlement was found.
  Future<bool> restore() async {
    try {
      _apply(await Purchases.restorePurchases());
      return isPremium;
    } on PlatformException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }
}
