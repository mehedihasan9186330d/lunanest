# Remaining work and external dependencies

## Cannot be done by code alone
| Item | Why | Simplest legitimate route |
|---|---|---|
| Real nature recordings, piano, music (rain on roof, birds, forest, waterfall, piano…) | Need recordings/licenses | Buy a royalty-free commercial pack, or commission/record; or CC0 (e.g. Freesound CC0 filter). Document in AUDIO_LICENSES.md |
| Audio hosting for streaming/downloads | Needs HTTPS storage | Cloudflare R2 / Firebase Storage / S3; add `url` + `offlineAllowed` in catalog.json |
| RevenueCat account + store products | External accounts | docs/SUBSCRIPTIONS.md |
| Google Play developer account | Paid, identity verification | Play Console |
| Apple Developer account + macOS build | Paid; Apple requirement | APP_STORE_RELEASE_CHECKLIST.md |
| Upload keystore / signing | Secret credential | Generate once, store as encrypted CI secret |
| Privacy Policy / Terms hosting + legal review | Public URL required | Fill templates; host on GitHub Pages / site |
| Support email, publisher name, contact | Not invented here | Set `SUPPORT_EMAIL`; fill placeholders |
| Store screenshots, 512px icon, feature graphic | Need real running app | Capture from your phone after first install |
| App icon / launcher artwork | Default Flutter icon is used until replaced | Provide 1024×1024 PNG; ask Claude for `flutter_launcher_icons` setup |

## Known limitations / not built
- Artwork is gradient + icon placeholders (no photography).
- Search is merged into the Explore screen; Restore Purchases lives in Premium and Settings (no dedicated screen).
- No remote catalog: catalog.json is bundled (update the app to change it). A remote catalog fetch is a straightforward next step.
- No Wi-Fi-only download setting (needs connectivity plugin); no storage-quota query.
- No download resume across app restarts (partial files are discarded).
- Streaming cache is not implemented (just_audio's caching proxy needs cleartext localhost config); explicit downloads cover offline.
- No home-screen widgets, Android Auto, or iOS Shortcuts.
- Free-tier limits (3 layers, 3 mixes, 3 downloads) and premium limits (6 / 50 / unlimited) are product guesses.
- Light theme is functional but less polished than the dark theme.
- Android process-kill/background restrictions on some OEM devices (Xiaomi, Huawei…) may stop playback; needs real-device testing.
