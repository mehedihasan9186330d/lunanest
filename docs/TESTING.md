# Testing

## Automated (run by CI: `flutter test`)
- `test/audio_math_test.dart` — headroom, timer fade curve, gain clamping.
- `test/models_test.dart` — catalog validation (no unplayable entries), presets, premium detection, JSON round-trips.
- `test/local_store_test.dart` — persistence, corruption tolerance, erase.
- `test/widget_test.dart` — SoundTile, premium lock, favorite toggle, paywall with billing unconfigured.
- `test/scene_test.dart` — scene mapping, every scene paints without throwing (incl. lightning frames), SceneView start/stop, TimerRing.
- `test/catalog_integrity_test.dart` — unique ids, rich categories, every sound free/CC0/has a generator entry, presets valid.
- `test/feature_gates_test.dart` — launch state locks nothing; gates only act when switched on.
- `test/routine_and_prefs_test.dart` — bedtime routine, volume preferences, one-time notification prompt, and a check that **every catalog sound is free and has audio**.
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

## Visual / performance checks for the Phase 1 redesign (manual)
- [ ] Each sound's scene matches what you hear; mix scenes blend sensibly.
- [ ] Scrolling Home stays smooth with the hero + sky animating (watch for dropped frames on your slowest phone).
- [ ] Now Playing for 30+ minutes: no stutter, phone not noticeably warm; scene freezes when paused.
- [ ] Settings → Remove animations (Android accessibility): sky, scenes, splash and entrances become static.
- [ ] Text at 200% scale: no overflow on Home cards, Player panel, Mixer.
- [ ] Dark / Light / System themes all readable; Player stays dark by design.
- [ ] Screen locked: confirm animations stop consuming CPU (ticker stops when the app is not visible).

## Background audio, notification and icon (manual, real Android phone — none of this has been verified)
- [ ] Android 13+: after the first sound, the "Allow notifications" prompt appears once; allow it.
- [ ] Start a sound, press Home: audio continues; notification shows the **moon icon**, LunaNest artwork, the sound title, Pause and Stop.
- [ ] Lock the phone, wait 10+ minutes: still playing; lock-screen controls Pause/Play/Stop work.
- [ ] Open another media app / take a call: LunaNest pauses and resumes appropriately (a short navigation voice should lower, not stop it).
- [ ] Unplug wired headphones / disconnect Bluetooth: playback pauses (does not blast from the speaker).
- [ ] Bluetooth headset play/pause button works.
- [ ] Sleep timer started, app in background, screen locked: sound fades out and the notification disappears at the end.
- [ ] Swipe the app away from Recents while playing (OEM-specific behaviour; note result). Settings → Background playback has the help text.
- [ ] Launcher shows the new moon icon (round and squircle masks); with Android 13+ themed icons on, the monochrome moon appears.
- [ ] Bedtime routine: set up on Home, tap Start → mix plays and the timer ring counts down.
- [ ] Master volume and per-sound volumes are remembered after force-closing the app.
- [ ] Next/Previous are intentionally absent (LunaNest has no playlist/queue).

## Listening checklist for the expanded sound library (manual, on your phone with headphones and speaker)
- [ ] Rain family: no sharp "static" or ticking; drizzle/window/leaves feel soft at a low bedtime volume.
- [ ] Thunder sounds: rumble is smooth, the crack in Close Thunder is not startling at low volume.
- [ ] Fire sounds: crackles audible but gentle.
- [ ] Loops: listen at the 20 s loop point of 5-6 sounds; no click or jump.
- [ ] Frogs, Birds at Dusk, Bamboo, Clock Tick, Page Turning: not irritating over 10+ minutes (these are stylised; tell me which to retune).
- [ ] Loudness: switching between sounds does not cause large volume jumps.
