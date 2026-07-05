class MemorizationPassage {
  final int? id;
  final String bookId;
  final int chapter;
  final DateTime createdAt;
  final int repetitions;
  final double easiness;
  final double intervalDays;
  final double masteryScore;
  final DateTime nextReviewAt;
  final DateTime? lastPracticedAt;

  const MemorizationPassage({
    this.id,
    required this.bookId,
    required this.chapter,
    required this.createdAt,
    this.repetitions = 0,
    this.easiness = 2.5,
    this.intervalDays = 0.0,
    this.masteryScore = 0.0,
    required this.nextReviewAt,
    this.lastPracticedAt,
  });

  bool isDue(DateTime now) => !nextReviewAt.isAfter(now);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter': chapter,
      'created_at': createdAt.millisecondsSinceEpoch,
      'repetitions': repetitions,
      'easiness': easiness,
      'interval_days': intervalDays,
      'mastery_score': masteryScore,
      'next_review_at': nextReviewAt.millisecondsSinceEpoch,
      'last_practiced_at': lastPracticedAt?.millisecondsSinceEpoch,
    };
  }

  factory MemorizationPassage.fromMap(Map<String, dynamic> map) {
    return MemorizationPassage(
      id: map['id'],
      bookId: map['book_id']?.toString() ?? '',
      chapter: (map['chapter'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as num?)?.toInt() ?? 0,
      ),
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,
      easiness: (map['easiness'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (map['interval_days'] as num?)?.toDouble() ?? 0.0,
      masteryScore: (map['mastery_score'] as num?)?.toDouble() ?? 0.0,
      nextReviewAt: DateTime.fromMillisecondsSinceEpoch(
        (map['next_review_at'] as num?)?.toInt() ?? 0,
      ),
      lastPracticedAt: map['last_practiced_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['last_practiced_at'] as num).toInt(),
            ),
    );
  }
}
