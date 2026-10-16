import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/audio/embedded_player.dart';
import 'package:original_bible/features/audio/embedded_tts_engine.dart';
import 'package:original_bible/features/audio/embedded_voices.dart';
import 'package:original_bible/features/audio/recitation_provider.dart';
import 'package:original_bible/features/audio/recitation_service.dart';
import 'package:original_bible/data/models/verse.dart';

class _SpeechEngine implements EmbeddedSpeechEngine {
  final synthesis = Completer<EmbeddedSynthesis?>();
  final synthesizing = Completer<void>();
  @override
  Future<bool> prepare(EmbeddedVoice voice) async => true;
  @override
  Future<EmbeddedSynthesis?> synthesize(String text, {double speed = 1.0}) {
    if (!synthesizing.isCompleted) synthesizing.complete();
    return synthesis.future;
  }

  @override
  void dispose() {}
}

class _Player implements EmbeddedAudioPlayer {
  int plays = 0;
  @override
  Future<bool> play(Uint8List wav) async {
    plays++;
    return true;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _NativePlayer extends Fake implements AudioPlayer {
  final completions = StreamController<void>.broadcast();
  final loading = Completer<void>();
  final sourceReady = Completer<void>();
  int resumes = 0;
  @override
  Stream<void> get onPlayerComplete => completions.stream;
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSource(Source source) async {
    if (!loading.isCompleted) loading.complete();
    await sourceReady.future;
  }

  @override
  Future<void> resume() async {
    resumes++;
  }

  @override
  Future<void> dispose() => completions.close();
}

class _PreparingService extends RecitationService {
  final preparing = Completer<void>();
  final available = Completer<VoiceAvailability>();
  int configurations = 0;
  int utterances = 0;
  @override
  Future<VoiceAvailability> availabilityFor(String code) {
    if (!preparing.isCompleted) preparing.complete();
    return available.future;
  }

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
  }) async {
    configurations++;
  }

  @override
  Future<bool> speak(String text) async {
    utterances++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'isLanguageAvailable') return true;
          return 1;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('concurrent voice preparations share a single asset copy', () async {
    final assets = Completer<VoicePaths>();
    var copies = 0;
    final engine = EmbeddedTtsEngine(
      provision: (_) {
        copies++;
        return assets.future;
      },
    );
    final first = engine.prepare(kEmbeddedGreekVoice);
    final second = engine.prepare(kEmbeddedGreekVoice);
    expect(copies, 1);
    engine.dispose();
    assets.complete(const VoicePaths('unused', 'unused', 'unused'));
    expect(await first, isFalse);
    expect(await second, isFalse);
    expect(engine.isReady, isFalse);
  });

  test('stopping during synthesis prevents delayed playback', () async {
    final engine = _SpeechEngine();
    final player = _Player();
    final service = RecitationService(
      embeddedEngine: engine,
      player: player,
      enableEmbeddedVoices: true,
    );
    expect(await service.availabilityFor('el-GR'), VoiceAvailability.ready);
    await service.configure(languageCode: 'el-GR', rate: 1);
    final speaking = service.speak('λόγος');
    await engine.synthesizing.future;
    await service.stop();
    engine.synthesis.complete(EmbeddedSynthesis(Float32List(160), 16000));
    expect(await speaking, isFalse);
    expect(player.plays, 0);
    service.dispose();
  });

  test('stopping while the native source loads never resumes it', () async {
    final native = _NativePlayer();
    final player = EmbeddedPlayer(player: native);
    final speaking = player.play(Uint8List(44));
    await native.loading.future;
    final stopping = player.stop();
    native.sourceReady.complete();
    await stopping;
    expect(await speaking, isFalse);
    expect(native.resumes, 0);
    await player.dispose();
  });

  test('native playback errors release the completion wait', () async {
    final native = _NativePlayer()..sourceReady.complete();
    final player = EmbeddedPlayer(player: native);
    final speaking = player.play(Uint8List(44));
    await native.loading.future;
    native.completions.addError(StateError('decoder failed'));
    expect(await speaking, isFalse);
    await player.dispose();
  });

  test(
    'stopping during chapter preparation prevents late configuration',
    () async {
      final service = _PreparingService();
      final notifier = RecitationNotifier(service);
      final reading = notifier.startChapter(
        bookId: 'JHN',
        chapter: 1,
        isHebrew: false,
        verses: [
          Verse(
            id: 'JHN.1.1',
            bookId: 'JHN',
            chapter: 1,
            verseNumber: 1,
            textContent: 'λόγος',
          ),
        ],
      );
      await service.preparing.future;
      await notifier.stop();
      service.available.complete(VoiceAvailability.ready);
      await reading;
      expect(service.configurations, 0);
      expect(service.utterances, 0);
      expect(notifier.state.status, RecitationStatus.idle);
      notifier.dispose();
    },
  );

  test('stopping a word during preparation prevents late speech', () async {
    final service = _PreparingService();
    final notifier = RecitationNotifier(service);
    final speaking = notifier.speakWord('λόγος', isHebrew: false);
    await service.preparing.future;
    await notifier.stop();
    service.available.complete(VoiceAvailability.ready);
    expect(await speaking, isFalse);
    expect(service.configurations, 0);
    expect(service.utterances, 0);
    notifier.dispose();
  });
}
