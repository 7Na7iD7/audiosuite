import 'package:audiosuite/core/audio/audio_channel.dart';
import 'package:audiosuite/core/audio/audio_manager.dart';
import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/features/decibel_meter/data/datasources/dsp_level_datasource.dart';
import 'package:audiosuite/features/decibel_meter/domain/repositories/decibel_repository.dart';

class DecibelRepositoryImpl implements DecibelRepository {
  DecibelRepositoryImpl(this._audio, this._dsp);

  final AudioManager _audio;
  final DspLevelDataSource _dsp;

  @override
  Future<Stream<double>> start() async {
    final pcm = await _audio.openMicrophone(AudioChannel.meter);
    return pcm.asyncMap(_dsp.measure).map(_toSpl);
  }

  @override
  Future<void> stop() => _audio.closeMicrophone(AudioChannel.meter);

  double _toSpl(double dbfs) {
    return (dbfs + AudioConstants.dbCalibrationOffset)
        .clamp(AudioConstants.splMin, AudioConstants.splMax)
        .toDouble();
  }
}
