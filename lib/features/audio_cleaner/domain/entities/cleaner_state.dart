import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/playback_snapshot.dart';

enum CleanerStatus { idle, starting, recording, saving }

final class CleanerState {
  const CleanerState({
    this.status = CleanerStatus.idle,
    this.level = -120,
    this.elapsed = Duration.zero,
    this.threshold = 0.5,
    this.recordings = const [],
    this.playback = const PlaybackSnapshot(),
    this.error,
    this.info,
  });

  final CleanerStatus status;
  final double level;
  final Duration elapsed;
  final double threshold;
  final List<CleanedRecording> recordings;
  final PlaybackSnapshot playback;
  final String? error;
  final String? info;

  bool get isRecording => status == CleanerStatus.recording;

  CleanerState copyWith({
    CleanerStatus? status,
    double? level,
    Duration? elapsed,
    double? threshold,
    List<CleanedRecording>? recordings,
    PlaybackSnapshot? playback,
    String? error,
    String? info,
    bool clearMessages = false,
  }) {
    return CleanerState(
      status: status ?? this.status,
      level: level ?? this.level,
      elapsed: elapsed ?? this.elapsed,
      threshold: threshold ?? this.threshold,
      recordings: recordings ?? this.recordings,
      playback: playback ?? this.playback,
      error: clearMessages ? null : (error ?? this.error),
      info: clearMessages ? null : (info ?? this.info),
    );
  }
}
