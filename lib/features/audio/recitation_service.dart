/// Thin wrapper over the platform speech engine.
///
/// Kept deliberately small and free of app state so the playback logic in
/// `recitation_provider.dart` can be reasoned about — and so the whole audio
/// feature degrades to a clear message rather than a crash when a device has
/// no Hebrew or Greek voice installed.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

/// Speaks prepared original-language text.
class RecitationService {
  RecitationService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;
  String? _currentLanguage;

  /// Cache so we do not re-probe the engine on every verse.
  final Map<String, VoiceAvailability> _availability = {};

  /// Whether the engine has a voice for [languageCode] (a BCP-47 tag).
  Future<VoiceAvailability> availabilityFor(String languageCode) async {
    final cached = _availability[languageCode];
    if (cached != null) return cached;

    VoiceAvailability result;
    try {
      final available = await _tts.isLanguageAvailable(languageCode);
      result = (available == true)
          ? VoiceAvailability.ready
          : VoiceAvailability.voiceMissing;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RecitationService availability probe failed: $e');
      }
      result = VoiceAvailability.unsupported;
    }

    _availability[languageCode] = result;
    return result;
  }

  /// Points the engine at a language and speaking rate.
  ///
  /// [rate] is a natural multiplier where 1.0 is an ordinary reading pace; it
  /// is mapped onto the platform's own scale.
  Future<void> configure({
    required String languageCode,
    required double rate,
  }) async {
    if (!_configured) {
      // Makes `speak` complete only when the utterance has finished, which is
      // what lets us read a chapter verse by verse without racing.
      await _tts.awaitSpeakCompletion(true);
      await _configureIosAudioSession();
      _configured = true;
    }

    if (_currentLanguage != languageCode) {
      await _tts.setLanguage(languageCode);
      _currentLanguage = languageCode;
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

  /// Maps a 1.0-is-normal multiplier onto the platform scale.
  ///
  /// Both iOS and Android take 0.0..1.0 from flutter_tts, with roughly 0.5 as
  /// a normal pace, so a plain halving gets us close on both.
  double _platformRate(double rate) => (rate * 0.5).clamp(0.0, 1.0);

  /// Speaks [text] and returns when the utterance has finished.
  ///
  /// Returns false when the engine refused the utterance.
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return true;
    try {
      await _tts.speak(text);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RecitationService speak failed: $e');
      }
      return false;
    }
  }

  /// Stops the current utterance immediately.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RecitationService stop failed: $e');
      }
    }
  }

  void dispose() {
    unawaited(stop());
  }
}
