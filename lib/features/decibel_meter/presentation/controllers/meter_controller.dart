import 'dart:async';
import 'dart:math' as math;

import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/features/decibel_meter/domain/entities/meter_state.dart';
import 'package:audiosuite/features/decibel_meter/presentation/providers/meter_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MeterController extends Notifier<MeterState> {
  StreamSubscription<double>? _subscription;
  double _sum = 0;
  int _count = 0;

  @override
  MeterState build() {
    final audio = ref.read(audioManagerProvider);
    audio.registerPreemptionHandler(AudioChannel.meter, stop);
    ref.onDispose(() {
      audio.unregisterPreemptionHandler(AudioChannel.meter);
      _subscription?.cancel();
    });
    return const MeterState();
  }

  Future<void> start() async {
    if (state.status != MeterStatus.idle) return;
    _sum = 0;
    _count = 0;
    state = const MeterState(status: MeterStatus.starting);
    try {
      final stream = await ref.read(startMeteringProvider)();
      _subscription = stream.listen(_onLevel, onError: _onError);
      state = state.copyWith(status: MeterStatus.running);
    } on AudioFailure catch (failure) {
      state = MeterState(error: failure.message);
    } catch (_) {
      state = const MeterState(error: AppStrings.errGeneric);
    }
  }

  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await ref.read(stopMeteringProvider)();
    state = state.copyWith(status: MeterStatus.idle);
  }

  Future<void> toggle() =>
      state.status == MeterStatus.running ? stop() : start();

  void reset() {
    _sum = 0;
    _count = 0;
    state = MeterState(status: state.status);
  }

  void _onLevel(double db) {
    _sum += db;
    _count++;
    final history = state.history.length >= AudioConstants.meterHistoryLength
        ? [...state.history.sublist(1), db]
        : [...state.history, db];
    state = state.copyWith(
      db: db,
      min: state.min == null ? db : math.min(state.min!, db),
      max: state.max == null ? db : math.max(state.max!, db),
      average: _sum / _count,
      history: history,
      clearError: true,
    );
  }

  void _onError(Object error) {
    state = state.copyWith(error: AppStrings.errDevice);
    stop();
  }
}
