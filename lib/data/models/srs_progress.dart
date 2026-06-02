class SrsProgress {
  final int? id;
  final String strongsId;
  final int exposureCount;
  final double masteryScore;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  const SrsProgress({
    this.id,
    required this.strongsId,
    this.exposureCount = 0,
    this.masteryScore = 0.0,
    required this.nextReviewAt,
    required this.lastReviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'strongs_id': strongsId,
      'exposure_count': exposureCount,
      'mastery_score': masteryScore,
      'next_review_at': nextReviewAt.millisecondsSinceEpoch,
      'last_reviewed_at': lastReviewedAt.millisecondsSinceEpoch,
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
    );
  }

  SrsProgress copyWith({
    int? id,
    String? strongsId,
    int? exposureCount,
    double? masteryScore,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
  }) {
    return SrsProgress(
      id: id ?? this.id,
      strongsId: strongsId ?? this.strongsId,
      exposureCount: exposureCount ?? this.exposureCount,
      masteryScore: masteryScore ?? this.masteryScore,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
