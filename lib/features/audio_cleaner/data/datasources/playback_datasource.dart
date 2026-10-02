import 'dart:async';

import 'package:audiosuite/features/audio_cleaner/domain/entities/playback_snapshot.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackDataSource {
  PlaybackDataSource() {
    _subscriptions
      ..add(_player.playerStateStream.listen((_) => _emit()))
      ..add(_player.positionStream.listen((_) => _emit()))
      ..add(_player.durationStream.listen((_) => _emit()));
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<PlaybackSnapshot> _controller =
      StreamController<PlaybackSnapshot>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _path;

  Stream<PlaybackSnapshot> get snapshots => _controller.stream;

  bool isPlaying(String path) =>
      _path == path &&
      _player.playing &&
      _player.processingState != ProcessingState.completed;

  Future<void> play(String path) async {
    if (_path != path) {
      await _player.setFilePath(path);
      _path = path;
    }
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    _path = null;
    _emit();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _controller.close();
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(
      PlaybackSnapshot(
        path: _path,
        playing: _player.playing &&
            _player.processingState != ProcessingState.completed,
        position: _player.position,
        duration: _player.duration ?? Duration.zero,
      ),
    );
  }
}
