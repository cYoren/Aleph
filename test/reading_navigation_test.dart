import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/features/reading/reading_provider.dart';
import 'package:original_bible/shared/utils/reading_tradition.dart';

/// Four places let a reader pick a verse — a bookmark, a search hit, a
/// cross-reference and the concordance — and all four used to land on verse 1
/// of the chapter with no way back. These cover the state that fixed it.
void main() {
  group('reading history', () {
    ReadingState withVerses(ReadingState state) =>
        state.copyWith(
          verses: [
            Verse(
              id: 'PSA.119.1',
              bookId: 'PSA',
              chapter: 119,
              verseNumber: 1,
              textContent: 'x',
            ),
          ],
        );

    test('a fresh state has nothing to go back to', () {
      expect(const ReadingState().canGoBack, isFalse);
    });

    test('history records where the reader jumped from', () {
      var state = withVerses(const ReadingState(bookId: 'GEN', chapter: 1));
      state = state.copyWith(
        history: [...state.history, const ReadingLocation('GEN', 1, 1)],
        bookId: 'PSA',
        chapter: 119,
        targetVerse: 105,
      );

      expect(state.canGoBack, isTrue);
      expect(state.history.single, const ReadingLocation('GEN', 1, 1));
      expect(state.targetVerse, 105);
    });

    test('targetVerse can be cleared once the reader has seen it', () {
      const state = ReadingState(targetVerse: 105);
      expect(state.copyWith(targetVerse: null).targetVerse, isNull);
    });

    test('copyWith leaves targetVerse alone when it is not passed', () {
      const state = ReadingState(targetVerse: 105);
      expect(state.copyWith(chapter: 120).targetVerse, 105);
    });

    test('locations compare by value, so a no-op jump can be detected', () {
      expect(
        const ReadingLocation('GEN', 1, 1),
        const ReadingLocation('GEN', 1, 1),
      );
      expect(
        const ReadingLocation('GEN', 1, 1),
        isNot(const ReadingLocation('GEN', 1, 2)),
      );
    });
  });

  group('search results', () {
    test('a full page with more behind it reports as truncated', () {
      const results = SearchResults(verses: [], totalMatches: 114);
      expect(results.isTruncated, isTrue);
    });

    test('a page holding every match is not truncated', () {
      expect(SearchResults.empty.isTruncated, isFalse);
    });
  });

  group('isOldTestamentBook', () {
    // This set decides script, font and text direction. It used to be written
    // out as a literal in two separate screens.
    test('covers all 39 books of the Hebrew Bible', () {
      expect(kHebrewBibleBooks, hasLength(39));
      for (final book in ['GEN', 'PSA', 'MAL', 'DAN', '2CH', 'RUT']) {
        expect(isOldTestamentBook(book), isTrue, reason: book);
      }
    });

    test('excludes the Greek New Testament', () {
      for (final book in ['MAT', 'JHN', 'ROM', 'REV', '1PE']) {
        expect(isOldTestamentBook(book), isFalse, reason: book);
      }
    });

    test('is not confused by case or stray whitespace', () {
      expect(isOldTestamentBook(' gen '), isTrue);
      expect(isOldTestamentBook(''), isFalse);
    });
  });
}
