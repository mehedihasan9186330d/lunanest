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

TextTheme _typography(ColorScheme scheme) {
  // System font with refined weights/spacing. (No bundled custom font yet: it would
  // need a licensed font file added to assets/ and pubspec.yaml.)
  final t = ThemeData(brightness: scheme.brightness).textTheme;
  return t
      .copyWith(
        displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w200, letterSpacing: 1.0),
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.4, height: 1.15),
        headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.2, height: 1.2),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.1),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.15),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.2),
        labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
        bodyMedium: t.bodyMedium?.copyWith(height: 1.4),
        bodySmall: t.bodySmall?.copyWith(height: 1.35, letterSpacing: 0.2),
      )
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}

// Scaffolds are transparent: the NightSky backdrop (see app.dart) shows through.
ThemeData _base(ColorScheme scheme, Color background) {
  final text = _typography(scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface.withAlpha(240),
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
