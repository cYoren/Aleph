/// FSRS (Free Spaced Repetition Scheduler) for vocabulary cards.
///
/// SM-2 kept two numbers per word — an easiness factor and an interval — and
/// grew the interval by that factor on every correct answer. FSRS models memory
/// instead: a stability (days until recall is expected to fall to 90%) and a
/// difficulty, and it schedules from those. It ships 21 pretrained weights, so
/// it schedules correctly with **zero** review history; only personalising the
/// weights needs volume, and nothing here attempts that.
///
/// The SM-2 columns on [SrsProgress] are kept alongside the FSRS ones. They are
/// the readable history ("answered correctly four times"), the learning path
/// reads them, and a row that arrives mid-schedule from SM-2 uses them to keep
/// the interval it already had.
library;

import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/models/srs_progress.dart';
import 'sm2.dart';

/// FSRS card states, as stored in `srs_progress.fsrs_state`.
const int kFsrsStateLearning = 1;
const int kFsrsStateReview = 2;
const int kFsrsStateRelearning = 3;

/// An interval at or above this many days counts as fully mastered for the
/// display score, matching the SM-2 era.
const double _masteryIntervalDays = 30;

const double _minutesPerDay = 24 * 60;

/// The scheduler every review uses.
///
/// The learning and relearning steps are 10 minutes, not the package's 1 and 10:
/// this app reviews in sessions, so a card that came due one minute after it was
/// answered could never be shown again in the same session. Ten minutes keeps a
/// lapsed card out of the current session and brings it back the same day if the
/// reader returns to the deck.
fsrs.Scheduler createFsrsScheduler({bool enableFuzzing = true}) {
  return fsrs.Scheduler(
    desiredRetention: 0.9,
    learningSteps: const [Duration(minutes: 10)],
    relearningSteps: const [Duration(minutes: 10)],
    enableFuzzing: enableFuzzing,
  );
}

/// The rating a binary review sheet maps to.
///
/// The quiz asks one question with two answers, so only the two ends of FSRS's
/// four-point scale are ever used. A four-button sheet would be one more
/// decision per card, on a scale the reader has no way to calibrate.
fsrs.Rating fsrsRatingFor({required bool isCorrect}) =>
    isCorrect ? fsrs.Rating.good : fsrs.Rating.again;

/// Difficulty implied by an SM-2 easiness factor, for rows that predate FSRS.
///
/// SM-2's easiness runs from 1.3 (hardest) up through a 2.5 default; FSRS
/// difficulty runs 1 (easiest) to 10. The mapping is linear through both
/// defaults (2.5 -> 5.0) and monotone, which is all a seed needs: the first
/// FSRS review replaces it.
double fsrsDifficultyFromEasiness(double easiness) {
  return (5.0 - (easiness - 2.5) * 2.5).clamp(1.0, 10.0);
}

/// Seeds FSRS state from an SM-2 row, touching nothing else.
///
/// Stability starts at the interval SM-2 had already scheduled and
/// `last_reviewed_at` is kept, so the first FSRS review sees the real elapsed
/// time. Mastery, exposure count and every SM-2 column are left exactly as they
/// were — a migration may not lower a mastery score.
///
/// A row with no SM-2 history stays in the learning state with no stability,
/// which is what a card that has never been answered looks like.
SrsProgress migrateSm2ProgressToFsrs(SrsProgress progress) {
  if (progress.intervalDays <= 0 || progress.repetitions < 1) {
    return progress.copyWith(
      fsrsState: kFsrsStateLearning,
      fsrsReps: progress.repetitions,
      fsrsFloorPending: false,
    );
  }

  return progress.copyWith(
    fsrsStability: math.max(progress.intervalDays, fsrs.stabilityMin),
    fsrsDifficulty: fsrsDifficultyFromEasiness(progress.easiness),
    fsrsState: kFsrsStateReview,
    fsrsReps: progress.repetitions,
    fsrsFloorPending: true,
  );
}

/// One FSRS review, separated from persistence so it can be tested directly.
///
/// [current] is the stored row (null for a word never reviewed). The returned
/// row carries the new due date in [SrsProgress.nextReviewAt], the FSRS card
/// state, and the SM-2 columns advanced as a shadow so nothing that reads them
/// changes meaning.
SrsProgress applyFsrsReview(
  SrsProgress? current, {
  required String strongsId,
  required bool isCorrect,
  required DateTime now,
  fsrs.Scheduler? scheduler,
}) {
  final engine = scheduler ?? createFsrsScheduler();
  final rating = fsrsRatingFor(isCorrect: isCorrect);
  final at = now.toUtc();

  final card = _cardFor(current, strongsId, at);
  final outcome = engine.reviewCard(card, rating, reviewDateTime: at);

  var intervalDays =
      outcome.card.due.difference(at).inMinutes / _minutesPerDay;
  intervalDays = math.max(intervalDays, fsrs.stabilityMin);

  // What SM-2 would have scheduled for this same answer, from the state the row
  // arrived with. It is the floor for the first FSRS review of a migrated row:
  // changing the scheduler must never pull a reader's reviews forward.
  final sm2 = applySm2Transition(
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

  if (current != null && current.fsrsFloorPending) {
    intervalDays = math.max(intervalDays, sm2.intervalDays);
  }

  return SrsProgress(
    id: current?.id,
    strongsId: strongsId,
    exposureCount: (current?.exposureCount ?? 0) + 1,
    masteryScore: (intervalDays / _masteryIntervalDays).clamp(0.0, 1.0),
    lastReviewedAt: now,
    nextReviewAt: now.add(
      Duration(minutes: (intervalDays * _minutesPerDay).round()),
    ),
    repetitions: sm2.repetitions,
    easiness: sm2.easiness,
    intervalDays: intervalDays,
    fsrsStability: outcome.card.stability,
    fsrsDifficulty: outcome.card.difficulty,
    fsrsState: outcome.card.state.value,
    fsrsStep: outcome.card.step,
    fsrsReps: (current?.fsrsReps ?? 0) + (isCorrect ? 1 : 0),
    fsrsLapses: (current?.fsrsLapses ?? 0) + (isCorrect ? 0 : 1),
    fsrsFloorPending: false,
  );
}

/// The stored row as an FSRS card, due now.
fsrs.Card _cardFor(SrsProgress? current, String strongsId, DateTime at) {
  final cardId = _stableCardId(strongsId);

  if (current == null || current.fsrsStability == null) {
    return fsrs.Card(cardId: cardId, due: at);
  }

  return fsrs.Card(
    cardId: cardId,
    state: fsrs.State.fromValue(current.fsrsState.clamp(1, 3)),
    step: current.fsrsStep,
    stability: current.fsrsStability,
    difficulty:
        current.fsrsDifficulty ?? fsrsDifficultyFromEasiness(current.easiness),
    due: at,
    lastReview: current.lastReviewedAt.toUtc(),
  );
}

/// A card id that is stable across runs and platforms.
///
/// FSRS only uses it to label review logs, but `String.hashCode` is not
/// guaranteed to survive a restart, and a log whose ids shuffle is not a log.
int _stableCardId(String strongsId) {
  var hash = 0x811c9dc5;
  for (final unit in strongsId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
