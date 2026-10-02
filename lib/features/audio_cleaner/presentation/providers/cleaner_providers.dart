import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/features/audio_cleaner/data/datasources/cleaner_dsp_datasource.dart';
import 'package:audiosuite/features/audio_cleaner/data/datasources/playback_datasource.dart';
import 'package:audiosuite/features/audio_cleaner/data/datasources/recording_storage_datasource.dart';
import 'package:audiosuite/features/audio_cleaner/data/repositories/cleaner_repository_impl.dart';
import 'package:audiosuite/features/audio_cleaner/data/repositories/playback_repository_impl.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaner_state.dart';
import 'package:audiosuite/features/audio_cleaner/domain/repositories/cleaner_repository.dart';
import 'package:audiosuite/features/audio_cleaner/domain/repositories/playback_repository.dart';
import 'package:audiosuite/features/audio_cleaner/domain/usecases/cleaner_usecases.dart';
import 'package:audiosuite/features/audio_cleaner/presentation/controllers/cleaner_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cleanerRepositoryProvider = Provider<CleanerRepository>((ref) {
  return CleanerRepositoryImpl(
    ref.watch(audioManagerProvider),
    CleanerDspDataSource(),
    RecordingStorageDataSource(),
  );
});

final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  final dataSource = PlaybackDataSource();
  ref.onDispose(dataSource.dispose);
  return PlaybackRepositoryImpl(ref.watch(audioManagerProvider), dataSource);
});

final startCleaningProvider = Provider(
  (ref) => StartCleaningRecording(ref.watch(cleanerRepositoryProvider)),
);
final stopCleaningProvider = Provider(
  (ref) => StopCleaningRecording(ref.watch(cleanerRepositoryProvider)),
);
final cancelCleaningProvider = Provider(
  (ref) => CancelCleaningRecording(ref.watch(cleanerRepositoryProvider)),
);
final loadRecordingsProvider =
    Provider((ref) => LoadRecordings(ref.watch(cleanerRepositoryProvider)));
final deleteRecordingProvider =
    Provider((ref) => DeleteRecording(ref.watch(cleanerRepositoryProvider)));
final exportRecordingProvider =
    Provider((ref) => ExportRecording(ref.watch(cleanerRepositoryProvider)));
final togglePlaybackProvider =
    Provider((ref) => TogglePlayback(ref.watch(playbackRepositoryProvider)));
final stopPlaybackProvider =
    Provider((ref) => StopPlayback(ref.watch(playbackRepositoryProvider)));

final cleanerControllerProvider =
    NotifierProvider<CleanerController, CleanerState>(CleanerController.new);
