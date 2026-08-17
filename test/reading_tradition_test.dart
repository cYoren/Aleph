/// The Tanakh ordering is content, not layout: getting it wrong tells a Jewish
/// reader the app does not know their Bible. These assertions encode the parts
/// that are easy to get subtly wrong.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/reading_tradition.dart';

void main() {
  group('Tanakh order', () {
    final allBooks = kTanakhOrder.values.expand((books) => books).toList();

    test('covers all 39 books of the Hebrew Bible exactly once', () {
      expect(allBooks, hasLength(39));
      expect(allBooks.toSet(), hasLength(39));
    });

    test('contains no New Testament book', () {
      const newTestament = {'MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', 'REV'};
      expect(allBooks.toSet().intersection(newTestament), isEmpty);
    });

    test('Torah is the five books, in order', () {
      expect(kTanakhOrder[TanakhSection.torah], [
        'GEN',
        'EXO',
        'LEV',
        'NUM',
        'DEU',
      ]);
    });

    test('Daniel is among the Writings, not the Prophets', () {
      // The single most common mistake when reordering a Christian canon: in
      // the Tanakh, Daniel is in Ketuvim.
      expect(kTanakhOrder[TanakhSection.ketuvim], contains('DAN'));
      expect(kTanakhOrder[TanakhSection.neviim], isNot(contains('DAN')));
    });

    test('Chronicles closes the canon', () {
      expect(kTanakhOrder[TanakhSection.ketuvim]!.last, '2CH');
    });

    test('the Twelve follow the major prophets, in traditional order', () {
      final prophets = kTanakhOrder[TanakhSection.neviim]!;
      final twelve = prophets.sublist(prophets.indexOf('HOS'));
      expect(twelve, [
        'HOS', 'JOL', 'AMO', 'OBA', 'JON', 'MIC',
        'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL',
      ]);
      expect(prophets.indexOf('ISA'), lessThan(prophets.indexOf('HOS')));
    });

    test('the five Megillot sit together, after the poetic books', () {
      final writings = kTanakhOrder[TanakhSection.ketuvim]!;
      final megillot = ['SNG', 'RUT', 'LAM', 'ECC', 'EST'];
      final positions = megillot.map(writings.indexOf).toList();
      for (var i = 1; i < positions.length; i++) {
        expect(
          positions[i],
          positions[i - 1] + 1,
          reason: 'the Megillot are read as a set and are listed as one',
        );
      }
      expect(positions.first, greaterThan(writings.indexOf('JOB')));
    });
  });

  group('sortForTradition', () {
    List<String> sort(List<String> ids, ReadingTradition tradition) =>
        sortForTradition(ids, tradition, abbreviationOf: (id) => id);

    test('leaves the Christian order untouched', () {
      final input = ['DAN', 'GEN', 'MAT'];
      expect(sort(input, ReadingTradition.christian), input);
    });

    test('reorders into Tanakh sequence', () {
      expect(
        sort(['DAN', 'GEN', 'ISA'], ReadingTradition.jewish),
        ['GEN', 'ISA', 'DAN'],
      );
    });

    test('keeps New Testament books, after the Tanakh', () {
      final sorted = sort(['MAT', 'GEN'], ReadingTradition.jewish);
      expect(sorted, ['GEN', 'MAT'], reason: 'nothing is dropped');
    });
  });

  group('daily verses', () {
    test('the Jewish list never leaves the Tanakh', () {
      final tanakh = kTanakhOrder.values.expand((books) => books).toSet();
      for (final reference in kJewishDailyVerses) {
        expect(
          tanakh,
          contains(reference.split('.').first),
          reason: '$reference is not in the Hebrew Bible',
        );
      }
    });

    test('both lists are non-empty and free of duplicates', () {
      for (final tradition in ReadingTradition.values) {
        final verses = dailyVersesFor(tradition);
        expect(verses, isNotEmpty);
        expect(verses.toSet(), hasLength(verses.length));
      }
    });
  });
}
