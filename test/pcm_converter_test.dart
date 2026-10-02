import 'dart:typed_data';

import 'package:audiosuite/core/audio/pcm_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts little endian pcm16 to normalized floats', () {
    final converter = PcmConverter();
    final bytes = Uint8List.fromList([0x00, 0x40, 0x00, 0xC0]);
    final out = converter.convert(bytes);
    expect(out.length, 2);
    expect(out[0], closeTo(0.5, 1e-6));
    expect(out[1], closeTo(-0.5, 1e-6));
  });

  test('carries a dangling byte across chunks', () {
    final converter = PcmConverter();
    final first = converter.convert(Uint8List.fromList([0x00, 0x40, 0x00]));
    final second = converter.convert(Uint8List.fromList([0xC0]));
    expect(first.length, 1);
    expect(second.length, 1);
    expect(second[0], closeTo(-0.5, 1e-6));
  });
}
