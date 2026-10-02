import 'dart:async';

import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_state.dart';
import 'package:audiosuite/features/noise_generator/presentation/providers/noise_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoiseController extends Notifier<NoiseState> {
  static const Duration _fadeOut = Duration(seconds: 8);

  Timer? _timer;
  DateTime? _deadline;
  StreamSubscription<bool>? _playingSubscription;

  @override
  NoiseState build() {
    _playingSubscription =
        ref.read(noiseRepositoryProvider).playingChanges.listen((playing) {
      if (!state.isLoading && state.isPlaying != playing) {
        state = state.copyWith(isPlaying: playing);
      }
    });
    ref.onDispose(() {
      _timer?.cancel();
      _playingSubscription?.cancel();
    });
    return const NoiseState();
  }

  Future<void> selectColor(NoiseColor color) async {
    if (color == state.color) return;
    final wasPlaying = state.isPlaying;
    state = state.copyWith(color: color);
    if (wasPlaying) await _start();
  }

  Future<void> toggle() => state.isPlaying ? pause() : _start();

  Future<void> pause() async {
    await ref.read(pauseNoiseProvider)();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> setVolume(double value) async {
    state = state.copyWith(volume: value);
    if (state.isPlaying) {
      await ref.read(setNoiseVolumeProvider)(value);
    }
  }

  void setSleepTimer(Duration? duration) {
    _timer?.cancel();
    _timer = null;
    if (duration == null) {
      _deadline = null;
      state = state.copyWith(clearTimer: true);
      if (state.isPlaying) {
        ref.read(setNoiseVolumeProvider)(state.volume);
      }
      return;
    }
    _deadline = DateTime.now().add(duration);
    state = state.copyWith(timerTotal: duration, remaining: duration);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _start() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(setNoiseVolumeProvider)(state.volume);
      await ref.read(playNoiseProvider)(state.color);
      state = state.copyWith(isLoading: false, isPlaying: true);
    } on AudioFailure catch (failure) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: AppStrings.errGeneric,
      );
    }
  }

  Future<void> _tick() async {
    final deadline = _deadline;
    if (deadline == null) return;
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      _timer = null;
      _deadline = null;
      await ref.read(stopNoiseProvider)();
      state = state.copyWith(isPlaying: false, clearTimer: true);
      return;
    }
    state = state.copyWith(remaining: remaining);
    if (state.isPlaying && remaining < _fadeOut) {
      final factor = remaining.inMilliseconds / _fadeOut.inMilliseconds;
      await ref.read(setNoiseVolumeProvider)(state.volume * factor);
    }
  }
}
