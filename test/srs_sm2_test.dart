import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/srs_dao.dart';
import 'package:original_bible/data/models/srs_progress.dart';

void main() {
  final now = DateTime(2026, 7, 5, 12);

  group('SM-2 spaced repetition', () {
    test('first correct review schedules a 1-day interval', () {
      final result = SrsDao.applySm2(
        null,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easiness, 2.5);
      expect(result.nextReviewAt, now.add(const Duration(days: 1)));
      expect(result.exposureCount, 1);
    });

    test('second correct review schedules a 6-day interval', () {
      final first = SrsDao.applySm2(
        null,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      final second = SrsDao.applySm2(
        first,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );

      expect(second.repetitions, 2);
      expect(second.intervalDays, 6);
    });

    test('third correct review multiplies interval by easiness', () {
      var progress = SrsDao.applySm2(
        null,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      progress = SrsDao.applySm2(
        progress,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      progress = SrsDao.applySm2(
        progress,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );

      expect(progress.repetitions, 3);
      expect(progress.intervalDays, closeTo(6 * 2.5, 0.001));
    });

    test('intervals keep expanding across further successful reviews', () {
      SrsProgress? progress;
      for (var i = 0; i < 6; i++) {
        progress = SrsDao.applySm2(
          progress,
          strongsId: 'H430',
          isCorrect: true,
          now: now,
        );
      }

      // 1, 6, 15, 37.5, 93.75, 234.375 days with a stable easiness of 2.5.
      expect(progress!.intervalDays, closeTo(6 * 2.5 * 2.5 * 2.5 * 2.5, 0.01));
      expect(progress.masteryScore, 1.0);
    });

    test('failure resets streak, lowers easiness, schedules quick relearn', () {
      var progress = SrsDao.applySm2(
        null,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      progress = SrsDao.applySm2(
        progress,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      final failed = SrsDao.applySm2(
        progress,
        strongsId: 'H430',
        isCorrect: false,
        now: now,
      );

      expect(failed.repetitions, 0);
      expect(failed.easiness, lessThan(2.5));
      // Relearning step: back in roughly an hour, not a full day.
      expect(failed.intervalDays, closeTo(1 / 24, 0.001));
      expect(failed.nextReviewAt.difference(now).inMinutes, 60);
    });

    test('easiness never drops below the SM-2 floor of 1.3', () {
      SrsProgress? progress;
      for (var i = 0; i < 20; i++) {
        progress = SrsDao.applySm2(
          progress,
          strongsId: 'H430',
          isCorrect: false,
          now: now,
        );
      }

      expect(progress!.easiness, greaterThanOrEqualTo(1.3));
    });

    test('legacy rows without SM-2 state get sane defaults', () {
      // Simulates a row written by the pre-SM-2 schema after the v3 migration
      // (repetitions=0, easiness=2.5, intervalDays=0).
      final legacy = SrsProgress(
        strongsId: 'G26',
        exposureCount: 7,
        masteryScore: 0.6,
        nextReviewAt: now,
        lastReviewedAt: now.subtract(const Duration(days: 3)),
      );

      final result = SrsDao.applySm2(
        legacy,
        strongsId: 'G26',
        isCorrect: true,
        now: now,
      );

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.exposureCount, 8);
    });

    test('mastery score scales with interval up to one month', () {
      var progress = SrsDao.applySm2(
        null,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      expect(progress.masteryScore, closeTo(1 / 30, 0.001));

      progress = SrsDao.applySm2(
        progress,
        strongsId: 'H430',
        isCorrect: true,
        now: now,
      );
      expect(progress.masteryScore, closeTo(6 / 30, 0.001));
    });
  });
}
