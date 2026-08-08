import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// AudioHandler для audio_service: фоновое воспроизведение на iOS/Android
/// и кнопки на экране блокировки / в шторке (now playing).
class AkAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();
  VoidCallback? onNext;
  VoidCallback? onPrev;
  VoidCallback? onFastForward;
  VoidCallback? onRewind;

  AkAudioHandler() {
    _initSession();
    player.playbackEventStream.listen(_broadcastState);
  }

  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (_) {}
    _broadcastState(player.playbackEvent);
  }

  static const _processingMap = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.pause,
        MediaAction.play,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _processingMap[event.processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    ));
  }

  @override
  Future<void> play() async => player.play();

  @override
  Future<void> pause() async => player.pause();

  @override
  Future<void> seek(Duration position) async => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async => player.setSpeed(speed);

  @override
  Future<void> skipToNext() async => onNext?.call();

  @override
  Future<void> skipToPrevious() async => onPrev?.call();

  @override
  Future<void> fastForward() async => onFastForward?.call();

  @override
  Future<void> rewind() async => onRewind?.call();

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async => onNext?.call();
}
