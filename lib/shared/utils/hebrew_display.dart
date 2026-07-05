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
  consonantal;

  static HebrewTextDisplay fromName(String? name) {
    return HebrewTextDisplay.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => HebrewTextDisplay.full,
    );
  }
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
  if (mode == HebrewTextDisplay.full || text.isEmpty) {
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
