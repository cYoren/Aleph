import 'word.dart';

class Verse {
  final String id; // "GEN.1.1"
  final String bookId;
  final int chapter;
  final int verseNumber;
  final String textContent;
  final List<Word> words;

  Verse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.textContent,
    this.words = const [],
  });

  factory Verse.fromMap(Map<String, dynamic> map) {
    final bookId = map['book_id']?.toString() ?? '';
    final chapter = map['chapter'] is int
        ? map['chapter']
        : int.tryParse(map['chapter']?.toString() ?? '0') ?? 0;
    final verseNumber = map['verse'] is int
        ? map['verse']
        : map['verse_number'] is int
        ? map['verse_number']
        : int.tryParse(
                map['verse']?.toString() ??
                    map['verse_number']?.toString() ??
                    '0',
              ) ??
              0;
    final rawId = map['id']?.toString() ?? '';

    final normalizedId = rawId.contains('.') && rawId.split('.').length >= 3
        ? rawId
        : (bookId.isNotEmpty && chapter > 0 && verseNumber > 0)
        ? '$bookId.$chapter.$verseNumber'
        : rawId;

    return Verse(
      id: normalizedId,
      bookId: bookId,
      chapter: chapter,
      verseNumber: verseNumber,
      textContent:
          map['text_content']?.toString() ?? map['text']?.toString() ?? '',
    );
  }
}
