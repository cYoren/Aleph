/// SM-2, still the scheduler for passage memorization and the reference the
/// FSRS migration is measured against.
///
/// Vocabulary cards moved to FSRS (`test/srs_fsrs_test.dart`), but SM-2 did not
/// leave the codebase: memorization passages keep their own SM-2 state, and the
/// first FSRS review of a migrated word is floored at the interval SM-2 would
/// have scheduled. These assertions moved from `SrsDao.applySm2` onto the
/// transition itself when the DAO stopped owning a scheduler.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/shared/utils/sm2.dart';

void main() {
  group('SM-2 spaced repetition', () {
    test('first correct review schedules a 1-day interval', () {
      final result = applySm2Transition(previous: null, isCorrect: true);

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easiness, 2.5);
      expect(result.interval, const Duration(days: 1));
    });

    test('second correct review schedules a 6-day interval', () {
      final first = applySm2Transition(previous: null, isCorrect: true);
      final second = applySm2Transition(previous: first, isCorrect: true);

      expect(second.repetitions, 2);
      expect(second.intervalDays, 6);
    });

    test('third correct review multiplies interval by easiness', () {
      var state = applySm2Transition(previous: null, isCorrect: true);
      state = applySm2Transition(previous: state, isCorrect: true);
      state = applySm2Transition(previous: state, isCorrect: true);

      expect(state.repetitions, 3);
      expect(state.intervalDays, closeTo(6 * 2.5, 0.001));
    });

    test('intervals keep expanding across further successful reviews', () {
      Sm2State? state;
      for (var i = 0; i < 6; i++) {
        state = applySm2Transition(previous: state, isCorrect: true);
      }

      // 1, 6, 15, 37.5, 93.75, 234.375 days with a stable easiness of 2.5.
      expect(state!.intervalDays, closeTo(6 * 2.5 * 2.5 * 2.5 * 2.5, 0.01));
      expect(state.masteryScore, 1.0);
    });

    test('failure resets streak, lowers easiness, schedules quick relearn', () {
      var state = applySm2Transition(previous: null, isCorrect: true);
      state = applySm2Transition(previous: state, isCorrect: true);
      final failed = applySm2Transition(previous: state, isCorrect: false);

      expect(failed.repetitions, 0);
      expect(failed.easiness, lessThan(2.5));
      // Relearning step: back in roughly an hour, not a full day.
      expect(failed.intervalDays, closeTo(1 / 24, 0.001));
      expect(failed.interval.inMinutes, 60);
    });

    test('easiness never drops below the SM-2 floor of 1.3', () {
      Sm2State? state;
      for (var i = 0; i < 20; i++) {
        state = applySm2Transition(previous: state, isCorrect: false);
      }

      expect(state!.easiness, greaterThanOrEqualTo(1.3));
    });

    test('mastery score scales with interval up to one month', () {
      var state = applySm2Transition(previous: null, isCorrect: true);
      expect(state.masteryScore, closeTo(1 / 30, 0.001));

      state = applySm2Transition(previous: state, isCorrect: true);
      expect(state.masteryScore, closeTo(6 / 30, 0.001));
    });
  });
}
