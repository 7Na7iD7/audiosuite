import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/repositories/cleaner_repository.dart';
import 'package:audiosuite/features/audio_cleaner/domain/repositories/playback_repository.dart';

final class StartCleaningRecording {
  const StartCleaningRecording(this._repository);

  final CleanerRepository _repository;

  Future<Stream<double>> call({required double threshold}) =>
      _repository.startRecording(threshold: threshold);
}

final class StopCleaningRecording {
  const StopCleaningRecording(this._repository);

  final CleanerRepository _repository;

  Future<CleanedRecording> call() => _repository.stopRecording();
}

final class CancelCleaningRecording {
  const CancelCleaningRecording(this._repository);

  final CleanerRepository _repository;

  Future<void> call() => _repository.cancelRecording();
}

final class LoadRecordings {
  const LoadRecordings(this._repository);

  final CleanerRepository _repository;

  Future<List<CleanedRecording>> call() => _repository.loadRecordings();
}

final class DeleteRecording {
  const DeleteRecording(this._repository);

  final CleanerRepository _repository;

  Future<void> call(CleanedRecording recording) =>
      _repository.deleteRecording(recording);
}

final class ExportRecording {
  const ExportRecording(this._repository);

  final CleanerRepository _repository;

  Future<void> call(CleanedRecording recording) =>
      _repository.exportRecording(recording);
}

final class TogglePlayback {
  const TogglePlayback(this._repository);

  final PlaybackRepository _repository;

  Future<void> call(CleanedRecording recording) =>
      _repository.toggle(recording);
}

final class StopPlayback {
  const StopPlayback(this._repository);

  final PlaybackRepository _repository;

  Future<void> call() => _repository.stop();
}
