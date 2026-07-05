import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';
import '../../models/srs_progress.dart';
import '../user_database_helper.dart';

class SrsDao {
  final UserDatabaseHelper _dbHelper = UserDatabaseHelper.instance;

  /// Quality grade fed into SM-2 for a binary correct answer.
  /// 4 = "correct response after a hesitation" keeps the easiness factor
  /// stable, so intervals grow through repetitions rather than grade inflation.
  static const int _qualityCorrect = 4;

  /// Quality grade for a failed review. Lowers easiness (floored at 1.3) and
  /// resets the repetition streak.
  static const int _qualityIncorrect = 2;

  /// Failed words come back quickly instead of waiting a full day.
  static const double _relearningIntervalDays = 1 / 24;

  /// Interval (in days) that counts as fully mastered for the display score.
  static const double _masteryIntervalDays = 30;

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
    final quality = isCorrect ? _qualityCorrect : _qualityIncorrect;

    double easiness = current?.easiness ?? 2.5;
    easiness += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    easiness = math.max(1.3, easiness);

    int repetitions = current?.repetitions ?? 0;
    double intervalDays;
    if (isCorrect) {
      repetitions += 1;
      if (repetitions == 1) {
        intervalDays = 1;
      } else if (repetitions == 2) {
        intervalDays = 6;
      } else {
        final previousInterval = math.max(1.0, current?.intervalDays ?? 1.0);
        intervalDays = previousInterval * easiness;
      }
    } else {
      repetitions = 0;
      intervalDays = _relearningIntervalDays;
    }

    final nextReviewAt = now.add(
      Duration(minutes: (intervalDays * 24 * 60).round()),
    );

    // Display-facing mastery: how close the interval is to a month.
    final masteryScore = (intervalDays / _masteryIntervalDays).clamp(0.0, 1.0);

    return SrsProgress(
      id: current?.id,
      strongsId: strongsId,
      exposureCount: (current?.exposureCount ?? 0) + 1,
      masteryScore: masteryScore.toDouble(),
      lastReviewedAt: now,
      nextReviewAt: nextReviewAt,
      repetitions: repetitions,
      easiness: easiness,
      intervalDays: intervalDays,
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
