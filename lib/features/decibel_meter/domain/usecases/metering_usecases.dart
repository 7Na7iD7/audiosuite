import 'package:audiosuite/features/decibel_meter/domain/repositories/decibel_repository.dart';

final class StartMetering {
  const StartMetering(this._repository);

  final DecibelRepository _repository;

  Future<Stream<double>> call() => _repository.start();
}

final class StopMetering {
  const StopMetering(this._repository);

  final DecibelRepository _repository;

  Future<void> call() => _repository.stop();
}
