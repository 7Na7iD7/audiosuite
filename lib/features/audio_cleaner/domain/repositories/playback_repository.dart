import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/playback_snapshot.dart';

abstract interface class PlaybackRepository {
  Stream<PlaybackSnapshot> get snapshots;

  Future<void> toggle(CleanedRecording recording);

  Future<void> stop();
}
