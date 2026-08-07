import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'api/ak_api.dart';
import 'models/ak_models.dart';

class DownloadItem {
  final String trackPath;
  final String savePath;
  final int total;
  final int received;
  final bool done;
  final String? error;

  DownloadItem({
    required this.trackPath,
    required this.savePath,
    required this.total,
    required this.received,
    required this.done,
    this.error,
  });

  double get progress => total > 0 ? received / total : 0;
}

class DownloadService extends ChangeNotifier {
  final AkApi api;
  final Dio _dio = Dio();
  final Map<String, DownloadItem> _items = {};
  final Map<String, CancelToken> _tokens = {};
  late Directory _baseDir;

  DownloadService(this.api);

  Directory get cacheDir => _baseDir;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _baseDir = Directory('${dir.path}/books');
    if (!await _baseDir.exists()) await _baseDir.create(recursive: true);
  }

  Map<String, DownloadItem> get items => Map.unmodifiable(_items);

  bool isBookDownloaded(String dir, List<AkTrack> tracks) {
    for (final t in tracks) {
      if (!File(_localPath(t.path)).existsSync()) return false;
    }
    return true;
  }

  String _localPath(String trackPath) => '${_baseDir.path}/$trackPath';

  String localPath(String trackPath) {
    final p = _localPath(trackPath);
    return File(p).existsSync() ? p : '';
  }

  Future<void> downloadTrack(String trackPath) async {
    if (_tokens.containsKey(trackPath)) return;
    final savePath = _localPath(trackPath);
    final saveDir = Directory(savePath.substring(0, savePath.lastIndexOf('/')));
    if (!await saveDir.exists()) await saveDir.create(recursive: true);
    final token = CancelToken();
    _tokens[trackPath] = token;
    _items[trackPath] = DownloadItem(trackPath: trackPath, savePath: savePath, total: 0, received: 0, done: false);
    notifyListeners();
    try {
      await _dio.downloadUri(api.streamUri(trackPath), savePath,
          cancelToken: token, onReceiveProgress: (r, t) {
        _items[trackPath] = DownloadItem(
            trackPath: trackPath, savePath: savePath, total: t, received: r, done: false);
        notifyListeners();
      });
      _items[trackPath] = DownloadItem(trackPath: trackPath, savePath: savePath, total: 1, received: 1, done: true);
    } catch (e) {
      _items[trackPath] = DownloadItem(
          trackPath: trackPath, savePath: savePath, total: 0, received: 0, done: false, error: '$e');
    } finally {
      _tokens.remove(trackPath);
      notifyListeners();
    }
  }

  Future<void> downloadBook(AkBook book, List<AkTrack> tracks) async {
    for (final t in tracks) {
      if (File(_localPath(t.path)).existsSync()) continue;
      await downloadTrack(t.path);
      if (_items[t.path]?.error != null) break;
    }
  }

  void cancelTrack(String trackPath) {
    _tokens[trackPath]?.cancel();
  }

  Future<void> deleteBook(String dir, List<AkTrack> tracks) async {
    for (final t in tracks) {
      final f = File(_localPath(t.path));
      if (await f.exists()) await f.delete();
    }
    _items.removeWhere((k, v) => tracks.any((t) => t.path == k));
    notifyListeners();
  }

  Future<String> downloadCover(String coverPath) async {
    if (coverPath.isEmpty) return '';
    final savePath = '${_baseDir.path}/covers/$coverPath';
    final f = File(savePath);
    if (await f.exists()) return savePath;
    final dir = f.parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    await _dio.download('${api.baseUrl}/$coverPath', savePath);
    return savePath;
  }

  Future<int> cacheSizeBytes() async {
    if (!await _baseDir.exists()) return 0;
    int total = 0;
    await for (final e in _baseDir.list(recursive: true, followLinks: false)) {
      if (e is File) {
        try {
          total += await e.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> clearCache() async {
    if (await _baseDir.exists()) await _baseDir.delete(recursive: true);
    await _baseDir.create(recursive: true);
    _items.clear();
    notifyListeners();
  }
}
