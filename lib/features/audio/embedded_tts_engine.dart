/// Offline speech synthesis using the voices bundled with the app.
///
/// Three responsibilities, kept apart from the recitation state machine:
///
///  * **Provisioning** — the model and its phonemizer data are Flutter assets,
///    which on Android live inside the APK and are not real files. The engine
///    copies them once into the app-support directory (stamped by version) so
///    the native library can open them by path.
///  * **Synthesis** — a sherpa-onnx VITS voice runs in a dedicated **background
///    isolate** that owns the loaded model. The UI thread only sends text and
///    receives PCM, so a long verse can never jank the reader.
///  * **Encoding** — the returned samples are wrapped in a 16-bit PCM WAV, which
///    is what the audio player consumes.
///
/// Nothing here reaches the network. The device voice remains the fallback for
/// languages with no bundled voice (see `RecitationService`).
library;

import 'dart:async';
import 'dart:io' show Directory, File;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'embedded_voices.dart';
import 'wav_encoder.dart';

/// Bump when the bundled voice files change so installed copies re-provision.
///
/// 3: the phonemizer data is trimmed to the languages the voice speaks
/// (`scripts/fetch_embedded_voices.py`), so an installed copy holding the
/// full eSpeak NG data set is replaced.
const int kBundledVoiceVersion = 3;

/// Synthesized audio: mono PCM plus its sample rate.
class EmbeddedSynthesis {
  const EmbeddedSynthesis(this.samples, this.sampleRate);

  final Float32List samples;
  final int sampleRate;

  double get durationSeconds =>
      sampleRate == 0 ? 0 : samples.length / sampleRate;

  /// Encodes as a 16-bit mono PCM WAV, the format the player takes.
  Uint8List toWav() => encodeWav16(samples, sampleRate);
}

/// Loads a bundled voice and synthesizes with it off the UI thread.
abstract interface class EmbeddedSpeechEngine {
  Future<bool> prepare(EmbeddedVoice voice);
  Future<EmbeddedSynthesis?> synthesize(String text, {double speed = 1.0});
  void dispose();
}

class EmbeddedTtsEngine implements EmbeddedSpeechEngine {
  EmbeddedTtsEngine({Future<VoicePaths> Function(EmbeddedVoice)? provision})
    : _provision = provision ?? provisionVoiceAssets;

  final Future<VoicePaths> Function(EmbeddedVoice) _provision;
  Isolate? _isolate;
  ReceivePort? _receive;
  SendPort? _toWorker;
  final Map<int, Completer<Object?>> _jobs = {};
  Completer<SendPort?>? _handshake;
  int _nextJob = 1;
  bool _loaded = false;
  String? _loadedVoiceId;
  int _generation = 0;
  Future<bool>? _preparing;
  String? _preparingVoiceId;

  bool get isReady => _loaded && _isolate != null;

  /// Loads [voice], provisioning its assets first. Returns true on success.
  @override
  Future<bool> prepare(EmbeddedVoice voice) {
    if (_loaded && _loadedVoiceId == voice.id) return Future.value(true);
    if (_preparingVoiceId == voice.id && _preparing != null) {
      return _preparing!;
    }
    dispose();
    final generation = _generation;
    _preparingVoiceId = voice.id;
    return _preparing = _prepare(voice, generation);
  }

  Future<bool> _prepare(EmbeddedVoice voice, int generation) async {
    try {
      final paths = await _provision(voice);
      if (generation != _generation) return false;
      final receive = ReceivePort();
      _receive = receive;
      final handshake = Completer<SendPort?>();
      _handshake = handshake;

      receive.listen((message) {
        if (generation != _generation) return;
        if (message is SendPort) {
          if (!handshake.isCompleted) handshake.complete(message);
          _toWorker = message;
          return;
        }
        if (message is Map) {
          final id = message['id'];
          if (id is! int) return;
          final job = _jobs.remove(id);
          if (job == null || job.isCompleted) return;
          if (message['error'] != null) {
            job.complete(null);
          } else {
            job.complete(message);
          }
        }
      });

      final isolate = await Isolate.spawn(
        _voiceIsolateMain,
        receive.sendPort,
        debugName: 'embedded-tts',
      );
      if (generation != _generation) {
        isolate.kill(priority: Isolate.immediate);
        return false;
      }
      _isolate = isolate;

      final port = await handshake.future.timeout(const Duration(seconds: 10));
      if (port == null || generation != _generation) return false;
      final id = _nextJob++;
      final completer = Completer<Object?>();
      _jobs[id] = completer;
      port.send({
        'cmd': 'load',
        'id': id,
        'model': paths.model,
        'tokens': paths.tokens,
        'lexicon': paths.lexicon,
        'threads': 2,
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 60),
      );
      if (generation != _generation) return false;
      if (result is Map && result['error'] == null) {
        _loaded = true;
        _loadedVoiceId = voice.id;
        return true;
      }
      debugPrint(
        'EmbeddedTtsEngine load failed: ${result is Map ? result['error'] : result}',
      );
      if (generation == _generation) dispose();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('EmbeddedTtsEngine prepare failed: $e');
      if (generation == _generation) dispose();
      return false;
    } finally {
      if (generation == _generation) {
        _preparing = null;
        _preparingVoiceId = null;
      }
    }
  }

