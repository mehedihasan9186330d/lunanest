import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/night_sky.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class LunaNestApp extends ConsumerStatefulWidget {
  const LunaNestApp({super.key});
  @override
  ConsumerState<LunaNestApp> createState() => _LunaNestAppState();
}

class _LunaNestAppState extends ConsumerState<LunaNestApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the store/another app: pick up renewals, expiry or restores.
    if (state == AppLifecycleState.resumed) {
      ref.read(billingProvider).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'LunaNest',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => NightSky(child: child ?? const SizedBox.shrink()),
    );
  }
}
