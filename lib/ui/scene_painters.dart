import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rand.dart';
import 'scene_kind.dart';

// All scenes are drawn with Flutter's Canvas (no images, works fully offline).
// Every particle is a pure function of time `t` (seconds) and its index, so a
// frame can be painted at any moment and static thumbnails look like the live scene.

const _lavender = Color(0xFFB8A9FF);
const _ice = Color(0xFFBFD0FF);
const _water = Color(0xFF5B7BF0);
const _deepWater = Color(0xFF6A4FD0);
const _leaf = Color(0xFF86D9B4);
const _ember = Color(0xFFFFA95C);

Color _a(Color c, double alpha, double o) => c.withAlpha((alpha * o * 255).round().clamp(0, 255).toInt());

void paintScene(Canvas c, Size s, double t, SceneLayer l) {
  final o = l.opacity.clamp(0.0, 1.0).toDouble();
  if (o <= 0.02 || s.isEmpty) return;
  final k = l.spec.intensity;
  switch (l.spec.kind) {
    case SceneKind.rain:
      _rain(c, s, t, o, k);
    case SceneKind.storm:
      _rain(c, s, t, o, 0.9);
      _lightning(c, s, t, o);
    case SceneKind.ocean:
      _ocean(c, s, t, o);
    case SceneKind.river:
      _river(c, s, t, o);
    case SceneKind.forest:
      _forest(c, s, t, o);
    case SceneKind.fire:
      _fire(c, s, t, o);
    case SceneKind.noise:
      _noise(c, s, t, o);
    case SceneKind.wind:
      _wind(c, s, t, o, k);
  }
}

void _rain(Canvas c, Size s, double t, double o, double intensity) {
  final n = (26 + 72 * intensity).round();
  final p = Paint()..strokeCap = StrokeCap.round;
  for (var i = 0; i < n; i++) {
    final depth = 0.4 + 0.6 * hash01(i, 4);
    final x = hash01(i, 1) * (s.width + 60) - 10;
    final speed = 0.5 + 0.7 * hash01(i, 2) + 0.3 * intensity;
    final len = (10 + 22 * hash01(i, 3)) * (0.6 + 0.6 * intensity) * depth;
    final prog = (t * speed * 0.9 + hash01(i, 5)) % 1.0;
    final y = prog * (s.height + len) - len;
    p
      ..strokeWidth = 0.8 + 1.2 * depth
      ..color = _a(_ice, 0.16 + 0.34 * depth, o);
    c.drawLine(Offset(x, y), Offset(x - len * 0.18, y + len), p);
  }
  if (intensity > 0.3) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var k = 0; k < 6; k++) {
      final phase = (t * 0.45 + hash01(k, 6)) % 1.0;
      final cx = hash01(k, 7) * s.width;
      final cy = s.height * (0.80 + 0.16 * hash01(k, 8));
      final rx = 6 + 34 * phase;
      ring.color = _a(_ice, (1 - phase) * 0.22, o);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: rx * 0.56), ring);
    }
  }
}

void _lightning(Canvas c, Size s, double t, double o) {
  const cycle = 11.0;
  final ph = t % cycle;
  var f = 0.0;
  if (ph > 7.0 && ph < 7.12) {
    f = 1 - (ph - 7.0) / 0.12;
  } else if (ph > 7.22 && ph < 7.4) {
    f = 0.7 * (1 - (ph - 7.22) / 0.18);
  }
  if (f <= 0) return;
  c.drawRect(Offset.zero & s, Paint()..color = _a(const Color(0xFFE6E0FF), 0.14 * f, o));
  final idx = (t / cycle).floor();
  var x = s.width * (0.25 + 0.5 * hash01(idx, 9));
  final path = Path()..moveTo(x, 0);
  for (var k = 1; k <= 7; k++) {
    x += (hash01(idx * 10 + k, 3) - 0.5) * 44;
    path.lineTo(x, s.height * 0.5 * k / 7);
  }
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = _a(Colors.white, 0.45 * f, o),
  );
}

