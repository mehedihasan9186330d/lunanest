# LunaNest — Sleep & Relax
*Find Your Calm. Drift Into Sleep.*

Flutter app (Android + iOS) for sleep and relaxation: multi-layer sound mixer, sleep timer with fade-out,
background playback with lock-screen controls, favorites, saved mixes, offline downloads and a Free/Premium
model using RevenueCat.

> ## Honest status
> **This code has not been compiled, run or tested by its author.** It was written in an environment with no
> Flutter SDK and no network. What *was* verified: the audio generator runs and produces 12 loopable WAV files;
> the native-config patch script was exercised against mock `flutter create` output; JSON catalog is valid.
> Everything else (compile, tests, background audio, timer, purchases, iOS) is **unverified until the CI build and the
> manual device checklist (docs/TESTING.md) are done.** Expect a few compile errors on the first CI run.

## What is implemented
- Navigation (go_router): splash, onboarding, Home, Explore (with search), category lists, Player, Mixer,
  Library (favorites / my mixes / offline), Premium, Settings, Privacy, Terms, About, Support. Loading, empty, error states.
- Audio (`lib/services/audio`): one looping `just_audio` player per layer, smoothed per-layer gain, headroom against clipping,
  master volume, audio-focus/interruption/ducking/headphone-unplug handling (`audio_session`), foreground service +
  lock-screen/notification controls (`audio_service`), sleep timer with quadratic fade-out that runs in the audio layer (not the UI).
- 12 bundled **original synthesized** sounds (rain, thunder, ocean, wind, stream, crickets, fireplace, white/pink/brown noise).
- Streaming (HTTPS, 3 retries) and resumable-less downloads to app-private storage with progress, cancel, retry, delete, storage usage —
  active only for catalog entries that have an `https` URL and `offlineAllowed: true` (none in this build; see docs/REMAINING_WORK.md).
- Persistence: favorites, recents, mixes, settings, download index (`shared_preferences`); "Erase all local data".
- Freemium (`PlaybackActions` is the single gate): premium sounds/presets locked; layer, saved-mix and download caps differ by tier.
- RevenueCat integration: store-sourced prices, purchase, restore, entitlement listener; unconfigured → free app, no fake unlock.
- Theme: dark (default), light, system; text scaling, reduced-motion, tooltips/semantics labels.

## Project layout
```
lib/
  main.dart                      startup + dependency wiring
  app/        providers, router, theme, playback gating
  core/       env (dart-define), audio math, formatting, category styles
  domain/     models (Sound, Mix, Catalog, AppSettings)
  data/       catalog loader, local store
  services/   audio/ (engine, handler)  downloads/  billing/
  features/   home explore player mixer timer library premium settings onboarding shell common
assets/       catalog.json, legal/, audio/ (generated)
tool/         generate_audio.py, bootstrap.sh, patch_platforms.py
ci/           GitHub Actions workflows (move into .github/workflows)
test/, integration_test/
```
`android/` and `ios/` are **generated** by `tool/bootstrap.sh` (`flutter create` + native patches: foreground service,
permissions, `AudioServiceActivity`, `UIBackgroundModes=audio`). This keeps the repo small and avoids hand-writing Gradle/Xcode files.

## Build (phone-only): see docs/MOBILE_WORKFLOW.md
On a computer: `python3 tool/generate_audio.py && bash tool/bootstrap.sh && flutter pub get && flutter test && flutter run`.

## Config (build-time `--dart-define`, never in source)
`REVENUECAT_ANDROID_KEY`, `REVENUECAT_IOS_KEY`, `PREMIUM_ENTITLEMENT` (default `premium`), `SUPPORT_EMAIL`.

## Other docs
AUDIO_LICENSES.md · PRIVACY_POLICY_TEMPLATE.md · TERMS_OF_USE_TEMPLATE.md · GOOGLE_PLAY_RELEASE_CHECKLIST.md ·
APP_STORE_RELEASE_CHECKLIST.md · docs/SUBSCRIPTIONS.md · docs/TESTING.md · docs/REMAINING_WORK.md · docs/TROUBLESHOOTING.md
