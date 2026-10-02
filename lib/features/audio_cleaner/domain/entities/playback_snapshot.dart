final class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.path,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final String? path;
  final bool playing;
  final Duration position;
  final Duration duration;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}
