/// Plays a synthesized WAV and reports when it finishes.
///
/// `flutter_tts` reports completion of an *utterance*; the bundled engine hands
/// us raw audio instead, so this tiny wrapper gives the recitation loop the same
/// "resolve when the sound is over" signal it already waits on, and the same
/// immediate [stop] for interruption.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract interface class EmbeddedAudioPlayer {
  Future<bool> play(Uint8List wav);
  Future<void> stop();
  Future<void> dispose();
}

class EmbeddedPlayer implements EmbeddedAudioPlayer {
  EmbeddedPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _completeSub = _player.onPlayerComplete.listen(
      (_) => _settle(true),
      onError: (Object error) => _settle(false),
    );
  }

  final AudioPlayer _player;
  StreamSubscription<void>? _completeSub;
  Completer<bool>? _done;
  int _generation = 0;
  bool _disposed = false;
  Future<void> _operations = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _operations.then((_) => action());
    _operations = operation.catchError((Object _) {});
    return operation;
  }

  /// Whether a clip is currently sounding.
  bool get isPlaying => _done != null;

  /// Plays [wav] from memory and completes when playback ends (or is stopped).
  @override
  Future<bool> play(Uint8List wav) async {
    if (_disposed) return false;
    final generation = ++_generation;
    _settle(false);
    final done = Completer<bool>();
    _done = done;
    try {
      await _enqueue(() async {
        if (generation != _generation || _disposed) return;
        await _player.stop();
        await _player.setSource(BytesSource(wav, mimeType: 'audio/wav'));
        // setSource can finish after the reader pressed stop. Never resume
        // that clip; serialize native commands so a stop cannot be overtaken.
        if (generation != _generation || _disposed) return;
        await _player.resume();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('EmbeddedPlayer play failed: $e');
      if (generation == _generation) _settle(false);
    }
    return done.future;
  }

  /// Stops immediately, releasing a pending [play] wait.
  @override
  Future<void> stop() async {
    _generation++;
    _settle(false);
    try {
      await _enqueue(_player.stop);
    } catch (e) {
      if (kDebugMode) debugPrint('EmbeddedPlayer stop failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _completeSub?.cancel();
    await stop();
    await _player.dispose();
  }

  void _settle(bool finished) {
    final done = _done;
    _done = null;
    if (done != null && !done.isCompleted) done.complete(finished);
  }
}
