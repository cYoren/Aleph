import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/hebrew_display.dart';

void main() {
  // Genesis 1:1 opening word with niqqud + cantillation (tipcha U+0596).
  const pointed = 'בְּרֵאשִׁ֖ית';
  const noCantillation = 'בְּרֵאשִׁית';
  const consonantal = 'בראשית';

  group('applyHebrewDisplay', () {
    test('full mode returns text unchanged', () {
      expect(applyHebrewDisplay(pointed, HebrewTextDisplay.full), pointed);
    });

    test('noCantillation strips accents but keeps vowels', () {
      expect(
        applyHebrewDisplay(pointed, HebrewTextDisplay.noCantillation),
        noCantillation,
      );
    });

    test('consonantal strips all pointing including shin dot', () {
      expect(
        applyHebrewDisplay(pointed, HebrewTextDisplay.consonantal),
        consonantal,
      );
    });

    test('maqaf and sof pasuq survive consonantal mode', () {
      // עַל־פְּנֵי with maqaf (U+05BE), plus sof pasuq (U+05C3)
      const withPunctuation = 'עַל־פְּנֵ֥י׃';
      final result = applyHebrewDisplay(
        withPunctuation,
        HebrewTextDisplay.consonantal,
      );
      expect(result, 'על־פני׃');
    });

    test('qamats qatan (U+05C7) is stripped in consonantal mode', () {
      const withQamatsQatan = 'כׇּל';
      expect(
        applyHebrewDisplay(withQamatsQatan, HebrewTextDisplay.consonantal),
        'כל',
      );
    });

    test('non-Hebrew text passes through untouched', () {
      const greek = 'Ἐν ἀρχῇ ἦν ὁ λόγος';
      expect(
        applyHebrewDisplay(greek, HebrewTextDisplay.consonantal),
        greek,
      );
    });

    test('fromName parses stored preference values', () {
      expect(
        HebrewTextDisplay.fromName('noCantillation'),
        HebrewTextDisplay.noCantillation,
      );
      expect(
        HebrewTextDisplay.fromName('consonantal'),
        HebrewTextDisplay.consonantal,
      );
      expect(HebrewTextDisplay.fromName(null), HebrewTextDisplay.full);
      expect(HebrewTextDisplay.fromName('bogus'), HebrewTextDisplay.full);
    });
  });
}
