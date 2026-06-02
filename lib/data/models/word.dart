class Word {
  final int id;
  final String verseId;
  final int position;
  final String displayText;
  final String? lemma;
  final String? strongs;
  final String? morphCode;
  final String language; // 'heb' or 'grc'

  Word({
    required this.id,
    required this.verseId,
    required this.position,
    required this.displayText,
    this.lemma,
    this.strongs,
    this.morphCode,
    required this.language,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      verseId: map['verse_id']?.toString() ?? '',
      position: map['position'] is int
          ? map['position']
          : int.tryParse(map['position']?.toString() ?? '0') ?? 0,
      displayText:
          map['display_text']?.toString() ?? map['word']?.toString() ?? '',
      lemma: map['lemma']?.toString(),
      strongs: map['strongs']?.toString() ?? map['strongs_id']?.toString(),
      morphCode: map['morph_code']?.toString() ?? map['morph']?.toString(),
      language: map['language']?.toString() ?? 'heb',
    );
  }

  /// Stable key for lexicon lookups and learning/SRS features.
  /// Prefers Strong's when available, falls back to lemma-based datasets.
  String? get lexiconLookupKey {
    final strongsKey = strongs?.trim();
    if (strongsKey != null && strongsKey.isNotEmpty) {
      return strongsKey;
    }

    final lemmaKey = lemma?.trim();
    if (lemmaKey != null && lemmaKey.isNotEmpty) {
      return lemmaKey;
    }

    return null;
  }
}
