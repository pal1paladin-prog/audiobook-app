import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/ak_models.dart';
import '../api/ak_api.dart';
import 'download_service.dart';
import 'audio_handler.dart';

class PlayerService extends ChangeNotifier {
  final AkAudioHandler handler;
  final AkApi api;
  final DownloadService downloads;

  List<AkTrack> _queue = [];
  int _index = -1;
  AkBook? _currentBook;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;

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

  Future<void> playBook(AkBook book, List<AkTrack> tracks, {int startIndex = 0}) async {
    _currentBook = book;
    _queue = tracks;
    await _playIndex(startIndex);
  }

  Future<void> _playIndex(int i) async {
    if (i < 0 || i >= _queue.length) return;
    _index = i;
    final track = _queue[i];
    final local = downloads.localPath(track.path);
    final uri = local.isNotEmpty ? Uri.file(local) : api.streamUri(track.path);
    await _player.setUrl(uri.toString());
    _updateMediaItem();
    final saved = await api.getProgress(track.path);
    if (saved != null && saved > 2) {
      await _player.seek(Duration(seconds: saved.round()));
    }
    await _player.play();
    notifyListeners();
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
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_index < _queue.length - 1) await _playIndex(_index + 1);
  }

  Future<void> prev() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_index > 0) {
      await _playIndex(_index - 1);
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
    api.saveProgress(currentTrack!.path, _player.position.inSeconds.toDouble(),
        dur: _player.duration?.inSeconds.toDouble());
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
    _player.playerStateStream.listen((s) {
      _playing = s.playing;
      if (s.processingState == ProcessingState.completed) {
        next();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    saveProgress();
    _player.dispose();
    super.dispose();
  }
}
