import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class NoiseAudioHandler extends BaseAudioHandler {
  NoiseAudioHandler() {
    _player.playbackEventStream.map(_toPlaybackState).pipe(playbackState);
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> load(String path, MediaItem item) async {
    mediaItem.add(item);
    await _player.setFilePath(path);
    await _player.setLoopMode(LoopMode.one);
  }

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  PlaybackState _toPlaybackState(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
