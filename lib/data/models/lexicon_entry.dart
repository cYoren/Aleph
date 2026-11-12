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

  /// Language the definition text is actually in.
  ///
  /// Null means the English original (either because the reader is on English,
  /// or because no translation exists for this entry yet). The definition sheet
  /// uses this to label the fallback honestly instead of passing English off as
  /// the reader's language.
  final String? definitionLanguage;

  /// Language the [extendedDefinition] text is actually in; see
  /// [definitionLanguage].
  final String? extendedDefinitionLanguage;

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
    this.definitionLanguage,
    this.extendedDefinitionLanguage,
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
      definitionLanguage: map['definition_language']?.toString(),
      extendedDefinitionLanguage:
          map['extended_definition_language']?.toString(),
    );
  }
}
