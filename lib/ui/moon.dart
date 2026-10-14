import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Brand mark (crescent + sparkles), drawn in code and matching the launcher icon.
class MoonMark extends StatelessWidget {
  const MoonMark({super.key, this.size = 120, this.glow = 1.0});
  final double size;
  final double glow; // 0..1 glow strength
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MoonPainter(glow.clamp(0.0, 1.0).toDouble()));
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.glow);
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide;
    final center = size.center(Offset.zero);
    final glowRect = Rect.fromCircle(center: center, radius: u * 0.8);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.fromRGBO(184, 169, 255, 0.35 * glow), const Color(0x00B8A9FF)],
        ).createShader(glowRect),
    );
    final disc = Path()..addOval(Rect.fromCircle(center: Offset(u * 0.46, u * 0.53), radius: u * 0.34));
    final bite = Path()..addOval(Rect.fromCircle(center: Offset(u * 0.58, u * 0.47), radius: u * 0.29));
    final moon = Path.combine(PathOperation.difference, disc, bite);
    canvas.drawPath(
      moon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F0FF), Color(0xFFB8A9FF)],
        ).createShader(Rect.fromCircle(center: center, radius: u * 0.5)),
    );
    final star = Paint()..color = Colors.white.withAlpha((230 * (0.5 + 0.5 * glow)).round());
    _sparkle(canvas, Offset(u * 0.62, u * 0.34), u * 0.10, star);
    _sparkle(canvas, Offset(u * 0.74, u * 0.53), u * 0.06, star);
    _sparkle(canvas, Offset(u * 0.54, u * 0.24), u * 0.045, star);
  }

  void _sparkle(Canvas c, Offset p, double r, Paint paint) {
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final ang = math.pi / 2 + k * math.pi / 4;
      final rr = k.isEven ? r : r * 0.30;
      final pt = Offset(p.dx + rr * math.cos(ang), p.dy - rr * math.sin(ang));
      if (k == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.glow != glow;
}
