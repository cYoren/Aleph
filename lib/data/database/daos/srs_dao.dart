import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/srs_progress.dart';
import '../../../shared/utils/reader_mode.dart';
import '../../../shared/utils/sm2.dart';
import '../user_database_helper.dart';

class SrsDao {
  final UserDatabaseHelper _dbHelper = UserDatabaseHelper.instance;

  Future<SrsProgress?> getProgress(String strongsId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'srs_progress',
      where: 'strongs_id = ?',
      whereArgs: [strongsId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SrsProgress.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveProgress(SrsProgress progress) async {
    final db = await _dbHelper.database;
    await db.insert(
      'srs_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Records a review outcome using the SM-2 spaced-repetition algorithm.
  ///
  /// Correct answers grow the interval (1 day, 6 days, then interval x
  /// easiness); a failure resets the repetition streak, lowers easiness, and
  /// schedules a quick relearning review.
  Future<void> recordReview(String strongsId, {required bool isCorrect}) async {
    final current = await getProgress(strongsId);
    final now = DateTime.now();
    final updated = applySm2(
      current,
      strongsId: strongsId,
      isCorrect: isCorrect,
      now: now,
    );
    await saveProgress(updated);
    await _logReview(strongsId, isCorrect: isCorrect, before: current, now: now);
  }

  /// One row per answered card, appended after the state moves.
  ///
  /// Nothing reads this yet: SM-2 keeps its own state. It is written because a
  /// scheduler that fits itself to history cannot be added later to readers who
  /// have no history, and writing it costs one insert per review.
  Future<void> _logReview(
    String strongsId, {
    required bool isCorrect,
    required SrsProgress? before,
    required DateTime now,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('srs_reviews', {
        'strongs_id': strongsId,
        'reviewed_at': now.millisecondsSinceEpoch,
        'grade': isCorrect ? 1 : 0,
        'repetitions_before': before?.repetitions ?? 0,
        'easiness_before': before?.easiness ?? 2.5,
        'interval_before': before?.intervalDays ?? 0.0,
      });
    } catch (e) {
      // An older install without the log table must not lose the review itself.
      if (kDebugMode) debugPrint('SrsDao review log error: $e');
    }
  }

  /// How many reviews this reader has answered, ever.
  ///
  /// The trigger for revisiting FSRS: parameter fitting needs a few hundred
  /// reviews per user before it beats SM-2's defaults measurably.
  Future<int> countReviews() async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM srs_reviews');
      return (rows.first['n'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Pure SM-2 state transition, separated from persistence for testability.
  static SrsProgress applySm2(
    SrsProgress? current, {
    required String strongsId,
    required bool isCorrect,
    required DateTime now,
  }) {
    final next = applySm2Transition(
      previous: current == null
          ? null
          : Sm2State(
              repetitions: current.repetitions,
              easiness: current.easiness,
              intervalDays: current.intervalDays,
              masteryScore: current.masteryScore,
            ),
      isCorrect: isCorrect,
    );

    return SrsProgress(
      id: current?.id,
      strongsId: strongsId,
      exposureCount: (current?.exposureCount ?? 0) + 1,
      masteryScore: next.masteryScore,
      lastReviewedAt: now,
      nextReviewAt: now.add(next.interval),
      repetitions: next.repetitions,
      easiness: next.easiness,
      intervalDays: next.intervalDays,
    );
  }

  /// Batch progress lookup for reader mode and vocabulary decks.
  Future<Map<String, SrsProgress>> getProgressForIds(List<String> ids) async {
    final requested = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (requested.isEmpty) return {};

    final db = await _dbHelper.database;
    final placeholders = requested.map((_) => '?').join(',');
    final maps = await db.query(
      'srs_progress',
      where: 'strongs_id IN ($placeholders)',
      whereArgs: requested,
    );

    final result = <String, SrsProgress>{};
    for (final map in maps) {
      final progress = SrsProgress.fromMap(map);
      result[progress.strongsId] = progress;
    }
    return result;
  }

  /// Marks a word known from reading exposure, without pretending it was
  /// reviewed.
  ///
  /// The reader knows plenty of words the app has never quizzed them on; making
  /// them sit through a card for each one is why vocabulary decks go untouched.
  /// This records the claim at a mastery above the reader-mode suppression
  /// threshold and schedules it far out, so the word stops being glossed and
  /// does not queue for review. Existing history is kept: exposure count and
  /// easiness are untouched, and nothing is ever lowered.
  Future<SrsProgress> markKnown(String strongsId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final current = await getProgress(strongsId);
    final masteries = <double>[
      current?.masteryScore ?? 0.0,
      kReaderModeMasterySuppression + 0.15,
    ];
    final updated = SrsProgress(
      id: current?.id,
      strongsId: strongsId,
      exposureCount: current?.exposureCount ?? 0,
      masteryScore: masteries.reduce((a, b) => a > b ? a : b),
      lastReviewedAt: current?.lastReviewedAt ?? at,
      nextReviewAt: at.add(const Duration(days: 180)),
      repetitions: current == null || current.repetitions < 1
          ? 1
          : current.repetitions,
      easiness: current?.easiness ?? 2.5,
      intervalDays: 180,
    );
    await saveProgress(updated);
    return updated;
  }

  /// Words the reader has met but not yet mastered, newest first.
  ///
  /// Reader mode uses this to find where the reader's own edge is; the cap
  /// keeps the frequency lookup that follows to one bounded query.
  Future<List<SrsProgress>> getProgressBelowMastery(
    double threshold, {
    int limit = 2000,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'srs_progress',
      where: 'mastery_score < ?',
      whereArgs: [threshold],
      orderBy: 'last_reviewed_at DESC',
      limit: limit,
    );
    return maps.map((m) => SrsProgress.fromMap(m)).toList();
  }

  /// Lexicon keys the reader has mastered at or above [threshold].
  ///
  /// Used by the readability map to work out how much of each book the reader
  /// can already read without stopping.
  Future<List<String>> getMasteredLexiconKeys(double threshold) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'srs_progress',
      columns: ['strongs_id'],
      where: 'mastery_score >= ?',
      whereArgs: [threshold],
    );

    return maps
        .map((m) => m['strongs_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// How many words will be due for review by [when].
  Future<int> countDueBy(DateTime when) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM srs_progress WHERE next_review_at <= ?',
      [when.millisecondsSinceEpoch],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  Future<List<SrsProgress>> getWordsDueForReview() async {
    final db = await _dbHelper.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final maps = await db.query(
      'srs_progress',
      where: 'next_review_at <= ?',
      whereArgs: [nowMs],
      orderBy: 'next_review_at ASC',
    );

    return maps.map((m) => SrsProgress.fromMap(m)).toList();
  }
}
