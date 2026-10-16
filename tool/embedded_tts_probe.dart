/// Command-line probe for the bundled offline voice.
///
/// Loads a bundled Piper voice through the same `sherpa_onnx` package the app
/// uses, synthesizes a phrase and a word, and writes WAV files. It exists so the
/// Dart + native integration can be exercised on a desktop build (where the
/// shared libraries are present) without a device, and so reviewers can produce
/// audio samples reproducibly.
///
///     python3 scripts/fetch_embedded_voices.py
///     LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib \
///       dart run tool/embedded_tts_probe.dart \
///       assets/voices/el_GR-rapunzelina-low /tmp/aleph-samples
///
/// The text passed here is what the app would send *after* its own preparation
/// (Modern Greek, polytonic folded to monotonic) — see `recitation_text.dart`.
library;

// A command-line tool: printing progress to stdout is the point.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:original_bible/features/audio/wav_encoder.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

void main(List<String> args) {
  final voiceDir = args.isNotEmpty ? args[0] : 'assets/voices/el_GR-rapunzelina-low';
  final outDir = args.length > 1 ? args[1] : '/tmp/aleph-samples';

  sherpa.initBindings();

  final tts = sherpa.OfflineTts(
    sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: '$voiceDir/el_GR-rapunzelina-low.onnx',
          tokens: '$voiceDir/tokens.txt',
          dataDir: '$voiceDir/espeak-ng-data',
        ),
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      ),
      maxNumSenetences: 1,
    ),
  );

  print('numSpeakers=${tts.numSpeakers} sampleRate=${tts.sampleRate}');

  const phrases = {
    'el-john1-1-normal': (1.0, 'Εν αρχή ήταν ο λόγος, και ο λόγος ήταν προς τον Θεό, και Θεός ήταν ο λόγος.'),
    'el-john1-1-slow': (0.5, 'Εν αρχή ήταν ο λόγος, και ο λόγος ήταν προς τον Θεό, και Θεός ήταν ο λόγος.'),
    'el-word-logos': (0.7, 'λόγος'),
    'el-word-agape': (0.7, 'αγάπη'),
  };

  Directory(outDir).createSync(recursive: true);
  for (final entry in phrases.entries) {
    final (speed, text) = entry.value;
    final audio = tts.generate(text: text, sid: 0, speed: speed);
    final path = '$outDir/${entry.key}.wav';
    File(path).writeAsBytesSync(encodeWav16(audio.samples, audio.sampleRate));
    final seconds = audio.sampleRate == 0 ? 0 : audio.samples.length / audio.sampleRate;
    print('${entry.key}: ${seconds.toStringAsFixed(2)}s @ ${audio.sampleRate}Hz -> $path');
  }

  tts.free();
}
