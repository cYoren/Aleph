class SrsProgress {
  final int? id;
  final String strongsId;
  final int exposureCount;
  final double masteryScore;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  /// SM-2 state: consecutive successful reviews since the last failure.
  ///
  /// FSRS schedules the card now, but this column is still written on every
  /// review: "has this word ever been answered correctly" is read by the
  /// learning path, and the migration floor needs the SM-2 numbers a row
  /// arrived with.
  final int repetitions;

  /// SM-2 easiness factor (>= 1.3, starts at 2.5).
  final double easiness;

  /// Current inter-review interval in days (fractional for sub-day steps).
  final double intervalDays;

  /// FSRS memory stability: days until recall is expected to fall to 90%.
  ///
  /// Null on a card that has never been answered.
  final double? fsrsStability;

  /// FSRS difficulty, 1 (easiest) to 10 (hardest). Null until first review.
  final double? fsrsDifficulty;

  /// FSRS card state: 1 learning, 2 review, 3 relearning.
  final int fsrsState;

  /// Position in the learning or relearning steps; null in the review state.
  final int? fsrsStep;

  /// Successful FSRS reviews of this card.
  final int fsrsReps;

  /// Times this card has been forgotten since it reached the review state.
  final int fsrsLapses;

  /// True while this row still carries the state SM-2 left it in.
  ///
  /// The first FSRS review of such a row is floored at the interval SM-2 would
  /// have scheduled, so upgrading the scheduler never pulls a review forward.
  final bool fsrsMigrated;

  const SrsProgress({
    this.id,
    required this.strongsId,
    this.exposureCount = 0,
    this.masteryScore = 0.0,
    required this.nextReviewAt,
    required this.lastReviewedAt,
    this.repetitions = 0,
    this.easiness = 2.5,
    this.intervalDays = 0.0,
    this.fsrsStability,
    this.fsrsDifficulty,
    this.fsrsState = 1,
    this.fsrsStep,
    this.fsrsReps = 0,
    this.fsrsLapses = 0,
    this.fsrsMigrated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strongs_id': strongsId,
      'exposure_count': exposureCount,
      'mastery_score': masteryScore,
      'next_review_at': nextReviewAt.millisecondsSinceEpoch,
      'last_reviewed_at': lastReviewedAt.millisecondsSinceEpoch,
      'repetitions': repetitions,
      'easiness': easiness,
      'interval_days': intervalDays,
      'fsrs_stability': fsrsStability,
      'fsrs_difficulty': fsrsDifficulty,
      'fsrs_state': fsrsState,
      'fsrs_step': fsrsStep,
      'fsrs_reps': fsrsReps,
      'fsrs_lapses': fsrsLapses,
      'fsrs_migrated': fsrsMigrated ? 1 : 0,
    };
  }

  factory SrsProgress.fromMap(Map<String, dynamic> map) {
    return SrsProgress(
      id: map['id'],
      strongsId: map['strongs_id'],
      exposureCount: map['exposure_count'],
      masteryScore: map['mastery_score'],
      nextReviewAt: DateTime.fromMillisecondsSinceEpoch(map['next_review_at']),
      lastReviewedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_reviewed_at'],
      ),
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,
      easiness: (map['easiness'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (map['interval_days'] as num?)?.toDouble() ?? 0.0,
      fsrsStability: (map['fsrs_stability'] as num?)?.toDouble(),
      fsrsDifficulty: (map['fsrs_difficulty'] as num?)?.toDouble(),
      fsrsState: (map['fsrs_state'] as num?)?.toInt() ?? 1,
      fsrsStep: (map['fsrs_step'] as num?)?.toInt(),
      fsrsReps: (map['fsrs_reps'] as num?)?.toInt() ?? 0,
      fsrsLapses: (map['fsrs_lapses'] as num?)?.toInt() ?? 0,
      fsrsMigrated: ((map['fsrs_migrated'] as num?)?.toInt() ?? 0) != 0,
    );
  }

  SrsProgress copyWith({
    int? id,
    String? strongsId,
    int? exposureCount,
    double? masteryScore,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    int? repetitions,
    double? easiness,
    double? intervalDays,
    double? fsrsStability,
    double? fsrsDifficulty,
    int? fsrsState,
    int? fsrsStep,
    int? fsrsReps,
    int? fsrsLapses,
    bool? fsrsMigrated,
  }) {
    return SrsProgress(
      id: id ?? this.id,
      strongsId: strongsId ?? this.strongsId,
      exposureCount: exposureCount ?? this.exposureCount,
      masteryScore: masteryScore ?? this.masteryScore,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      repetitions: repetitions ?? this.repetitions,
      easiness: easiness ?? this.easiness,
      intervalDays: intervalDays ?? this.intervalDays,
      fsrsStability: fsrsStability ?? this.fsrsStability,
      fsrsDifficulty: fsrsDifficulty ?? this.fsrsDifficulty,
      fsrsState: fsrsState ?? this.fsrsState,
      fsrsStep: fsrsStep ?? this.fsrsStep,
      fsrsReps: fsrsReps ?? this.fsrsReps,
      fsrsLapses: fsrsLapses ?? this.fsrsLapses,
      fsrsMigrated: fsrsMigrated ?? this.fsrsMigrated,
    );
  }
}
