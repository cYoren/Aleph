import 'package:sqflite/sqflite.dart';

import '../../models/memorization_passage.dart';
import '../../../shared/utils/sm2.dart';
import '../user_database_helper.dart';

class MemorizationDao {
  final UserDatabaseHelper _dbHelper = UserDatabaseHelper.instance;

  Future<List<MemorizationPassage>> getPassages() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'memorization_passages',
      orderBy: 'next_review_at ASC',
    );
    return maps.map((m) => MemorizationPassage.fromMap(m)).toList();
  }

  Future<MemorizationPassage?> getPassage(String bookId, int chapter) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'memorization_passages',
      where: 'book_id = ? AND chapter = ?',
      whereArgs: [bookId, chapter],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MemorizationPassage.fromMap(maps.first);
  }

  /// Adds a passage to the memorization list (no-op if already present).
  Future<MemorizationPassage> addPassage(String bookId, int chapter) async {
    final existing = await getPassage(bookId, chapter);
    if (existing != null) return existing;

    final now = DateTime.now();
    final passage = MemorizationPassage(
      bookId: bookId,
      chapter: chapter,
      createdAt: now,
      nextReviewAt: now,
    );

    final db = await _dbHelper.database;
    final id = await db.insert(
      'memorization_passages',
      passage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return MemorizationPassage.fromMap({...passage.toMap(), 'id': id});
  }

  Future<void> removePassage(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'memorization_passages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Records a practice session outcome via the shared SM-2 transition.
  Future<MemorizationPassage> recordPractice(
    MemorizationPassage passage, {
    required bool wasSuccessful,
  }) async {
    final now = DateTime.now();
    final next = applySm2Transition(
      previous: Sm2State(
        repetitions: passage.repetitions,
        easiness: passage.easiness,
        intervalDays: passage.intervalDays,
        masteryScore: passage.masteryScore,
      ),
      isCorrect: wasSuccessful,
    );

    final updated = MemorizationPassage(
      id: passage.id,
      bookId: passage.bookId,
      chapter: passage.chapter,
      createdAt: passage.createdAt,
      repetitions: next.repetitions,
      easiness: next.easiness,
      intervalDays: next.intervalDays,
      masteryScore: next.masteryScore,
      nextReviewAt: now.add(next.interval),
      lastPracticedAt: now,
    );

    final db = await _dbHelper.database;
    await db.insert(
      'memorization_passages',
      updated.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return updated;
  }
}
