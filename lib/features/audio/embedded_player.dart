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

class EmbeddedPlayer {
  EmbeddedPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _completeSub = _player.onPlayerComplete.listen((_) => _settle(true));
  }

  final AudioPlayer _player;
  StreamSubscription<void>? _completeSub;
  Completer<bool>? _done;

  /// Whether a clip is currently sounding.
  bool get isPlaying => _done != null;

  /// Plays [wav] from memory and completes when playback ends (or is stopped).
  Future<bool> play(Uint8List wav) async {
    _settle(false);
    final done = Completer<bool>();
    _done = done;
    try {
      await _player.stop();
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (e) {
      if (kDebugMode) debugPrint('EmbeddedPlayer play failed: $e');
      _settle(false);
    }
    return done.future;
  }

  /// Stops immediately, releasing a pending [play] wait.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('EmbeddedPlayer stop failed: $e');
    }
    _settle(false);
  }

  Future<void> dispose() async {
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
