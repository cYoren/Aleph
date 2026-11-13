/// One place where another edition of the Greek New Testament reads differently
/// from the SBLGNT this app carries.
///
/// This is a text comparison, not a critical apparatus: it names the edition,
/// not the manuscripts, and it makes no claim about which reading is original.
class TextualVariant {
  final int id;
  final String bookId;
  final int chapter;
  final int verse;
  final int position;

  /// The edition that differs from the base text, e.g. `RP2018` or `SR`.
  final String edition;

  /// What the base text (SBLGNT) reads here. Empty where the other edition adds.
  final String baseReading;

  /// What [edition] reads here. Empty where it omits.
  final String otherReading;

  const TextualVariant({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.position,
    required this.edition,
    required this.baseReading,
    required this.otherReading,
  });

  factory TextualVariant.fromMap(Map<String, dynamic> map) {
    return TextualVariant(
      id: (map['id'] as num?)?.toInt() ?? 0,
      bookId: map['book_id']?.toString() ?? '',
      chapter: (map['chapter'] as num?)?.toInt() ?? 0,
      verse: (map['verse'] as num?)?.toInt() ?? 0,
      position: (map['position'] as num?)?.toInt() ?? 0,
      edition: map['edition']?.toString() ?? '',
      baseReading: map['base_reading']?.toString() ?? '',
      otherReading: map['other_reading']?.toString() ?? '',
    );
  }

  /// The edition's own name, as a reader would recognise it.
  String get editionLabel {
    switch (edition) {
      case 'RP2018':
        return 'Robinson–Pierpont (Byzantine, 2018)';
      case 'SR':
        return 'Statistical Restoration (CNTR, 2022)';
      default:
        return edition;
    }
  }
}
