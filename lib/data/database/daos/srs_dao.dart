import 'package:sqflite/sqflite.dart';
import '../../models/srs_progress.dart';
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

  /// Records an exposure to a word. Adjusts SRS score.
  /// A simple algorithm:
  /// - A correct review increases mastery by 0.2 (max 1.0)
  /// - An incorrect review drops mastery heavily
  /// For pure exposure (just reading), we can gently bump it.
  Future<void> recordReview(String strongsId, {required bool isCorrect}) async {
    final current = await getProgress(strongsId);

    final now = DateTime.now();
    double newMastery = current?.masteryScore ?? 0.0;
    int newExposureCount = (current?.exposureCount ?? 0) + 1;

    if (isCorrect) {
      newMastery = (newMastery + 0.2).clamp(0.0, 1.0);
    } else {
      newMastery = (newMastery - 0.4).clamp(0.0, 1.0);
    }

    // Calculate next review based on mastery
    // e.g., 0.0 -> review in 1 minute
    // e.g., 1.0 -> review in 30 days
    int hoursToNextReview = (newMastery * newMastery * 24 * 30).toInt().clamp(
      1,
      24 * 30,
    );
    final nextReviewAt = now.add(Duration(hours: hoursToNextReview));

    final updated = SrsProgress(
      id: current?.id,
      strongsId: strongsId,
      exposureCount: newExposureCount,
      masteryScore: newMastery,
      lastReviewedAt: now,
      nextReviewAt: nextReviewAt,
    );

    await saveProgress(updated);
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
