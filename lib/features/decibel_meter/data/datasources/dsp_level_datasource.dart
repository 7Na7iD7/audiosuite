import 'dart:typed_data';

import 'package:audiosuite/src/rust/api/audio.dart' as rust;

class DspLevelDataSource {
  Future<double> measure(Float32List buffer) async {
    final db = await rust.calculateDb(buffer: buffer);
    return db;
  }
}
