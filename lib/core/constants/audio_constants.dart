abstract final class AudioConstants {
  static const int micSampleRate = 44100;
  static const int noiseSampleRate = 44100;
  static const int noiseLoopSeconds = 30;
  static const double dbCalibrationOffset = 90.0;
  static const double splMin = 0.0;
  static const double splMax = 130.0;
  static const int meterHistoryLength = 90;
  static const Duration maxRecording = Duration(minutes: 10);
  static const int wavHeaderBytes = 44;
}
