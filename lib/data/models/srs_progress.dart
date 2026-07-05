class SrsProgress {
  final int? id;
  final String strongsId;
  final int exposureCount;
  final double masteryScore;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  /// SM-2 state: consecutive successful reviews since the last failure.
  final int repetitions;

  /// SM-2 easiness factor (>= 1.3, starts at 2.5).
  final double easiness;

  /// Current inter-review interval in days (fractional for sub-day steps).
  final double intervalDays;

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
    );
  }
}
