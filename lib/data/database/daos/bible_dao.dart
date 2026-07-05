import 'package:flutter/foundation.dart';
import '../../models/book.dart';
import '../../models/verse.dart';
import '../../models/word.dart';
import '../../models/lexicon_entry.dart';
import '../../models/translation.dart';
import '../database_helper.dart';

@visibleForTesting
List<String> buildSearchQueryVariants(String query) {
  final normalized = query.trim();
  if (normalized.isEmpty) {
    return const [];
  }

  final variants = <String>{
    normalized,
    normalized.toLowerCase(),
    normalized.toUpperCase(),
  };

  if (normalized.length > 1) {
    final titleCaseFirst =
        '${normalized[0].toUpperCase()}${normalized.substring(1).toLowerCase()}';
    variants.add(titleCaseFirst);
  }

  return variants.where((variant) => variant.trim().isNotEmpty).toList();
}

@visibleForTesting
String escapeLikePattern(String query) {
  return query
      .replaceAll('\\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

class BibleDAO {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Book>> getBooks() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'books',
        orderBy: 'book_order ASC',
      );
      if (maps.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('BibleDAO: Found ${maps.length} books');
        }
        return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO: books table unavailable, using fallback: $e');
      }
    }

    return _buildFallbackBooks();
  }

  Future<List<Verse>> getVersesForChapter(String bookId, int chapter) async {
    final db = await _dbHelper.database;
    try {
      // Newer schema: verses(book_id, chapter, verse_number, text)
      final List<Map<String, dynamic>> maps = await db.query(
        'verses',
        columns: ['id', 'book_id', 'chapter', 'verse_number', 'text'],
        where: 'book_id = ? AND chapter = ?',
        whereArgs: [bookId, chapter],
        orderBy: 'verse_number ASC',
      );

      if (kDebugMode) {
        debugPrint(
          'BibleDAO: Found ${maps.length} verses for $bookId $chapter',
        );
      }
      return List.generate(maps.length, (i) => Verse.fromMap(maps[i]));
    } catch (_) {
      // Legacy schema: verses(id, book_id, chapter, verse, text_content)
      final String idPattern = '$bookId.$chapter.%';
      final List<Map<String, dynamic>> maps = await db.query(
        'verses',
        where: 'id LIKE ?',
        whereArgs: [idPattern],
        orderBy: 'verse ASC',
      );
      return List.generate(maps.length, (i) => Verse.fromMap(maps[i]));
    }
  }

  Future<List<Word>> getWordsForVerse(String verseId) async {
    final db = await _dbHelper.database;

    // If verse ID is canonical (e.g. GEN.1.1), map it to numeric row ID first.
    if (verseId.contains('.')) {
      final parts = verseId.split('.');
      if (parts.length >= 3) {
        final chapter = int.tryParse(parts[1]) ?? 0;
        final verseNumber = int.tryParse(parts[2]) ?? 0;
        if (chapter > 0 && verseNumber > 0) {
          try {
            final verseRows = await db.query(
              'verses',
              columns: ['id'],
              where: 'book_id = ? AND chapter = ? AND verse_number = ?',
              whereArgs: [parts[0], chapter, verseNumber],
              limit: 1,
            );
            if (verseRows.isNotEmpty) {
              final mappedId = verseRows.first['id']?.toString() ?? verseId;
              final maps = await db.query(
                'words',
                where: 'verse_id = ?',
                whereArgs: [mappedId],
                orderBy: 'position ASC',
              );
              return List.generate(maps.length, (i) => Word.fromMap(maps[i]));
            }
          } catch (_) {
            // Fallback to direct query below.
          }
        }
      }
    }

    final maps = await db.query(
      'words',
      where: 'verse_id = ?',
      whereArgs: [verseId],
      orderBy: 'position ASC',
    );
    return List.generate(maps.length, (i) => Word.fromMap(maps[i]));
  }

  Future<LexiconEntry?> getLexiconEntry(String key) async {
    if (key.isEmpty) return null;

    final db = await _dbHelper.database;

    try {
      final maps = await db.query(
        'lexicon',
        where: 'strongs_id = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return LexiconEntry.fromMap(maps.first);
      }
    } catch (_) {
      // strongs_id may not exist in the current schema.
    }

    try {
      final maps = await db.query(
        'lexicon',
        where: 'lemma = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return LexiconEntry.fromMap(maps.first);
      }
    } catch (_) {
      // No compatible lexicon schema found.
    }

    return null;
  }

  /// Batch fetch lexicon entries for a list of Strong's numbers
  Future<Map<String, LexiconEntry>> getLexiconEntriesForStrongs(
    List<String> strongsNumbers,
  ) async {
    if (strongsNumbers.isEmpty) return {};

    final requestedKeys = strongsNumbers.map((e) => e.trim()).toSet();

    try {
      final db = await _dbHelper.database;
      final placeholders = strongsNumbers.map((_) => '?').join(',');

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM lexicon WHERE strongs_id IN ($placeholders)',
        strongsNumbers,
      );

      final Map<String, LexiconEntry> result = {};
      for (final map in maps) {
        final strongsId = map['strongs_id']?.toString() ?? '';
        if (strongsId.isNotEmpty && requestedKeys.contains(strongsId)) {
          result[strongsId] = LexiconEntry.fromMap(map);
        }
      }

      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {
      // Fallback to lemma-based schema below.
    }

    try {
      final db = await _dbHelper.database;
      final placeholders = strongsNumbers.map((_) => '?').join(',');

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT * FROM lexicon WHERE lemma IN ($placeholders)',
        strongsNumbers,
      );

      final Map<String, LexiconEntry> result = {};
      for (final map in maps) {
        final lemma = map['lemma']?.toString() ?? '';
        if (lemma.isNotEmpty && requestedKeys.contains(lemma)) {
          result[lemma] = LexiconEntry.fromMap(map);
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  Future<List<Verse>> search(
    String query, {
    required String translationId,
  }) async {
    final db = await _dbHelper.database;
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final normalizedTranslationId = translationId.trim().toUpperCase().isEmpty
        ? 'KJV'
        : translationId.trim().toUpperCase();
    final queryVariants = buildSearchQueryVariants(normalizedQuery);
    if (queryVariants.isEmpty) {
      return [];
    }
    final escapedPatterns = queryVariants
        .map(escapeLikePattern)
        .map((variant) => '%$variant%')
        .toList();
    final modernWhereClause = List.generate(
      escapedPatterns.length,
      (_) =>
          "COALESCE(tv_sel.text, tv_fallback.text, v.text) LIKE ? ESCAPE '\\\\'",
    ).join(' OR ');
    final modernArgs = <Object>[normalizedTranslationId, ...escapedPatterns];

    try {
      // Search selected translation with controlled fallback to KJV/canonical text.
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT DISTINCT
          v.id,
          v.book_id,
          v.chapter,
          v.verse_number,
          COALESCE(tv_sel.text, tv_fallback.text, v.text) AS text
        FROM verses v
        LEFT JOIN translation_verses tv_sel
          ON tv_sel.book_id = v.book_id
         AND tv_sel.chapter = v.chapter
         AND tv_sel.verse_number = v.verse_number
         AND UPPER(tv_sel.translation_id) = UPPER(?)
        LEFT JOIN translation_verses tv_fallback
          ON tv_fallback.book_id = v.book_id
         AND tv_fallback.chapter = v.chapter
         AND tv_fallback.verse_number = v.verse_number
         AND tv_fallback.translation_id = 'KJV'
        WHERE ($modernWhereClause)
        ORDER BY v.book_id, v.chapter, v.verse_number
        LIMIT 50
      ''', modernArgs);
      return List.generate(maps.length, (i) => Verse.fromMap(maps[i]));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Modern search fallback failed: $e');
      }
    }

    final legacyWhereClause = List.generate(
      escapedPatterns.length,
      (_) =>
          "COALESCE(tv_sel.text_content, tv_fallback.text_content, v.text_content) LIKE ? ESCAPE '\\\\'",
    ).join(' OR ');
    final legacyArgs = <Object>[normalizedTranslationId, ...escapedPatterns];

    try {
      // Legacy non-FTS schema fallback.
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT DISTINCT v.id, v.book_id, v.chapter, v.verse, 
               COALESCE(tv_sel.text_content, tv_fallback.text_content, v.text_content) AS text_content
        FROM verses v
        LEFT JOIN translation_verses tv_sel
          ON v.id = tv_sel.verse_id
         AND UPPER(tv_sel.translation_id) = UPPER(?)
        LEFT JOIN translation_verses tv_fallback
          ON v.id = tv_fallback.verse_id
         AND tv_fallback.translation_id = 'KJV'
        WHERE ($legacyWhereClause)
        ORDER BY v.book_id, v.chapter, v.verse
        LIMIT 50
      ''', legacyArgs);
      return List.generate(maps.length, (i) => Verse.fromMap(maps[i]));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Legacy search fallback failed: $e');
      }
      return [];
    }
  }

  /// Batch fetch pronunciations for a list of Strong's numbers
  Future<Map<String, String>> getPronunciationsForStrongs(
    List<String> strongsNumbers,
  ) async {
    if (strongsNumbers.isEmpty) return {};

    try {
      final db = await _dbHelper.database;
      final placeholders = strongsNumbers.map((_) => '?').join(',');

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT strongs_id, pronunciation FROM lexicon WHERE strongs_id IN ($placeholders)',
        strongsNumbers,
      );

      final Map<String, String> result = {};
      for (final map in maps) {
        final strongsId = map['strongs_id']?.toString() ?? '';
        final pronunciation = map['pronunciation']?.toString() ?? '';
        if (strongsId.isNotEmpty && pronunciation.isNotEmpty) {
          result[strongsId] = pronunciation;
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  /// Get the top 5 books where a specific Strong's number appears the most
  Future<List<Map<String, dynamic>>> getStrongsUsageFrequencies(
    String strongs,
  ) async {
    if (strongs.isEmpty) return [];

    try {
      final db = await _dbHelper.database;
      final columns = await db.rawQuery('PRAGMA table_info(words)');
      final hasStrongsColumn = columns.any((column) {
        return (column['name']?.toString() ?? '').toLowerCase() == 'strongs';
      });
      final hasStrongsIdColumn = columns.any((column) {
        return (column['name']?.toString() ?? '').toLowerCase() == 'strongs_id';
      });

      if (!hasStrongsColumn && !hasStrongsIdColumn) {
        return [];
      }

      final whereClauses = <String>[];
      final args = <Object>[];
      if (hasStrongsColumn) {
        whereClauses.add('w.strongs = ?');
        args.add(strongs);
      }
      if (hasStrongsIdColumn) {
        whereClauses.add('w.strongs_id = ?');
        args.add(strongs);
      }

      // We join verses and words to count occurrences of the strongs number grouped by book_id
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT v.book_id, COUNT(*) as count 
        FROM words w
        JOIN verses v ON w.verse_id = v.id
        WHERE ${whereClauses.join(' OR ')}
        GROUP BY v.book_id
        ORDER BY count DESC
        LIMIT 5
        ''', args);

      if (maps.isNotEmpty) {
        return maps;
      }
    } catch (_) {
      // Fall back to lemma-based schema below.
    }

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT v.book_id, COUNT(*) as count
        FROM words w
        JOIN verses v ON w.verse_id = v.id
        WHERE w.lemma = ?
        GROUP BY v.book_id
        ORDER BY count DESC
        LIMIT 5
        ''',
        [strongs],
      );
      return maps;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO usage frequency error: $e');
      }
      return [];
    }
  }

  /// Total number of verses containing a word keyed by Strong's id or lemma.
  Future<int> countOccurrencesForLexiconKey(String key) async {
    if (key.isEmpty) return 0;

    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT w.verse_id) as total
        FROM words w
        WHERE w.strongs = ? OR w.lemma = ?
        ''',
        [key, key],
      );
      if (rows.isNotEmpty) {
        return (rows.first['total'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO occurrence count error: $e');
      }
    }
    return 0;
  }

  /// Whole-Bible occurrence counts for a batch of lexicon keys (Strong's ids
  /// or lemmas). Used by reader mode to decide which words are rare enough
  /// to gloss inline.
  Future<Map<String, int>> getFrequenciesForLexiconKeys(
    List<String> keys,
  ) async {
    final requested = keys.where((k) => k.isNotEmpty).toSet().toList();
    if (requested.isEmpty) return {};

    final result = <String, int>{};
    try {
      final db = await _dbHelper.database;
      final placeholders = requested.map((_) => '?').join(',');

      final strongsRows = await db.rawQuery(
        'SELECT strongs AS k, COUNT(*) AS c FROM words '
        'WHERE strongs IN ($placeholders) GROUP BY strongs',
        requested,
      );
      for (final row in strongsRows) {
        final key = row['k']?.toString() ?? '';
        if (key.isNotEmpty) {
          result[key] = (row['c'] as num?)?.toInt() ?? 0;
        }
      }

      final remaining = requested.where((k) => !result.containsKey(k)).toList();
      if (remaining.isNotEmpty) {
        final remainingPlaceholders = remaining.map((_) => '?').join(',');
        final lemmaRows = await db.rawQuery(
          'SELECT lemma AS k, COUNT(*) AS c FROM words '
          'WHERE lemma IN ($remainingPlaceholders) GROUP BY lemma',
          remaining,
        );
        for (final row in lemmaRows) {
          final key = row['k']?.toString() ?? '';
          if (key.isNotEmpty) {
            result[key] = (row['c'] as num?)?.toInt() ?? 0;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO frequency batch error: $e');
      }
    }
    return result;
  }

  /// All verses containing a word (by Strong's id or lemma), in canonical
  /// order. [limit] caps the result for very frequent words (particles,
  /// conjunctions) that appear tens of thousands of times.
  Future<List<Verse>> getOccurrencesForLexiconKey(
    String key, {
    int limit = 300,
  }) async {
    if (key.isEmpty) return [];

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT DISTINCT v.id, v.book_id, v.chapter, v.verse_number, v.text
        FROM words w
        JOIN verses v ON w.verse_id = v.id
        WHERE w.strongs = ? OR w.lemma = ?
        ORDER BY v.id
        LIMIT ?
        ''',
        [key, key, limit],
      );
      return maps.map((m) => Verse.fromMap(m)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO occurrences error: $e');
      }
      return [];
    }
  }

  // ========== TRANSLATIONS ==========

  Future<List<Translation>> getTranslations() async {
    try {
      final db = await _dbHelper.database;
      List<Map<String, dynamic>> maps;
      try {
        maps = await db.query(
          'translations',
          where: 'enabled = 1',
          orderBy: 'id ASC',
        );
      } catch (_) {
        maps = await db.query('translations', orderBy: 'id ASC');
      }
      if (kDebugMode) {
        debugPrint('BibleDAO: Found ${maps.length} translations');
      }
      return List.generate(maps.length, (i) => Translation.fromMap(maps[i]));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO: translations table error: $e');
      }
      return [];
    }
  }

  Future<Map<String, String>> getTranslationVersesForChapter(
    String bookId,
    int chapter,
    String translationId,
  ) async {
    try {
      // Newer schema: translation_verses(book_id, chapter, verse_number, text)
      final db = await _dbHelper.database;
      final maps = await db.query(
        'translation_verses',
        columns: ['book_id', 'chapter', 'verse_number', 'text'],
        where:
            'book_id = ? AND chapter = ? AND UPPER(translation_id) = UPPER(?)',
        whereArgs: [bookId, chapter, translationId],
        orderBy: 'verse_number ASC',
      );
      final Map<String, String> result = {};
      for (final map in maps) {
        final verseNum = map['verse_number'] is int
            ? map['verse_number'] as int
            : int.tryParse(map['verse_number']?.toString() ?? '0') ?? 0;
        if (verseNum > 0) {
          result['$bookId.$chapter.$verseNum'] = map['text']?.toString() ?? '';
        }
      }
      if (result.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            'BibleDAO: Found ${result.length} translation verses for $translationId',
          );
        }
        return result;
      }
    } catch (_) {
      // Try legacy schema below.
    }

    try {
      // Legacy schema: translation_verses(verse_id, translation_id, text_content)
      final db = await _dbHelper.database;
      final String idPattern = '$bookId.$chapter.%';
      final maps = await db.query(
        'translation_verses',
        where: 'verse_id LIKE ? AND UPPER(translation_id) = UPPER(?)',
        whereArgs: [idPattern, translationId],
      );
      final Map<String, String> result = {};
      for (final map in maps) {
        final verseId = map['verse_id']?.toString() ?? '';
        if (verseId.isNotEmpty) {
          result[verseId] = map['text_content']?.toString() ?? '';
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO: translation_verses error: $e');
      }
      return {};
    }
  }

  List<Book> _buildFallbackBooks() {
    return List<Book>.generate(_bookOrder.length, (index) {
      final abbr = _bookOrder[index];
      return Book(
        id: index + 1,
        abbreviation: abbr,
        name: _bookNames[abbr] ?? abbr,
        testament: index < 39 ? 'OT' : 'NT',
        order: index + 1,
        chapterCount: Book.standardChapterCounts[abbr] ?? 1,
      );
    });
  }
}

