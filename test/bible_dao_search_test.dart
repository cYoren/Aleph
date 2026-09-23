import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'search results follow canonical book order, not book-code order',
    () async {
      final results = await BibleDAO().search('love', translationId: 'kjv');

      expect(results, isNotEmpty);
      // Alphabetical book codes would put 1CO first.
      expect(results.first.bookId, 'GEN');
    },
  );

  test('chapter translation lookup ignores translation id case', () async {
    final verses = await BibleDAO().getTranslationVersesForChapter(
      'JHN',
      3,
      'almeida',
    );

    expect(verses['JHN.3.16'], isNotEmpty);
  });
}
