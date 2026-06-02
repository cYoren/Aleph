/// Utility class for transliterating Hebrew and Greek text to Latin alphabet.
/// Provides layman-friendly pronunciation guides for Biblical languages.
class Transliterator {
  /// Transliterate Hebrew text to Latin alphabet
  /// Uses simplified SBL transliteration for readability
  static String hebrewToLatin(String text) {
    if (text.isEmpty) return '';

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final codeUnit = char.codeUnitAt(0);

      // Hebrew consonants (U+05D0 - U+05EA)
      if (codeUnit >= 0x05D0 && codeUnit <= 0x05EA) {
        final index = codeUnit - 0x05D0;
        if (index < _hebrewConsonants.length) {
          buffer.write(_hebrewConsonants[index]);
        }
      }
      // Hebrew vowel points - nikud (U+05B0 - U+05C7)
      else if (codeUnit >= 0x05B0 && codeUnit <= 0x05C7) {
        buffer.write(_hebrewVowels[codeUnit] ?? '');
      }
      // Skip other diacritics and markers
      else if (codeUnit >= 0x0591 && codeUnit <= 0x05AF) {
        // Cantillation marks - skip
        continue;
      }
      // Pass through spaces and common punctuation
      else if (char == ' ' || char == '-' || char == '־') {
        buffer.write(' ');
      }
    }

