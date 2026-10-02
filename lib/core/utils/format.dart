String formatDuration(Duration duration) {
  final total = duration.inSeconds;
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String formatTimestamp(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${value.year}/${two(value.month)}/${two(value.day)}  ${two(value.hour)}:${two(value.minute)}';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
