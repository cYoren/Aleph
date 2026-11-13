class Word {
  final int id;
  final String verseId;
  final int position;
  final String displayText;
  final String? lemma;
  final String? strongs;
  final String? morphCode;
  final String language; // 'heb' or 'grc'

  /// MACULA participant data: the word this token's subject actually is, and —
  /// for a pronoun — what it refers back to. Resolved from the treebank's own
  /// node ids at build time, which is how the app can answer "who is he here".
  final String? subjectText;
  final String? subjectStrongs;
  final String? referentText;
  final String? referentStrongs;

  /// Qere/Ketiv: the reading tradition's form of a word the scroll writes
  /// differently. Both are stored because the flowing text follows one or the
  /// other case by case, and the app must not assume which.
  final String? qereText;
  final String? ketivText;

  /// The dictionary form of the reading, when it is a different word from the
  /// one written (H1938 for a ketiv of H1939, for instance).
  final String? qereLemma;

  Word({
    required this.id,
    required this.verseId,
    required this.position,
    required this.displayText,
    this.lemma,
    this.strongs,
    this.morphCode,
    required this.language,
    this.subjectText,
    this.subjectStrongs,
    this.referentText,
    this.referentStrongs,
    this.qereText,
    this.ketivText,
    this.qereLemma,
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
      subjectText: _nonEmpty(map['subject_text']?.toString()),
      subjectStrongs: _nonEmpty(map['subject_strongs']?.toString()),
      referentText: _nonEmpty(map['referent_text']?.toString()),
      referentStrongs: _nonEmpty(map['referent_strongs']?.toString()),
      qereText: _nonEmpty(map['qere_text']?.toString()),
      ketivText: _nonEmpty(map['ketiv_text']?.toString()),
      qereLemma: _nonEmpty(map['qere_lemma']?.toString()),
    );
  }

  /// True where the written text and the reading differ.
  bool get hasQereKetiv => qereText != null && ketivText != null;

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
