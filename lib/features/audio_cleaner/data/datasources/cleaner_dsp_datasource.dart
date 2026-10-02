import 'dart:typed_data';

import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/src/rust/api/audio.dart' as rust;

class CleanerDspDataSource {
  Future<rust.AudioDenoiser> createDenoiser(double threshold) {
    return rust.createDenoiser(
      sampleRate: AudioConstants.micSampleRate,
      noiseThreshold: threshold,
    );
  }

  Future<Float32List> process(rust.AudioDenoiser denoiser, Float32List chunk) {
    return denoiser.process(buffer: chunk);
  }

  Future<Float32List> flush(rust.AudioDenoiser denoiser) => denoiser.flush();

  Future<double> level(Float32List chunk) => rust.calculateDb(buffer: chunk);

  Future<Uint8List> encodeWav(Float32List samples) {
    return rust.encodeWav(
      samples: samples,
      sampleRate: AudioConstants.micSampleRate,
    );
  }
}
