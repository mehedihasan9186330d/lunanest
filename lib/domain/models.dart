import 'package:flutter/material.dart' show ThemeMode;

class SoundCategory {
  const SoundCategory({required this.id, required this.title});
  final String id;
  final String title;
  factory SoundCategory.fromJson(Map<String, dynamic> j) =>
      SoundCategory(id: j['id'] as String, title: j['title'] as String);
}

class Sound {
  const Sound({
    required this.id,
    required this.title,
    required this.categoryId,
    this.assetPath,
    this.url,
    this.premium = false,
    this.offlineAllowed = false,
    this.license = '',
  });

  final String id;
  final String title;
  final String categoryId;
  final String? assetPath; // bundled in the app
  final String? url; // HTTPS stream / download source
  final bool premium;
  final bool offlineAllowed; // license permits offline copies
  final String license;

  /// Never list a sound that has nothing to play.
  bool get isPlayable => assetPath != null || url != null;
  bool get canDownload => offlineAllowed && url != null && url!.startsWith('https://');

  factory Sound.fromJson(Map<String, dynamic> j) => Sound(
        id: j['id'] as String,
        title: j['title'] as String,
        categoryId: j['category'] as String,
        assetPath: j['asset'] as String?,
        url: j['url'] as String?,
        premium: j['premium'] as bool? ?? false,
        offlineAllowed: j['offlineAllowed'] as bool? ?? false,
        license: j['license'] as String? ?? '',
      );
}

class MixLayer {
  const MixLayer(this.soundId, this.volume);
  final String soundId;
  final double volume;
  Map<String, dynamic> toJson() => {'soundId': soundId, 'volume': volume};
  factory MixLayer.fromJson(Map<String, dynamic> j) =>
      MixLayer(j['soundId'] as String, (j['volume'] as num).toDouble());
}

class Mix {
  const Mix({required this.id, required this.name, required this.layers, this.isPreset = false});
  final String id;
  final String name;
  final List<MixLayer> layers;
  final bool isPreset;

  Mix copyWith({String? name}) => Mix(id: id, name: name ?? this.name, layers: layers, isPreset: isPreset);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'layers': layers.map((l) => l.toJson()).toList()};

  factory Mix.fromJson(Map<String, dynamic> j, {bool isPreset = false}) => Mix(
        id: j['id'] as String,
        name: j['name'] as String,
        layers: (j['layers'] as List)
            .map((e) => MixLayer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        isPreset: isPreset,
      );
}

/// "Start this mix and this sleep timer together" – one tap at bedtime.
class BedtimeRoutine {
  const BedtimeRoutine({required this.mixId, required this.minutes});
  final String mixId; // a preset id or a saved mix id
  final int minutes;
  Map<String, dynamic> toJson() => {'mixId': mixId, 'minutes': minutes};
  factory BedtimeRoutine.fromJson(Map<String, dynamic> j) =>
      BedtimeRoutine(mixId: j['mixId'] as String, minutes: (j['minutes'] as num).toInt());
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.fadeSeconds = 20,
    this.defaultTimerMinutes = 30,
    this.onboardingDone = false,
  });

  final ThemeMode themeMode;
  final int fadeSeconds;
  final int defaultTimerMinutes;
  final bool onboardingDone;

  AppSettings copyWith({ThemeMode? themeMode, int? fadeSeconds, int? defaultTimerMinutes, bool? onboardingDone}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        fadeSeconds: fadeSeconds ?? this.fadeSeconds,
        defaultTimerMinutes: defaultTimerMinutes ?? this.defaultTimerMinutes,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'fadeSeconds': fadeSeconds,
        'defaultTimerMinutes': defaultTimerMinutes,
        'onboardingDone': onboardingDone,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: ThemeMode.values.firstWhere((m) => m.name == j['themeMode'], orElse: () => ThemeMode.dark),
        fadeSeconds: (j['fadeSeconds'] as num?)?.toInt() ?? 20,
        defaultTimerMinutes: (j['defaultTimerMinutes'] as num?)?.toInt() ?? 30,
        onboardingDone: j['onboardingDone'] as bool? ?? false,
      );
}

class Catalog {
  const Catalog({required this.categories, required this.sounds, required this.presets});
  final List<SoundCategory> categories;
  final List<Sound> sounds;
  final List<Mix> presets;

  Sound? sound(String id) {
    for (final s in sounds) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Sound> inCategory(String categoryId) => sounds.where((s) => s.categoryId == categoryId).toList();

  SoundCategory? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// A mix needs Premium if any of its sounds does.
  bool mixNeedsPremium(Mix m) => m.layers.any((l) => sound(l.soundId)?.premium ?? false);

  factory Catalog.fromJson(Map<String, dynamic> j) {
    final cats = (j['categories'] as List).map((e) => SoundCategory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final sounds = (j['sounds'] as List)
        .map((e) => Sound.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((s) => s.isPlayable)
        .toList();
    final ids = sounds.map((s) => s.id).toSet();
    final presets = ((j['presets'] as List?) ?? const [])
        .map((e) => Mix.fromJson(Map<String, dynamic>.from(e as Map), isPreset: true))
        .where((m) => m.layers.isNotEmpty && m.layers.every((l) => ids.contains(l.soundId)))
        .toList();
    return Catalog(categories: cats, sounds: sounds, presets: presets);
  }
}
