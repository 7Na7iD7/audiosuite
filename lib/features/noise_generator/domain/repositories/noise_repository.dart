import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';

abstract interface class NoiseRepository {
  Stream<bool> get playingChanges;

  Future<void> play(NoiseColor color);

  Future<void> pause();

  Future<void> stop();

  Future<void> setVolume(double volume);
}
