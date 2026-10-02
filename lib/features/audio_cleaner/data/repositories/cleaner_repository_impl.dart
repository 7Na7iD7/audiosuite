import 'dart:async';
import 'dart:typed_data';

import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/audio/audio_manager.dart';
import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/features/audio_cleaner/data/datasources/cleaner_dsp_datasource.dart';
import 'package:audiosuite/features/audio_cleaner/data/datasources/recording_storage_datasource.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:audiosuite/features/audio_cleaner/domain/repositories/cleaner_repository.dart';
import 'package:audiosuite/src/rust/api/audio.dart' as rust;

class _Session {
  _Session({
    required this.denoiser,
    required this.levels,
    required this.done,
  });

  final rust.AudioDenoiser denoiser;
  final StreamController<double> levels;
  final Completer<void> done;
  final List<Float32List> parts = [];
  int total = 0;
  StreamSubscription<(double, Float32List)>? subscription;

  void append(Float32List samples) {
    if (samples.isEmpty) return;
    parts.add(samples);
    total += samples.length;
  }

  Float32List merge() {
    final out = Float32List(total);
    var offset = 0;
    for (final part in parts) {
      out.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return out;
  }
}

class CleanerRepositoryImpl implements CleanerRepository {
  CleanerRepositoryImpl(this._audio, this._dsp, this._storage);

  static const int _minSamples = AudioConstants.micSampleRate ~/ 3;

  final AudioManager _audio;
  final CleanerDspDataSource _dsp;
  final RecordingStorageDataSource _storage;
  _Session? _session;

  @override
  Future<Stream<double>> startRecording({required double threshold}) async {
    if (_session != null) throw const AudioDeviceFailure();
    final denoiser = await _dsp.createDenoiser(threshold);
    final Stream<Float32List> pcm;
    try {
      pcm = await _audio.openMicrophone(AudioChannel.cleanerRecording);
    } catch (_) {
      denoiser.dispose();
      rethrow;
    }
    final session = _Session(
      denoiser: denoiser,
      levels: StreamController<double>.broadcast(),
      done: Completer<void>(),
    );
    session.subscription = pcm.asyncMap((chunk) async {
      final level = await _dsp.level(chunk);
      final cleaned = await _dsp.process(denoiser, chunk);
      return (level, cleaned);
    }).listen(
      (result) {
        session.append(result.$2);
        if (!session.levels.isClosed) session.levels.add(result.$1);
      },
      onDone: () {
        if (!session.done.isCompleted) session.done.complete();
      },
      onError: (Object _) {
        if (!session.done.isCompleted) session.done.complete();
      },
    );
    _session = session;
    return session.levels.stream;
  }

  @override
  Future<CleanedRecording> stopRecording() async {
    final session = _session;
    if (session == null) throw const AudioDeviceFailure();
    _session = null;
    try {
      await _audio.closeMicrophone(AudioChannel.cleanerRecording);
      await session.done.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
      await session.subscription?.cancel();
      session.append(await _dsp.flush(session.denoiser));
      if (session.total < _minSamples) throw const RecordingTooShortFailure();
      final wav = await _dsp.encodeWav(session.merge());
      return await _storage.save(wav);
    } finally {
      await session.levels.close();
      session.denoiser.dispose();
    }
  }

  @override
  Future<void> cancelRecording() async {
    final session = _session;
    if (session == null) return;
    _session = null;
    await session.subscription?.cancel();
    await _audio.closeMicrophone(AudioChannel.cleanerRecording);
    await session.levels.close();
    session.denoiser.dispose();
  }

  @override
  Future<List<CleanedRecording>> loadRecordings() => _storage.list();

  @override
  Future<void> deleteRecording(CleanedRecording recording) =>
      _storage.delete(recording);

  @override
  Future<void> exportRecording(CleanedRecording recording) =>
      _storage.export(recording);
}
