import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/data/models/book.dart';

void main() {
  group('Verse', () {
    test('fromMap creates Verse correctly', () {
      final map = {
        'id': 'GEN.1.1',
        'book_id': 'GEN',
        'chapter': 1,
        'verse': 1,
        'text_content': 'בְּרֵאשִׁית בָּרָא אֱלֹהִים',
      };

      final verse = Verse.fromMap(map);

      expect(verse.id, equals('GEN.1.1'));
      expect(verse.bookId, equals('GEN'));
      expect(verse.chapter, equals(1));
      expect(verse.verseNumber, equals(1));
      expect(verse.textContent, contains('בְּרֵאשִׁית'));
    });

    test('fromMap handles string numbers', () {
      final map = {
        'id': 'GEN.1.2',
        'book_id': 'GEN',
        'chapter': '1',
        'verse': '2',
        'text_content': 'Test content',
      };

      final verse = Verse.fromMap(map);

      expect(verse.chapter, equals(1));
      expect(verse.verseNumber, equals(2));
    });

    test('fromMap handles null values gracefully', () {
      final map = <String, dynamic>{
        'id': null,
        'book_id': null,
        'chapter': null,
        'verse': null,
        'text_content': null,
      };

      final verse = Verse.fromMap(map);

      expect(verse.id, equals(''));
      expect(verse.bookId, equals(''));
      expect(verse.chapter, equals(0));
      expect(verse.verseNumber, equals(0));
      expect(verse.textContent, equals(''));
    });
  });

  group('Word', () {
    test('fromMap creates Word correctly', () {
      final map = {
        'id': 1,
        'verse_id': 'GEN.1.1',
        'position': 0,
        'display_text': 'בְּרֵאשִׁית',
        'lemma': 'רֵאשִׁית',
        'strongs': 'H7225',
        'morph_code': 'HNcfsa',
        'language': 'heb',
      };

      final word = Word.fromMap(map);

      expect(word.id, equals(1));
      expect(word.verseId, equals('GEN.1.1'));
      expect(word.position, equals(0));
      expect(word.displayText, equals('בְּרֵאשִׁית'));
      expect(word.lemma, equals('רֵאשִׁית'));
      expect(word.strongs, equals('H7225'));
      expect(word.morphCode, equals('HNcfsa'));
      expect(word.language, equals('heb'));
    });

    test('fromMap handles Greek words', () {
      final map = {
        'id': 100,
        'verse_id': 'JHN.1.1',
        'position': 0,
        'display_text': 'Ἐν',
        'lemma': 'ἐν',
        'strongs': 'G1722',
        'morph_code': 'PREP',
        'language': 'grc',
      };

      final word = Word.fromMap(map);

      expect(word.language, equals('grc'));
      expect(word.strongs, startsWith('G'));
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'id': 1,
        'verse_id': 'GEN.1.1',
        'position': 0,
        'display_text': 'Test',
        'language': 'heb',
      };

      final word = Word.fromMap(map);

      expect(word.lemma, isNull);
      expect(word.strongs, isNull);
      expect(word.morphCode, isNull);
    });
  });

  group('Book', () {
    test('fromMap creates Book correctly', () {
      final map = {
        'id': 1,
        'abbreviation': 'GEN',
        'name_en': 'Genesis',
        'testament': 'OT',
        'book_order': 1,
        'chapter_count': 50,
      };

      final book = Book.fromMap(map);

      expect(book.id, equals(1));
      expect(book.abbreviation, equals('GEN'));
      expect(book.name, equals('Genesis'));
      expect(book.testament, equals('OT'));
      expect(book.order, equals(1));
      expect(book.chapterCount, equals(50));
    });

    test('effectiveChapterCount uses fallback when chapterCount is 0', () {
      final map = {
        'id': 1,
        'abbreviation': 'GEN',
        'name_en': 'Genesis',
        'testament': 'OT',
        'book_order': 1,
        'chapter_count': 0,
      };

      final book = Book.fromMap(map);

      expect(
        book.effectiveChapterCount,
        equals(50),
      ); // From standardChapterCounts
    });
  });
}
