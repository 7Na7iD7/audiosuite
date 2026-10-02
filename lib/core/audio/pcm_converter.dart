import 'dart:typed_data';

final class PcmConverter {
  int? _carry;

  Float32List convert(Uint8List bytes) {
    if (bytes.isEmpty) return Float32List(0);
    final carry = _carry;
    final total = bytes.length + (carry == null ? 0 : 1);
    final samples = total >> 1;
    final out = Float32List(samples);
    final view = ByteData.sublistView(bytes);
    var index = 0;
    var offset = 0;
    if (carry != null) {
      final raw = carry | (bytes[0] << 8);
      final signed = raw >= 0x8000 ? raw - 0x10000 : raw;
      if (samples > 0) out[0] = signed / 32768.0;
      index = 1;
      offset = 1;
    }
    for (; index < samples; index++, offset += 2) {
      out[index] = view.getInt16(offset, Endian.little) / 32768.0;
    }
    _carry = total.isOdd ? bytes.last : null;
    return out;
  }

  void reset() => _carry = null;
}
