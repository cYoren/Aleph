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
  test('falls back to KJV and persists normalized translation', () async {
    final dao = _FakeBibleDAO({
      'ACF': const {},
      'KJV': const {
        'GEN.1.1': 'In the beginning God created the heavens and the earth.',
      },
    });

    final persisted = <String>[];

    final translations = await loadTranslationsWithFallback(
      dao: dao,
      bookId: 'GEN',
      chapter: 1,
      preferredTranslation: 'ACF',
      persistNormalizedTranslation: (code) async {
        persisted.add(code);
      },
    );

    expect(dao.requestedTranslations, equals(['ACF', 'KJV']));
    expect(translations.isNotEmpty, isTrue);
    expect(persisted, equals(['KJV']));
  });

  test('does not fallback when preferred translation has data', () async {
    final dao = _FakeBibleDAO({
      'KJV': const {
        'GEN.1.1': 'In the beginning God created the heavens and the earth.',
      },
    });

    final persisted = <String>[];

    final translations = await loadTranslationsWithFallback(
      dao: dao,
      bookId: 'GEN',
      chapter: 1,
      preferredTranslation: 'KJV',
      persistNormalizedTranslation: (code) async {
        persisted.add(code);
      },
    );

    expect(dao.requestedTranslations, equals(['KJV']));
    expect(translations.isNotEmpty, isTrue);
    expect(persisted, isEmpty);
  });
}
