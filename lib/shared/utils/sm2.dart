import 'dart:math' as math;

/// SM-2 spaced-repetition state shared by word SRS and passage memorization.
class Sm2State {
  final int repetitions;
  final double easiness;
  final double intervalDays;

  /// Display-facing mastery: how close the interval is to a month.
  final double masteryScore;

  const Sm2State({
    required this.repetitions,
    required this.easiness,
    required this.intervalDays,
    required this.masteryScore,
  });

  Duration get interval => Duration(minutes: (intervalDays * 24 * 60).round());
}

/// Quality grade for a binary correct answer: "correct after hesitation"
/// keeps easiness stable so intervals grow through repetitions, not grade
/// inflation.
const int _qualityCorrect = 4;

/// Failed reviews lower easiness (floored at 1.3) and reset the streak.
const int _qualityIncorrect = 2;

/// Failed items come back quickly instead of waiting a full day.
const double _relearningIntervalDays = 1 / 24;

/// Interval (in days) that counts as fully mastered for the display score.
const double _masteryIntervalDays = 30;

/// One SM-2 transition. [previous] is null for the first review.
Sm2State applySm2Transition({
  Sm2State? previous,
  required bool isCorrect,
}) {
  final quality = isCorrect ? _qualityCorrect : _qualityIncorrect;

  double easiness = previous?.easiness ?? 2.5;
  easiness += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
  easiness = math.max(1.3, easiness);

  int repetitions = previous?.repetitions ?? 0;
  double intervalDays;
  if (isCorrect) {
    repetitions += 1;
    if (repetitions == 1) {
      intervalDays = 1;
    } else if (repetitions == 2) {
      intervalDays = 6;
    } else {
      final previousInterval = math.max(1.0, previous?.intervalDays ?? 1.0);
      intervalDays = previousInterval * easiness;
    }
  } else {
    repetitions = 0;
    intervalDays = _relearningIntervalDays;
  }

  return Sm2State(
    repetitions: repetitions,
    easiness: easiness,
    intervalDays: intervalDays,
    masteryScore: (intervalDays / _masteryIntervalDays).clamp(0.0, 1.0),
  );
}
