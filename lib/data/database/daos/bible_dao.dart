import 'package:flutter/foundation.dart';
import '../../models/book.dart';
import '../../models/verse.dart';
import '../../models/word.dart';
import '../../models/cross_reference.dart';
import '../../models/lexicon_entry.dart';
import '../../models/translation.dart';
import '../database_helper.dart';

/// How many verses one search returns. Generous enough that a common word
/// still reaches the end of the canon, small enough to build in one frame.
const int _searchResultLimit = 200;

/// A page of search results, and how many verses matched in total.
///
/// The count is what lets the screen say "200 of 431" rather than presenting a
/// truncated list as the whole answer.
class SearchResults {
  const SearchResults({required this.verses, required this.totalMatches});

  final List<Verse> verses;
  final int totalMatches;

  static const empty = SearchResults(verses: [], totalMatches: 0);

  bool get isTruncated => verses.length < totalMatches;
}

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
  /// Interface language the short glosses should be read in.
  ///
  /// Applied centrally, in the three lexicon reads below, so the definition
  /// sheet, the long-press peek, reader-mode inline glosses, the vocabulary
  /// deck and word search all speak the reader's language without each of
  /// them having to know that translated glosses exist.
  BibleDAO({this.glossLanguage = 'en'});

  final String glossLanguage;

  /// True once the reader is on something other than the language the lexicon
  /// was written in.
  bool get _needsGlossTranslation =>
      glossLanguage.isNotEmpty && glossLanguage != 'en';

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

  /// Translated short glosses for [strongsIds], keyed by Strong's id.
  ///
  /// Returns empty for English readers, and also for any database built before
  /// `lexicon_gloss_i18n` existed — an untranslated gloss is a far better
  /// outcome than a crash, so a missing table is silently an empty result.
  Future<Map<String, String>> _translatedGlosses(
    Iterable<String> strongsIds,
  ) async {
    if (!_needsGlossTranslation) return const {};
    final ids = strongsIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const {};

    try {
      final db = await _dbHelper.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT strongs_id, gloss FROM lexicon_gloss_i18n '
        'WHERE lang = ? AND strongs_id IN ($placeholders)',
        [glossLanguage, ...ids],
      );

      final result = <String, String>{};
      for (final row in rows) {
        final id = row['strongs_id']?.toString() ?? '';
        final gloss = row['gloss']?.toString() ?? '';
        if (id.isNotEmpty && gloss.isNotEmpty) {
          result[id] = gloss;
        }
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO translated glosses unavailable: $e');
      }
      return const {};
    }
  }

  /// Copy of [row] with its `gloss` replaced by the reader's language, where
  /// one has been translated.
  Map<String, dynamic> _withTranslatedGloss(
    Map<String, dynamic> row,
    Map<String, String> translations,
  ) {
    if (translations.isEmpty) return row;
    final gloss = translations[row['strongs_id']?.toString() ?? ''];
    if (gloss == null) return row;
    return {...row, 'gloss': gloss};
  }

  Future<LexiconEntry?> getLexiconEntry(String key) async {
    if (key.isEmpty) return null;

    final db = await _dbHelper.database;

    Future<LexiconEntry> localized(Map<String, dynamic> row) async {
      final strongsId = row['strongs_id']?.toString() ?? '';
      final translations = await _translatedGlosses([strongsId]);
      return LexiconEntry.fromMap(_withTranslatedGloss(row, translations));
    }

    try {
      final maps = await db.query(
        'lexicon',
        where: 'strongs_id = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return localized(maps.first);
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
        return localized(maps.first);
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

      final translations = await _translatedGlosses(
        maps.map((m) => m['strongs_id']?.toString() ?? ''),
      );

      final Map<String, LexiconEntry> result = {};
      for (final map in maps) {
        final strongsId = map['strongs_id']?.toString() ?? '';
        if (strongsId.isNotEmpty && requestedKeys.contains(strongsId)) {
          result[strongsId] = LexiconEntry.fromMap(
            _withTranslatedGloss(map, translations),
          );
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

      final translations = await _translatedGlosses(
        maps.map((m) => m['strongs_id']?.toString() ?? ''),
      );

      final Map<String, LexiconEntry> result = {};
      for (final map in maps) {
        final lemma = map['lemma']?.toString() ?? '';
        if (lemma.isNotEmpty && requestedKeys.contains(lemma)) {
          result[lemma] = LexiconEntry.fromMap(
            _withTranslatedGloss(map, translations),
          );
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  /// Searches the reader's translation, in canonical order.
  ///
  /// The result carries [SearchResults.totalMatches] as well as the page of
  /// verses, because the cap has to be visible: sorting by `book_id` — the
  /// abbreviation, as a string — and then cutting at 50 used to drop the
  /// second half of the canon silently. "shepherd" in the KJV matched 114
  /// verses, returned 50 of them alphabetically from 1 Chronicles to Isaiah,
  /// and left out Psalm 23:1.
  Future<SearchResults> search(
    String query, {
    required String translationId,
    int limit = _searchResultLimit,
  }) async {
    final db = await _dbHelper.database;
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return SearchResults.empty;
    }

    final normalizedTranslationId = translationId.trim().toUpperCase().isEmpty
        ? 'KJV'
        : translationId.trim().toUpperCase();
    final queryVariants = buildSearchQueryVariants(normalizedQuery);
    if (queryVariants.isEmpty) {
      return SearchResults.empty;
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
      // Search selected translation with controlled fallback to KJV/canonical
      // text. `books.book_order` puts Genesis before Exodus; without the join
      // SQLite sorts '1CH' before 'GEN' and the LIMIT lands mid-alphabet.
      const modernFrom = '''
        FROM verses v
        LEFT JOIN books b ON b.abbreviation = v.book_id
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
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT DISTINCT
          v.id,
          v.book_id,
          v.chapter,
          v.verse_number,
          COALESCE(tv_sel.text, tv_fallback.text, v.text) AS text
        $modernFrom
        WHERE ($modernWhereClause)
        ORDER BY b.book_order, v.chapter, v.verse_number
        LIMIT ?
      ''',
        [...modernArgs, limit],
      );

      final verses = List.generate(maps.length, (i) => Verse.fromMap(maps[i]));

      // Only worth a second query when the page is full; otherwise the page
      // is the whole answer.
      var total = verses.length;
      if (verses.length >= limit) {
        final countRows = await db.rawQuery('''
          SELECT COUNT(*) AS c FROM (
            SELECT DISTINCT v.id
            $modernFrom
            WHERE ($modernWhereClause)
          )
        ''', modernArgs);
        final counted = countRows.isEmpty ? null : countRows.first['c'];
        if (counted is int && counted > total) total = counted;
      }

      return SearchResults(verses: verses, totalMatches: total);
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
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT DISTINCT v.id, v.book_id, v.chapter, v.verse,
               COALESCE(tv_sel.text_content, tv_fallback.text_content, v.text_content) AS text_content
        FROM verses v
        LEFT JOIN books b ON b.abbreviation = v.book_id
        LEFT JOIN translation_verses tv_sel
          ON v.id = tv_sel.verse_id
         AND UPPER(tv_sel.translation_id) = UPPER(?)
        LEFT JOIN translation_verses tv_fallback
          ON v.id = tv_fallback.verse_id
         AND tv_fallback.translation_id = 'KJV'
        WHERE ($legacyWhereClause)
        ORDER BY b.book_order, v.chapter, v.verse
        LIMIT ?
      ''',
        [...legacyArgs, limit],
      );
      final verses = List.generate(maps.length, (i) => Verse.fromMap(maps[i]));
      return SearchResults(verses: verses, totalMatches: verses.length);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Legacy search fallback failed: $e');
      }
      return SearchResults.empty;
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

  /// Lightweight dump of the whole lexicon for the in-memory word-search
  /// index (~13k rows; loaded once and cached by the provider).
  Future<List<Map<String, dynamic>>> getLexiconIndex() async {
    try {
      final db = await _dbHelper.database;
      // Word search matches on the gloss, so it has to index the gloss the
      // reader would actually type. LEFT JOIN keeps every entry, translated or
      // not; COALESCE falls back to the English one.
      if (_needsGlossTranslation) {
        try {
          return await db.rawQuery(
            'SELECT lx.lemma, lx.strongs_id, lx.transliteration, '
            'COALESCE(i18n.gloss, lx.gloss) AS gloss, lx.language '
            'FROM lexicon lx '
            'LEFT JOIN lexicon_gloss_i18n i18n '
            '  ON i18n.strongs_id = lx.strongs_id AND i18n.lang = ?',
            [glossLanguage],
          );
        } catch (_) {
          // Database predates lexicon_gloss_i18n; fall through to English.
        }
      }

      return await db.rawQuery(
        'SELECT lemma, strongs_id, transliteration, gloss, language '
        'FROM lexicon',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO lexicon index error: $e');
      }
      return [];
    }
  }

  /// Random words with morphology codes for the parsing quiz.
  Future<List<Word>> getRandomMorphWords({
    required String language,
    int limit = 40,
  }) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT id, verse_id, position, word, lemma, morph, strongs, language
        FROM words
        WHERE language = ? AND morph IS NOT NULL AND morph != ''
        ORDER BY RANDOM()
        LIMIT ?
        ''',
        [language, limit],
      );
      return maps.map((m) => Word.fromMap(m)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO random morph words error: $e');
      }
      return [];
    }
  }

  /// Most frequent Strong's-keyed words for one language ('heb' or 'grc'),
  /// for the frequency-ordered vocabulary deck.
  Future<List<Map<String, dynamic>>> getTopFrequencyWords({
    required String language,
    int limit = 100,
  }) async {
    try {
      final db = await _dbHelper.database;
      return await db.rawQuery(
        '''
        SELECT w.strongs AS key, COUNT(*) AS c
        FROM words w
        WHERE w.language = ? AND w.strongs IS NOT NULL AND w.strongs != ''
        GROUP BY w.strongs
        ORDER BY c DESC
        LIMIT ?
        ''',
        [language, limit],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO top frequency error: $e');
      }
      return [];
    }
  }

  /// Total original-language token count for every book.
  ///
  /// The denominator of the readability map: how much text there is to read.
  Future<Map<String, int>> getTokenCountsByBook() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery('''
        SELECT v.book_id AS book, COUNT(*) AS c
        FROM words w
        JOIN verses v ON v.id = w.verse_id
        GROUP BY v.book_id
      ''');

      final result = <String, int>{};
      for (final row in rows) {
        final book = row['book']?.toString() ?? '';
        if (book.isEmpty) continue;
        result[book] = (row['c'] as num?)?.toInt() ?? 0;
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO token counts by book error: $e');
      }
      return {};
    }
  }

  /// Per-book count of tokens whose lexicon key is in [lexiconKeys].
  ///
  /// The numerator of the readability map: how much of each book the reader
  /// already knows. Keys are batched because SQLite caps how many bound
  /// variables a single statement may carry.
  Future<Map<String, int>> getTokenCountsByBookForKeys(
    List<String> lexiconKeys,
  ) async {
    final keys = lexiconKeys.where((k) => k.isNotEmpty).toSet().toList();
    if (keys.isEmpty) return {};

    const batchSize = 800;
    final result = <String, int>{};

    try {
      final db = await _dbHelper.database;

      for (int start = 0; start < keys.length; start += batchSize) {
        final batch = keys.sublist(
          start,
          start + batchSize > keys.length ? keys.length : start + batchSize,
        );
        final placeholders = batch.map((_) => '?').join(',');

        final rows = await db.rawQuery('''
          SELECT v.book_id AS book, COUNT(*) AS c
          FROM words w
          JOIN verses v ON v.id = w.verse_id
          WHERE w.strongs IN ($placeholders)
          GROUP BY v.book_id
          ''', batch);

        for (final row in rows) {
          final book = row['book']?.toString() ?? '';
          if (book.isEmpty) continue;
          result[book] =
              (result[book] ?? 0) + ((row['c'] as num?)?.toInt() ?? 0);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO known token counts error: $e');
      }
      return {};
    }

    return result;
  }

  /// Total token count for one language, for vocabulary coverage stats.
  Future<int> getTotalWordCount(String language) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM words WHERE language = ?',
        [language],
      );
      if (rows.isNotEmpty) {
        return (rows.first['c'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO total word count error: $e');
      }
    }
    return 0;
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

  /// Top cross-references for a verse (OpenBible.info data), best-voted
  /// first. Returns [] when the DB predates the cross_references table.
  /// Cross-reference count for every verse of one chapter, in a single query.
  ///
  /// Feeds the badge on the reader's cross-reference button: the icon alone
  /// gave no sign that 61 references sit behind Genesis 1:1, so it read as
  /// absent. A per-verse count query inside the scrolling verse list would
  /// risk scroll jank, so this loads once per chapter instead.
  Future<Map<int, int>> getCrossReferenceCountsForChapter(
    String bookId,
    int chapter,
  ) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery(
        '''
        SELECT from_verse, COUNT(*) AS c
        FROM cross_references
        WHERE from_book = ? AND from_chapter = ?
        GROUP BY from_verse
        ''',
        [bookId, chapter],
      );

      final result = <int, int>{};
      for (final row in rows) {
        final verse = (row['from_verse'] as num?)?.toInt();
        final count = (row['c'] as num?)?.toInt();
        if (verse != null && count != null) {
          result[verse] = count;
        }
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO cross-reference counts error: $e');
      }
      return {};
    }
  }

  Future<List<CrossReference>> getCrossReferencesForVerse(
    String bookId,
    int chapter,
    int verse, {
    int limit = 15,
  }) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT to_book, to_chapter, to_verse_start, to_verse_end, votes
        FROM cross_references
        WHERE from_book = ? AND from_chapter = ? AND from_verse = ?
        ORDER BY votes DESC
        LIMIT ?
        ''',
        [bookId, chapter, verse, limit],
      );
      return maps.map((m) => CrossReference.fromMap(m)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO cross-references error: $e');
      }
      return [];
    }
  }

  /// Text of one verse in the given translation, falling back to KJV and
  /// then the original-language text.
  Future<String?> getVerseTextWithFallback({
    required String translationId,
    required String bookId,
    required int chapter,
    required int verse,
  }) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery(
        '''
        SELECT COALESCE(tv_sel.text, tv_kjv.text, v.text) AS text
        FROM verses v
        LEFT JOIN translation_verses tv_sel
          ON tv_sel.book_id = v.book_id
         AND tv_sel.chapter = v.chapter
         AND tv_sel.verse_number = v.verse_number
         AND UPPER(tv_sel.translation_id) = UPPER(?)
        LEFT JOIN translation_verses tv_kjv
          ON tv_kjv.book_id = v.book_id
         AND tv_kjv.chapter = v.chapter
         AND tv_kjv.verse_number = v.verse_number
         AND tv_kjv.translation_id = 'KJV'
        WHERE v.book_id = ? AND v.chapter = ? AND v.verse_number = ?
        LIMIT 1
        ''',
        [translationId, bookId, chapter, verse],
      );
      if (rows.isNotEmpty) {
        return rows.first['text']?.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO verse text lookup error: $e');
      }
    }
    return null;
  }

  /// Raw JSON array of MACULA sentence trees covering a verse, or null when
  /// the DB predates the syntax_trees table (or has no tree for the verse).
  Future<String?> getSyntaxTreesForVerse(
    String bookId,
    int chapter,
    int verse,
  ) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'syntax_trees',
        columns: ['trees'],
        where: 'book_id = ? AND chapter = ? AND verse = ?',
        whereArgs: [bookId, chapter, verse],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows.first['trees']?.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO syntax trees error: $e');
      }
    }
    return null;
  }

  /// Resolves a verses-table row id to (book, chapter, verse).
  Future<(String, int, int)?> getVerseRefByRowId(int rowId) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'verses',
        columns: ['book_id', 'chapter', 'verse_number'],
        where: 'id = ?',
        whereArgs: [rowId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        return (
          row['book_id']?.toString() ?? '',
          (row['chapter'] as num?)?.toInt() ?? 0,
          (row['verse_number'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BibleDAO verse ref lookup error: $e');
      }
    }
    return null;
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
