import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/audio/audio_manager.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/features/noise_generator/data/datasources/noise_player_datasource.dart';
import 'package:audiosuite/features/noise_generator/data/datasources/noise_synth_datasource.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';
import 'package:audiosuite/features/noise_generator/domain/repositories/noise_repository.dart';

class NoiseRepositoryImpl implements NoiseRepository {
  NoiseRepositoryImpl(this._audio, this._synth, this._player);

  final AudioManager _audio;
  final NoiseSynthDataSource _synth;
  final NoisePlayerDataSource _player;
  NoiseColor? _loaded;

  @override
  Stream<bool> get playingChanges => _player.playing;

  @override
  Future<void> play(NoiseColor color) async {
    try {
      await _audio.claim(AudioChannel.noisePlayback);
      if (_loaded != color) {
        final path = await _synth.ensureLoop(color);
        await _player.load(path, color);
        _loaded = color;
      }
      await _player.play();
    } on AudioFailure {
      rethrow;
    } catch (_) {
      _loaded = null;
      throw const AudioDeviceFailure();
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _loaded = null;
    await _player.stop();
    _audio.release(AudioChannel.noisePlayback);
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
}
