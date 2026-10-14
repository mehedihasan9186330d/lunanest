import '../domain/models.dart';

enum SceneKind { rain, storm, ocean, river, forest, fire, noise, wind }

class SceneSpec {
  const SceneSpec(this.kind, [this.intensity = 0.6]);
  final SceneKind kind;
  final double intensity; // 0..1, e.g. rain density
}

/// One drawn layer of a scene. Mixes draw several layers; opacity follows the
/// layer's volume so quieter sounds are visually quieter.
class SceneLayer {
  const SceneLayer(this.spec, [this.opacity = 1.0]);
  final SceneSpec spec;
  final double opacity;
}

/// Maps a sound to the animated scene that matches it. Every catalog sound has an
/// explicit entry; unknown ids (future sounds) fall back by category.
SceneSpec sceneForSound(Sound s) {
  switch (s.id) {
    // ---- rain & thunder
    case 'soft_drizzle':
      return const SceneSpec(SceneKind.rain, 0.25);
    case 'gentle_rain':
      return const SceneSpec(SceneKind.rain, 0.45);
    case 'rain_on_window':
      return const SceneSpec(SceneKind.rain, 0.5);
    case 'forest_rain':
    case 'rain_soft_wind':
      return const SceneSpec(SceneKind.rain, 0.55);
    case 'light_shower':
    case 'rain_on_leaves':
      return const SceneSpec(SceneKind.rain, 0.65);
    case 'heavy_rain':
      return const SceneSpec(SceneKind.rain, 1.0);
    case 'distant_thunder':
    case 'thunderstorm':
    case 'close_thunder':
      return const SceneSpec(SceneKind.storm, 0.9);
    // ---- ocean
    case 'ocean_waves':
    case 'ocean_night':
    case 'soft_beach_waves':
    case 'deep_ocean':
    case 'tide_pool':
    case 'rocky_shore':
    case 'distant_surf':
    case 'underwater_soft':
    case 'night_tide':
      return const SceneSpec(SceneKind.ocean);
    // ---- wind & nature
    case 'soft_wind':
    case 'mountain_breeze':
      return const SceneSpec(SceneKind.wind, 0.4);
    case 'strong_wind':
      return const SceneSpec(SceneKind.wind, 1.0);
    case 'forest_stream':
    case 'creek':
    case 'river_rapids':
      return const SceneSpec(SceneKind.river);
    case 'wind_in_trees':
    case 'night_crickets':
    case 'frogs_night':
    case 'birds_dusk':
    case 'bamboo_forest':
    case 'leaves_rustling':
      return const SceneSpec(SceneKind.forest);
    // ---- noise
    case 'white_noise':
    case 'pink_noise':
    case 'brown_noise':
    case 'soft_fan':
    case 'air_conditioner':
    case 'soft_hiss':
    case 'deep_rumble':
    case 'violet_noise':
    case 'cabin_noise':
      return const SceneSpec(SceneKind.noise);
    // ---- cozy
    case 'fireplace':
    case 'soft_crackling_fire':
    case 'campfire':
      return const SceneSpec(SceneKind.fire);
    case 'soft_room_tone':
    case 'clock_tick_soft':
    case 'page_turning_ambient':
    case 'warm_indoor_hum':
    case 'blanket_rustle':
      return const SceneSpec(SceneKind.noise);
  }
  switch (s.categoryId) {
    case 'rain':
      return const SceneSpec(SceneKind.rain, 0.6);
    case 'ocean':
      return const SceneSpec(SceneKind.ocean);
    case 'nature':
      return const SceneSpec(SceneKind.forest);
    case 'cozy':
      return const SceneSpec(SceneKind.fire);
    default:
      return const SceneSpec(SceneKind.noise);
  }
}
