import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/audio/audio_manager.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/features/audio_cleaner/data/datasources/playback_datasource.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/playback_snapshot.dart';
import 'package:audiosuite/features/audio_cleaner/domain/repositories/playback_repository.dart';

class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl(this._audio, this._player);

  final AudioManager _audio;
  final PlaybackDataSource _player;

  @override
  Stream<PlaybackSnapshot> get snapshots => _player.snapshots;

  @override
  Future<void> toggle(CleanedRecording recording) async {
    try {
      if (_player.isPlaying(recording.path)) {
        await _player.pause();
        _audio.release(AudioChannel.cleanerPlayback);
        return;
      }
      await _audio.claim(AudioChannel.cleanerPlayback);
      await _player.play(recording.path);
    } on AudioFailure {
      rethrow;
    } catch (_) {
      _audio.release(AudioChannel.cleanerPlayback);
      throw const AudioDeviceFailure();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _audio.release(AudioChannel.cleanerPlayback);
  }
}
