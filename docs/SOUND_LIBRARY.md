# Sound library (all free)

49 synthesized sounds, all `premium: false`. Regenerate with `python3 tool/generate_audio.py`.


## Rain & Thunder (11)
- `gentle_rain` – Gentle Rain
- `heavy_rain` – Heavy Rain
- `distant_thunder` – Distant Thunder
- `soft_drizzle` – Soft Drizzle
- `rain_on_window` – Rain on Window
- `rain_on_leaves` – Rain on Leaves
- `light_shower` – Light Shower
- `forest_rain` – Forest Rain
- `rain_soft_wind` – Rain with Soft Wind
- `thunderstorm` – Thunderstorm
- `close_thunder` – Close Thunder

## Ocean (9)
- `ocean_waves` – Calm Ocean Waves
- `ocean_night` – Ocean at Night
- `soft_beach_waves` – Soft Beach Waves
- `deep_ocean` – Deep Ocean
- `tide_pool` – Tide Pool
- `rocky_shore` – Rocky Shore
- `distant_surf` – Distant Surf
- `underwater_soft` – Underwater Soft
- `night_tide` – Night Tide

## Wind & Nature (12)
- `soft_wind` – Soft Wind
- `strong_wind` – Strong Wind
- `wind_in_trees` – Wind in Trees
- `mountain_breeze` – Mountain Breeze
- `forest_stream` – Gentle Stream
- `creek` – Creek
- `river_rapids` – River Rapids
- `night_crickets` – Night Crickets
- `frogs_night` – Frogs at Night
- `birds_dusk` – Birds at Dusk
- `bamboo_forest` – Bamboo Forest
- `leaves_rustling` – Leaves Rustling

## Noise (9)
- `white_noise` – White Noise
- `pink_noise` – Pink Noise
- `brown_noise` – Brown Noise
- `soft_fan` – Soft Fan
- `air_conditioner` – Air Conditioner
- `soft_hiss` – Soft Hiss
- `deep_rumble` – Deep Rumble
- `violet_noise` – Violet Noise
- `cabin_noise` – Cabin Noise

## Cozy (8)
- `fireplace` – Fireplace
- `soft_crackling_fire` – Soft Crackling Fire
- `campfire` – Campfire
- `soft_room_tone` – Soft Room Tone
- `clock_tick_soft` – Soft Clock Tick
- `page_turning_ambient` – Page Turning
- `warm_indoor_hum` – Warm Indoor Hum
- `blanket_rustle` – Blanket Rustle

## Presets
- Ocean Dreams: ocean_waves, soft_wind
- Cozy Cabin: gentle_rain, fireplace
- Rainy Night: gentle_rain, distant_thunder, soft_wind
- Summer Night: night_crickets, forest_stream, soft_wind
- Stormy Night: rain_on_window, close_thunder, soft_room_tone
- Beach Evening: soft_beach_waves, birds_dusk, soft_wind
- Campfire Night: campfire, night_crickets, mountain_breeze
- Quiet Study: soft_room_tone, clock_tick_soft, soft_drizzle

## How to add a sound
1. Write a generator function in `tool/generate_audio.py` and add it to the `SOUNDS` registry (function, final low-pass Hz, limiter sigmas, target RMS).
2. Add the entry to `assets/catalog.json` (`"asset": "assets/audio/<id>.wav"`, `"premium": false`, CC0 license line).
3. Map it to a scene in `lib/ui/scene_kind.dart` (`sceneForSound`).
4. `python3 tool/verify_project.py` fails if any of these three is missing.

## Softness design rules used by the generator
Soft attacks and band-limited transients (no raw clicks), per-sound low-pass, soft limiter on rare peaks, seamless loops
(frequency-domain noise, whole-number modulation cycles, wrap-around events). These are verified with measurements
(high-frequency energy, loop-seam steps), **not by listening**: please listen on your phone and tell me which sounds to tune.

