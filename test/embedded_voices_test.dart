import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/audio/embedded_voices.dart';

void main() {
  group('embedded voice registry', () {
    test('ships a Greek voice and no Hebrew voice', () {
      expect(kEmbeddedVoices.containsKey('el-GR'), isTrue);
      expect(kEmbeddedVoices.containsKey('he-IL'), isFalse);

      final greek = embeddedVoiceFor(isHebrew: false);
      expect(greek, isNotNull);
      expect(greek!.languageCode, 'el-GR');
      expect(greek.isHebrew, isFalse);

      expect(embeddedVoiceFor(isHebrew: true), isNull);
    });

    test('asset paths are rooted at the voice id', () {
      for (final voice in kEmbeddedVoices.values) {
        final prefix = 'assets/voices/${voice.id}/';
        expect(voice.modelAsset.startsWith(prefix), isTrue);
        expect(voice.tokensAsset.startsWith(prefix), isTrue);
        expect(voice.dataDirAsset.startsWith(prefix), isTrue);
        expect(voice.modelAsset.endsWith('.onnx'), isTrue);
        expect(voice.sampleRate, greaterThan(0));
      }
    });

    test('every voice records its license and attribution', () {
      for (final voice in kEmbeddedVoices.values) {
        expect(voice.license.trim(), isNotEmpty);
        expect(voice.attribution.trim(), isNotEmpty);
      }
    });

    test('the Hebrew gap is explained, not silently empty', () {
      expect(kHebrewEmbeddedVoiceUnavailableReason.trim(), isNotEmpty);
      expect(
        kHebrewEmbeddedVoiceUnavailableReason.toLowerCase(),
        contains('license'),
      );
    });
  });
}
