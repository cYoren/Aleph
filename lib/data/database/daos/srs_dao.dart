import 'package:sqflite/sqflite.dart';
import '../../models/srs_progress.dart';
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
    final updated = applySm2(
      current,
      strongsId: strongsId,
      isCorrect: isCorrect,
      now: DateTime.now(),
    );
    await saveProgress(updated);
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
