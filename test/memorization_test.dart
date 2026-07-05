import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/memorization.dart';

void main() {
  group('selectHiddenWordIndices', () {
    test('warm-up hides about 30% of words', () {
      final hidden = selectHiddenWordIndices(
        wordCount: 10,
        level: MemorizationLevel.warmUp,
        seed: 42,
      );
      expect(hidden.length, 3);
      expect(hidden.every((i) => i >= 0 && i < 10), isTrue);
    });

    test('challenge hides about 60% of words', () {
      final hidden = selectHiddenWordIndices(
        wordCount: 10,
        level: MemorizationLevel.challenge,
        seed: 42,
      );
      expect(hidden.length, 6);
    });

    test('first-letters level hides every word', () {
      final hidden = selectHiddenWordIndices(
        wordCount: 7,
        level: MemorizationLevel.firstLetters,
        seed: 42,
      );
      expect(hidden, {0, 1, 2, 3, 4, 5, 6});
    });

    test('same seed gives the same selection (stable practice)', () {
      final a = selectHiddenWordIndices(
        wordCount: 12,
        level: MemorizationLevel.challenge,
        seed: 99,
      );
      final b = selectHiddenWordIndices(
        wordCount: 12,
        level: MemorizationLevel.challenge,
        seed: 99,
      );
      expect(a, b);
    });

    test('different seeds give different selections', () {
      final a = selectHiddenWordIndices(
        wordCount: 20,
        level: MemorizationLevel.challenge,
        seed: 1,
      );
      final b = selectHiddenWordIndices(
        wordCount: 20,
        level: MemorizationLevel.challenge,
        seed: 2,
      );
      expect(a, isNot(equals(b)));
    });

    test('empty verse hides nothing', () {
      expect(
        selectHiddenWordIndices(
          wordCount: 0,
          level: MemorizationLevel.challenge,
          seed: 1,
        ),
        isEmpty,
      );
    });
  });

  group('defaultLevelForRepetitions', () {
    test('progression follows recall streak', () {
      expect(defaultLevelForRepetitions(0), MemorizationLevel.warmUp);
      expect(defaultLevelForRepetitions(1), MemorizationLevel.warmUp);
      expect(defaultLevelForRepetitions(2), MemorizationLevel.challenge);
      expect(defaultLevelForRepetitions(3), MemorizationLevel.challenge);
      expect(defaultLevelForRepetitions(4), MemorizationLevel.firstLetters);
    });
  });

  group('firstLetterHint', () {
    test('keeps the vowel point of a pointed Hebrew letter', () {
      // בְּרֵאשִׁית -> בְּ…  (bet + sheva + dagesh kept together)
      const word = 'בְּרֵאשִׁית';
      final hint = firstLetterHint(word);
      expect(hint.endsWith('…'), isTrue);
      expect(hint.codeUnits.first, 0x05D1); // bet
      expect(hint.contains('ר'), isFalse);
    });

    test('plain latin word keeps one letter', () {
      expect(firstLetterHint('word'), 'w…');
    });

    test('empty word yields ellipsis', () {
      expect(firstLetterHint(''), '…');
    });
  });

  group('tokenizeVerse', () {
    test('splits on any whitespace and drops empties', () {
      expect(tokenizeVerse('  אָמַר  יְהוָה \n אֶל '), [
        'אָמַר',
        'יְהוָה',
        'אֶל',
      ]);
    });
  });
}
