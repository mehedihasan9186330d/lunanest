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

SceneSpec sceneForSound(Sound s) {
  switch (s.id) {
    case 'gentle_rain':
      return const SceneSpec(SceneKind.rain, 0.45);
    case 'heavy_rain':
      return const SceneSpec(SceneKind.rain, 1.0);
    case 'distant_thunder':
      return const SceneSpec(SceneKind.storm, 0.9);
    case 'ocean_waves':
    case 'ocean_night':
      return const SceneSpec(SceneKind.ocean);
    case 'soft_wind':
      return const SceneSpec(SceneKind.wind);
    case 'forest_stream':
      return const SceneSpec(SceneKind.river);
    case 'night_crickets':
      return const SceneSpec(SceneKind.forest);
    case 'fireplace':
      return const SceneSpec(SceneKind.fire);
    case 'white_noise':
    case 'pink_noise':
    case 'brown_noise':
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
