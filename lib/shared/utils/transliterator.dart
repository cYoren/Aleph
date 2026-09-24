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

  /// Transliterate Greek text to Latin alphabet, SBL style: rough breathing
  /// as h (ὑπόστασις hypostasis, ῥῆμα rhēma), υ as y except in the diphthongs
  /// au, eu, ēu, ou, ui, and nasal γ as n (ἄγγελος angelos). Accents dropped.
  static String greekToLatin(String text) {
    if (text.isEmpty) return '';

    final out = StringBuffer();
    final word = <(String, bool)>[];

    void flushWord() {
      out.write(_romanizeGreekWord(word));
      word.clear();
    }

    for (final rune in text.runes) {
      if (rune == 0x0314 && word.isNotEmpty) {
        // Combining rough breathing (decomposed text) marks the letter before.
        word[word.length - 1] = (word.last.$1, true);
        continue;
      }
      if (rune >= 0x0300 && rune <= 0x036F) continue; // other combining marks
      final letter = _greekBase(rune);
      if (letter != null) {
        word.add(letter);
        continue;
      }
      // Elision marks (δι’ αὐτοῦ) are dropped.
      if (rune == 0x2019 || rune == 0x1FBD || rune == 0x02BC) continue;
      flushWord();
      final char = String.fromCharCode(rune);
      if (char == ' ' || char == '·') {
        out.write(' ');
      } else if (',.;'.contains(char)) {
        out.write(char);
      }
    }
    flushWord();

    return _cleanupTransliteration(out.toString());
  }

  static const _greekVowels = 'αεηιουω';

  static String _romanizeGreekWord(List<(String, bool)> letters) {
    final buffer = StringBuffer();
    // Rough breathing sits on the second vowel of a diphthong (οὗτος) but
    // the h belongs before the whole vowel cluster: houtos.
    final hBefore = <int>{};
    for (var i = 0; i < letters.length; i++) {
      final (base, rough) = letters[i];
      if (!rough || !_greekVowels.contains(base)) continue;
      var start = i;
      while (start > 0 && _greekVowels.contains(letters[start - 1].$1)) {
        start--;
      }
      hBefore.add(start);
    }

    for (var i = 0; i < letters.length; i++) {
      final (base, rough) = letters[i];
      final prev = i > 0 ? letters[i - 1].$1 : '';
      final next = i + 1 < letters.length ? letters[i + 1].$1 : '';
      if (hBefore.contains(i)) buffer.write('h');
      if (base == 'ρ' && rough) {
        buffer.write('rh');
      } else if (base == 'γ' && 'γκξχ'.contains(next) && next.isNotEmpty) {
        buffer.write('n');
      } else if (base == 'υ') {
        final diphthong =
            (prev.isNotEmpty && 'αεηο'.contains(prev)) || next == 'ι';
        buffer.write(diphthong ? 'u' : 'y');
      } else {
        buffer.write(_greekLetters[base] ?? '');
      }
    }
    return buffer.toString();
  }

  static const _tonos = <int, String>{
    0x0386: 'α',
    0x0388: 'ε',
    0x0389: 'η',
    0x038A: 'ι',
    0x038C: 'ο',
    0x038E: 'υ',
    0x038F: 'ω',
    0x0390: 'ι',
    0x03AA: 'ι',
    0x03AB: 'υ',
    0x03AC: 'α',
    0x03AD: 'ε',
    0x03AE: 'η',
    0x03AF: 'ι',
    0x03B0: 'υ',
    0x03CA: 'ι',
    0x03CB: 'υ',
    0x03CC: 'ο',
    0x03CD: 'υ',
    0x03CE: 'ω',
  };

  /// Base lowercase letter and rough-breathing flag for one Greek code point,
  /// or null when it is not a Greek letter.
  static (String, bool)? _greekBase(int cu) {
    if (_tonos.containsKey(cu)) return (_tonos[cu]!, false);
    if (cu == 0x03C2) return ('σ', false); // final sigma
    if (cu >= 0x0391 && cu <= 0x03A9 && cu != 0x03A2) {
      return (String.fromCharCode(cu + 0x20), false);
    }
    if (cu >= 0x03B1 && cu <= 0x03C9) return (String.fromCharCode(cu), false);
    if (cu == 0x03F2 || cu == 0x03F9) return ('σ', false); // lunate sigma

    final rough = cu.isOdd;
    if (cu >= 0x1F00 && cu <= 0x1F6F) {
      return ('αεηιουω'[(cu - 0x1F00) >> 4], rough);
    }
    if (cu >= 0x1F70 && cu <= 0x1F7D) {
      return ('ααεεηηιιοουυωω'[cu - 0x1F70], false);
    }
    if (cu >= 0x1F80 && cu <= 0x1FAF) {
      return ('αηω'[(cu - 0x1F80) >> 4], rough);
    }
    if (cu >= 0x1FB0 && cu <= 0x1FBC) return ('α', false);
    if (cu == 0x1FC8 || cu == 0x1FC9) return ('ε', false);
    if (cu >= 0x1FC2 && cu <= 0x1FCC) return ('η', false);
    if (cu >= 0x1FD0 && cu <= 0x1FDB) return ('ι', false);
    if (cu == 0x1FE4) return ('ρ', false);
    if (cu == 0x1FE5 || cu == 0x1FEC) return ('ρ', true);
    if (cu >= 0x1FE0 && cu <= 0x1FEB) return ('υ', false);
    if (cu == 0x1FF8 || cu == 0x1FF9) return ('ο', false);
    if (cu >= 0x1FF2 && cu <= 0x1FFC) return ('ω', false);
    return null;
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
    'υ': 'y', // upsilon (u in diphthongs, see _romanizeGreekWord)
    'φ': 'ph', // phi
    'χ': 'ch', // chi
    'ψ': 'ps', // psi
    'ω': 'ō', // omega (long o)
  };
}
