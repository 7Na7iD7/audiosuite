import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';

final class NoiseState {
  const NoiseState({
    this.color = NoiseColor.white,
    this.isPlaying = false,
    this.isLoading = false,
    this.volume = 0.6,
    this.timerTotal,
    this.remaining,
    this.error,
  });

  final NoiseColor color;
  final bool isPlaying;
  final bool isLoading;
  final double volume;
  final Duration? timerTotal;
  final Duration? remaining;
  final String? error;

  NoiseState copyWith({
    NoiseColor? color,
    bool? isPlaying,
    bool? isLoading,
    double? volume,
    Duration? timerTotal,
    Duration? remaining,
    String? error,
    bool clearTimer = false,
    bool clearError = false,
  }) {
    return NoiseState(
      color: color ?? this.color,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      volume: volume ?? this.volume,
      timerTotal: clearTimer ? null : (timerTotal ?? this.timerTotal),
      remaining: clearTimer ? null : (remaining ?? this.remaining),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
