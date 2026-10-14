import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'scene_kind.dart';
import 'scene_painters.dart';

/// Draws one or more animated scene layers. Pass `animate: false` for a static
/// thumbnail (no ticker running) or while audio is paused. Honors the system
/// "reduce motion" setting and stops automatically when the widget is hidden
/// (TickerMode), so inactive tabs cost nothing.
class SceneView extends StatefulWidget {
  const SceneView({super.key, required this.layers, this.animate = true, this.seedTime = 3.0});
  final List<SceneLayer> layers;
  final bool animate;
  final double seedTime;

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _t = ValueNotifier<double>(widget.seedTime);
  late final Ticker _ticker = createTicker(_onTick);
  double _base = 0;
  bool _reduceMotion = false;

  void _onTick(Duration d) => _t.value = _base + d.inMicroseconds / 1e6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    _sync();
  }

  @override
  void didUpdateWidget(SceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final want = widget.animate && !_reduceMotion;
    if (want && !_ticker.isActive) {
      _base = _t.value;
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
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ScenePainter(widget.layers, _t),
        size: Size.infinite,
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.layers, this.time) : super(repaint: time);
  final List<SceneLayer> layers;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final l in layers) {
      paintScene(canvas, size, t, l);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.layers != layers;
}
