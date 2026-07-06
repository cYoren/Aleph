import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/search_fold.dart';

void main() {
  group('foldForSearch', () {
    test('strips Hebrew pointing so unpointed input matches', () {
      expect(foldForSearch('אֱלֹהִים'), 'אלהים');
      expect(foldForSearch('אלהים'), 'אלהים');
    });

    test('strips Greek accents and breathing marks', () {
      expect(foldForSearch('ἀγάπη'), 'αγαπη');
      // Final sigma folds to sigma so mid-word and typed forms match.
      expect(foldForSearch('λόγος'), 'λογοσ');
      expect(foldForSearch('Θεός'), foldForSearch('θεος'));
    });

    test('folds Strong-style transliterations to plain ascii', () {
      expect(foldForSearch('ʼĕlôhîym'), 'elohiym');
      expect(foldForSearch('agápē'), 'agape');
    });

    test('lowercases and trims', () {
      expect(foldForSearch('  ELOHIM  '), 'elohim');
    });

    test('plain english passes through', () {
      expect(foldForSearch('love'), 'love');
    });

    test('strongs ids keep digits', () {
      expect(foldForSearch('H430'), 'h430');
    });
  });
}
