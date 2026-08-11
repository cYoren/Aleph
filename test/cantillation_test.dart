import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/cantillation.dart';

/// Genesis 1:1 as it stands in the bundled Leningrad text, word by word.
const _gen11 = <String>[
  'בְּרֵאשִׁ֖ית', // tipcha
  'בָּרָ֣א', // munach
  'אֱלֹהִ֑ים', // etnachta
  'אֵ֥ת', // merkha
  'הַשָּׁמַ֖יִם', // tipcha
  'וְאֵ֥ת', // merkha
  'הָאָֽרֶץ׃', // silluq + sof pasuq
];

void main() {
  group('accent identification', () {
    test('reads the governing accent of each word of Genesis 1:1', () {
      expect(primaryTaam(_gen11[0])?.name, 'Tipcha');
      expect(primaryTaam(_gen11[1])?.name, 'Munach');
      expect(primaryTaam(_gen11[2])?.name, 'Etnachta');
      expect(primaryTaam(_gen11[3])?.name, 'Merkha');
      expect(primaryTaam(_gen11[4])?.name, 'Tipcha');
      expect(primaryTaam(_gen11[5])?.name, 'Merkha');
    });

    test('classifies disjunctives and conjunctives', () {
      expect(primaryTaam(_gen11[0])!.isDisjunctive, isTrue); // tipcha
      expect(primaryTaam(_gen11[1])!.isDisjunctive, isFalse); // munach
      expect(primaryTaam(_gen11[2])!.isDisjunctive, isTrue); // etnachta
      expect(primaryTaam(_gen11[2])!.rank, 1); // splits the verse
      expect(primaryTaam(_gen11[0])!.rank, 2);
    });

    test('reads U+05BD as silluq only on the final word', () {
      // Verse-final: silluq, the strongest disjunctive.
      final asSilluq = primaryTaam(_gen11[6], isVerseFinal: true);
      expect(asSilluq?.name, 'Silluq');
      expect(asSilluq?.rank, 1);

      // Elsewhere the same glyph is meteg, which is pointing, not an accent.
      expect(primaryTaam(_gen11[6]), isNull);
    });

    test('returns null for morphologically split tokens with no accent', () {
      // The words table splits prefixes out; they carry no accent of their own.
      expect(primaryTaam('בְּ'), isNull);
      expect(primaryTaam('הַ'), isNull);
      expect(primaryTaam(''), isNull);
    });
  });

  group('stress detection', () {
    test('locates the stressed consonant under an impositive accent', () {
      // bərēˈšîṯ — tipcha sits on the shin, so the tone is on the last
      // syllable, as expected for this word.
      final index = stressedConsonantIndex(_gen11[0]);
      expect(index, isNotNull);
      expect(_gen11[0][index!], 'ש');
    });

    test('locates stress in bārāʾ', () {
      // bāˈrāʾ — munach on the resh.
      final index = stressedConsonantIndex(_gen11[1]);
      expect(index, isNotNull);
      expect(_gen11[1][index!], 'ר');
    });

    test('locates stress under silluq on the final word', () {
      // hā-ˈʾāreṣ — silluq on the alef: penultimate stress (segolate noun).
      final index = stressedConsonantIndex(_gen11[6], isVerseFinal: true);
      expect(index, isNotNull);
      expect(_gen11[6][index!], 'א');
    });

    test('refuses to guess when the accent is postpositive', () {
      // Pashta is always written on the final letter regardless of stress,
      // so it cannot tell us where the tone falls.
      const withPashta = 'וַיֹּ֙אמֶר֙';
      expect(primaryTaam(withPashta)?.name, 'Pashta');
      expect(primaryTaam(withPashta)!.marksStress, isFalse);
      expect(stressedConsonantIndex(withPashta), isNull);
    });

    test('refuses to guess when the accent is prepositive', () {
      // Telisha gedola is always written on the first letter.
      const withTelishaGedola = 'וְ֠אָמַר';
      expect(primaryTaam(withTelishaGedola)?.name, 'Telisha gedola');
      expect(stressedConsonantIndex(withTelishaGedola), isNull);
    });

    test('returns null for unaccented text', () {
      expect(stressedConsonantIndex('בְּ'), isNull);
      expect(stressedConsonantIndex('שלום'), isNull);
    });
  });

  group('sense units', () {
    test('rank 1 splits Genesis 1:1 at the etnachta', () {
      final units = senseUnits(_gen11, upToRank: 1);

      // "In the beginning God created" // "the heavens and the earth"
      expect(units, hasLength(2));
      expect(units[0].wordIndices, [0, 1, 2]);
      expect(units[0].closingTaam?.name, 'Etnachta');
      expect(units[1].wordIndices, [3, 4, 5, 6]);
      expect(units[1].closingTaam?.name, 'Silluq');
    });

    test('rank 2 gives the four traditional phrases', () {
      final units = senseUnits(_gen11, upToRank: 2);

      // bərēšiṯ / bārāʾ ʾĕlōhîm / ʾēṯ haššāmayim / wəʾēṯ hāʾāreṣ
      expect(units, hasLength(4));
      expect(units[0].wordIndices, [0]);
      expect(units[1].wordIndices, [1, 2]);
      expect(units[2].wordIndices, [3, 4]);
      expect(units[3].wordIndices, [5, 6]);
    });

    test('reports break strength per unit', () {
      final units = senseUnits(_gen11, upToRank: 2);
      expect(units[0].breakRank, 2); // tipcha
      expect(units[1].breakRank, 1); // etnachta — the great divide
      expect(units[2].breakRank, 2); // tipcha
      expect(units[3].breakRank, 1); // silluq
    });

    test('every word lands in exactly one unit', () {
      for (final rank in [1, 2, 3, 4]) {
        final units = senseUnits(_gen11, upToRank: rank);
        final covered = units.expand((u) => u.wordIndices).toList();
        expect(
          covered,
          List.generate(_gen11.length, (i) => i),
          reason: 'rank $rank must partition the verse in order',
        );
      }
    });

    test('handles unaccented and empty input', () {
      expect(senseUnits(const []), isEmpty);

      final units = senseUnits(const ['שלום', 'עולם']);
      expect(units, hasLength(1));
      expect(units.first.wordIndices, [0, 1]);
      expect(units.first.closingTaam, isNull);
      expect(units.first.breakRank, 5);
    });
  });

  group('stripCantillation', () {
    test('removes accents but keeps consonants and vowel points', () {
      final stripped = stripCantillation('בְּרֵאשִׁ֖ית');
      expect(stripped.contains('֖'), isFalse); // tipcha gone
      expect(stripped.contains('ְ'), isTrue); // shva kept
      expect(stripped.contains('ִ'), isTrue); // hiriq kept
      expect(stripped.contains('ב'), isTrue);
    });

    test('keeps meteg, which affects how a word is read aloud', () {
      const withMeteg = 'הָאָֽרֶץ';
      expect(stripCantillation(withMeteg).contains('ֽ'), isTrue);
    });

    test('leaves Greek and Latin untouched', () {
      expect(stripCantillation('Ἐν ἀρχῇ ἦν ὁ λόγος'), 'Ἐν ἀρχῇ ἦν ὁ λόγος');
      expect(stripCantillation(''), '');
    });
  });
}
