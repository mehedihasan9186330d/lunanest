import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Midnight-sky backdrop: deep navy → violet gradient with softly twinkling stars.
/// Twinkle updates ~10 times per second (cheap on battery). Static when the system
/// asks for reduced motion. In light theme it becomes a pale lavender gradient.
class NightSky extends StatefulWidget {
  const NightSky({super.key, required this.child, this.animate = true, this.forceDark = false});
  final Widget child;
  final bool animate;
  final bool forceDark;

  @override
  State<NightSky> createState() => _NightSkyState();
}

class _NightSkyState extends State<NightSky> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _t = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  double _base = 0;
  bool _reduceMotion = false;

  void _onTick(Duration d) {
    if ((d - _last).inMilliseconds >= 100) {
      _last = d;
      _t.value = _base + d.inMilliseconds / 1000.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    _sync();
  }

  @override
  void didUpdateWidget(NightSky old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final want = widget.animate && !_reduceMotion;
    if (want && !_ticker.isActive) {
      _base = _t.value;
      _last = Duration.zero;
      _ticker.start();
    } else if (!want && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.forceDark || Theme.of(context).brightness == Brightness.dark;
    return Stack(fit: StackFit.expand, children: [
      RepaintBoundary(child: CustomPaint(painter: _SkyPainter(_t, dark), size: Size.infinite)),
      widget.child,
    ]);
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.time, this.dark) : super(repaint: time);
  final ValueListenable<double> time;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = dark
        ? const [Color(0xFF070B24), Color(0xFF0B1030), Color(0xFF1A1650), Color(0xFF2A1B5E)]
        : const [Color(0xFFEDEBFF), Color(0xFFF5F4FF), Color(0xFFEAE5FF), Color(0xFFDCD3FF)];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.4, 0.75, 1.0],
        ).createShader(rect),
    );
    if (!dark) return;

    // faint violet nebula + moon glow
    final glow1 = Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.10), radius: size.width * 0.55);
    canvas.drawRect(
      glow1,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x2EB8A9FF), Color(0x00B8A9FF)]).createShader(glow1),
    );
    final glow2 = Rect.fromCircle(center: Offset(size.width * 0.1, size.height * 0.9), radius: size.width * 0.7);
    canvas.drawRect(
      glow2,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x336A3FD0), Color(0x006A3FD0)]).createShader(glow2),
    );

    final t = time.value;
    final p = Paint();
    for (var i = 0; i < 70; i++) {
      final x = hash01(i, 1) * size.width;
      final y = hash01(i, 2) * size.height * 0.8;
      final tw = 0.5 + 0.5 * math.sin(t * (0.6 + hash01(i, 3) * 1.4) + hash01(i, 4) * 6.283);
      final a = (0.15 + 0.6 * tw * (0.4 + hash01(i, 6) * 0.6)).clamp(0.0, 1.0);
      p.color = Color.fromRGBO(232, 233, 255, a.toDouble());
      canvas.drawCircle(Offset(x, y), 0.5 + 1.1 * hash01(i, 5), p);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.dark != dark;
}
