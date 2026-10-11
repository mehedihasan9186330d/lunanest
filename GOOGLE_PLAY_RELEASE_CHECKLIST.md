# Google Play release checklist

Requirements change. Verify each item against current Google Play policy/Play Console help on the day you
release. Nothing below has been done by this project.

## Account and app
- [ ] Google Play developer account (one-time registration fee; identity verification required).
- [ ] Check whether your account type requires a **closed test with a minimum number of testers for a
      minimum period** before production access (applies to newer personal accounts — verify current rule).
- [ ] Create app: name "LunaNest — Sleep & Relax", default language, free app, category (e.g. Health & Fitness or Lifestyle).

## Build
- [ ] Confirm `targetSdkVersion` meets Google Play's current target API requirement (Flutter's template
      follows recent Flutter releases; check `android/app/build.gradle*`).
- [ ] Create an **upload key** (keystore) and keep it backed up offline. Enroll in **Play App Signing**.
- [ ] Configure release signing (`android/key.properties` + `build.gradle*`; never commit keystore/passwords).
- [ ] Build an **Android App Bundle**: `flutter build appbundle --release --dart-define=REVENUECAT_ANDROID_KEY=...`
- [ ] Test the exact release build on real devices (Android 8 → latest): background playback with screen
      locked, notification controls, timer fade, interruptions (call, other media app, Bluetooth disconnect).
- [ ] Android 13+: POST_NOTIFICATIONS — confirm the playback notification is visible (consider a runtime request
      flow if it is not).
- [ ] Android 14+: confirm foreground service type `mediaPlayback` + permission declarations pass pre-launch checks
      and the Play Console foreground-service declaration (describe: playing user-initiated ambient audio).

## Store listing
- [ ] Short description (≤80 chars), full description (≤4000 chars) — no medical claims ("cures insomnia" etc.).
- [ ] Icon 512×512, feature graphic 1024×500, phone screenshots (real app screens only).
- [ ] Privacy Policy URL (public), support email.
- [ ] Contains ads: **No** (verify if you add any).

## Policy forms
- [ ] **Data safety** form — declare accurately. With RevenueCat: purchase history / device or other IDs
      are processed by a third-party service; encryption in transit yes; deletion request mechanism per your setup.
- [ ] Content rating questionnaire.
- [ ] Target audience (not designed for children unless you meet Families policy).
- [ ] Health apps declaration: check whether your listing/features trigger it (this app makes no medical claims).
- [ ] In-app products: create subscriptions in Play Console (see docs/SUBSCRIPTIONS.md); activate base plans.
- [ ] Licensed audio documented (AUDIO_LICENSES.md) — you attest you have rights to all content.

## Release
- [ ] Internal testing track → add license testers → verify purchase/restore flows with test cards.
- [ ] Closed/open testing as needed → production rollout (staged).
- [ ] Do not claim approval until Google actually approves.
