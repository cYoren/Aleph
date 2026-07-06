class CrossReference {
  final String toBook;
  final int toChapter;
  final int toVerseStart;
  final int toVerseEnd;
  final int votes;

  const CrossReference({
    required this.toBook,
    required this.toChapter,
    required this.toVerseStart,
    required this.toVerseEnd,
    required this.votes,
  });

  bool get isRange => toVerseEnd > toVerseStart;

  factory CrossReference.fromMap(Map<String, dynamic> map) {
    return CrossReference(
      toBook: map['to_book']?.toString() ?? '',
      toChapter: (map['to_chapter'] as num?)?.toInt() ?? 1,
      toVerseStart: (map['to_verse_start'] as num?)?.toInt() ?? 1,
      toVerseEnd: (map['to_verse_end'] as num?)?.toInt() ?? 1,
      votes: (map['votes'] as num?)?.toInt() ?? 0,
    );
  }
}