const List<String> _bookOrder = [
  'GEN',
  'EXO',
  'LEV',
  'NUM',
  'DEU',
  'JOS',
  'JDG',
  'RUT',
  '1SA',
  '2SA',
  '1KI',
  '2KI',
  '1CH',
  '2CH',
  'EZR',
  'NEH',
  'EST',
  'JOB',
  'PSA',
  'PRO',
  'ECC',
  'SNG',
  'ISA',
  'JER',
  'LAM',
  'EZK',
  'DAN',
  'HOS',
  'JOL',
  'AMO',
  'OBA',
  'JON',
  'MIC',
  'NAM',
  'HAB',
  'ZEP',
  'HAG',
  'ZEC',
  'MAL',
  'MAT',
  'MRK',
  'LUK',
  'JHN',
  'ACT',
  'ROM',
  '1CO',
  '2CO',
  'GAL',
  'EPH',
  'PHP',
  'COL',
  '1TH',
  '2TH',
  '1TI',
  '2TI',
  'TIT',
  'PHM',
  'HEB',
  'JAS',
  '1PE',
  '2PE',
  '1JN',
  '2JN',
  '3JN',
  'JUD',
  'REV',
];

const Map<String, String> _bookNames = {
  'GEN': 'Genesis',
  'EXO': 'Exodus',
  'LEV': 'Leviticus',
  'NUM': 'Numbers',
  'DEU': 'Deuteronomy',
  'JOS': 'Joshua',
  'JDG': 'Judges',
  'RUT': 'Ruth',
  '1SA': '1 Samuel',
  '2SA': '2 Samuel',
  '1KI': '1 Kings',
  '2KI': '2 Kings',
  '1CH': '1 Chronicles',
  '2CH': '2 Chronicles',
  'EZR': 'Ezra',
  'NEH': 'Nehemiah',
  'EST': 'Esther',
  'JOB': 'Job',
  'PSA': 'Psalms',
  'PRO': 'Proverbs',
  'ECC': 'Ecclesiastes',
  'SNG': 'Song of Songs',
  'ISA': 'Isaiah',
  'JER': 'Jeremiah',
  'LAM': 'Lamentations',
  'EZK': 'Ezekiel',
  'DAN': 'Daniel',
  'HOS': 'Hosea',
  'JOL': 'Joel',
  'AMO': 'Amos',
  'OBA': 'Obadiah',
  'JON': 'Jonah',
  'MIC': 'Micah',
  'NAM': 'Nahum',
  'HAB': 'Habakkuk',
  'ZEP': 'Zephaniah',
  'HAG': 'Haggai',
  'ZEC': 'Zechariah',
  'MAL': 'Malachi',
  'MAT': 'Matthew',
  'MRK': 'Mark',
  'LUK': 'Luke',
  'JHN': 'John',
  'ACT': 'Acts',
  'ROM': 'Romans',
  '1CO': '1 Corinthians',
  '2CO': '2 Corinthians',
  'GAL': 'Galatians',
  'EPH': 'Ephesians',
  'PHP': 'Philippians',
  'COL': 'Colossians',
  '1TH': '1 Thessalonians',
  '2TH': '2 Thessalonians',
  '1TI': '1 Timothy',
  '2TI': '2 Timothy',
  'TIT': 'Titus',
  'PHM': 'Philemon',
  'HEB': 'Hebrews',
  'JAS': 'James',
  '1PE': '1 Peter',
  '2PE': '2 Peter',
  '1JN': '1 John',
  '2JN': '2 John',
  '3JN': '3 John',
  'JUD': 'Jude',
  'REV': 'Revelation',
};
