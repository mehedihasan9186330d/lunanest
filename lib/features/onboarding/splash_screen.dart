import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final done = ref.read(settingsProvider).onboardingDone;
      context.go(done ? '/home' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LunaColors.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [LunaColors.navy, LunaColors.indigo], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.nightlight_round, size: 72, color: LunaColors.lavender),
            SizedBox(height: 16),
            Text('LunaNest', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: LunaColors.text)),
            SizedBox(height: 8),
            Text('Find Your Calm. Drift Into Sleep.', style: TextStyle(color: LunaColors.muted)),
          ]),
        ),
      ),
    );
  }
}
