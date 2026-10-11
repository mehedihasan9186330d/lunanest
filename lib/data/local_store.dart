import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';

/// Thin persistence layer. Everything user-created stays on the device.
class LocalStore {
  LocalStore(this._p);
  final SharedPreferences _p;

  static const _fav = 'favorites';
  static const _recents = 'recents';
  static const _mixes = 'mixes';
  static const _settings = 'settings';
  static const _downloads = 'downloads_index';

  Set<String> get favorites => (_p.getStringList(_fav) ?? const <String>[]).toSet();
  Future<void> saveFavorites(Set<String> v) async => _p.setStringList(_fav, v.toList());

  List<String> get recents => _p.getStringList(_recents) ?? const <String>[];
  Future<void> saveRecents(List<String> v) async => _p.setStringList(_recents, v);

  List<Mix> get mixes {
    final out = <Mix>[];
    for (final raw in _p.getStringList(_mixes) ?? const <String>[]) {
      try {
        out.add(Mix.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map)));
      } catch (_) {/* skip corrupt entry */}
    }
    return out;
  }

  Future<void> saveMixes(List<Mix> v) async =>
      _p.setStringList(_mixes, v.map((m) => jsonEncode(m.toJson())).toList());

  AppSettings get settings {
    final raw = _p.getString(_settings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) async => _p.setString(_settings, jsonEncode(s.toJson()));

  Map<String, dynamic> get downloadsIndex {
    final raw = _p.getString(_downloads);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDownloadsIndex(Map<String, dynamic> v) async => _p.setString(_downloads, jsonEncode(v));

  Future<void> clearAll() async => _p.clear();
}
