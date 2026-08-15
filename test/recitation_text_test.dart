import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/features/audio/recitation_text.dart';

void main() {
  group('Hebrew preparation', () {
    const gen11 = 'בְּרֵאשִׁ֖ית בָּרָ֣א אֱלֹהִ֑ים אֵ֥ת הַשָּׁמַ֖יִם וְאֵ֥ת הָאָֽרֶץ׃';

    test('removes cantillation, which engines cannot read', () {
      final spoken = prepareHebrewForSpeech(gen11);
      final hasAccents = spoken.codeUnits.any(
        (cu) => cu >= 0x0591 && cu <= 0x05AE,
      );
      expect(hasAccents, isFalse);
    });

    test('keeps the vowel points, which are the reason to read a pointed text',
        () {
      final spoken = prepareHebrewForSpeech(gen11);
      expect(spoken.contains('ְ'), isTrue); // shva
      expect(spoken.contains('ִ'), isTrue); // hiriq
      expect(spoken.contains('ָ'), isTrue); // qamats
    });

    test('can hand the engine unpointed text when asked', () {
      final spoken = prepareHebrewForSpeech(gen11, keepVowels: false);
      final hasPoints = spoken.codeUnits.any(
        (cu) => cu >= 0x05B0 && cu <= 0x05BD,
      );
      expect(hasPoints, isFalse);
      expect(spoken.contains('ב'), isTrue); // consonants survive
    });

    test('turns sof pasuq into a full stop for a verse-final cadence', () {
      final spoken = prepareHebrewForSpeech(gen11);
      expect(spoken.contains('׃'), isFalse);
      expect(spoken.endsWith('.'), isTrue);
    });

    test('turns maqaf into a space so joined words are spoken apart', () {
      final spoken = prepareHebrewForSpeech('כָּל־הָאָרֶץ');
      expect(spoken.contains('־'), isFalse);
      expect(spoken.split(' '), hasLength(2));
    });

    test('collapses whitespace and trims', () {
      expect(prepareHebrewForSpeech('  אֵת   אֵת  '), 'אֵת אֵת');
    });

    test('handles empty input', () {
      expect(prepareHebrewForSpeech(''), '');
    });
  });

  group('Greek preparation', () {
    test('folds polytonic to monotonic so a modern voice can read it', () {
      // The engines speak modern Greek and do not know the Extended block.
      expect(toMonotonicGreek('Ἰησοῦ χριστοῦ'), 'Ιησού χριστού');
    });

    test('leaves no Greek Extended characters behind', () {
      const john11 = 'Ἐν ἀρχῇ ἦν ὁ λόγος καὶ ὁ λόγος ἦν πρὸς τὸν θεόν';
      final folded = toMonotonicGreek(john11);
      final residue = folded.codeUnits.any(
        (cu) => cu >= 0x1F00 && cu <= 0x1FFF,
      );
      expect(residue, isFalse);
    });

    test('drops breathings but keeps the accent', () {
      // ἀ (smooth breathing) -> α ; ά keeps its acute.
      expect(toMonotonicGreek('ἀρχή'), 'αρχή');
    });

    test('collapses the grave and circumflex onto the acute', () {
      expect(toMonotonicGreek('πρὸς'), 'προς'.replaceFirst('ο', 'ό'));
      expect(toMonotonicGreek('ἦν'), 'ήν');
    });

    test('leaves plain monotonic Greek untouched', () {
      expect(toMonotonicGreek('λόγος'), 'λόγος');
    });

    test('leaves non-Greek untouched', () {
      expect(toMonotonicGreek('hello'), 'hello');
      expect(toMonotonicGreek(''), '');
    });
  });

  group('prepareForSpeech dispatch', () {
    test('routes Hebrew through the Hebrew path', () {
      final spoken = prepareForSpeech('בָּרָ֣א', isHebrew: true);
      expect(spoken.contains('֣'), isFalse); // munach stripped
    });

    test('routes Greek through the folding path', () {
      final spoken = prepareForSpeech('ἀρχῇ', isHebrew: false);
      expect(spoken, 'αρχή');
    });

    test('spaces commas the source text writes tight against the next word',
        () {
      // Every comma in the bundled Greek lacks a following space, which makes
      // the engine run through the break instead of pausing.
      final spoken = prepareForSpeech(
        'ὁ λόγος,καὶ ὁ θεός',
        isHebrew: false,
      );
      expect(spoken, 'ο λόγος, καί ο θεός');
    });

    test('does not insert a space before an existing one', () {
      final spoken = prepareForSpeech('λόγος, καί', isHebrew: false);
      expect(spoken.contains('  '), isFalse);
    });
  });

  group('voice selection', () {
    test('picks the right BCP-47 tag per testament', () {
      expect(voiceLanguageFor(isHebrew: true), 'he-IL');
      expect(voiceLanguageFor(isHebrew: false), 'el-GR');
    });
  });
}
