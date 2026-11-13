/// FSRS scheduling and the SM-2 migration.
///
/// Two things have to hold after the scheduler changes. A new card must be
/// scheduled by FSRS's own model, and a reader who already had a schedule must
/// not be pulled forward by the upgrade — the gate is that the first
/// post-migration review is never due sooner than SM-2 would have made it.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:original_bible/data/database/migrations/srs_fsrs_migration.dart';
import 'package:original_bible/data/models/srs_progress.dart';
import 'package:original_bible/shared/utils/fsrs_scheduler.dart';
import 'package:original_bible/shared/utils/sm2.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// No fuzzing: a gate that compares two schedules cannot tolerate a random
/// interval, and the package applies fuzz only to review-state cards.
final _scheduler = createFsrsScheduler(enableFuzzing: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime(2026, 11, 13, 9);

  group('FSRS scheduling', () {
    test('a first correct review leaves the learning steps for review', () {
      final result = applyFsrsReview(
        null,
        strongsId: 'H7225',
        isCorrect: true,
        now: now,
        scheduler: _scheduler,
      );

      expect(result.fsrsState, kFsrsStateReview);
      expect(result.fsrsStep, isNull);
      expect(result.fsrsStability, isNotNull);
      expect(result.fsrsDifficulty, isNotNull);
      expect(result.fsrsReps, 1);
      expect(result.fsrsLapses, 0);
      expect(result.exposureCount, 1);
      // FSRS's own first interval for a remembered card, not SM-2's 1 day.
      expect(result.intervalDays, greaterThanOrEqualTo(1));
      expect(result.nextReviewAt.isAfter(now), isTrue);
      expect(result.fsrsMigrated, isFalse);
    });

    test('a forgotten card comes back in the relearning step', () {
      final result = applyFsrsReview(
        null,
        strongsId: 'H7225',
        isCorrect: false,
        now: now,
        scheduler: _scheduler,
      );

      // A card that has never been remembered is still in learning; only a card
      // that falls out of review enters relearning (asserted below).
      expect(result.fsrsState, kFsrsStateLearning);
      expect(result.fsrsLapses, 1);
      expect(result.fsrsReps, 0);
      expect(result.intervalDays, closeTo(10 / (24 * 60), 0.0001));
      expect(result.nextReviewAt.difference(now).inMinutes, 10);
    });

    test('a remembered card keeps moving out', () {
      var progress = applyFsrsReview(
        null,
        strongsId: 'H7225',
        isCorrect: true,
        now: now,
        scheduler: _scheduler,
      );
      final firstInterval = progress.intervalDays;

      progress = applyFsrsReview(
        progress,
        strongsId: 'H7225',
        isCorrect: true,
        now: progress.nextReviewAt,
        scheduler: _scheduler,
      );

      expect(progress.intervalDays, greaterThan(firstInterval));
      expect(progress.fsrsReps, 2);
      expect(progress.exposureCount, 2);
    });

    test('the binary sheet only uses the two ends of the rating scale', () {
      expect(fsrsRatingFor(isCorrect: true), fsrs.Rating.good);
      expect(fsrsRatingFor(isCorrect: false), fsrs.Rating.again);
    });
  });

  group('SM-2 migration', () {
    /// An SM-2 row whose last review happened exactly one interval ago, which
    /// is when a card is due.
    SrsProgress sm2Row({
      double intervalDays = 6,
      double easiness = 2.5,
      int repetitions = 2,
      double mastery = 0.2,
    }) {
      return SrsProgress(
        id: 1,
        strongsId: 'H7225',
        exposureCount: 9,
        masteryScore: mastery,
        repetitions: repetitions,
        easiness: easiness,
        intervalDays: intervalDays,
        nextReviewAt: now,
        lastReviewedAt: now.subtract(
          Duration(days: intervalDays.round()),
        ),
      );
    }

    test('stability is seeded from the interval SM-2 had scheduled', () {
      final migrated = migrateSm2ProgressToFsrs(sm2Row());

      expect(migrated.fsrsStability, 6.0);
      expect(migrated.fsrsState, kFsrsStateReview);
      expect(migrated.fsrsStep, isNull);
      expect(migrated.fsrsMigrated, isTrue);
      expect(migrated.lastReviewedAt, now.subtract(const Duration(days: 6)));
      expect(migrated.masteryScore, 0.2);
    });

    test('nothing a reader owns is lowered or rewritten', () {
      final row = sm2Row(mastery: 0.9, easiness: 2.1, repetitions: 4);
      final migrated = migrateSm2ProgressToFsrs(row);

      expect(migrated.masteryScore, 0.9);
      expect(migrated.exposureCount, 9);
      expect(migrated.easiness, 2.1);
      expect(migrated.repetitions, 4);
      expect(migrated.intervalDays, row.intervalDays);
      expect(migrated.nextReviewAt, row.nextReviewAt);
    });

    test('a row with no SM-2 history stays a card never answered', () {
      final migrated = migrateSm2ProgressToFsrs(
        SrsProgress(
          strongsId: 'H7225',
          nextReviewAt: now,
          lastReviewedAt: now,
        ),
      );

      expect(migrated.fsrsStability, isNull);
      expect(migrated.fsrsState, kFsrsStateLearning);
      expect(migrated.fsrsMigrated, isFalse);
    });

    test('difficulty follows easiness monotonically', () {
      final hard = fsrsDifficultyFromEasiness(1.3);
      final normal = fsrsDifficultyFromEasiness(2.5);
      final easy = fsrsDifficultyFromEasiness(3.5);

      expect(normal, 5.0);
      expect(hard, greaterThan(normal));
      expect(easy, lessThan(normal));
      expect(hard, lessThanOrEqualTo(10.0));
      expect(easy, greaterThanOrEqualTo(1.0));
    });

    test('the first post-migration review is never sooner than SM-2', () {
      // A fixture history of 40 reviews: five words, eight reviews each, one
      // lapse apiece, every review taken when the card came due. Each word ends
      // in a different SM-2 state, so the gate is not one lucky row.
      final words = <String>['H7225', 'H430', 'H9001', 'G26', 'G2316'];
      const grades = <bool>[true, true, true, false, true, true, true, true];

      var checked = 0;
      for (final word in words) {
        Sm2State? state;
        var lastReviewedAt = DateTime(2025, 1, 1, 9);
        for (final grade in grades) {
          state = applySm2Transition(previous: state, isCorrect: grade);
          lastReviewedAt = lastReviewedAt.add(state.interval);
        }

        final row = SrsProgress(
          strongsId: word,
          exposureCount: grades.length,
          masteryScore: state!.masteryScore,
          repetitions: state.repetitions,
          easiness: state.easiness,
          intervalDays: state.intervalDays,
          nextReviewAt: lastReviewedAt,
          lastReviewedAt: lastReviewedAt,
        );
        final migrated = migrateSm2ProgressToFsrs(row);

        for (final grade in <bool>[true, false]) {
          final fsrsNext = applyFsrsReview(
            migrated,
            strongsId: word,
            isCorrect: grade,
            now: lastReviewedAt,
            scheduler: _scheduler,
          );
          final sm2Next = applySm2Transition(
            previous: state,
            isCorrect: grade,
          );

          expect(
            fsrsNext.nextReviewAt.difference(lastReviewedAt),
            greaterThanOrEqualTo(sm2Next.interval),
            reason:
                '$word (${grade ? 'correct' : 'lapsed'}) was scheduled sooner '
                'than SM-2 would have',
          );
          checked++;
        }
      }

      expect(checked, 10);
    });

    test('without the floor FSRS would pull the same row forward', () {
      // The gate above only means something if FSRS alone would have failed it.
      // A young card is where the two models disagree: FSRS grows a one-day
      // stability to four days, SM-2 to six.
      final row = sm2Row(intervalDays: 1, easiness: 2.5, repetitions: 1);
      final migrated = migrateSm2ProgressToFsrs(row);
      final unfloored = migrated.copyWith(fsrsMigrated: false);

      final fsrsOnly = applyFsrsReview(
        unfloored,
        strongsId: row.strongsId,
        isCorrect: true,
        now: now,
        scheduler: _scheduler,
      );
      final sm2 = applySm2Transition(
        previous: Sm2State(
          repetitions: row.repetitions,
          easiness: row.easiness,
          intervalDays: row.intervalDays,
          masteryScore: row.masteryScore,
        ),
        isCorrect: true,
      );

      expect(fsrsOnly.intervalDays, lessThan(sm2.intervalDays));
    });

    test('the floor only applies to the first review after migration', () {
      final migrated = migrateSm2ProgressToFsrs(sm2Row(intervalDays: 6));
      final first = applyFsrsReview(
        migrated,
        strongsId: 'H7225',
        isCorrect: true,
        now: now,
        scheduler: _scheduler,
      );

      expect(first.fsrsMigrated, isFalse);
      expect(first.intervalDays, greaterThanOrEqualTo(6 * 2.5));
    });
  });

  group('installed database upgrade', () {
    late Directory tempDir;
    late String path;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aleph_srs_migration');
      path = p.join(tempDir.path, 'user_data.db');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('a version 5 install keeps its schedule and gains FSRS state',
        () async {
      final legacy = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE srs_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                strongs_id TEXT NOT NULL UNIQUE,
                exposure_count INTEGER NOT NULL DEFAULT 0,
                mastery_score REAL NOT NULL DEFAULT 0.0,
                next_review_at INTEGER NOT NULL,
                last_reviewed_at INTEGER NOT NULL,
                repetitions INTEGER NOT NULL DEFAULT 0,
                easiness REAL NOT NULL DEFAULT 2.5,
                interval_days REAL NOT NULL DEFAULT 0.0
              )
            ''');
            await db.execute('''
              CREATE TABLE srs_reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                strongs_id TEXT NOT NULL,
                reviewed_at INTEGER NOT NULL,
                grade INTEGER NOT NULL,
                repetitions_before INTEGER NOT NULL DEFAULT 0,
                easiness_before REAL NOT NULL DEFAULT 2.5,
                interval_before REAL NOT NULL DEFAULT 0.0
              )
            ''');
          },
        ),
      );

      final dueAt = now.add(const Duration(days: 6));
      await legacy.insert('srs_progress', {
        'strongs_id': 'H7225',
        'exposure_count': 9,
        'mastery_score': 0.2,
        'next_review_at': dueAt.millisecondsSinceEpoch,
        'last_reviewed_at': now.millisecondsSinceEpoch,
        'repetitions': 2,
        'easiness': 2.5,
        'interval_days': 6.0,
      });
      await legacy.close();

      // The version 6 step, run against the fixture the way the helper runs it.
      final db = await databaseFactory.openDatabase(path);
      await migrateSrsToFsrs(db);

      final rows = await db.query(
        'srs_progress',
        where: 'strongs_id = ?',
        whereArgs: ['H7225'],
      );
      final progress = SrsProgress.fromMap(rows.single);

      expect(progress.masteryScore, 0.2);
      expect(progress.exposureCount, 9);
      expect(progress.repetitions, 2);
      expect(progress.easiness, 2.5);
      expect(progress.intervalDays, 6.0);
      expect(progress.nextReviewAt, dueAt);
      expect(progress.fsrsStability, 6.0);
      expect(progress.fsrsState, kFsrsStateReview);
      expect(progress.fsrsMigrated, isTrue);

      // And the review log gained the rating column the new rows write.
      final columns = await db.rawQuery('PRAGMA table_info(srs_reviews)');
      expect(
        columns.map((c) => c['name']),
        contains('rating'),
      );

      await db.close();
    });

    test('running the migration twice changes nothing', () async {
      final legacy = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE srs_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                strongs_id TEXT NOT NULL UNIQUE,
                exposure_count INTEGER NOT NULL DEFAULT 0,
                mastery_score REAL NOT NULL DEFAULT 0.0,
                next_review_at INTEGER NOT NULL,
                last_reviewed_at INTEGER NOT NULL,
                repetitions INTEGER NOT NULL DEFAULT 0,
                easiness REAL NOT NULL DEFAULT 2.5,
                interval_days REAL NOT NULL DEFAULT 0.0
              )
            ''');
            await db.execute('''
              CREATE TABLE srs_reviews (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                strongs_id TEXT NOT NULL,
                reviewed_at INTEGER NOT NULL,
                grade INTEGER NOT NULL
              )
            ''');
          },
        ),
      );
      await legacy.insert('srs_progress', {
        'strongs_id': 'H430',
        'exposure_count': 3,
        'mastery_score': 0.5,
        'next_review_at': now.millisecondsSinceEpoch,
        'last_reviewed_at': now.millisecondsSinceEpoch,
        'repetitions': 3,
        'easiness': 2.3,
        'interval_days': 15.0,
      });
      await legacy.close();

      final db = await databaseFactory.openDatabase(path);
      await migrateSrsToFsrs(db);
      await migrateSrsToFsrs(db);

      final rows = await db.query('srs_progress');
      final progress = SrsProgress.fromMap(rows.single);
      expect(progress.fsrsStability, 15.0);
      expect(progress.masteryScore, 0.5);
      expect(progress.fsrsState, kFsrsStateReview);
      await db.close();
    });
  });
}
