enum AudioChannel {
  noisePlayback,
  meter,
  cleanerRecording,
  cleanerPlayback;

  bool get usesMicrophone =>
      this == AudioChannel.meter || this == AudioChannel.cleanerRecording;

  Set<AudioChannel> get conflicts => switch (this) {
        AudioChannel.noisePlayback => const {},
        AudioChannel.meter => const {
            AudioChannel.cleanerRecording,
            AudioChannel.cleanerPlayback,
          },
        AudioChannel.cleanerRecording => const {
            AudioChannel.meter,
            AudioChannel.cleanerPlayback,
          },
        AudioChannel.cleanerPlayback => const {
            AudioChannel.meter,
            AudioChannel.cleanerRecording,
          },
      };
}

enum AppTab {
  noise,
  meter,
  cleaner;

  Set<AudioChannel> get allowedChannels => switch (this) {
        AppTab.noise => const {AudioChannel.noisePlayback},
        AppTab.meter => const {
            AudioChannel.noisePlayback,
            AudioChannel.meter,
          },
        AppTab.cleaner => const {
            AudioChannel.noisePlayback,
            AudioChannel.cleanerRecording,
            AudioChannel.cleanerPlayback,
          },
      };
}
