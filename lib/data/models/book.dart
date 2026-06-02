class Book {
  final int id; // Numeric ID from database
  final String abbreviation; // "GEN", "EXO", etc.
  final String name; // "Gen", "Exod", etc.
  final String testament; // "OT" or "NT"
  final int order; // Book order (1-66)
  final int chapterCount; // Number of chapters in this book

  Book({
    required this.id,
    required this.abbreviation,
    required this.name,
    required this.testament,
    required this.order,
    this.chapterCount = 0,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      abbreviation: map['abbreviation']?.toString() ?? '',
      name: map['name_en']?.toString() ?? map['name']?.toString() ?? '',
      testament: map['testament']?.toString() ?? '',
      order: map['book_order'] is int
          ? map['book_order']
          : int.tryParse(map['book_order']?.toString() ?? '0') ?? 0,
      chapterCount: map['chapter_count'] is int
          ? map['chapter_count']
          : int.tryParse(map['chapter_count']?.toString() ?? '0') ?? 0,
    );
  }

  /// Standard chapter counts for each book (fallback if not in DB)
  static const Map<String, int> standardChapterCounts = {
    'GEN': 50,
    'EXO': 40,
    'LEV': 27,
    'NUM': 36,
    'DEU': 34,
    'JOS': 24,
    'JDG': 21,
    'RUT': 4,
    '1SA': 31,
    '2SA': 24,
    '1KI': 22,
    '2KI': 25,
    '1CH': 29,
    '2CH': 36,
    'EZR': 10,
    'NEH': 13,
    'EST': 10,
    'JOB': 42,
    'PSA': 150,
    'PRO': 31,
    'ECC': 12,
    'SNG': 8,
    'ISA': 66,
    'JER': 52,
    'LAM': 5,
    'EZK': 48,
    'DAN': 12,
    'HOS': 14,
    'JOL': 3,
    'AMO': 9,
    'OBA': 1,
    'JON': 4,
    'MIC': 7,
    'NAM': 3,
    'HAB': 3,
    'ZEP': 3,
    'HAG': 2,
    'ZEC': 14,
    'MAL': 4,
    'MAT': 28,
    'MRK': 16,
    'LUK': 24,
    'JHN': 21,
    'ACT': 28,
    'ROM': 16,
    '1CO': 16,
    '2CO': 13,
    'GAL': 6,
    'EPH': 6,
    'PHP': 4,
    'COL': 4,
    '1TH': 5,
    '2TH': 3,
    '1TI': 6,
    '2TI': 4,
    'TIT': 3,
    'PHM': 1,
    'HEB': 13,
    'JAS': 5,
    '1PE': 5,
    '2PE': 3,
    '1JN': 5,
    '2JN': 1,
    '3JN': 1,
    'JUD': 1,
    'REV': 22,
  };

  int get effectiveChapterCount => chapterCount > 0
      ? chapterCount
      : (standardChapterCounts[abbreviation] ?? 1);
}
