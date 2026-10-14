# Phase 1 UI redesign — what was built

**Status: written but NOT compiled, run, or visually checked.** No Flutter SDK was available. Treat it as
untested until the CI build is green and you have looked at it on a phone.

## Design system (`lib/ui/`, all drawn with Flutter — no images, no new dependencies)
| File | Purpose |
|---|---|
| `night_sky.dart` | App-wide midnight gradient (navy → indigo → violet), nebula glows, 70 twinkling stars (updates ~10 fps). Pale gradient in light theme. Static under "reduce motion". Mounted once in `app.dart`; scaffolds are transparent so it shows through. |
| `scene_kind.dart` | `SceneKind` (rain, storm, ocean, river, forest, fire, noise, wind) and `sceneForSound()` mapping each catalog sound to a scene; unknown sounds fall back by category. |
| `scene_painters.dart` | The scenes. Every particle is a pure function of time, so frozen thumbnails match the live scene. |
| `scene_view.dart` | Widget that animates scenes with a `Ticker`; stops when `animate:false`, when paused, when the widget is hidden (TickerMode), or under reduce-motion. |
| `glass_card.dart`, `reveal.dart`, `timer_ring.dart`, `moon.dart` | Translucent card (no blur, for performance), staggered entrance, circular timer countdown, crescent logo. |

## Scenes
- **Rain**: slanted falling drops (density by intensity), ripples near the bottom. Heavy Rain is denser.
- **Thunderstorm** (Distant Thunder): heavy rain + a subtle screen flash and faint bolt every ~11 s.
- **Ocean**: four layered moving wave bands with foam lines.
- **River** (Gentle Stream): flowing shimmering streaks over a water band.
- **Forest** (Night Crickets): pine silhouettes, drifting leaves, pulsing fireflies.
- **Fireplace**: flickering flames, warm glow, rising embers.
- **Noise** (white/pink/brown): breathing rings and soft rising particles.
- **Wind** (Soft Wind): drifting wisps and dust.
- **Mixes**: all layers are drawn together; each layer's visual strength follows its volume.

## Screens changed
Home (greeting, hero "now playing / tonight's pick" card, mix cards, sound artwork cards, glass category cards, staggered
entrance), Now Playing (full-screen live scene, glass control panel, glowing play button, timer ring), Mixer (live blended
preview, scene thumbnails, per-layer accent sliders with % labels), mini-player (floating, live thumbnail, timer progress bar),
sleep-timer sheet (countdown ring), splash (animated moon + title), route transitions (fade + rise for Player and Premium),
typography (weights/letter-spacing tuned; still the system font).

## Not changed
Audio engine, handler, downloads, billing, persistence, favorites, saved mixes, sleep timer logic, router structure.

## Known limitations
- Thumbnails/cards are code-drawn illustrations, not photography. Fine for offline/APK size; real artwork needs licensed assets.
- No custom font bundled (would require a licensed font file added to `assets/`).
- Animation cost is unmeasured. Hero card, now-playing scene, mixer preview and mini-player animate only while audio plays.
  If a low-end phone stutters, lower particle counts in `scene_painters.dart`.
- Light theme gets the new layout but the night look is the primary design.
- Lightning is deliberately subtle; adjust `_lightning` if you want more drama.
