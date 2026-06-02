class LexiconEntry {
  final String strongsId;
  final String lemma;
  final String? transliteration;
  final String? pronunciation; // Simple Latin alphabet pronunciation
  final String? gloss;
  final String? definition;
  final String? language;

  LexiconEntry({
    required this.strongsId,
    required this.lemma,
    this.transliteration,
    this.pronunciation,
    this.gloss,
    this.definition,
    this.language,
  });

  factory LexiconEntry.fromMap(Map<String, dynamic> map) {
    return LexiconEntry(
      strongsId: map['strongs_id']?.toString() ?? '',
      lemma: map['lemma']?.toString() ?? '',
      transliteration: map['transliteration']?.toString(),
      pronunciation: map['pronunciation']?.toString(),
      gloss: map['gloss']?.toString(),
      definition: map['definition']?.toString(),
      language: map['language']?.toString(),
    );
  }
}
