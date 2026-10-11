import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

final routerProvider = Provider<GoRouter>((ref) => buildRouter());

class LunaNestApp extends ConsumerWidget {
  const LunaNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'LunaNest',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
