import 'package:audio_service/audio_service.dart';
import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/features/noise_generator/data/services/noise_audio_handler.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';

class NoisePlayerDataSource {
  NoisePlayerDataSource(this._handler);

  final NoiseAudioHandler _handler;

  Stream<bool> get playing =>
      _handler.playbackState.map((state) => state.playing).distinct();

  Future<void> load(String path, NoiseColor color) {
    final title = switch (color) {
      NoiseColor.white => AppStrings.white,
      NoiseColor.pink => AppStrings.pink,
      NoiseColor.brown => AppStrings.brown,
    };
    return _handler.load(
      path,
      MediaItem(
        id: path,
        title: title,
        artist: AppStrings.appName,
        album: AppStrings.noiseTitle,
      ),
    );
  }

  Future<void> play() => _handler.play();

  Future<void> pause() => _handler.pause();

  Future<void> stop() => _handler.stop();

  Future<void> setVolume(double volume) => _handler.setVolume(volume);
}
