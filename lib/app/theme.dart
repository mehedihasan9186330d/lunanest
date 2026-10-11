import 'package:flutter/material.dart';

class LunaColors {
  static const navy = Color(0xFF0B1030);
  static const indigo = Color(0xFF181C4A);
  static const surface = Color(0xFF12163B);
  static const lavender = Color(0xFFB8A9FF);
  static const onLavender = Color(0xFF1A1340);
  static const text = Color(0xFFE8E9FF);
  static const muted = Color(0xFFA6A9D6);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: LunaColors.indigo, brightness: Brightness.dark).copyWith(
    primary: LunaColors.lavender,
    onPrimary: LunaColors.onLavender,
    secondary: const Color(0xFF8E9BFF),
    surface: LunaColors.surface,
    onSurface: LunaColors.text,
  );
  return _base(scheme, LunaColors.navy);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4B4FB8), brightness: Brightness.light);
  return _base(scheme, const Color(0xFFF5F4FF));
}

ThemeData _base(ColorScheme scheme, Color background) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withAlpha(60),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    visualDensity: VisualDensity.standard,
  );
}
