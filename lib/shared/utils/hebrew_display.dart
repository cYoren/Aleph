/// Display modes for the Hebrew text.
///
/// Reading with fewer diacritics is itself a learning progression: cantillation
/// first, then vowel points, until the consonantal text reads on its own.
enum HebrewTextDisplay {
  /// Full Masoretic text: consonants, niqqud, and cantillation marks.
  full,

  /// Consonants and vowel points, cantillation (te'amim) stripped.
  noCantillation,

  /// Consonantal text only, as in a Torah scroll.
  consonantal,

  /// Full text, plus the other half of every qere/ketiv pair: where the scroll
  /// writes one thing and the reading tradition says another, the reader sees
  /// what is written beside what is read.
  qere;

  static HebrewTextDisplay fromName(String? name) {
    return HebrewTextDisplay.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => HebrewTextDisplay.full,
    );
  }
}

/// Marks that separate or punctuate rather than spell: maqaf, paseq, sof pasuq
/// and nun hafukha. The consonantal *display* mode keeps them on purpose, but
/// they never distinguish one spelling of a word from another, so a comparison
/// has to drop them — the build drops the same set.
final RegExp _hebrewSeparators = RegExp('[\u05BE\u05C0\u05C3\u05C6]');

/// The consonants of [text], for comparing two spellings of the same word.
String hebrewConsonants(String text) {
  return applyHebrewDisplay(
    text,
    HebrewTextDisplay.consonantal,
  ).replaceAll(_hebrewSeparators, '');
}

bool _isCantillation(int codeUnit) {
  // Hebrew accents (te'amim): U+0591..U+05AF
  return codeUnit >= 0x0591 && codeUnit <= 0x05AF;
}

bool _isVocalization(int codeUnit) {
  // Niqqud and related pointing, excluding real punctuation that must stay:
  // maqaf U+05BE, paseq U+05C0, sof pasuq U+05C3, nun hafukha U+05C6.
  if (codeUnit >= 0x05B0 && codeUnit <= 0x05BD) return true; // points + meteg
  if (codeUnit == 0x05BF) return true; // rafe
  if (codeUnit == 0x05C1 || codeUnit == 0x05C2) return true; // shin/sin dots
  if (codeUnit == 0x05C4 || codeUnit == 0x05C5) return true; // puncta
  if (codeUnit == 0x05C7) return true; // qamats qatan
  return false;
}

/// Applies a [HebrewTextDisplay] mode to Hebrew [text].
/// Non-Hebrew characters pass through untouched.
String applyHebrewDisplay(String text, HebrewTextDisplay mode) {
  if (mode == HebrewTextDisplay.full ||
      mode == HebrewTextDisplay.qere ||
      text.isEmpty) {
    return text;
  }

  final buffer = StringBuffer();
  for (final codeUnit in text.codeUnits) {
    if (_isCantillation(codeUnit)) {
      continue;
    }
    if (mode == HebrewTextDisplay.consonantal && _isVocalization(codeUnit)) {
      continue;
    }
    buffer.writeCharCode(codeUnit);
  }
  return buffer.toString();
}
