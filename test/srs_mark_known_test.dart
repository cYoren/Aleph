/// "Mark as known" from the definition sheet.
///
/// A reader who knows a word should not have to sit through a card to prove it,
/// and the claim must survive the review engine: a word marked known has to stop
/// being glossed in reader mode while never losing history it already had.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/srs_dao.dart';
import 'package:original_bible/data/database/user_database_helper.dart';
import 'package:original_bible/data/models/srs_progress.dart';
import 'package:original_bible/shared/utils/reader_mode.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    await UserDatabaseHelper.instance.close();
  });

  tearDown(() async {
    await UserDatabaseHelper.instance.close();
  });

  final now = DateTime(2026, 11, 13, 9);

  group('markKnown', () {
    test('a new word lands above the reader-mode suppression bar', () async {
      final dao = SrsDao();
      final progress = await dao.markKnown('H9001', now: now);

      expect(
        progress.masteryScore,
        greaterThan(kReaderModeMasterySuppression),
      );
      expect(progress.repetitions, greaterThanOrEqualTo(1));
      expect(progress.intervalDays, 180);
      expect(progress.nextReviewAt.isAfter(now), isTrue);
      expect(progress.exposureCount, 0);
    });

    test('existing history is kept, never lowered', () async {
      final dao = SrsDao();
      await dao.saveProgress(
        SrsProgress(
          strongsId: 'H9002',
          exposureCount: 7,
          masteryScore: 0.9,
          easiness: 2.1,
          repetitions: 4,
          intervalDays: 30,
          nextReviewAt: now.add(const Duration(days: 30)),
          lastReviewedAt: now.subtract(const Duration(days: 5)),
        ),
      );

      final marked = await dao.markKnown('H9002', now: now);

      expect(marked.masteryScore, 0.9);
      expect(marked.exposureCount, 7);
      expect(marked.easiness, 2.1);
      expect(marked.repetitions, 4);
    });

    test('every answered card is appended to the review log', () async {
      final dao = SrsDao();
      final before = await dao.countReviews();

      await dao.recordReview('H9004', isCorrect: true);
      await dao.recordReview('H9004', isCorrect: false);

      expect(await dao.countReviews(), before + 2);
      final db = await UserDatabaseHelper.instance.database;
      // The test database outlives a run, so read the two newest rows rather
      // than assuming this is the first pass.
      final rows = await db.query(
        'srs_reviews',
        where: 'strongs_id = ?',
        whereArgs: ['H9004'],
        orderBy: 'id DESC',
        limit: 2,
      );
      expect(rows, hasLength(2));
      expect(rows.last['grade'], 1);
      expect(rows.first['grade'], 0);
      // The second review happened after the first had taken hold.
      expect(
        (rows.first['repetitions_before'] as num).toInt(),
        greaterThanOrEqualTo(1),
      );
    });

    test('marking known is not logged as a review', () async {
      final dao = SrsDao();
      final before = await dao.countReviews();
      await dao.markKnown('H9005');
      expect(await dao.countReviews(), before);
    });

    test('a word below the bar is raised past it', () async {
      final dao = SrsDao();
      await dao.saveProgress(
        SrsProgress(
          strongsId: 'H9003',
          exposureCount: 3,
          masteryScore: 0.1,
          repetitions: 1,
          nextReviewAt: now,
          lastReviewedAt: now,
        ),
      );

      final marked = await dao.markKnown('H9003', now: now);

      expect(
        marked.masteryScore,
        greaterThan(kReaderModeMasterySuppression),
      );
      expect(marked.exposureCount, 3);
    });
  });
}
