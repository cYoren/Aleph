/// Encodes synthesized float samples as a 16-bit PCM WAV.
///
/// Kept free of any Flutter import so it can be exercised from a plain Dart
/// command-line probe (`tool/embedded_tts_probe.dart`) as well as from the app.
library;

import 'dart:typed_data';

/// Wraps mono [samples] (range -1.0..1.0) at [sampleRate] Hz in a WAV header.
Uint8List encodeWav16(Float32List samples, int sampleRate) {
  const int channels = 1;
  const int bitsPerSample = 16;
  final int byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final int blockAlign = channels * bitsPerSample ~/ 8;
  final int dataBytes = samples.length * 2;

  final out = BytesBuilder();
  void ascii(String s) => out.add(s.codeUnits);
  void uint32(int v) =>
      out.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void uint16(int v) =>
      out.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

  ascii('RIFF');
  uint32(36 + dataBytes);
  ascii('WAVE');
  ascii('fmt ');
  uint32(16);
  uint16(1); // PCM
  uint16(channels);
  uint32(sampleRate);
  uint32(byteRate);
  uint16(blockAlign);
  uint16(bitsPerSample);
  ascii('data');
  uint32(dataBytes);

  final pcm = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    final v = samples[i];
    pcm[i] = v <= -1.0 ? -32768 : (v >= 1.0 ? 32767 : (v * 32767).round());
  }
  out.add(pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes));
  return out.toBytes();
}
