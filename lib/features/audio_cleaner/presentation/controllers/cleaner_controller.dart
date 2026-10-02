import 'dart:async';

import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/di/providers.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/core/l10n/app_strings.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaner_state.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/playback_snapshot.dart';
import 'package:audiosuite/features/audio_cleaner/presentation/providers/cleaner_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CleanerController extends Notifier<CleanerState> {
  StreamSubscription<double>? _levelSubscription;
  StreamSubscription<PlaybackSnapshot>? _playbackSubscription;
  Timer? _clock;
  DateTime? _startedAt;

  @override
  CleanerState build() {
    final audio = ref.read(audioManagerProvider);
    audio.registerPreemptionHandler(
        AudioChannel.cleanerRecording, stopRecording);
    audio.registerPreemptionHandler(
      AudioChannel.cleanerPlayback,
      () => ref.read(stopPlaybackProvider)(),
    );
    _playbackSubscription =
        ref.read(playbackRepositoryProvider).snapshots.listen((snapshot) {
      state = state.copyWith(playback: snapshot);
    });
    ref.onDispose(() {
      audio.unregisterPreemptionHandler(AudioChannel.cleanerRecording);
      audio.unregisterPreemptionHandler(AudioChannel.cleanerPlayback);
      _clock?.cancel();
      _levelSubscription?.cancel();
      _playbackSubscription?.cancel();
    });
    Future.microtask(refresh);
    return const CleanerState();
  }

  Future<void> refresh() async {
    try {
      final items = await ref.read(loadRecordingsProvider)();
      state = state.copyWith(recordings: items);
    } on AudioFailure catch (failure) {
      state = state.copyWith(error: failure.message);
    }
  }

  void setThreshold(double value) {
    if (state.status != CleanerStatus.idle) return;
    state = state.copyWith(threshold: value);
  }

  Future<void> toggleRecording() =>
      state.isRecording ? stopRecording() : startRecording();

  Future<void> startRecording() async {
    if (state.status != CleanerStatus.idle) return;
    state = state.copyWith(
      status: CleanerStatus.starting,
      elapsed: Duration.zero,
      level: -120,
      clearMessages: true,
    );
    try {
      final levels = await ref.read(startCleaningProvider)(
        threshold: state.threshold,
      );
      _levelSubscription = levels.listen(
        (level) => state = state.copyWith(level: level),
      );
      _startedAt = DateTime.now();
      _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final started = _startedAt;
        if (started == null) return;
        final elapsed = DateTime.now().difference(started);
        state = state.copyWith(elapsed: elapsed);
        if (elapsed >= AudioConstants.maxRecording) stopRecording();
      });
      state = state.copyWith(status: CleanerStatus.recording);
    } on AudioFailure catch (failure) {
      state =
          state.copyWith(status: CleanerStatus.idle, error: failure.message);
    } catch (_) {
      state = state.copyWith(
        status: CleanerStatus.idle,
        error: AppStrings.errGeneric,
      );
    }
  }

  Future<void> stopRecording() async {
    if (state.status != CleanerStatus.recording) return;
    state = state.copyWith(status: CleanerStatus.saving);
    _clock?.cancel();
    _clock = null;
    _startedAt = null;
    final levelSubscription = _levelSubscription;
    _levelSubscription = null;
    await levelSubscription?.cancel();
    try {
      await ref.read(stopCleaningProvider)();
      final items = await ref.read(loadRecordingsProvider)();
      state = state.copyWith(
        status: CleanerStatus.idle,
        recordings: items,
        level: -120,
        info: AppStrings.saved,
      );
    } on AudioFailure catch (failure) {
      state = state.copyWith(
        status: CleanerStatus.idle,
        level: -120,
        error: failure.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: CleanerStatus.idle,
        level: -120,
        error: AppStrings.errGeneric,
      );
    }
  }

  Future<void> cancelRecording() async {
    if (state.status != CleanerStatus.recording) return;
    _clock?.cancel();
    _clock = null;
    _startedAt = null;
    await _levelSubscription?.cancel();
    _levelSubscription = null;
    await ref.read(cancelCleaningProvider)();
    state = state.copyWith(status: CleanerStatus.idle, level: -120);
  }

  Future<void> togglePlayback(CleanedRecording recording) async {
    try {
      await ref.read(togglePlaybackProvider)(recording);
    } on AudioFailure catch (failure) {
      state = state.copyWith(error: failure.message);
    }
  }

  Future<void> delete(CleanedRecording recording) async {
    try {
      if (state.playback.path == recording.path) {
        await ref.read(stopPlaybackProvider)();
      }
      await ref.read(deleteRecordingProvider)(recording);
      await refresh();
    } on AudioFailure catch (failure) {
      state = state.copyWith(error: failure.message);
    }
  }

  Future<void> export(CleanedRecording recording) async {
    try {
      await ref.read(exportRecordingProvider)(recording);
    } catch (_) {
      state = state.copyWith(error: AppStrings.errStorage);
    }
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
}
