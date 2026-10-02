import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';

abstract interface class CleanerRepository {
  Future<Stream<double>> startRecording({required double threshold});

  Future<CleanedRecording> stopRecording();

  Future<void> cancelRecording();

  Future<List<CleanedRecording>> loadRecordings();

  Future<void> deleteRecording(CleanedRecording recording);

  Future<void> exportRecording(CleanedRecording recording);
}
