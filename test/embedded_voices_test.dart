import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/audio/embedded_voices.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Flutter bundle contains every voice and phonemizer file', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    for (final voice in kEmbeddedVoices.values) {
      final files = Directory(
        'assets/voices/${voice.id}',
      ).listSync(recursive: true).whereType<File>();
      expect(files, isNotEmpty);
      for (final file in files) {
        expect(
          bundled,
          contains(file.path),
          reason: 'Missing from app: ${file.path}',
        );
      }
      expect(bundled, contains('${voice.dataDirAsset}/phondata'));
      expect(bundled, contains('${voice.dataDirAsset}/lang/grk/el'));
    }
  });

  test('the phonemizer data is trimmed to the languages the voice speaks', () {
    for (final voice in kEmbeddedVoices.values) {
      final directory = Directory('assets/voices/${voice.id}');
      final config = jsonDecode(
        File('${voice.modelAsset}.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final espeakVoice =
          (config['espeak'] as Map<String, dynamic>)['voice'] as String;

      final dictionaries = directory
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => p.basename(file.path))
          .where((name) => name.endsWith('_dict'))
          .toSet();

      // The declared eSpeak voice must keep its own dictionary; without it the
      // phonemizer silently produces nothing.
      expect(
        dictionaries,
        contains('${espeakVoice}_dict'),
        reason: '${voice.id} declares espeak voice "$espeakVoice"',
      );
      // eSpeak NG ships roughly a hundred dictionaries (~17 MB). Only the
      // voice's own language and its close relatives should survive the trim;
      // a regression that restores the full set must fail here.
      expect(
        dictionaries.length,
        lessThanOrEqualTo(3),
        reason:
            '${voice.id} bundles ${dictionaries.length} dictionaries: $dictionaries',
      );
    }
  });

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
