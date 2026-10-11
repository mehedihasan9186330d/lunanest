import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/env.dart';

enum BillingStatus { unconfigured, loading, ready, error }

enum PurchaseOutcome { success, cancelled, pending, failed }

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
    isPremium = info.entitlements.active.containsKey(Env.premiumEntitlement);
    notifyListeners();
  }

  Future<PurchaseOutcome> purchase(Package p) async {
    try {
      final info = await Purchases.purchasePackage(p);
      _apply(info);
      return isPremium ? PurchaseOutcome.success : PurchaseOutcome.pending;
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