void _ocean(Canvas c, Size s, double t, double o) {
  const layers = 4;
  for (var k = 0; k < layers; k++) {
    final baseY = s.height * (0.60 + 0.085 * k);
    final amp = 9.0 + 6.0 * k;
    final wl = s.width * (0.95 - 0.13 * k);
    final speed = (0.30 + 0.12 * k) * (k.isEven ? 1 : -1);
    final path = Path()..moveTo(0, s.height);
    final crest = Path();
    for (var x = 0.0; x <= s.width + 8; x += 8) {
      final y = baseY +
          amp * math.sin(2 * math.pi * x / wl + t * speed * 2) +
          amp * 0.4 * math.sin(2 * math.pi * x / (wl * 0.45) - t * speed * 1.4 + k);
      path.lineTo(x, y);
      if (x == 0) {
        crest.moveTo(x, y);
      } else {
        crest.lineTo(x, y);
      }
    }
    path
      ..lineTo(s.width + 8, s.height)
      ..close();
    final color = Color.lerp(_water, _deepWater, k / (layers - 1))!;
    c.drawPath(path, Paint()..color = _a(color, 0.16 + 0.07 * k, o));
    if (k < 3) {
      c.drawPath(
        crest,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _a(_lavender, 0.20 - 0.04 * k, o),
      );
    }
  }
}

void _river(Canvas c, Size s, double t, double o) {
  final band = Rect.fromLTWH(0, s.height * 0.38, s.width, s.height * 0.62);
  c.drawRect(
    band,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_a(_water, 0.0, o), _a(_water, 0.18, o)],
      ).createShader(band),
  );
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 22; i++) {
    final y = s.height * (0.42 + 0.55 * hash01(i, 1));
    final near = (y / s.height - 0.4).clamp(0.0, 1.0).toDouble();
    final speed = 0.05 + 0.12 * near;
    final len = 40 + 110 * hash01(i, 3);
    final x0 = ((t * speed + hash01(i, 2)) % 1.0) * (s.width + len * 2) - len;
    final shimmer = 0.5 + 0.5 * math.sin(t * 1.8 + i);
    p
      ..strokeWidth = 0.8 + 1.4 * near
      ..color = _a(_ice, (0.08 + 0.22 * hash01(i, 4)) * (0.5 + 0.5 * shimmer), o);
    final path = Path()..moveTo(x0, y);
    for (var j = 1; j <= 8; j++) {
      final x = x0 + len * j / 8;
      path.lineTo(x, y + 3 * math.sin(x * 0.03 + t * 1.5 + i));
    }
    c.drawPath(path, p);
  }
}

void _forest(Canvas c, Size s, double t, double o) {
  // pine silhouettes
  final tree = Paint()..color = _a(const Color(0xFF070B24), 0.55, o);
  for (var i = 0; i < 9; i++) {
    final x = s.width * (i / 8) + (hash01(i, 1) - 0.5) * 30 + math.sin(t * 0.4 + i) * 1.5;
    final h = s.height * (0.20 + 0.18 * hash01(i, 2));
    final w = h * 0.38;
    final base = s.height;
    for (var tier = 0; tier < 3; tier++) {
      final top = base - h + tier * h * 0.22;
      final tw = w * (0.55 + 0.22 * tier);
      final bottom = base - h * 0.62 + tier * h * 0.34;
      c.drawPath(
        Path()
          ..moveTo(x, top)
          ..lineTo(x - tw, bottom)
          ..lineTo(x + tw, bottom)
          ..close(),
        tree,
      );
    }
  }
  // drifting leaves
  final lp = Paint();
  for (var i = 0; i < 10; i++) {
    final y = ((t * 0.05 * (0.6 + hash01(i, 4)) + hash01(i, 5)) % 1.0) * (s.height + 40) - 20;
    final x = hash01(i, 2) * s.width + math.sin(t * 0.9 + i) * 18;
    c.save();
    c.translate(x, y);
    c.rotate(t * (0.5 + hash01(i, 6)) + i);
    lp.color = _a(_leaf, 0.35 + 0.2 * hash01(i, 7), o);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 5), lp);
    c.restore();
  }
  // fireflies
  final fp = Paint();
  for (var i = 0; i < 16; i++) {
    final cx = hash01(i, 6) * s.width;
    final cy = s.height * (0.35 + 0.5 * hash01(i, 7));
    final x = cx + math.sin(t * (0.2 + 0.3 * hash01(i, 8)) + i) * 40;
    final y = cy + math.cos(t * (0.15 + 0.25 * hash01(i, 9)) + i * 2) * 28;
    final pulse = 0.5 + 0.5 * math.sin(t * (1 + hash01(i, 10) * 1.5) + i * 3);
    final pos = Offset(x, y);
    fp.color = _a(const Color(0xFFF4F0A0), 0.10 * pulse, o);
    c.drawCircle(pos, 10, fp);
    fp.color = _a(const Color(0xFFF4F0A0), 0.20 * pulse, o);
    c.drawCircle(pos, 5, fp);
    fp.color = _a(const Color(0xFFFFFBD0), 0.9 * pulse, o);
    c.drawCircle(pos, 1.8, fp);
  }
}

