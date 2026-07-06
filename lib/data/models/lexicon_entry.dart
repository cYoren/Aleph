class LexiconEntry {
  final String strongsId;
  final String lemma;
  final String? transliteration;
  final String? pronunciation; // Simple Latin alphabet pronunciation
  final String? gloss;
  final String? definition;
  final String? language;

  /// Full scholarly lexicon entry (BDB for Hebrew, Abbott-Smith for Greek).
  final String? extendedDefinition;

  /// Which lexicon [extendedDefinition] comes from: 'BDB' or 'Abbott-Smith'.
  final String? extendedSource;

  LexiconEntry({
    required this.strongsId,
    required this.lemma,
    this.transliteration,
    this.pronunciation,
    this.gloss,
    this.definition,
    this.language,
    this.extendedDefinition,
    this.extendedSource,
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
      extendedDefinition: map['extended_definition']?.toString(),
      extendedSource: map['extended_source']?.toString(),
    );
  }
}
