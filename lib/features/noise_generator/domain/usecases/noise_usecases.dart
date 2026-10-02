import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';
import 'package:audiosuite/features/noise_generator/domain/repositories/noise_repository.dart';

final class PlayNoise {
  const PlayNoise(this._repository);

  final NoiseRepository _repository;

  Future<void> call(NoiseColor color) => _repository.play(color);
}

final class PauseNoise {
  const PauseNoise(this._repository);

  final NoiseRepository _repository;

  Future<void> call() => _repository.pause();
}

final class StopNoise {
  const StopNoise(this._repository);

  final NoiseRepository _repository;

  Future<void> call() => _repository.stop();
}

final class SetNoiseVolume {
  const SetNoiseVolume(this._repository);

  final NoiseRepository _repository;

  Future<void> call(double volume) =>
      _repository.setVolume(volume.clamp(0.0, 1.0));
}
