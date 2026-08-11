/// Deciding what belongs in a vocabulary deck.
///
/// The frequency table is built from the source data's *tokens*, and MACULA
/// splits Hebrew words morphologically: the conjunction ו, the article ה, and
/// the prepositions ל, ב, מ each become a token of their own. By raw count
/// they are the five most common "words" in the Hebrew Bible — so an unfiltered
/// deck opens with "and", "the", "to", "in", "from", none of which is a word a
/// learner studies as vocabulary. They are prefixes, learned as grammar.
///
/// A second, plainer defect: some Strong's ids in the token table have no
/// lexicon row at all, so they would render as an empty card.
///
/// Both are filtered here rather than in SQL, because telling a prefix from a
/// real word means counting consonants underneath the pointing, which SQLite
/// cannot do.
library;

/// Hebrew letters alef..tav, including the final forms.
bool _isHebrewConsonant(int codeUnit) =>
    codeUnit >= 0x05D0 && codeUnit <= 0x05EA;

/// Greek letters, both cases, including the polytonic block.
bool _isGreekLetter(int codeUnit) =>
    (codeUnit >= 0x0386 && codeUnit <= 0x03FF) ||
    (codeUnit >= 0x1F00 && codeUnit <= 0x1FFF);

/// Number of real consonants in a pointed Hebrew lemma, ignoring vowel points,
/// dagesh, and accents.
int hebrewConsonantCount(String lemma) {
  var count = 0;
  for (final codeUnit in lemma.codeUnits) {
    if (_isHebrewConsonant(codeUnit)) count++;
  }
  return count;
}

/// Number of letters in a Greek lemma.
int greekLetterCount(String lemma) {
  var count = 0;
  for (final codeUnit in lemma.codeUnits) {
    if (_isGreekLetter(codeUnit)) count++;
  }
  return count;
}

/// Whether a lemma is a bare proclitic prefix rather than a standalone word.
///
/// Every Hebrew prefix that the tokenizer splits out — ו, ה, ל, ב, כ, מ, שׁ —
/// is a single consonant. Every ordinary Hebrew word has at least two. That one
/// test separates them cleanly, and needs no hand-maintained list.
bool isProcliticPrefix(String lemma, {required bool isHebrew}) {
  if (!isHebrew) return false;
  return hebrewConsonantCount(lemma) < 2;
}

/// Whether a lexicon key deserves a place in a vocabulary deck.
///
/// [lemma] and [gloss] come from the lexicon row; either being absent means the
/// token has no dictionary entry and would show as an empty card.
bool isDeckWorthy({
  required String? lemma,
  required String? gloss,
  required bool isHebrew,
}) {
  final trimmedLemma = lemma?.trim() ?? '';
  final trimmedGloss = gloss?.trim() ?? '';

  // No dictionary entry: nothing to show, nothing to learn.
  if (trimmedLemma.isEmpty || trimmedGloss.isEmpty) return false;

  // A gloss that is only punctuation or a bare Strong's marker, e.g. "(et)".
  if (!_hasLetter(trimmedGloss)) return false;

  // Grammar, not vocabulary.
  if (isProcliticPrefix(trimmedLemma, isHebrew: isHebrew)) return false;

  // The lemma must actually be in the right script.
  final scriptLetters = isHebrew
      ? hebrewConsonantCount(trimmedLemma)
      : greekLetterCount(trimmedLemma);
  if (scriptLetters == 0) return false;

  return true;
}

/// True when [text] contains at least one letter in any script.
bool _hasLetter(String text) =>
    RegExp(r'[A-Za-zͰ-Ͽ֐-׿ἀ-῿]').hasMatch(text);
