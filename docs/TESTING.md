# Testing

## Automated (run by CI: `flutter test`)
- `test/audio_math_test.dart` — headroom, timer fade curve, gain clamping.
- `test/models_test.dart` — catalog validation (no unplayable entries), presets, premium detection, JSON round-trips.
- `test/local_store_test.dart` — persistence, corruption tolerance, erase.
- `test/widget_test.dart` — SoundTile, premium lock, favorite toggle, paywall with billing unconfigured.
- `integration_test/app_test.dart` — launch → explore → play (needs a device/emulator: `flutter test integration_test`).

**Status: none of these have been executed by the author** (no Flutter SDK in the authoring environment).
The first CI run is their first run.

## Manual device checklist (must be done on real hardware; record results)
Android and iOS:
- [ ] Play single sound; lock screen → audio continues > 10 min; notification/lock-screen play/pause/stop work.
- [ ] Mix of 3 layers: independent volume sliders audibly independent; no clipping at max; add/remove without clicks.
- [ ] Find the highest layer count that stays smooth on your lowest-end device (default free 3 / premium 6 caps are guesses).
- [ ] Gapless loop check on iOS and Android (listen at loop point for 2+ minutes per sound).
- [ ] Sleep timer: 5-min test with screen locked; fade audible; playback and notification gone afterwards; timer survives app switching.
- [ ] Interruptions: incoming call, alarm, navigation voice (duck), other music app, Bluetooth/headphone disconnect.
- [ ] Airplane mode: bundled sounds play; streamed sound shows error with Retry.
- [ ] Battery: 8-hour overnight run, note % drained.
- [ ] Process death: swipe app away while playing (Android behavior may stop service) — decide desired behavior.
- [ ] Accessibility: TalkBack/VoiceOver reads sliders/buttons; 200% font; reduce-motion on.
- [ ] Billing sandbox flows (see SUBSCRIPTIONS.md).
