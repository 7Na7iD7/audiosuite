import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/features/decibel_meter/data/datasources/dsp_level_datasource.dart';
import 'package:audiosuite/features/decibel_meter/data/repositories/decibel_repository_impl.dart';
import 'package:audiosuite/features/decibel_meter/domain/entities/meter_state.dart';
import 'package:audiosuite/features/decibel_meter/domain/repositories/decibel_repository.dart';
import 'package:audiosuite/features/decibel_meter/domain/usecases/metering_usecases.dart';
import 'package:audiosuite/features/decibel_meter/presentation/controllers/meter_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final decibelRepositoryProvider = Provider<DecibelRepository>((ref) {
  return DecibelRepositoryImpl(
    ref.watch(audioManagerProvider),
    DspLevelDataSource(),
  );
});

final startMeteringProvider =
    Provider((ref) => StartMetering(ref.watch(decibelRepositoryProvider)));
final stopMeteringProvider =
    Provider((ref) => StopMetering(ref.watch(decibelRepositoryProvider)));

final meterControllerProvider =
    NotifierProvider<MeterController, MeterState>(MeterController.new);
