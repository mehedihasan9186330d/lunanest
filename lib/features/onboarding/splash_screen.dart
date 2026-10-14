import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../ui/moon.dart';
import '../../ui/night_sky.dart';

/// Branded splash: moon rises and glows, name and tagline fade in. Static for
/// reduced motion. Navigates to onboarding (first run) or Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _c.value = 1;
    } else {
      _c.forward();
    }
    Future<void>.delayed(Duration(milliseconds: reduce ? 700 : 2100), () {
      if (!mounted) return;
      final done = ref.read(settingsProvider).onboardingDone;
      context.go(done ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moon = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic));
    final title = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.8, curve: Curves.easeOut));
    final tag = CurvedAnimation(parent: _c, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));
    return NightSky(
      forceDark: true,
      child: Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: moon,
              builder: (context, _) => Opacity(
                opacity: moon.value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - moon.value)),
                  child: MoonMark(size: 150, glow: moon.value),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: title,
              child: const Text('LunaNest',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w200, letterSpacing: 6, color: Color(0xFFE8E9FF))),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: tag,
              child: const Text('Find Your Calm. Drift Into Sleep.',
                  style: TextStyle(color: Color(0xFFA6A9D6), letterSpacing: 0.8)),
            ),
          ]),
        ),
      ),
    );
  }
}
