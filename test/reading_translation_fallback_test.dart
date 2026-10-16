import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/features/reading/reading_provider.dart';

class _FakeBibleDAO extends BibleDAO {
  _FakeBibleDAO(this.responsesByTranslation);

  final Map<String, Map<String, String>> responsesByTranslation;
  final List<String> requestedTranslations = [];

  @override
  Future<Map<String, String>> getTranslationVersesForChapter(
    String bookId,
    int chapter,
    String translationId,
  ) async {
    requestedTranslations.add(translationId);
    return responsesByTranslation[translationId] ?? const {};
  }
}

void main() {
  test('a missing chapter never silently substitutes English', () async {
    final dao = _FakeBibleDAO({
      'ALMEIDA': const {},
      'KJV': const {
        'GEN.1.1': 'In the beginning God created the heavens and the earth.',
      },
    });

    final translations = await loadChapterTranslations(
      dao: dao,
      bookId: 'GEN',
      chapter: 1,
      translationId: 'ALMEIDA',
    );

    expect(dao.requestedTranslations, equals(['ALMEIDA']));
    expect(translations, isEmpty);
  });

  test('keeps an explicitly selected English translation', () async {
    final dao = _FakeBibleDAO({
      'KJV': const {
        'GEN.1.1': 'In the beginning God created the heavens and the earth.',
      },
    });

    final translations = await loadChapterTranslations(
      dao: dao,
      bookId: 'GEN',
      chapter: 1,
      translationId: 'kjv',
    );

    expect(dao.requestedTranslations, equals(['KJV']));
    expect(translations.isNotEmpty, isTrue);
  });

  for (final edition in [
    'ALMEIDA',
    'LUTHER1912',
    'OSTERVALD',
    'VALERA1909',
    'SYNODAL',
    'CUVS',
    'KOREAN',
  ]) {
    test('loads $edition without mixing in English verses', () async {
      final dao = _FakeBibleDAO({
        edition: {'GEN.1.1': 'localized-$edition'},
        'KJV': {'GEN.1.2': 'English fallback'},
      });
      final translations = await loadChapterTranslations(
        dao: dao,
        bookId: 'GEN',
        chapter: 1,
        translationId: ' ${edition.toLowerCase()} ',
      );
      expect(translations, {'GEN.1.1': 'localized-$edition'});
      expect(dao.requestedTranslations, [edition]);
    });
  }
}
