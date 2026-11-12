/// Thin wrapper over a speech engine.
///
/// Two engines sit behind one interface so the playback logic in
/// `recitation_provider.dart` never has to know which is in use:
///
///  * the **bundled** offline voice (sherpa-onnx + a Piper model shipped in the
///    app), preferred where a voice for the language exists — no install, no
///    network, works on the first run; and
///  * the **device** voice via `flutter_tts`, still the path for Hebrew (no
///    redistributable model exists) and for any platform the bundled engine is
///    not enabled on.
///
/// Kept deliberately small and free of app state, and it degrades to a clear
/// message rather than a crash when neither engine can read a language.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'embedded_player.dart';
import 'embedded_tts_engine.dart';
import 'embedded_voices.dart';

/// Why recitation is or is not available for a language.
enum VoiceAvailability {
  /// A voice for the language is installed and ready.
  ready,

  /// The engine works but has no voice for this language. On Android the user
  /// usually has to download the voice data; on iOS/macOS it ships with the
  /// system.
  voiceMissing,

  /// The platform has no usable speech engine at all.
  unsupported,
}

/// Maps a 1.0-is-normal multiplier onto the platform's own speech-rate scale.
///
/// The two platforms do not share a scale, and flutter_tts passes the number
/// through untouched rather than reconciling them:
///
/// * iOS wants a 0.0..1.0 position across the engine's range, where 0.5 —
///   `AVSpeechUtteranceDefaultSpeechRate` — is an ordinary pace.
/// * Android wants the multiplier itself, where 1.0 is an ordinary pace.
///
/// Halving for both, as this once did, leaves every Android reading at half the
/// pace the reader chose: the default setting drawls along at a quarter speed,
/// and the slowest one is barely speech at all.
///
/// The bundled engine has no such split — it takes the multiplier directly —
/// so this is only applied on the device-voice path.
@visibleForTesting
double platformSpeechRate(double rate, {required bool isAndroid}) =>
    isAndroid ? rate.clamp(0.1, 4.0) : (rate * 0.5).clamp(0.0, 1.0);

/// Speaks prepared original-language text.
class RecitationService {
  RecitationService({
    FlutterTts? tts,
    EmbeddedSpeechEngine? embeddedEngine,
    EmbeddedAudioPlayer? player,
    bool? enableEmbeddedVoices,
  }) : _tts = tts ?? FlutterTts(),
       _embedded = embeddedEngine,
       _player = player,
       _enableEmbeddedVoices = enableEmbeddedVoices {
    _installUtteranceHandlers();
  }

  final FlutterTts _tts;

  /// Created lazily the first time a bundled voice is used.
  EmbeddedSpeechEngine? _embedded;
  EmbeddedAudioPlayer? _player;
  final bool? _enableEmbeddedVoices;
  int _speechGeneration = 0;
  bool _disposed = false;
  EmbeddedVoice? _preparedBundledVoice;

  /// Set to true by tests that cannot load native libraries, so every language
  /// uses the device path and behavior stays deterministic.
  @visibleForTesting
  static bool debugForceSystemVoices = false;

  /// The bundled engine is enabled on the mobile platforms where the device
  /// voice is the weak link. macOS ships high-quality voices with the system,
  /// and desktop Linux is a development target only.
  bool get _bundledAllowed =>
      !debugForceSystemVoices &&
      !kIsWeb &&
      (_enableEmbeddedVoices ?? (Platform.isAndroid || Platform.isIOS));

  /// The bundled voice currently selected, or null when using the device voice.
  EmbeddedVoice? _activeBundledVoice;
  double _bundledRate = 1.0;

  bool _configured = false;
  String? _currentLanguage;

  /// Resolved when the current utterance finished, was cancelled, or failed.
  /// See [speak] for why the `speak` call itself is not what we wait on.
  Completer<bool>? _utterance;

  /// The tag each requested language is actually spoken with.
  ///
  /// Only successes are kept. A missing voice is something the reader can go
  /// and install, and caching "no" would keep the app insisting the voice is
  /// absent for the rest of the session after they had installed it.
  final Map<String, String> _resolved = {};

