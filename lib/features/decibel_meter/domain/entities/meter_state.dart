enum MeterStatus { idle, starting, running }

final class MeterState {
  const MeterState({
    this.status = MeterStatus.idle,
    this.db = 0,
    this.min,
    this.max,
    this.average,
    this.history = const [],
    this.error,
  });

  final MeterStatus status;
  final double db;
  final double? min;
  final double? max;
  final double? average;
  final List<double> history;
  final String? error;

  bool get isRunning => status == MeterStatus.running;

  MeterState copyWith({
    MeterStatus? status,
    double? db,
    double? min,
    double? max,
    double? average,
    List<double>? history,
    String? error,
    bool clearError = false,
  }) {
    return MeterState(
      status: status ?? this.status,
      db: db ?? this.db,
      min: min ?? this.min,
      max: max ?? this.max,
      average: average ?? this.average,
      history: history ?? this.history,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
