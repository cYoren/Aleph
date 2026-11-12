import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/vocabulary_filter.dart';

void main() {
  group('proclitic prefixes', () {
    test('rejects the Hebrew prefixes that head the raw frequency table', () {
      // These are the five most common "words" in the token table, and none of
      // them is vocabulary — they are prefixes the tokenizer split off.
      for (final prefix in ['וְ', 'הַ', 'לְ', 'בְּ', 'מִ']) {
        expect(
          isProcliticPrefix(prefix, isHebrew: true),
          isTrue,
          reason: '$prefix should be treated as a prefix',
        );
      }
    });

    test('keeps real Hebrew words of two or more consonants', () {
      for (final word in ['אֵת', 'עַל', 'כֹּל', 'יהוה', 'אֶל', 'אֲשֶׁר']) {
        expect(
          isProcliticPrefix(word, isHebrew: true),
          isFalse,
          reason: '$word is a real word',
        );
      }
    });

    test('never treats Greek as prefixed', () {
      expect(isProcliticPrefix('ὁ', isHebrew: false), isFalse);
    });
  });

  group('consonant counting', () {
    test('ignores vowel points, dagesh, and accents', () {
      // b-r-'-sh-y-t: six letters, counting the mater yod, ignoring the
      // shva, tsere, dagesh, hiriq, shin dot, and tipcha.
      expect(hebrewConsonantCount('בְּרֵאשִׁ֖ית'), 6);
      expect(hebrewConsonantCount('וְ'), 1);
      expect(hebrewConsonantCount('אֵת'), 2);
    });

    test('counts Greek letters including polytonic', () {
      expect(greekLetterCount('ὁ'), 1);
      expect(greekLetterCount('λόγος'), 5);
    });
  });

  group('deck worthiness', () {
    test('rejects an id with no lexicon entry', () {
      // Several Strong's ids in the token table have no lexicon row at all and
      // would render as an empty card.
      expect(
        isDeckWorthy(lemma: null, gloss: null, isHebrew: true),
        isFalse,
      );
      expect(
        isDeckWorthy(lemma: '', gloss: '', isHebrew: true),
        isFalse,
      );
    });

    test('rejects an entry with a lemma but no gloss', () {
      expect(
        isDeckWorthy(lemma: 'דָּבָר', gloss: '  ', isHebrew: true),
        isFalse,
      );
    });

    test('rejects a gloss that carries no actual word', () {
      expect(
        isDeckWorthy(lemma: 'אֵת', gloss: '---', isHebrew: true),
        isFalse,
      );
    });

    test('accepts ordinary Hebrew vocabulary', () {
      expect(
        isDeckWorthy(lemma: 'יהוה', gloss: 'LORD', isHebrew: true),
        isTrue,
      );
      expect(
        isDeckWorthy(lemma: 'כֹּל', gloss: 'all', isHebrew: true),
        isTrue,
      );
    });

    test('accepts ordinary Greek vocabulary, including short words', () {
      // Greek has no proclitic splitting, so one-letter words stay.
      expect(isDeckWorthy(lemma: 'ὁ', gloss: 'the', isHebrew: false), isTrue);
      expect(
        isDeckWorthy(lemma: 'θεός', gloss: 'God', isHebrew: false),
        isTrue,
      );
    });

    test('rejects a lemma written in the wrong script', () {
      expect(
        isDeckWorthy(lemma: 'abc', gloss: 'word', isHebrew: true),
        isFalse,
      );
    });

    test('rejects the bare object-marker gloss "(et)"', () {
      // The letters inside the parentheses are a transliteration, not a
      // meaning. This card used to head the Hebrew deck and then leak its
      // gloss into every later review.
      expect(
        isDeckWorthy(lemma: 'אֵת', gloss: '(et)', isHebrew: true),
        isFalse,
      );
    });

    test('keeps a gloss that only adds a parenthetical transliteration', () {
      expect(
        isDeckWorthy(lemma: 'אֱלֹהִים', gloss: 'God (Elohim)', isHebrew: true),
        isTrue,
      );
    });

    test('accepts translated glosses in every shipped script', () {
      // The deck is built from the localized gloss once the reader picks a
      // language. A Latin/Greek/Hebrew-only letter test emptied the Korean,
      // Russian and Chinese decks, leaving a single card.
      expect(
        isDeckWorthy(lemma: 'מִן', gloss: '~로부터', isHebrew: true),
        isTrue,
        reason: 'Korean',
      );
      expect(
        isDeckWorthy(lemma: 'מִן', gloss: 'из', isHebrew: true),
        isTrue,
        reason: 'Russian',
      );
      expect(
        isDeckWorthy(lemma: 'מִן', gloss: '从', isHebrew: true),
        isTrue,
        reason: 'Chinese',
      );
      expect(
        isDeckWorthy(lemma: 'מִן', gloss: 'von', isHebrew: true),
        isTrue,
        reason: 'German',
      );
    });
  });
}
