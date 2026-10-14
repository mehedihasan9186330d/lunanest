import 'package:flutter/material.dart';

/// Translucent rounded card that lets the night sky show through.
/// (No BackdropFilter blur on purpose: it is expensive on mid-range phones.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: Material(
        color: dark ? Colors.white.withAlpha(16) : Colors.white.withAlpha(190),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(color: dark ? Colors.white.withAlpha(26) : const Color(0x1A4B4FB8)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