void _fire(Canvas c, Size s, double t, double o) {
  final flick = 0.8 + 0.12 * math.sin(t * 7) + 0.08 * math.sin(t * 13.3);
  final glowRect = Rect.fromLTWH(0, s.height * 0.45, s.width, s.height * 0.55);
  c.drawRect(
    glowRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.0),
        radius: 0.9,
        colors: [_a(const Color(0xFFFF7A3D), 0.36 * flick, o), _a(const Color(0xFFFF7A3D), 0.0, o)],
      ).createShader(glowRect),
  );
  final baseY = s.height * 0.92;
  for (var k = 0; k < 5; k++) {
    final center = s.width * (0.5 + (k - 2) * 0.09);
    final tall = 1.0 - 0.25 * (k - 2).abs();
    final f = 0.85 + 0.15 * math.sin(t * (5 + k * 1.3) + k) + 0.08 * math.sin(t * 11 + k * 2);
    final h = s.height * 0.26 * tall * f;
    final w = s.width * 0.10;
    final sway = math.sin(t * 3 + k) * w * 0.25;
    _flame(c, center, baseY, w, h, sway, _a(const Color(0xFFFF7A3D), 0.45, o));
    _flame(c, center, baseY, w * 0.55, h * 0.6, sway * 0.6, _a(const Color(0xFFFFD27A), 0.55, o));
  }
  final ep = Paint();
  for (var i = 0; i < 22; i++) {
    final prog = (t * (0.12 + 0.18 * hash01(i, 2)) + hash01(i, 3)) % 1.0;
    final x = s.width * (0.3 + 0.4 * hash01(i, 1)) + math.sin(t * 0.8 + i) * 14;
    final y = s.height * 0.9 - prog * s.height * 0.6;
    ep.color = _a(_ember, (1 - prog) * 0.9, o);
    c.drawCircle(Offset(x, y), 1 + 1.6 * hash01(i, 4), ep);
  }
}

void _flame(Canvas c, double x, double baseY, double w, double h, double sway, Color color) {
  final path = Path()
    ..moveTo(x - w / 2, baseY)
    ..quadraticBezierTo(x - w * 0.6, baseY - h * 0.5, x + sway, baseY - h)
    ..quadraticBezierTo(x + w * 0.6, baseY - h * 0.5, x + w / 2, baseY)
    ..close();
  c.drawPath(path, Paint()..color = color);
}

void _noise(Canvas c, Size s, double t, double o) {
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final center = Offset(s.width / 2, s.height * 0.46);
  final maxR = s.shortestSide * 0.55;
  for (var k = 0; k < 3; k++) {
    final ph = (t / 8 + k / 3) % 1.0;
    ring.color = _a(_lavender, (1 - ph) * 0.20, o);
    c.drawCircle(center, maxR * (0.35 + 0.65 * ph), ring);
  }
  final p = Paint();
  for (var i = 0; i < 60; i++) {
    final prog = (t * (0.012 + 0.03 * hash01(i, 2)) + hash01(i, 3)) % 1.0;
    final x = hash01(i, 1) * s.width + math.sin(t * 0.3 + i) * 10;
    final y = s.height - prog * s.height;
    final tw = 0.5 + 0.5 * math.sin(t * 0.8 + i * 1.7);
    p.color = _a(_lavender, (0.15 + 0.35 * hash01(i, 5)) * tw, o);
    c.drawCircle(Offset(x, y), 1 + 2.2 * hash01(i, 4), p);
  }
}

void _wind(Canvas c, Size s, double t, double o, double intensity) {
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6;
  final wisps = (6 + 8 * intensity).round();
  for (var i = 0; i < wisps; i++) {
    final y = s.height * (0.15 + 0.7 * hash01(i, 1));
    final x0 = ((t * (0.04 + 0.06 * hash01(i, 2)) + hash01(i, 3)) % 1.0) * (s.width + 280) - 200;
    p.color = _a(_ice, 0.10 + 0.12 * hash01(i, 4), o);
    final path = Path()..moveTo(x0, y);
    for (var j = 1; j <= 10; j++) {
      final x = x0 + 180 * j / 10;
      path.lineTo(x, y + 8 * math.sin(j * 0.7 + t * 0.9 + i));
    }
    c.drawPath(path, p);
  }
  final dp = Paint();
  for (var i = 0; i < 18; i++) {
    final x = ((t * (0.05 + 0.08 * hash01(i, 6)) + hash01(i, 7)) % 1.0) * (s.width + 40) - 20;
    final y = s.height * hash01(i, 8) + math.sin(t + i) * 8;
    dp.color = _a(_lavender, 0.2 + 0.25 * hash01(i, 9), o);
    c.drawCircle(Offset(x, y), 1 + 1.4 * hash01(i, 10), dp);
  }
}
