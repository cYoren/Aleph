import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/hebrew_syllables.dart';

void main() {
  group('syllable division', () {
    test('divides bərēʾšîṯ into three syllables', () {
      // The quiescent alef is still transcribed and closes its syllable, as in
      // the lexicon's own transliteration column.
      final word = syllabifyHebrew('בְּרֵאשִׁ֖ית');
      expect(word.syllables.map((s) => s.text).toList(), hasLength(3));
      expect(word.segmented, 'bə·rēʾ·šîṯ');
    });

    test('divides bārāʾ into two', () {
      final word = syllabifyHebrew('בָּרָ֣א');
      expect(word.segmented, 'bā·rāʾ');
    });

    test('handles a word with a quiescent final he', () {
      // tôrāh — the final he is a vowel letter, not a consonant.
      final word = syllabifyHebrew('תּוֹרָה');
      expect(word.flat, 'tôrā');
    });
  });

  group('stress marking', () {
    test('marks final stress under tipcha', () {
      final word = syllabifyHebrew('בְּרֵאשִׁ֖ית');
      expect(word.stressKnown, isTrue);
      expect(word.syllables.last.stressed, isTrue);
      expect(word.marked, 'bə·rēʾ·ˈšîṯ');
    });

    test('marks stress under munach', () {
      final word = syllabifyHebrew('בָּרָ֣א');
      expect(word.stressKnown, isTrue);
      expect(word.marked, 'bā·ˈrāʾ');
    });

    test('marks penultimate stress on a segolate under silluq', () {
      // hā·ˈʾā·reṣ — the tone falls back off the last syllable.
      final word = syllabifyHebrew('הָאָֽרֶץ', isVerseFinal: true);
      expect(word.stressKnown, isTrue);
      final stressed = word.syllables.indexWhere((s) => s.stressed);
      expect(stressed, isNot(word.syllables.length - 1),
          reason: 'segolate nouns take the tone off the final syllable');
    });

    test('emits no stress mark when the accent cannot show it', () {
      // Pashta is postpositive.
      final word = syllabifyHebrew('וַיֹּ֙אמֶר֙');
      expect(word.stressKnown, isFalse);
      expect(word.marked, word.segmented);
      expect(word.marked.contains('ˈ'), isFalse);
    });

    test('emits no stress mark for an unaccented token', () {
      final word = syllabifyHebrew('בְּ');
      expect(word.stressKnown, isFalse);
    });
  });

  group('consonant realisation', () {
    test('spirantizes bgdkpt after a vowel', () {
      // The tav of bərēšîṯ has no dagesh and follows a vowel.
      expect(syllabifyHebrew('בְּרֵאשִׁ֖ית').flat.endsWith('ṯ'), isTrue);
    });

    test('keeps the plosive when a dagesh is present', () {
      // Initial bet with dagesh lene.
      expect(syllabifyHebrew('בָּרָ֣א').flat.startsWith('b'), isTrue);
    });

    test('distinguishes shin from sin by the dot', () {
      expect(syllabifyHebrew('שָׁלוֹם').flat.startsWith('š'), isTrue);
      expect(syllabifyHebrew('שָׂדֶה').flat.startsWith('ś'), isTrue);
    });

    test('doubles a letter with dagesh forte', () {
      // haš·šā·ma·yim — the shin is doubled after the article.
      final word = syllabifyHebrew('הַשָּׁמַ֖יִם');
      expect(word.flat.contains('šš'), isTrue);
    });
  });

  group('vowel letters', () {
    test('reads hiriq + yod as î', () {
      expect(syllabifyHebrew('בְּרֵאשִׁ֖ית').flat.contains('î'), isTrue);
    });

    test('reads holam + vav as ô', () {
      expect(syllabifyHebrew('תּוֹרָה').flat.contains('ô'), isTrue);
    });
  });

  group('vocal and silent shva', () {
    test('treats word-initial shva as vocal', () {
      expect(syllabifyHebrew('בְּרֵאשִׁ֖ית').syllables.first.text, 'bə');
    });

    test('does not open a syllable on a silent shva', () {
      // mal·kî — the lamed's shva is silent and closes the first syllable.
      final word = syllabifyHebrew('מַלְכִּי');
      expect(word.segmented, 'mal·kî');
    });
  });

  group('edge cases', () {
    test('returns empty for empty input', () {
      expect(syllabifyHebrew('').isEmpty, isTrue);
      expect(syllabifyHebrew('').marked, '');
    });

    test('returns empty for text with no Hebrew letters', () {
      expect(syllabifyHebrew('123 abc').isEmpty, isTrue);
    });

    test('handles unpointed consonantal text without crashing', () {
      final word = syllabifyHebrew('שלום');
      expect(word.stressKnown, isFalse);
      expect(word.flat, isNotEmpty);
    });
  });
}
