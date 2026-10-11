import 'dart:math' as math;

/// Gain reduction applied when several layers play at once, to avoid clipping.
double headroomFor(int layerCount) => layerCount <= 1 ? 1.0 : 1.0 / math.sqrt(layerCount);

/// Fade multiplier (0..1) for the sleep timer. Quadratic curve sounds more even.
double timerFadeFactor(Duration remaining, Duration fade) {
  if (remaining <= Duration.zero) return 0.0;
  if (fade <= Duration.zero || remaining >= fade) return 1.0;
  final f = remaining.inMilliseconds / fade.inMilliseconds;
  return f * f;
}

double targetGain({
  required double layerVolume,
  required double master,
  required int layerCount,
  double fade = 1.0,
  double timer = 1.0,
  double duck = 1.0,
}) {
  final g = layerVolume * master * headroomFor(layerCount) * fade * timer * duck;
  return g.clamp(0.0, 1.0).toDouble();
}
