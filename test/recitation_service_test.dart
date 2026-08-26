/// Covers how [RecitationService] decides an utterance is over.
///
/// These drive the real `flutter_tts` plugin against a stand-in for the native
/// side, because the bug they guard against lives exactly in the gap between
/// the two: the engine has more ways to finish an utterance than it has ways
/// to answer the `speak` call that started it.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/audio/recitation_provider.dart';
import 'package:original_bible/features/audio/recitation_service.dart';

const MethodChannel _channel = MethodChannel('flutter_tts');

/// Stands in for the speech engine on the far side of the plugin channel.
class _FakeEngine {
  _FakeEngine() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call.method);
          if (call.method == 'speak') {
            // Never answered: with awaitSpeakCompletion the real engine holds
            // this call open until the utterance ends, and when the utterance
            // fails it never answers at all.
            return speakReply;
          }
          if (call.method == 'isLanguageAvailable') return languageAvailable;
          return 1;
        });
  }

  final List<String> calls = [];

  /// Non-null only when the engine refuses the text up front.
  Object? speakReply;

  bool languageAvailable = true;

  /// Delivers one of the plugin's native-to-Dart callbacks.
  Future<void> report(String event, [Object? arguments]) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          _channel.name,
          _channel.codec.encodeMethodCall(MethodCall(event, arguments)),
          (_) {},
        );
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}

/// Puts the service in the state it is in mid-chapter: configured, handlers
/// installed, ready to be handed a verse.
Future<RecitationService> _configuredService() async {
  final service = RecitationService();
  await service.configure(languageCode: 'he-IL', rate: 0.5);
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeEngine engine;

  setUp(() => engine = _FakeEngine());
  tearDown(() => engine.dispose());

  test('an utterance that finishes normally reports success', () async {
    final service = await _configuredService();

    final spoken = service.speak('בְּרֵאשִׁית');
    await engine.report('speak.onComplete');

    expect(await spoken, isTrue);
  });

  test('an utterance the engine fails ends the wait rather than hanging', () async {
    final service = await _configuredService();

    // The regression: Android's TextToSpeech reports a failed utterance through
    // this callback and leaves the `speak` call unanswered forever. A service
    // that waited on `speak` alone would never reach the next verse, leaving the
    // transport bar claiming to play a chapter in silence.
    final spoken = service.speak('בְּרֵאשִׁית');
    await engine.report('speak.onError', 'Error from TextToSpeech (speak) - 5');

    expect(await spoken, isFalse);
  });

  test('a cancelled utterance ends the wait', () async {
    final service = await _configuredService();

    final spoken = service.speak('בְּרֵאשִׁית');
    await engine.report('speak.onCancel');

    expect(await spoken, isFalse);
  });

  test('text the engine refuses outright reports failure', () async {
    engine.speakReply = 0;
    final service = await _configuredService();

    // No callback follows a refusal — there is no utterance to report on — so
    // the reply to `speak` is the only signal there will ever be.
    expect(await service.speak('בְּרֵאשִׁית'), isFalse);
  });

  test('stopping releases a verse that had not started sounding', () async {
    final service = await _configuredService();

    final spoken = service.speak('בְּרֵאשִׁית');
    await service.stop();

    expect(await spoken, isFalse);
  });

  test('empty text is not handed to the engine', () async {
    final service = await _configuredService();
    engine.calls.clear();

    expect(await service.speak('   '), isTrue);
    expect(engine.calls, isEmpty);
  });

  group('speech rate', () {
    test('1.0 is an ordinary pace on both platforms', () {
      // Android takes the multiplier itself; iOS takes a position on a 0..1
      // scale whose midpoint is its default rate. Both describe the same pace.
      expect(platformSpeechRate(1.0, isAndroid: true), 1.0);
      expect(platformSpeechRate(1.0, isAndroid: false), 0.5);
    });

    test('Android is not halved', () {
      // The regression: halving here made the default setting a quarter-speed
      // drawl, which reads as a broken voice rather than a slow one.
      expect(
        platformSpeechRate(kDefaultRecitationRate, isAndroid: true),
        kDefaultRecitationRate,
      );
    });

    test('every offered rate stays within each platform range', () {
      for (final rate in kRecitationRates) {
        expect(platformSpeechRate(rate, isAndroid: true), greaterThan(0));
        final ios = platformSpeechRate(rate, isAndroid: false);
        expect(ios, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  test('a missing voice is re-probed, so installing one takes effect', () async {
    final service = await _configuredService();

    engine.languageAvailable = false;
    expect(
      await service.availabilityFor('he-IL'),
      VoiceAvailability.voiceMissing,
    );

    // The user goes to the system settings, installs the voice, and comes back
    // without restarting the app.
    engine.languageAvailable = true;
    expect(await service.availabilityFor('he-IL'), VoiceAvailability.ready);
  });
}
