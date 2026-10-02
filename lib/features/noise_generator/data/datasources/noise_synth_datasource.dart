import 'dart:io';

import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/features/noise_generator/domain/entities/noise_color.dart';
import 'package:audiosuite/src/rust/api/audio.dart' as rust;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class NoiseSynthDataSource {
  Future<String> ensureLoop(NoiseColor color) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'noise_${color.name}_v1.wav'));
      if (await file.exists() &&
          await file.length() > AudioConstants.wavHeaderBytes) {
        return file.path;
      }
      final bytes = await rust.generateNoiseWav(
        kind: _kind(color),
        seconds: AudioConstants.noiseLoopSeconds,
        sampleRate: AudioConstants.noiseSampleRate,
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException {
      throw const StorageFailure();
    }
  }

  rust.NoiseKind _kind(NoiseColor color) => switch (color) {
        NoiseColor.white => rust.NoiseKind.white,
        NoiseColor.pink => rust.NoiseKind.pink,
        NoiseColor.brown => rust.NoiseKind.brown,
      };
}
