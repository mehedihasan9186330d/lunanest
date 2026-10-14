import 'dart:math' as math;

/// Deterministic pseudo-random number in [0, 1) from an index and a salt.
/// Lets painters derive stable particle properties without storing state.
double hash01(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}
