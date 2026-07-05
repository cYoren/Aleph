// Pure logic for passage memorization practice (cloze deletion).

/// Practice difficulty: how much of the text is hidden.
enum MemorizationLevel {
  /// ~30% of words hidden.
  warmUp,

  /// ~60% of words hidden.
  challenge,

  /// Every word reduced to its first letter.
  firstLetters,
}

/// Suggested difficulty from how often the passage has been recalled
/// successfully in a row.
MemorizationLevel defaultLevelForRepetitions(int repetitions) {
  if (repetitions <= 1) return MemorizationLevel.warmUp;
  if (repetitions <= 3) return MemorizationLevel.challenge;
  return MemorizationLevel.firstLetters;
}

double _hideFraction(MemorizationLevel level) {
  switch (level) {
    case MemorizationLevel.warmUp:
      return 0.3;
    case MemorizationLevel.challenge:
      return 0.6;
    case MemorizationLevel.firstLetters:
      return 1.0;
  }
}

/// Deterministically selects which word positions to hide, so the same verse
/// at the same level always hides the same words (stable practice, no reroll
/// on rebuild). Simple LCG keyed by [seed].
Set<int> selectHiddenWordIndices({
  required int wordCount,
  required MemorizationLevel level,
  required int seed,
}) {
  if (wordCount <= 0) return const {};

  final fraction = _hideFraction(level);
  final targetCount = (wordCount * fraction).round().clamp(0, wordCount);
  if (targetCount == 0) return const {};
  if (targetCount >= wordCount) {
    return {for (var i = 0; i < wordCount; i++) i};
  }

  // Fisher-Yates over indices with an LCG (Numerical Recipes constants).
  var state = seed & 0x7fffffff;
  int nextInt(int max) {
    state = (state * 1664525 + 1013904223) & 0x7fffffff;
    return state % max;
  }

  final indices = List<int>.generate(wordCount, (i) => i);
  for (var i = wordCount - 1; i > 0; i--) {
    final j = nextInt(i + 1);
    final tmp = indices[i];
    indices[i] = indices[j];
    indices[j] = tmp;
  }
  return indices.take(targetCount).toSet();
}

bool _isCombiningHebrewMark(int codeUnit) {
  return codeUnit >= 0x0591 && codeUnit <= 0x05C7 && codeUnit != 0x05BE;
}

/// First-letter hint for a hidden word: the first base character plus any
/// combining marks that belong to it (so pointed Hebrew keeps its vowel),
/// followed by an ellipsis.
String firstLetterHint(String word) {
  if (word.isEmpty) return '…';

  final units = word.codeUnits;
  final kept = <int>[units[0]];
  for (var i = 1; i < units.length; i++) {
    if (_isCombiningHebrewMark(units[i])) {
      kept.add(units[i]);
    } else {
      break;
    }
  }
  return '${String.fromCharCodes(kept)}…';
}

/// Splits verse text into practice tokens (whitespace-separated words).
List<String> tokenizeVerse(String text) {
  return text
      .split(RegExp(r'\s+'))
      .where((token) => token.trim().isNotEmpty)
      .toList();
}
