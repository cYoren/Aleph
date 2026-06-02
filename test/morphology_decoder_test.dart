import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/morphology_decoder.dart';

void main() {
  group('MorphologyDecoder', () {
    group('Hebrew morphology', () {
      test('decodes Hebrew noun correctly', () {
        // HNcmsa = Hebrew Noun, common, masculine, singular, absolute
        final result = MorphologyDecoder.decodeHebrew('HNcmsa');
        expect(result.toLowerCase(), contains('hebrew'));
        expect(result.toLowerCase(), contains('noun'));
        expect(result.toLowerCase(), contains('masculine'));
        expect(result.toLowerCase(), contains('singular'));
        expect(result.toLowerCase(), contains('absolute'));
      });

      test('decodes Hebrew verb correctly', () {
        // HVqp3ms = Hebrew Verb, Qal, Perfect, 3rd person, masculine, singular
        final result = MorphologyDecoder.decodeHebrew('HVqp3ms');
        expect(result.toLowerCase(), contains('hebrew'));
        expect(result.toLowerCase(), contains('verb'));
        expect(result.toLowerCase(), contains('qal'));
        expect(result.toLowerCase(), contains('perfect'));
      });

      test('handles empty code', () {
        final result = MorphologyDecoder.decodeHebrew('');
        expect(result, equals(''));
      });

      test('handles Aramaic prefix', () {
        final result = MorphologyDecoder.decodeHebrew('ANcmsa');
        expect(result.toLowerCase(), contains('aramaic'));
      });
    });

    group('Greek morphology', () {
      test('decodes Greek verb correctly', () {
        // V-AAI-3S = Verb, Aorist, Active, Indicative, 3rd person, Singular
        final result = MorphologyDecoder.decodeGreek('V-AAI-3S');
        expect(result.toLowerCase(), contains('verb'));
        expect(result.toLowerCase(), contains('aorist'));
        expect(result.toLowerCase(), contains('active'));
        expect(result.toLowerCase(), contains('indicative'));
      });

      test('decodes Greek noun correctly', () {
        // N-NSM = Noun, Nominative, Singular, Masculine
        final result = MorphologyDecoder.decodeGreek('N-NSM');
        expect(result.toLowerCase(), contains('noun'));
        expect(result.toLowerCase(), contains('nominative'));
        expect(result.toLowerCase(), contains('singular'));
        expect(result.toLowerCase(), contains('masculine'));
      });

      test('handles empty code', () {
        final result = MorphologyDecoder.decodeGreek('');
        expect(result, equals(''));
      });
    });

    group('decode with language flag', () {
      test('uses Hebrew decoder when isHebrew is true', () {
        final result = MorphologyDecoder.decode('HNcmsa', isHebrew: true);
        expect(result.toLowerCase(), contains('hebrew'));
      });

      test('uses Greek decoder when isHebrew is false', () {
        final result = MorphologyDecoder.decode('V-AAI-3S', isHebrew: false);
        expect(result.toLowerCase(), contains('verb'));
      });
    });

    group('getPartOfSpeechColor', () {
      test('returns blue for verbs', () {
        final hebrewVerbColor = MorphologyDecoder.getPartOfSpeechColor(
          'HV',
          isHebrew: true,
        );
        final greekVerbColor = MorphologyDecoder.getPartOfSpeechColor(
          'V-AAI-3S',
          isHebrew: false,
        );
        // Blue color: 0xFF1976D2
        expect(hebrewVerbColor, equals(0xFF1976D2));
        expect(greekVerbColor, equals(0xFF1976D2));
      });

      test('returns green for nouns', () {
        final color = MorphologyDecoder.getPartOfSpeechColor(
          'HN',
          isHebrew: true,
        );
        // Green color: 0xFF388E3C
        expect(color, equals(0xFF388E3C));
      });

      test('returns grey for empty code', () {
        final color = MorphologyDecoder.getPartOfSpeechColor(
          '',
          isHebrew: true,
        );
        // Grey color: 0xFF757575
        expect(color, equals(0xFF757575));
      });
    });
  });
}
