# Subscription setup (RevenueCat)

## Current product decision: everything is FREE
At launch **no sound, mixer feature or download is restricted** and no paywall appears in the player or mixer.
All gating decisions live in one file, `lib/app/feature_gates.dart` (`FeatureGates.launch`: every lock off, free and
premium limits equal). `"premium"` flags in `assets/catalog.json` are all `false` and are ignored unless
`lockPremiumSounds` is turned on. A unit test fails if a catalog sound is marked premium or lacks audio.

To make something Premium later (only when you decide):
- Sounds: set `"premium": true` on chosen sounds in `assets/catalog.json` AND `lockPremiumSounds: true` in `FeatureGates.launch`.
- Limits: lower `freeMaxLayers`, `freeMaxSavedMixes` or `freeMaxDownloads`.
- The Premium screen's benefit list updates itself from these settings.

**Store-policy warning:** do not publish subscription products to production while Premium gives nothing. Google Play and
Apple both expect a subscription to deliver clear ongoing value. Until you gate something, keep the products in
testing/inactive, or ship with no RevenueCat key (the app then shows "not set up" on the Premium screen).

## What the code already does
- Status: `BillingService` (loading / ready / unconfigured / error), entitlement `premium`, renewal date, cancelled-but-active,
  billing-issue, expired, offline fallback to the SDK's cached state; refreshed whenever the app returns to the foreground.
- Purchase outcomes: success only when the store-verified entitlement is active; cancelled, pending, failed, and
  "purchased but entitlement not active" each have their own message. A tap never grants Premium.
- Restore purchases (Premium screen and Settings), manage-subscription link, privacy/terms links, store-renewal disclosure.

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

## Testing on a real phone (Google Play)
1. Play Console → Testing → **Internal testing** → create a release with a signed **App Bundle** (not the debug-signed CI APK).
   Add yourself under *Testers*; open the opt-in link on your phone and install from Play.
2. Play Console → Settings → **License testing**: add your Gmail; test purchases are free and renew every few minutes.
3. In RevenueCat set the Android public key as the `REVENUECAT_ANDROID_KEY` GitHub secret and rebuild.
4. Verify: paywall shows real prices → subscribe → "Premium is active" appears → cancel in Play → card says it ends on a date →
   after expiry the app shows the "ended" message → Restore after reinstall.
5. Record real results. Nothing in this repository has been purchase-tested.

## Credentials (never in source)
| Item | Where it goes |
|---|---|
| RevenueCat public SDK key `goog_...` | GitHub secret `REVENUECAT_ANDROID_KEY` → `--dart-define` (public key, but keep out of source) |
| RevenueCat public key `appl_...` | secret `REVENUECAT_IOS_KEY` |
| Google service-account JSON (Play API access) | uploaded to the RevenueCat dashboard only; never to GitHub |
