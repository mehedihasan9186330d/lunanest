# Apple App Store release checklist

Requirements change. Verify against current App Store Connect/App Review documentation at release time.
Nothing below has been done by this project; an iOS build has never been run by the author.

## Prerequisites (no way around these)
- [ ] Apple Developer Program membership (annual fee).
- [ ] A macOS build environment: a Mac, **or** a cloud macOS CI (GitHub Actions `macos-latest`, Codemagic) —
      usable from a phone, but signing assets are still required.
- [ ] Minimum Xcode/iOS SDK required for new submissions (Apple raises this yearly) — check current requirement
      and make sure the CI runner's Xcode meets it.

## Project
- [ ] Bundle ID (default `com.lunanest.lunanest`) registered in the developer portal; change if needed everywhere.
- [ ] `UIBackgroundModes = audio` present (applied by `tool/patch_platforms.py`) — verify in `ios/Runner/Info.plist`.
- [ ] Real-device test: lock screen controls, background playback, timer fade, phone call interruption,
      headphone unplug, AirPods, silent switch behavior.
- [ ] App icons (all sizes, no alpha channel for the 1024 marketing icon), launch screen.

## Signing and upload
- [ ] Distribution certificate + App Store provisioning profile (or automatic signing via App Store Connect API key in CI).
- [ ] `flutter build ipa --release --dart-define=REVENUECAT_IOS_KEY=...` → upload via Transporter / `xcrun altool` / CI → TestFlight.

## App Store Connect
- [ ] App name, subtitle, description, keywords, support URL, **Privacy Policy URL**.
- [ ] **App Privacy** (nutrition labels) — accurate for RevenueCat (purchases, identifiers) and nothing else unless you add SDKs.
- [ ] Subscriptions: create a subscription group + monthly/annual products, localized names, review screenshot of the paywall,
      pricing; link Terms of Use (EULA) and Privacy Policy (Guideline 3.1.2).
- [ ] Paywall shows price, period, renewal and cancellation info (done in-app), plus a working **Restore Purchases**.
- [ ] Age rating questionnaire; export compliance (standard HTTPS only → typically exempt; answer accurately).
- [ ] Screenshots for required device sizes (real screens, no misleading claims or medical claims).
- [ ] Review notes: how to test Premium (sandbox/TestFlight), explain background audio.
- [ ] TestFlight with sandbox testers: purchase, cancel, restore, expiry.
- [ ] Do not claim approval until Apple approves.