    return _cleanupTransliteration(buffer.toString());
  }

  /// Transliterate Greek text to Latin alphabet
  /// Uses simplified scholarly transliteration
  static String greekToLatin(String text) {
    if (text.isEmpty) return '';

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final codeUnit = char.codeUnitAt(0);

      // Final sigma (must check before range check since ς is U+03C2)
      if (char == 'ς' || char == 'Ϲ' || char == 'ϲ') {
        buffer.write('s');
      }
      // Greek letters (U+0370 - U+03FF)
      else if (codeUnit >= 0x0391 && codeUnit <= 0x03C9) {
        // Basic Greek alphabet
        buffer.write(_greekLetters[char.toLowerCase()] ?? char);
      }
      // Extended Greek with diacritics (U+1F00 - U+1FFF)
      else if (codeUnit >= 0x1F00 && codeUnit <= 0x1FFF) {
        buffer.write(_getExtendedGreekBase(codeUnit));
      }
      // Pass through spaces and punctuation
      else if (char == ' ' ||
          char == ',' ||
          char == '.' ||
          char == '·' ||
          char == ';' ||
          char == '᾽') {
        buffer.write(char == '·' ? ' ' : (char == '᾽' ? '' : char));
      }
    }

    return _cleanupTransliteration(buffer.toString());
  }

  /// Get transliteration for a word based on language
  static String transliterate(String text, {required bool isHebrew}) {
    if (text.isEmpty) return '';
    return isHebrew ? hebrewToLatin(text) : greekToLatin(text);
  }

  /// Clean up transliteration output
  static String _cleanupTransliteration(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(
          RegExp(r"^'+|'+$"),
          '',
        ) // Remove leading/trailing apostrophes
        .trim();
  }

  /// Get base letter for extended Greek characters
  static String _getExtendedGreekBase(int codeUnit) {
    // Extended Greek A block (U+1F00-1F0F = alpha variants)
    if (codeUnit >= 0x1F00 && codeUnit <= 0x1F0F) return 'a';
    if (codeUnit >= 0x1F10 && codeUnit <= 0x1F1D) return 'e';
    if (codeUnit >= 0x1F20 && codeUnit <= 0x1F2F) return 'ē';
    if (codeUnit >= 0x1F30 && codeUnit <= 0x1F3F) return 'i';
    if (codeUnit >= 0x1F40 && codeUnit <= 0x1F4D) return 'o';
    if (codeUnit >= 0x1F50 && codeUnit <= 0x1F5F) return 'u';
    if (codeUnit >= 0x1F60 && codeUnit <= 0x1F6F) return 'ō';
    if (codeUnit >= 0x1F70 && codeUnit <= 0x1F7D) {
      // Vowels with accents
      final offset = codeUnit - 0x1F70;
      const vowels = [
        'a',
        'a',
        'e',
        'e',
        'ē',
        'ē',
        'i',
        'i',
        'o',
        'o',
        'u',
        'u',
        'ō',
        'ō',
      ];
      return offset < vowels.length ? vowels[offset] : '';
    }
    if (codeUnit >= 0x1F80 && codeUnit <= 0x1FAF) return 'a';
    if (codeUnit >= 0x1FB0 && codeUnit <= 0x1FBF) return 'a';
    if (codeUnit >= 0x1FC0 && codeUnit <= 0x1FCF) return 'ē';
    if (codeUnit >= 0x1FD0 && codeUnit <= 0x1FDF) return 'i';
    if (codeUnit >= 0x1FE0 && codeUnit <= 0x1FEF) return 'u';
    if (codeUnit >= 0x1FF0 && codeUnit <= 0x1FFF) return 'ō';
    return '';
  }

  // Hebrew consonants (aleph to tav)
  static const _hebrewConsonants = [
    "'", // א aleph
    'b', // ב bet
    'g', // ג gimel
    'd', // ד dalet
    'h', // ה he
    'v', // ו vav
    'z', // ז zayin
    'ch', // ח chet
    't', // ט tet
    'y', // י yod
    'k', // כ kaf
    'k', // ך kaf sofit
    'l', // ל lamed
    'm', // מ mem
    'm', // ם mem sofit
    'n', // נ nun
    'n', // ן nun sofit
    's', // ס samekh
    "'", // ע ayin
    'p', // פ pe
    'f', // ף pe sofit
    'ts', // צ tsade
    'ts', // ץ tsade sofit
    'k', // ק qof
    'r', // ר resh
    'sh', // ש shin
    't', // ת tav
  ];

  // Hebrew vowel points (nikud)
  static const _hebrewVowels = <int, String>{
    0x05B0: 'e', // sheva
    0x05B1: 'e', // hataf segol
    0x05B2: 'a', // hataf patach
    0x05B3: 'o', // hataf qamats
    0x05B4: 'i', // hiriq
    0x05B5: 'e', // tsere
    0x05B6: 'e', // segol
    0x05B7: 'a', // patach
    0x05B8: 'a', // qamats
    0x05B9: 'o', // holam
    0x05BA: 'o', // holam haser
    0x05BB: 'u', // qubuts
    0x05BC: '', // dagesh (skip, modifies consonant)
    0x05BD: '', // meteg (skip)
    0x05BE: '-', // maqaf
    0x05BF: '', // rafe (skip)
    0x05C1: '', // shin dot
    0x05C2: '', // sin dot
    0x05C7: 'o', // qamats qatan
  };

  // Greek letters (lowercase) - complete alphabet
  static const _greekLetters = <String, String>{
    'α': 'a', // alpha
    'β': 'b', // beta
    'γ': 'g', // gamma
    'δ': 'd', // delta
    'ε': 'e', // epsilon
    'ζ': 'z', // zeta
    'η': 'ē', // eta (long e)
    'θ': 'th', // theta
    'ι': 'i', // iota
    'κ': 'k', // kappa
    'λ': 'l', // lambda
    'μ': 'm', // mu
    'ν': 'n', // nu
    'ξ': 'x', // xi
    'ο': 'o', // omicron
    'π': 'p', // pi
    'ρ': 'r', // rho
    'σ': 's', // sigma
    'ς': 's', // final sigma (redundant but safe)
    'τ': 't', // tau
    'υ': 'u', // upsilon
    'φ': 'ph', // phi
    'χ': 'ch', // chi
    'ψ': 'ps', // psi
    'ω': 'ō', // omega (long o)
  };
}
