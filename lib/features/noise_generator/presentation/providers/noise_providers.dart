import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/features/noise_generator/data/datasources/noise_player_datasource.dart';
import 'package:audiosuite/features/noise_generator/data/datasources/noise_synth_datasource.dart';
import 'package:audiosuite/features/noise_generator/data/repositories/noise_repository_impl.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_state.dart';
import 'package:audiosuite/features/noise_generator/domain/repositories/noise_repository.dart';
import 'package:audiosuite/features/noise_generator/domain/usecases/noise_usecases.dart';
import 'package:audiosuite/features/noise_generator/presentation/controllers/noise_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final noiseRepositoryProvider = Provider<NoiseRepository>((ref) {
  return NoiseRepositoryImpl(
    ref.watch(audioManagerProvider),
    NoiseSynthDataSource(),
    NoisePlayerDataSource(ref.watch(noiseAudioHandlerProvider)),
  );
});

final playNoiseProvider =
    Provider((ref) => PlayNoise(ref.watch(noiseRepositoryProvider)));
final pauseNoiseProvider =
    Provider((ref) => PauseNoise(ref.watch(noiseRepositoryProvider)));
final stopNoiseProvider =
    Provider((ref) => StopNoise(ref.watch(noiseRepositoryProvider)));
final setNoiseVolumeProvider =
    Provider((ref) => SetNoiseVolume(ref.watch(noiseRepositoryProvider)));

final noiseControllerProvider =
    NotifierProvider<NoiseController, NoiseState>(NoiseController.new);
