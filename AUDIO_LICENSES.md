# Audio licenses

## Bundled sounds (49 files, `assets/audio/*.wav`, generated at build time)

All bundled audio is **synthesized by `tool/generate_audio.py`** from random noise and mathematical models
(filtered noise, envelopes, decaying tones). **No third-party recordings, samples, or code-derived audio are used.**

| Field | Value |
|---|---|
| Source | Original, synthesized by this project's own script |
| License | CC0 1.0 Universal (public-domain dedication by the project author) |
| Commercial use | Yes |
| Offline copies / redistribution | Yes (bundled in the app) |
| Attribution required | No |

The project author must confirm they are comfortable releasing the generator output under CC0 (or choose another license)
before shipping. Each catalog entry in `assets/catalog.json` carries the same license line.

| Category | Sounds |
|---|---|
| Rain & Thunder | Gentle Rain (`gentle_rain`), Heavy Rain (`heavy_rain`), Distant Thunder (`distant_thunder`), Soft Drizzle (`soft_drizzle`), Rain on Window (`rain_on_window`), Rain on Leaves (`rain_on_leaves`), Light Shower (`light_shower`), Forest Rain (`forest_rain`), Rain with Soft Wind (`rain_soft_wind`), Thunderstorm (`thunderstorm`), Close Thunder (`close_thunder`) |
| Ocean | Calm Ocean Waves (`ocean_waves`), Ocean at Night (`ocean_night`), Soft Beach Waves (`soft_beach_waves`), Deep Ocean (`deep_ocean`), Tide Pool (`tide_pool`), Rocky Shore (`rocky_shore`), Distant Surf (`distant_surf`), Underwater Soft (`underwater_soft`), Night Tide (`night_tide`) |
| Wind & Nature | Soft Wind (`soft_wind`), Strong Wind (`strong_wind`), Wind in Trees (`wind_in_trees`), Mountain Breeze (`mountain_breeze`), Gentle Stream (`forest_stream`), Creek (`creek`), River Rapids (`river_rapids`), Night Crickets (`night_crickets`), Frogs at Night (`frogs_night`), Birds at Dusk (`birds_dusk`), Bamboo Forest (`bamboo_forest`), Leaves Rustling (`leaves_rustling`) |
| Noise | White Noise (`white_noise`), Pink Noise (`pink_noise`), Brown Noise (`brown_noise`), Soft Fan (`soft_fan`), Air Conditioner (`air_conditioner`), Soft Hiss (`soft_hiss`), Deep Rumble (`deep_rumble`), Violet Noise (`violet_noise`), Cabin Noise (`cabin_noise`) |
| Cozy | Fireplace (`fireplace`), Soft Crackling Fire (`soft_crackling_fire`), Campfire (`campfire`), Soft Room Tone (`soft_room_tone`), Soft Clock Tick (`clock_tick_soft`), Page Turning (`page_turning_ambient`), Warm Indoor Hum (`warm_indoor_hum`), Blanket Rustle (`blanket_rustle`) |

Format: 20 s loops, 22.05 kHz, 16-bit mono WAV (about 0.88 MB each, 43 MB in total in the app package).

**Honesty note:** these are synthetic approximations. They are designed to be gentle and to loop seamlessly, but they are not
field recordings and some (frogs, birds, bamboo, clock, paper) are stylised. For a market-competitive product, add licensed
recordings alongside them.

## Not in the catalog (no audio exists, so nothing is listed)
Piano, ambient music, meditation ambience, real recordings of birds/frogs/waterfalls, etc. The catalog never lists a sound
without a playable source.

## Adding licensed audio
1. Obtain files whose license explicitly allows **commercial use in an app** and, for downloads, **redistribution**. Prefer CC0,
   CC-BY (with attribution), or a purchased commercial license. Avoid CC-NC and CC-ND. Never use YouTube audio without a license.
2. Host streamed files on HTTPS storage, or bundle them in `assets/audio/`.
3. Add a catalog entry (`"url"` and/or `"asset"`, `"offlineAllowed"`, `"license"`), keep `"premium": false` unless you decide otherwise.
4. Record source URL, author, license, receipt and attribution text here; show required attributions in the app.
5. Prefer seamlessly loopable files.
