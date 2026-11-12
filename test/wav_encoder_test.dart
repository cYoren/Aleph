import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/audio/wav_encoder.dart';

int _u32(Uint8List b, int o) =>
    b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);
int _u16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);
String _ascii(Uint8List b, int o, int n) =>
    String.fromCharCodes(b.sublist(o, o + n));

void main() {
  test('writes a valid mono 16-bit PCM WAV header', () {
    final samples = Float32List.fromList([0.0, 0.5, -0.5, 1.0, -1.0]);
    final wav = encodeWav16(samples, 16000);

    expect(_ascii(wav, 0, 4), 'RIFF');
    expect(_ascii(wav, 8, 4), 'WAVE');
    expect(_ascii(wav, 12, 4), 'fmt ');
    expect(_ascii(wav, 36, 4), 'data');

    expect(_u32(wav, 16), 16); // fmt chunk size
    expect(_u16(wav, 20), 1); // PCM
    expect(_u16(wav, 22), 1); // mono
    expect(_u32(wav, 24), 16000); // sample rate
    expect(_u32(wav, 28), 16000 * 2); // byte rate
    expect(_u16(wav, 32), 2); // block align
    expect(_u16(wav, 34), 16); // bits per sample

    expect(_u32(wav, 40), samples.length * 2); // data size
    expect(_u32(wav, 4), 36 + samples.length * 2); // RIFF size
    expect(wav.length, 44 + samples.length * 2);
  });

  test('maps floats to int16 with clipping', () {
    final samples = Float32List.fromList([0.0, 1.0, -1.0, 0.5]);
    final wav = encodeWav16(samples, 8000);
    final data = wav.buffer.asByteData(44);

    expect(data.getInt16(0, Endian.little), 0);
    expect(data.getInt16(2, Endian.little), 32767);
    expect(data.getInt16(4, Endian.little), -32768);
    expect(data.getInt16(6, Endian.little), 16384);
  });

  test('empty input still produces a well-formed header', () {
    final wav = encodeWav16(Float32List(0), 22050);
    expect(wav.length, 44);
    expect(_ascii(wav, 0, 4), 'RIFF');
    expect(_u32(wav, 40), 0);
  });
}
