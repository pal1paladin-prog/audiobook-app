import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ak_models.dart';
import '../api/ak_api.dart';
import '../ui/app_toast.dart';
import 'download_service.dart';
import 'audio_handler.dart';

/// Плеер поверх just_audio + audio_service.
///
/// Треки книги загружаются одним [ConcatenatingAudioSource]-плейлистом: на iOS
/// переход между треками выполняется нативно (без остановки/старта с Dart-стороны),
/// поэтому аудио-сессия не деактивируется и в фоне звук не пропадает.
class PlayerService extends ChangeNotifier {
  static const _prefBook = 'lastBookPath';
  static const _prefIndex = 'lastTrackIndex';
  static const _prefPos = 'lastPositionSec';
  static const _prefPlaying = 'lastWasPlaying';

  final AkAudioHandler handler;
  final AkApi api;
  final DownloadService downloads;

  List<AkTrack> _queue = [];
  int _index = -1;
  int _lastRestoredIndex = -1;
  AkBook? _currentBook;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  Timer? _saveTimer;

  PlayerService(this.api, this.downloads, this.handler) {
    handler.onNext = next;
    handler.onPrev = prev;
    handler.onFastForward = () => skip30(30);
    handler.onRewind = () => skip30(-30);
  }

  AudioPlayer get _player => handler.player;

  List<AkTrack> get queue => _queue;
  int get index => _index;
  AkBook? get currentBook => _currentBook;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get playing => _playing;
  bool get hasTrack => _index >= 0 && _index < _queue.length;
  AkTrack? get currentTrack => hasTrack ? _queue[_index] : null;

  AudioPlayer get raw => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  Uri _trackUri(String trackPath) {
    final local = downloads.localPath(trackPath);
    return local.isNotEmpty ? Uri.file(local) : api.streamUri(trackPath);
  }

  List<AudioSource> _buildSources(List<AkTrack> tracks) =>
      [for (final t in tracks) AudioSource.uri(_trackUri(t.path))];

  Future<void> playBook(AkBook book, List<AkTrack> tracks, {int startIndex = 0}) async {
    _currentBook = book;
    _queue = tracks;
    if (tracks.isEmpty) return;
    final index = startIndex.clamp(0, tracks.length - 1);
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      await _player.setAudioSource(ConcatenatingAudioSource(
        children: _buildSources(tracks),
        useLazyPreparation: true,
      ), initialIndex: index);
      _updateMediaItem();
      await _player.play();
      _startSaving();
      saveState();
    } catch (e) {
      showToast('Не удалось воспроизвести «${book.title}»', error: true);
    }
    notifyListeners();
  }

  Future<void> _restoreProgress(String trackPath) async {
    try {
      final saved = await api.getProgress(trackPath);
      if (saved != null && saved > 2 && _player.duration != null) {
        await _player.seek(Duration(seconds: saved.round()));
      }
    } catch (_) {}
  }

  Future<void> playIndex(int i) async {
    if (i < 0 || i >= _queue.length) return;
    if (i == _index) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seek(Duration.zero, index: i);
    }
  }

  void _updateMediaItem() {
    final track = currentTrack;
    final book = _currentBook;
    if (track == null) return;
    Uri? art;
    final cover = book?.coverPath ?? '';
    if (cover.isNotEmpty) art = api.coverUri(cover);
    final author = book?.author;
    handler.mediaItem.add(MediaItem(
      id: track.path,
      title: track.name,
      artist: (author != null && author.isNotEmpty) ? author : null,
      album: book?.title,
      artUri: art,
    ));
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      final session = await AudioSession.instance;
      await session.setActive(true);
      await _player.play();
      _startSaving();
    }
    saveState();
    notifyListeners();
  }

  Future<void> next() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> prev() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration p) => _player.seek(p);

  Future<void> skip30(int seconds) async {
    final target = _player.position + Duration(seconds: seconds);
    final max = _player.duration ?? Duration.zero;
    await _player.seek(target > max ? max : target < Duration.zero ? Duration.zero : target);
  }

  Future<void> setSpeed(double s) => _player.setSpeed(s);

  void saveProgress() {
    if (!hasTrack) return;
    final t = currentTrack!;
    unawaited(api.saveProgress(t.path, _player.position.inSeconds.toDouble(),
        dur: _player.duration?.inSeconds.toDouble()).catchError((_) => null));
  }

  Future<void> saveState() async {
    if (!hasTrack) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefBook, _currentBook?.path ?? '');
      await p.setInt(_prefIndex, _index);
      await p.setDouble(_prefPos, _player.position.inSeconds.toDouble());
      await p.setBool(_prefPlaying, _player.playing);
    } catch (_) {}
    saveProgress();
  }

  void _startSaving() {
    _saveTimer ??= Timer.periodic(const Duration(seconds: 15), (_) => saveState());
  }

  /// Восстанавливает последний проигрываемый трек после перезапуска приложения.
  Future<void> restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final bookPath = p.getString(_prefBook) ?? '';
      if (bookPath.isEmpty) return;
      final books = await api.books();
      final book = books.where((b) => b.path == bookPath).toList();
      if (book.isEmpty) return;
      final tracks = await api.bookTracks(bookPath);
      if (tracks.isEmpty) return;
      final index = (p.getInt(_prefIndex) ?? 0).clamp(0, tracks.length - 1);
      final pos = p.getDouble(_prefPos) ?? 0;
      _currentBook = book.first;
      _queue = tracks;
      _index = index;
      await _player.setAudioSource(ConcatenatingAudioSource(
        children: _buildSources(tracks),
        useLazyPreparation: true,
      ), initialIndex: index);
      _updateMediaItem();
      _lastRestoredIndex = index;
      if (pos > 2 && _player.duration != null) {
        await _player.seek(Duration(seconds: pos.round()));
      }
      if (p.getBool(_prefPlaying) ?? false) {
        final session = await AudioSession.instance;
        await session.setActive(true);
        await _player.play();
        _startSaving();
      }
      notifyListeners();
    } catch (_) {}
  }

  void listen() {
    _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });
    _player.currentIndexStream.listen((idx) {
      if (idx == null || idx < 0 || idx >= _queue.length) return;
      _index = idx;
      _updateMediaItem();
      notifyListeners();
    });
    _player.playerStateStream.listen((s) {
      _playing = s.playing;
      if (s.processingState == ProcessingState.ready && _lastRestoredIndex != _index) {
        _lastRestoredIndex = _index;
        if (currentTrack != null) {
          _restoreProgress(currentTrack!.path);
        }
      }
      if (s.processingState == ProcessingState.completed && !_player.hasNext) {
        saveProgress();
        unawaited(_player.pause());
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    saveState();
    _player.dispose();
    super.dispose();
  }
}