  /// Whether the engine has a voice for [languageCode] (a BCP-47 tag).
  Future<VoiceAvailability> availabilityFor(String languageCode) async {
    if (_disposed) return VoiceAvailability.unsupported;

    final bundled = _bundledAllowed ? kEmbeddedVoices[languageCode] : null;
    if (bundled != null) {
      final engine = _embedded ??= EmbeddedTtsEngine();
      if (await engine.prepare(bundled)) {
        if (_disposed) return VoiceAvailability.unsupported;
        _preparedBundledVoice = bundled;
        _player ??= EmbeddedPlayer();
        return VoiceAvailability.ready;
      }
      // The bundled voice failed to load; fall through to the device voice
      // rather than declaring speech unsupported.
    }

    if (_resolved.containsKey(languageCode)) return VoiceAvailability.ready;
    try {
      final voice = await _findVoice(languageCode);
      if (voice == null) return VoiceAvailability.voiceMissing;
      _resolved[languageCode] = voice;
      return VoiceAvailability.ready;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RecitationService availability probe failed: $e');
      }
      return VoiceAvailability.unsupported;
    }
  }

  /// Finds a tag the engine will speak [languageCode] with, or null.
  Future<String?> _findVoice(String languageCode) async {
    // The exact tag first: it is what a properly installed voice reports, and
    // what gives the intended regional pronunciation.
    if (await _tts.isLanguageAvailable(languageCode) == true) {
      return languageCode;
    }

    // Then any installed voice for the same language. Engines differ on how
    // they name one — Hebrew turns up as `he-IL`, bare `he`, or the legacy
    // `iw-IL` that Java still emits — and turning down a voice sitting right
    // there on the device, to tell the reader none is installed, is the worst
    // of both answers.
    final installed = await _tts.getLanguages;
    if (installed is! List) return null;

    final wanted = _languageOf(languageCode);
    for (final entry in installed) {
      final tag = entry?.toString();
      if (tag == null || tag.isEmpty) continue;
      if (_languageOf(tag) == wanted) return tag;
    }
    return null;
  }

  /// The language subtag of [tag], with Hebrew's two spellings folded together.
  ///
  /// Hebrew changed ISO code from `iw` to `he` decades ago and Java never
  /// followed, so the same voice answers to either depending on which layer is
  /// asked. Greek's `el` has no such history.
  static String _languageOf(String tag) {
    final language = tag.split(RegExp('[-_]')).first.toLowerCase();
    return language == 'iw' ? 'he' : language;
  }

  /// Points the engine at a language and speaking rate.
  ///
  /// [rate] is a natural multiplier where 1.0 is an ordinary reading pace; it
  /// is mapped onto the platform's own scale on the device path.
  Future<void> configure({
    required String languageCode,
    required double rate,
  }) async {
    if (_disposed) return;
    final bundled = _preparedBundledVoice;
    if (bundled != null && bundled.languageCode == languageCode) {
      // The bundled engine takes the multiplier as-is; nothing to set up.
      _bundledRate = rate;
      _activeBundledVoice = bundled;
      return;
    }
    _activeBundledVoice = null;

    if (!_configured) {
      // Makes `speak` complete only when the utterance has finished, which is
      // what lets us read a chapter verse by verse without racing.
      await _tts.awaitSpeakCompletion(true);
      await _configureIosAudioSession();
      _configured = true;
    }

    // The engine may have answered with a different tag than the one asked for
    // — see [_findVoice] — and it will only speak with the one it named.
    final voice = _resolved[languageCode] ?? languageCode;
    if (_currentLanguage != voice) {
      await _tts.setLanguage(voice);
      _currentLanguage = voice;
    }

    await _tts.setSpeechRate(_platformRate(rate));
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Puts iOS into an audio session that suits spoken content.
  ///
  /// Without this, iOS applies the default (`ambientSolo`) session, and the
  /// recitation is **silenced by the Ring/Silent switch and by screen lock** —
  /// so a user with their phone on silent taps play, watches the verse
  /// highlight and scroll, and hears nothing. That reads as a broken feature
  /// rather than a muted one.
  ///
  /// `playback` keeps the audio going through the silent switch and, together
  /// with the `audio` background mode in Info.plist, through screen lock, which
  /// is what makes listening while walking or driving possible. The session is
  /// deliberately non-mixing: this is spoken content, so it should interrupt
  /// music the way a podcast does rather than talk over it.
  ///
  /// Does nothing on other platforms.
  Future<void> _configureIosAudioSession() async {
    if (!Platform.isIOS) return;
    try {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const [IosTextToSpeechAudioCategoryOptions.duckOthers],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    } catch (e) {
      // A failed session setup must not stop playback: audio may still work,
      // just subject to the silent switch.
      if (kDebugMode) {
        debugPrint('RecitationService iOS audio session setup failed: $e');
      }
    }
  }

  double _platformRate(double rate) =>
      platformSpeechRate(rate, isAndroid: Platform.isAndroid);

  /// Subscribes to the engine's own notion of an utterance ending.
  ///
  /// The chapter loop needs a signal that arrives on **every** outcome, and the
  /// `speak` call is not one: when an Android utterance errors, the engine
  /// reports it through this error callback and never answers the pending
  /// `speak`, so a service that awaited `speak` alone would sit on one verse
  /// forever with the transport bar showing it as still playing. Listening here
  /// turns that hang into an ordinary failure the reader can report.
  void _installUtteranceHandlers() {
    _tts.setCompletionHandler(() => _settleUtterance(true));
    _tts.setCancelHandler(() => _settleUtterance(false));
    _tts.setErrorHandler((dynamic message) {
      if (kDebugMode) {
        debugPrint('RecitationService engine reported: $message');
      }
      _settleUtterance(false);
    });
  }

  /// Ends the wait started by [speak], if one is outstanding.
  void _settleUtterance(bool spoken) {
    final pending = _utterance;
    _utterance = null;
    if (pending != null && !pending.isCompleted) pending.complete(spoken);
  }

  /// Speaks [text] and returns when the utterance has finished.
  ///
  /// Returns false when the engine refused or failed the utterance.
  Future<bool> speak(String text) async {
    if (_disposed) return false;
    if (text.trim().isEmpty) return true;
    final generation = _speechGeneration;

    final bundled = _activeBundledVoice;
    if (bundled != null) {
      final engine = _embedded;
      final player = _player;
      if (engine == null || player == null) return false;
      final synthesis = await engine.synthesize(text, speed: _bundledRate);
      if (synthesis == null || generation != _speechGeneration || _disposed) {
        return false;
      }
      return player.play(synthesis.toWav());
    }

    // Nothing should still be waiting, but an abandoned utterance must not
    // capture the callback that belongs to this one.
    _settleUtterance(false);
    final utterance = Completer<bool>();
    _utterance = utterance;

    // Deliberately not awaited — see [_installUtteranceHandlers]. This call is
    // still worth watching for the one thing the callbacks do not cover: a
    // refusal, where the engine declines the text up front and so never starts
    // an utterance to report on.
    unawaited(
      _tts
          .speak(text)
          .then(
            (result) {
              if (result == 0) _settleUtterance(false);
            },
            onError: (Object e) {
              if (kDebugMode) {
                debugPrint('RecitationService speak failed: $e');
              }
              _settleUtterance(false);
            },
          ),
    );

    return utterance.future;
  }

  /// Stops the current utterance immediately.
  Future<void> stop() async {
    _speechGeneration++;
    await _player?.stop();
    try {
      await _tts.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RecitationService stop failed: $e');
      }
    }
    // Android reports a stop through the cancel callback, but only for an
    // utterance that had already begun sounding; releasing the wait here covers
    // a stop that lands while the engine is still starting up.
    _settleUtterance(false);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(stop());
    _embedded?.dispose();
    unawaited(_player?.dispose());
    _embedded = null;
    _player = null;
    _activeBundledVoice = null;
  }
}
