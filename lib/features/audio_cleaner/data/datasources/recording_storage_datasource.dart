import 'dart:io';
import 'dart:typed_data';

import 'package:audiosuite/core/constants/audio_constants.dart';
import 'package:audiosuite/core/error/failures.dart';
import 'package:audiosuite/features/audio_cleaner/domain/entities/cleaned_recording.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class RecordingStorageDataSource {
  Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'cleaned_audio'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<CleanedRecording> save(Uint8List wav) async {
    try {
      final dir = await _directory();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final file = File(p.join(dir.path, 'clean_$id.wav'));
      await file.writeAsBytes(wav, flush: true);
      return _describe(file);
    } on FileSystemException {
      throw const StorageFailure();
    }
  }

  Future<List<CleanedRecording>> list() async {
    try {
      final dir = await _directory();
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.wav'))
          .cast<File>()
          .toList();
      final items = <CleanedRecording>[];
      for (final file in files) {
        items.add(await _describe(file));
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } on FileSystemException {
      throw const StorageFailure();
    }
  }

  Future<void> delete(CleanedRecording recording) async {
    try {
      final file = File(recording.path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      throw const StorageFailure();
    }
  }

  Future<void> export(CleanedRecording recording) async {
    await Share.shareXFiles([XFile(recording.path, mimeType: 'audio/wav')]);
  }

  Future<CleanedRecording> _describe(File file) async {
    final stat = await file.stat();
    final payload =
        (stat.size - AudioConstants.wavHeaderBytes).clamp(0, stat.size);
    final seconds = payload / 2 / AudioConstants.micSampleRate;
    return CleanedRecording(
      id: p.basenameWithoutExtension(file.path),
      path: file.path,
      createdAt: stat.modified,
      duration: Duration(milliseconds: (seconds * 1000).round()),
      sizeBytes: stat.size,
    );
  }
}
