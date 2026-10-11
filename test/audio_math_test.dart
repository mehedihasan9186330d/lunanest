import 'package:flutter_test/flutter_test.dart';
import 'package:lunanest/core/audio_math.dart';

void main() {
  group('headroomFor', () {
    test('single layer has no reduction', () => expect(headroomFor(1), 1.0));
    test('more layers reduce gain', () {
      expect(headroomFor(4), closeTo(0.5, 1e-9));
      expect(headroomFor(6), lessThan(headroomFor(3)));
    });
  });

  group('timerFadeFactor', () {
    const fade = Duration(seconds: 20);
    test('full volume before the fade window', () => expect(timerFadeFactor(const Duration(minutes: 5), fade), 1.0));
    test('silent at zero', () => expect(timerFadeFactor(Duration.zero, fade), 0.0));
    test('monotonic decrease inside the window', () {
      final a = timerFadeFactor(const Duration(seconds: 15), fade);
      final b = timerFadeFactor(const Duration(seconds: 10), fade);
      final c = timerFadeFactor(const Duration(seconds: 2), fade);
      expect(a, greaterThan(b));
      expect(b, greaterThan(c));
      expect(c, greaterThan(0));
    });
    test('zero fade means instant stop only at the end', () {
      expect(timerFadeFactor(const Duration(seconds: 1), Duration.zero), 1.0);
    });
  });

  group('targetGain', () {
    test('never exceeds 1.0', () {
      expect(targetGain(layerVolume: 1, master: 1, layerCount: 1), 1.0);
    });
    test('applies master, headroom and fades', () {
      final g = targetGain(layerVolume: 0.8, master: 0.5, layerCount: 4, fade: 0.5);
      expect(g, closeTo(0.8 * 0.5 * 0.5 * 0.5, 1e-9));
    });
    test('never negative', () {
      expect(targetGain(layerVolume: 0, master: 1, layerCount: 2), 0.0);
    });
  });
}
