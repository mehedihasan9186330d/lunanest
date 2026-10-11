# Audio licenses

## Bundled sounds (12 files, in `assets/audio/`, generated at build time)

All bundled audio is **synthesized by `tool/generate_audio.py`** from random noise and
mathematical models. No third-party recordings or samples are used.

| id | Title | Method (summary) | Source | License | Commercial use | Attribution |
|----|-------|------------------|--------|---------|----------------|-------------|
| white_noise | White Noise | flat spectrum noise | original, synthesized | CC0 1.0 | yes | none |
| pink_noise | Pink Noise | 1/√f spectrum | original, synthesized | CC0 1.0 | yes | none |
| brown_noise | Brown Noise | 1/f spectrum | original, synthesized | CC0 1.0 | yes | none |
| gentle_rain | Gentle Rain | band-limited noise + light drop transients | original, synthesized | CC0 1.0 | yes | none |
| heavy_rain | Heavy Rain | dense drops + broadband noise | original, synthesized | CC0 1.0 | yes | none |
| distant_thunder | Distant Thunder | low-passed rumble with swells | original, synthesized | CC0 1.0 | yes | none |
| ocean_waves | Calm Ocean Waves | noise with 10 s swell envelope | original, synthesized | CC0 1.0 | yes | none |
| ocean_night | Ocean at Night | darker noise, 20 s swell | original, synthesized | CC0 1.0 | yes | none |
| soft_wind | Soft Wind | band-passed noise, slow modulation | original, synthesized | CC0 1.0 | yes | none |
| forest_stream | Gentle Stream | modulated band noise + bubbles | original, synthesized | CC0 1.0 | yes | none |
| night_crickets | Night Crickets | synthesized chirp pulse trains + noise bed | original, synthesized | CC0 1.0 | yes | none |
| fireplace | Fireplace | low rumble + random crackle/pop transients | original, synthesized | CC0 1.0 | yes | none |

The project author must confirm they are comfortable releasing the generator output under CC0
(or choose another license) before shipping.

**Honesty note:** these are synthetic approximations. They are useful and loop seamlessly, but they
do not sound like real field recordings. For a market-competitive product, replace or add to them
with licensed recordings.

## Not yet in the catalog (no audio exists → intentionally not listed)

Piano, ambient music, meditation ambience, birds/dawn chorus, frogs, waterfall, river, lake, forest
ambience, rain on window/roof/leaves, etc. These need recordings or music you own or license.
The catalog never lists a sound without a playable source.

## Adding licensed audio

1. Obtain files with a license that explicitly allows **commercial use in an app** and, if you want
   downloads, **redistribution/offline copies**. Prefer CC0, CC-BY (with attribution), or a purchased
   commercial license. Avoid CC-NC and CC-ND.
2. Host streamed files on HTTPS storage (e.g. Cloudflare R2, Firebase Storage, S3). Bundled files go
   in `assets/audio/` (increases app size).
3. Add an entry to `assets/catalog.json` with `"url": "https://..."` and/or `"asset": "..."`,
   `"offlineAllowed": true|false`, and a `"license"` string.
4. Record source URL, author, license, purchase receipt and attribution text in the table above.
   Put required attributions into the app (About screen) before release.
5. Prefer seamlessly loopable files (equal start/end, or crossfaded) – looped playback is gapless on
   Android and near-gapless on iOS.
