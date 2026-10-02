final class CleanedRecording {
  const CleanedRecording({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.duration,
    required this.sizeBytes,
  });

  final String id;
  final String path;
  final DateTime createdAt;
  final Duration duration;
  final int sizeBytes;
}
