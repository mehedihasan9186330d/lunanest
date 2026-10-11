import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local_store.dart';
import '../../domain/models.dart';

class DownloadProgress {
  const DownloadProgress({this.received = 0, this.total = 0, this.failed = false, this.error});
  final int received;
  final int total;
  final bool failed;
  final String? error;
  double? get fraction => total > 0 ? received / total : null;
}

class _Entry {
  _Entry(this.path, this.bytes);
  final String path;
  final int bytes;
}

/// Downloads licensed audio into app-private storage (HTTPS only).
/// Only sounds with `offlineAllowed: true` and an `https` url are downloadable.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this._store, {Dio? dio}) : _dio = dio ?? Dio();

  final LocalStore _store;
  final Dio _dio;
  final Map<String, _Entry> _done = {};
  final Map<String, DownloadProgress> _active = {};
  final Map<String, CancelToken> _tokens = {};

  Future<void> load() async {
    var pruned = false;
    for (final e in _store.downloadsIndex.entries) {
      final v = Map<String, dynamic>.from(e.value as Map);
      final path = v['path'] as String;
      if (File(path).existsSync()) {
        _done[e.key] = _Entry(path, (v['bytes'] as num).toInt());
      } else {
        pruned = true;
      }
    }
    if (pruned) await _persist();
  }

  String? localPath(String soundId) => _done[soundId]?.path;
  bool isDownloaded(String id) => _done.containsKey(id);
  DownloadProgress? progress(String id) => _active[id];
  int get downloadedCount => _done.length;
  int get totalBytes => _done.values.fold(0, (a, e) => a + e.bytes);

  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/audio');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<void> download(Sound s) async {
    final url = s.url;
    if (url == null || !s.canDownload || _active.containsKey(s.id) || isDownloaded(s.id)) return;
    final token = CancelToken();
    _tokens[s.id] = token;
    _active[s.id] = const DownloadProgress();
    notifyListeners();

    String? part;
    var lastPct = -1;
    try {
      final dir = await _dir();
      final ext = _extension(url);
      final target = '${dir.path}/${s.id}$ext';
      part = '$target.part';
      await _dio.download(
        url,
        part,
        cancelToken: token,
        deleteOnError: true,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
        onReceiveProgress: (r, t) {
          final pct = t > 0 ? (r * 100 ~/ t) : -1;
          if (pct != lastPct) {
            lastPct = pct;
            _active[s.id] = DownloadProgress(received: r, total: t);
            notifyListeners();
          }
        },
      );
      await File(part).rename(target);
      _done[s.id] = _Entry(target, await File(target).length());
      _active.remove(s.id);
      await _persist();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _active.remove(s.id);
      } else {
        _active[s.id] = DownloadProgress(failed: true, error: _describe(e));
      }
      await _deleteQuietly(part);
    } on FileSystemException catch (e) {
      final noSpace = e.osError?.errorCode == 28 || e.message.toLowerCase().contains('no space');
      _active[s.id] = DownloadProgress(
          failed: true, error: noSpace ? 'Not enough storage space. Free some space and retry.' : 'Could not save the file.');
      await _deleteQuietly(part);
    } finally {
      _tokens.remove(s.id);
      notifyListeners();
    }
  }

  void cancel(String id) => _tokens[id]?.cancel('cancelled by user');

  void dismissError(String id) {
    if (_active[id]?.failed ?? false) {
      _active.remove(id);
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    final e = _done.remove(id);
    if (e != null) await _deleteQuietly(e.path);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    for (final id in _done.keys.toList()) {
      await delete(id);
    }
  }

  Future<void> _persist() => _store.saveDownloadsIndex({
        for (final e in _done.entries) e.key: {'path': e.value.path, 'bytes': e.value.bytes}
      });

  Future<void> _deleteQuietly(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }

  String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    final ext = dot >= 0 ? path.substring(dot) : '';
    return const {'.mp3', '.m4a', '.aac', '.ogg', '.wav', '.flac'}.contains(ext) ? ext : '.mp3';
  }

  String _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return 'No connection or the server timed out. Check your internet and retry.';
      case DioExceptionType.badResponse:
        return 'The server returned an error (${e.response?.statusCode}).';
      default:
        return 'Download failed. Please retry.';
    }
  }
}