  /// Synthesizes [text] at [speed] (1.0 = the model's normal pace).
  @override
  Future<EmbeddedSynthesis?> synthesize(
    String text, {
    double speed = 1.0,
  }) async {
    final port = _toWorker;
    if (!_loaded || port == null) return null;
    final id = _nextJob++;
    final completer = Completer<Object?>();
    _jobs[id] = completer;
    port.send({'cmd': 'synth', 'id': id, 'text': text, 'speed': speed});

    try {
      final result = await completer.future.timeout(
        const Duration(seconds: 30),
      );
      if (result is! Map) return null;
      final samples = result['samples'];
      final rate = result['rate'];
      if (samples is! Float32List || rate is! int || rate <= 0) return null;
      return EmbeddedSynthesis(samples, rate);
    } catch (e) {
      if (kDebugMode) debugPrint('EmbeddedTtsEngine synthesize failed: $e');
      return null;
    } finally {
      _jobs.remove(id);
    }
  }

  @override
  void dispose() {
    _generation++;
    final handshake = _handshake;
    if (handshake != null && !handshake.isCompleted) handshake.complete(null);
    for (final job in _jobs.values) {
      if (!job.isCompleted) job.complete(null);
    }
    _jobs.clear();
    final isolate = _isolate;
    final port = _toWorker;
    if (isolate != null) {
      if (port == null) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        // Let the worker free its native model. Killing the isolate first
        // would bypass tts.free() and leak native allocations on every reload.
        final exited = ReceivePort();
        isolate.addOnExitListener(exited.sendPort);
        final deadline = Timer(const Duration(seconds: 35), () {
          isolate.kill(priority: Isolate.immediate);
          exited.close();
        });
        exited.listen((_) {
          deadline.cancel();
          exited.close();
        });
        port.send({'cmd': 'dispose'});
      }
    }
    _isolate = null;
    _toWorker = null;
    _receive?.close();
    _receive = null;
    _handshake = null;
    _loaded = false;
    _loadedVoiceId = null;
    _preparing = null;
    _preparingVoiceId = null;
  }
}

/// Owns the sherpa-onnx OfflineTts for one voice inside a background isolate.
void _voiceIsolateMain(SendPort toMain) {
  final receive = ReceivePort();
  toMain.send(receive.sendPort);
  sherpa.initBindings();
  sherpa.OfflineTts? tts;

  receive.listen((message) {
    if (message is! Map) return;
    final cmd = message['cmd'];
    final id = message['id'];

    if (cmd == 'dispose') {
      tts?.free();
      tts = null;
      receive.close();
      return;
    }

    if (cmd == 'load') {
      try {
        tts = sherpa.OfflineTts(
          sherpa.OfflineTtsConfig(
            model: sherpa.OfflineTtsModelConfig(
              vits: sherpa.OfflineTtsVitsModelConfig(
                model: message['model'] as String,
                tokens: message['tokens'] as String,
                lexicon: message['lexicon'] as String,
              ),
              numThreads: (message['threads'] as int?) ?? 2,
              debug: false,
              provider: 'cpu',
            ),
            maxNumSentences: 1,
          ),
        );
        toMain.send({'id': id, 'sampleRate': tts!.sampleRate});
      } catch (e) {
        toMain.send({'id': id, 'error': '$e'});
      }
      return;
    }

    if (cmd == 'synth') {
      final engine = tts;
      if (engine == null) {
        toMain.send({'id': id, 'error': 'not loaded'});
        return;
      }
      try {
        final audio = engine.generate(
          text: message['text'] as String,
          sid: 0,
          speed: (message['speed'] as num?)?.toDouble() ?? 1.0,
        );
        toMain.send({
          'id': id,
          'samples': audio.samples,
          'rate': audio.sampleRate,
        });
      } catch (e) {
        toMain.send({'id': id, 'error': '$e'});
      }
    }
  });
}

/// Filesystem paths the native library can open for one voice.
class VoicePaths {
  const VoicePaths(this.model, this.tokens, this.lexicon);
  final String model;
  final String tokens;
  final String lexicon;
}

/// Copies a bundled voice's assets into a real directory, once per version.
Future<VoicePaths> provisionVoiceAssets(EmbeddedVoice voice) async {
  final support = await getApplicationSupportDirectory();
  final base = Directory(p.join(support.path, 'voices', voice.id));
  final stamp = File(p.join(base.path, '.version'));

  var current = false;
  try {
    current =
        stamp.existsSync() &&
        int.tryParse(stamp.readAsStringSync().trim()) == kBundledVoiceVersion;
  } catch (_) {
    current = false;
  }

  final prefix = 'assets/voices/${voice.id}/';
  final requiredAssets = [
    voice.modelAsset,
    voice.tokensAsset,
    voice.lexiconAsset,
  ];
  String localPath(String asset) =>
      p.join(base.path, asset.substring(prefix.length));
  if (current) {
    for (final asset in requiredAssets) {
      if (!await File(localPath(asset)).exists()) current = false;
    }
  }

  if (!current) {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((a) => a.startsWith(prefix))
        .toList();
    if (!requiredAssets.every(assets.contains)) {
      throw StateError(
        'Bundled voice ${voice.id} is missing model or pronunciation assets',
      );
    }
    for (final asset in assets) {
      final relative = asset.substring(prefix.length);
      final target = File(p.join(base.path, relative));
      await target.parent.create(recursive: true);
      final data = await rootBundle.load(asset);
      await target.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: false,
      );
    }
    await base.create(recursive: true);
    // Written only after every file is in place, so an interrupted copy is
    // retried rather than trusted.
    await stamp.writeAsString('$kBundledVoiceVersion', flush: true);
  }

  String at(String relative) => p.join(base.path, relative);
  final modelFile = voice.modelAsset.substring(
    'assets/voices/${voice.id}/'.length,
  );
  final tokensFile = voice.tokensAsset.substring(
    'assets/voices/${voice.id}/'.length,
  );
  final lexicon = voice.lexiconAsset.substring(
    'assets/voices/${voice.id}/'.length,
  );
  return VoicePaths(at(modelFile), at(tokensFile), at(lexicon));
}
