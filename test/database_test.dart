import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _expectedMissingKjvRefs = <String>{};
const _requiredEnabledTranslationIds = <String>{
  'KJV',
  'ALMEIDA',
  'LUTHER1912',
  'OSTERVALD',
  'SYNODAL',
  'VALERA1909',
  'CUVS',
  'KOREAN',
};
const _legacyKjvGapRefs = <String>{
  '1CH 12:5',
  '1KI 22:44',
  '1SA 21:1',
  '3JN 1:15',
  'NUM 26:1',
  'PSA 51:2',
  'PSA 52:2',
  'PSA 54:2',
  'PSA 60:2',
  'REV 13:1',
  'ROM 16:24',
};

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  String getDbPath() => p.join(Directory.current.path, 'assets', 'bible.db');

  group('Database Schema', () {
    test('bible.db has required tables', () async {
      final dbPath = getDbPath();
      expect(
        File(dbPath).existsSync(),
        isTrue,
        reason: 'bible.db should exist in assets/',
      );

      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tableNames = tables.map((t) => t['name'] as String).toList();

      expect(tableNames, contains('books'));
      expect(tableNames, contains('verses'));
      expect(tableNames, contains('translations'));
      expect(tableNames, contains('translation_verses'));
      expect(tableNames, contains('translation_ref_map'));
      expect(tableNames, contains('words'));
      expect(tableNames, contains('lexicon'));

      await db.close();
    });

    test('depth layers are present at release scale', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      Future<int> count(String sql) async =>
          (await db.rawQuery(sql)).first.values.first as int;

      // Numbered senses: what the definition sheet renders instead of one
      // flattened paragraph. Measured 17,030 rows over 1,807 Hebrew and 5,249
      // Greek entries; the gate sits under that.
      expect(
        await count('SELECT COUNT(*) FROM lexicon_senses'),
        greaterThanOrEqualTo(16000),
      );
      expect(
        await count(
          "SELECT COUNT(DISTINCT strongs_id) FROM lexicon_senses "
          "WHERE source = 'BDB'",
        ),
        greaterThanOrEqualTo(1700),
      );
      expect(
        await count(
          "SELECT COUNT(DISTINCT strongs_id) FROM lexicon_senses "
          "WHERE source = 'Abbott-Smith'",
        ),
        greaterThanOrEqualTo(5100),
      );

      // Hebrew roots from TWOT: the basis of root search across binyanim.
      expect(
        await count('SELECT COUNT(*) FROM lexicon_roots'),
        greaterThanOrEqualTo(4800),
      );
      expect(
        await count('SELECT COUNT(DISTINCT twot) FROM lexicon_roots'),
        greaterThanOrEqualTo(2000),
      );

      // MACULA participant links: "who is he in this verse".
      expect(
        await count(
          'SELECT COUNT(*) FROM words WHERE subject_text IS NOT NULL '
          'OR referent_text IS NOT NULL',
        ),
        greaterThanOrEqualTo(40000),
      );

      // Qere/Ketiv: the written form and the reading, both stored.
      expect(
        await count(
          'SELECT COUNT(*) FROM words WHERE qere_text IS NOT NULL '
          'AND ketiv_text IS NOT NULL',
        ),
        greaterThanOrEqualTo(1100),
      );
      // The reading is a different word in a few dozen places; the sheet names
      // its dictionary form, so those rows must carry one.
      expect(
        await count('SELECT COUNT(*) FROM words WHERE qere_lemma IS NOT NULL'),
        greaterThanOrEqualTo(20),
      );
      final qere = await db.query(
        'words',
        columns: ['word', 'qere_text', 'ketiv_text'],
        where: 'qere_text IS NOT NULL AND ketiv_text IS NOT NULL',
        orderBy: 'id ASC',
        limit: 1,
      );
      expect(qere, hasLength(1));
      expect(qere.first['qere_text'], isNot(qere.first['ketiv_text']));

      await db.close();
    });

    test('a Hebrew root groups words across Strong\'s numbers', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      // בָּרַךְ (to bless) and בְּרָכָה (a blessing) are separate Strong's
      // numbers on one root; searching either alone hides the other.
      final rows = await db.query(
        'lexicon_roots',
        where: 'strongs_id IN (?, ?)',
        whereArgs: ['H1288', 'H1293'],
      );
      expect(rows, hasLength(2));
      final twots = rows.map((r) => r['twot']).toSet();
      expect(twots, hasLength(1));

      await db.close();
    });

    test('sense rows follow the dictionary numbering', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      // אָב (father): BDB's own numbered senses, not a paragraph.
      final rows = await db.query(
        'lexicon_senses',
        where: 'strongs_id = ?',
        whereArgs: ['H0001'],
        orderBy: 'id',
      );
      expect(rows.length, greaterThanOrEqualTo(3));
      expect(rows.first['number'], '1');
      expect(rows.first['heading'], contains('father'));

      await db.close();
    });

    test('Database has full-release scale', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final booksCount =
          (await db.rawQuery('SELECT COUNT(*) FROM books')).first.values.first
              as int;
      final distinctVerseBooks =
          (await db.rawQuery(
                'SELECT COUNT(DISTINCT book_id) FROM verses',
              )).first.values.first
              as int;
      final versesCount =
          (await db.rawQuery('SELECT COUNT(*) FROM verses')).first.values.first
              as int;
      final kjvTranslationCount =
          (await db.rawQuery(
                "SELECT COUNT(*) FROM translation_verses WHERE translation_id = 'KJV'",
              )).first.values.first
              as int;
      final wordsCount =
          (await db.rawQuery('SELECT COUNT(*) FROM words')).first.values.first
              as int;
      final lexiconCount =
          (await db.rawQuery('SELECT COUNT(*) FROM lexicon')).first.values.first
              as int;

      expect(booksCount, equals(66));
      expect(distinctVerseBooks, equals(66));
      expect(versesCount, greaterThanOrEqualTo(31100));
      expect(kjvTranslationCount, greaterThanOrEqualTo(31100));
      expect(wordsCount, greaterThanOrEqualTo(600000));
      expect(lexiconCount, greaterThanOrEqualTo(13000));

      await db.close();
    });

    test('Genesis 1:1 exists in database', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final gen11 = await db.query(
        'verses',
        where: 'book_id = ? AND chapter = ? AND verse_number = ?',
        whereArgs: ['GEN', 1, 1],
      );

      expect(gen11, isNotEmpty, reason: 'Genesis 1:1 should exist');
      final text = gen11.first['text']?.toString() ?? '';
      expect(text, isNotEmpty);
      expect(
        RegExp(r'[\u0590-\u05FF]').hasMatch(text),
        isTrue,
        reason: 'Should contain Hebrew text',
      );

      await db.close();
    });

    test('Spot checks include OT, NT start and NT end', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      Future<bool> hasVerse(String bookId, int chapter, int verse) async {
        final rows = await db.query(
          'verses',
          where: 'book_id = ? AND chapter = ? AND verse_number = ?',
          whereArgs: [bookId, chapter, verse],
          limit: 1,
        );
        return rows.isNotEmpty;
      }

      expect(await hasVerse('GEN', 1, 1), isTrue);
      expect(await hasVerse('MAT', 1, 1), isTrue);
      expect(await hasVerse('REV', 22, 21), isTrue);

      await db.close();
    });

    test('Translations are properly linked', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final kjvGen11 = await db.query(
        'translation_verses',
        where:
            'translation_id = ? AND book_id = ? AND chapter = ? AND verse_number = ?',
        whereArgs: ['KJV', 'GEN', 1, 1],
      );

      expect(kjvGen11, isNotEmpty, reason: 'KJV Genesis 1:1 should exist');
      expect(
        kjvGen11.first['text'],
        contains('beginning'),
        reason: 'Should be English translation',
      );

      await db.close();
    });

    test(
      'Translation metadata columns exist and release translations are enabled',
      () async {
        final dbPath = getDbPath();
        final db = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(readOnly: true),
        );

        final columns = await db.rawQuery('PRAGMA table_info(translations)');
        final columnNames = columns.map((row) => row['name'] as String).toSet();
        expect(columnNames, contains('abbreviation'));
        expect(columnNames, contains('enabled'));
        expect(columnNames, contains('coverage_percent'));
        expect(columnNames, contains('source_file'));
        expect(columnNames, contains('license'));

        final enabledRows = await db.rawQuery(
          'SELECT id FROM translations WHERE enabled = 1 ORDER BY id',
        );
        final enabledIds = enabledRows
            .map((row) => row['id'] as String)
            .toSet();
        expect(enabledIds, containsAll(_requiredEnabledTranslationIds));
        expect(enabledIds, isNot(contains('KOUGO')));

        await db.close();
      },
    );

    test('KJV has zero canonical missing references', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final rows = await db.rawQuery('''
        SELECT v.book_id || ' ' || v.chapter || ':' || v.verse_number AS ref
        FROM verses v
        LEFT JOIN translation_verses tv
          ON tv.translation_id = 'KJV'
         AND tv.book_id = v.book_id
         AND tv.chapter = v.chapter
         AND tv.verse_number = v.verse_number
        WHERE tv.id IS NULL
        ORDER BY v.book_id, v.chapter, v.verse_number
      ''');

      final missingRefs = rows.map((r) => r['ref'] as String).toSet();
      expect(missingRefs, equals(_expectedMissingKjvRefs));

      await db.close();
    });

    test(
      'Every enabled release translation has zero canonical missing references',
      () async {
        final dbPath = getDbPath();
        final db = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(readOnly: true),
        );

        for (final translationId in _requiredEnabledTranslationIds) {
          final rows = await db.rawQuery(
            '''
          SELECT COUNT(*) AS count
          FROM verses v
          LEFT JOIN translation_verses tv
            ON tv.translation_id = ?
           AND tv.book_id = v.book_id
           AND tv.chapter = v.chapter
           AND tv.verse_number = v.verse_number
          WHERE tv.id IS NULL
        ''',
            [translationId],
          );
          final missingCount = rows.first['count'] as int;
          expect(
            missingCount,
            equals(0),
            reason:
                'Expected zero canonical missing refs for $translationId, found $missingCount',
          );
        }

        await db.close();
      },
    );

    test(
      'KJV filled refs are represented in translation_ref_map overrides',
      () async {
        final dbPath = getDbPath();
        final db = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(readOnly: true),
        );

        final rows = await db.rawQuery('''
        SELECT COUNT(*) AS count
        FROM translation_ref_map
        WHERE translation_id = 'KJV' AND match_type = 'override'
      ''');
        final overrideCount = rows.first.values.first as int;
        expect(
          overrideCount,
          greaterThanOrEqualTo(11),
          reason: 'Expected KJV gap-fill override refs in translation_ref_map',
        );

        await db.close();
      },
    );

    test(
      'Legacy KJV versification gap refs are now present in translation_verses',
      () async {
        final dbPath = getDbPath();
        final db = await databaseFactory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(readOnly: true),
        );

        for (final ref in _legacyKjvGapRefs) {
          final parts = ref.split(' ');
          final bookId = parts[0];
          final cv = parts[1].split(':');
          final chapter = int.parse(cv[0]);
          final verse = int.parse(cv[1]);

          final rows = await db.query(
            'translation_verses',
            where:
                'translation_id = ? AND book_id = ? AND chapter = ? AND verse_number = ?',
            whereArgs: ['KJV', bookId, chapter, verse],
            limit: 1,
          );

          expect(
            rows,
            isNotEmpty,
            reason: 'Expected KJV ref $ref to exist after gap fill',
          );
        }

        await db.close();
      },
    );

    test('Lexicon has definitions', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final lexiconEntry = await db.query(
        'lexicon',
        where: 'strongs_id = ?',
        whereArgs: ['H1254'],
      );

      expect(
        lexiconEntry,
        isNotEmpty,
        reason: 'Should have lexicon entry for "created"',
      );
      expect(lexiconEntry.first['gloss'], equals('created'));
      expect(lexiconEntry.first['definition'], isNotEmpty);

      await db.close();
    });

    test('Translation-specific language probes return matches', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      const probes = <String, String>{
        'KJV': 'God',
        'ALMEIDA': 'Deus',
        'LUTHER1912': 'Gott',
        'OSTERVALD': 'Dieu',
        'VALERA1909': 'Dios',
        'SYNODAL': 'Бог',
        'CUVS': '神',
        'KOREAN': '하나님',
      };

      for (final entry in probes.entries) {
        final rows = await db.rawQuery(
          '''
        SELECT COUNT(*) AS count
        FROM translation_verses
        WHERE translation_id = ?
          AND text LIKE ?
      ''',
          [entry.key, '%${entry.value}%'],
        );
        final count = rows.first['count'] as int;
        expect(
          count,
          greaterThan(0),
          reason:
              'Expected translation probe ${entry.value} to match for ${entry.key}',
        );
      }

      await db.close();
    });
  });

  group('Data Integrity', () {
    test('No orphaned translation verses', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final orphans = await db.rawQuery('''
        SELECT COUNT(*) as count FROM translation_verses tv
        WHERE NOT EXISTS (
          SELECT 1 FROM translations t WHERE t.id = tv.translation_id
        )
      ''');

      final orphanCount = orphans.first.values.first as int;
      expect(
        orphanCount,
        equals(0),
        reason: 'Should have no orphaned translation verses',
      );

      await db.close();
    });

    test('Word records link to valid verses', () async {
      final dbPath = getDbPath();
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      final orphans = await db.rawQuery('''
        SELECT COUNT(*) as count FROM words w
        WHERE NOT EXISTS (
          SELECT 1 FROM verses v WHERE v.id = w.verse_id
        )
      ''');

      final orphanCount = orphans.first.values.first as int;
      expect(
        orphanCount,
        equals(0),
        reason: 'Should have no orphaned word records',
      );

      await db.close();
    });
  });
}
