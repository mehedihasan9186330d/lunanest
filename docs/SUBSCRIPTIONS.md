# Subscription setup (RevenueCat)

Why RevenueCat: one SDK for Google Play Billing and StoreKit, server-side receipt validation, cached entitlement
state offline, free up to a revenue threshold (check current pricing). Alternative: native billing + your own backend
(more work, no advantage at this size).

**Code behaviour:** `lib/services/billing/billing_service.dart`
- No API key → status `unconfigured`; paywall explains this; app is fully usable as Free. Nothing unlocks locally.
- Premium = RevenueCat entitlement `premium` (override with `--dart-define=PREMIUM_ENTITLEMENT=...`) is active.
- Prices come from the store (`storeProduct.priceString`). Nothing is hardcoded.
- Purchase cancelled / pending / failed, restore, and renewal/expiry updates (customer-info listener) are handled.
- Offline: RevenueCat's cached CustomerInfo is used; if never loaded the user is treated as Free.

## Steps you must do
1. **RevenueCat**: create a project; add an Android app (package `com.lunanest.lunanest`, or whatever you set)
   and an iOS app (bundle id).
2. **Google Play Console** → app → Monetize → Subscriptions → create subscription `lunanest_premium` with base plans:
   `monthly` (1 month, auto-renew) and `annual` (1 year, auto-renew). Set prices, activate. Link a Google Cloud
   service account to RevenueCat (RevenueCat's "Google Play" setup guide) and grant it Play Console permissions.
3. **App Store Connect** → Subscriptions → create a group "LunaNest Premium" with products `lunanest_premium_monthly`,
   `lunanest_premium_annual`; add localization, price, review screenshot. Add the in-app purchase key
   (App Store Connect → Keys) to RevenueCat.
4. **RevenueCat dashboard**: Products → add the store products; Entitlements → create `premium` and attach all products;
   Offerings → default offering `default` with package **Monthly** (`$rc_monthly`) and **Annual** (`$rc_annual`) —
   the app reads `offering.monthly` / `offering.annual`.
5. Copy the **public SDK keys** (Android `goog_...`, iOS `appl_...`). Add as GitHub secrets / `--dart-define`.
6. **Testing**: Play Console → Setup → License testing (add tester Gmail accounts) and upload a build to an internal
   testing track (billing only works for apps installed from Play, signed with the upload/app-signing key — a sideloaded
   debug APK will show no products). iOS: sandbox testers in App Store Connect + TestFlight.
7. **Verify** purchase, cancel, restore (reinstall), expiry, offline launch — and record real results.

## Disclosures
Paywall shows renewal terms, restore button, links to Terms/Privacy. Update store Privacy/Data Safety forms for RevenueCat.
