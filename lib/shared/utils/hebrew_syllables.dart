/// Syllabified, stress-marked transliteration of pointed Hebrew.
///
/// The Masoretic pointing is very nearly a phonemic transcription, and the
/// cantillation tells us which syllable carries the tone (see
/// `cantillation.dart`). Together they let us show a learner not just *what*
/// the letters say but *how the word is spoken*: `bə·rē·ˈšîṯ`.
///
/// This is a pedagogical rendering, not a scholarly phonological analysis.
/// Two places where it approximates:
///
/// - **Shva.** Whether a shva is vocal or silent follows the usual teaching
///   rules (word-initial, doubled letter, second of a pair, after a long
///   vowel). Real texts have exceptions.
/// - **Dagesh.** Lene and forte are told apart by position, since Unicode uses
///   one code point for both.
///
/// Where the accentuation cannot show the stress — a prepositive or
/// postpositive accent, or an unaccented token — no stress mark is emitted
/// rather than a guessed one. [SyllabifiedWord.stressKnown] reports which.
library;

import 'cantillation.dart';

/// One spoken syllable.
class Syllable {
  /// Transliterated text, e.g. `rē`.
  final String text;

  /// True when this syllable carries the word's tone.
  final bool stressed;

  const Syllable({required this.text, required this.stressed});
}

/// A word broken into syllables, with the tone located where possible.
class SyllabifiedWord {
  final List<Syllable> syllables;

  /// False when the accentuation could not tell us where the stress falls, in
  /// which case no syllable is marked.
  final bool stressKnown;

  const SyllabifiedWord({required this.syllables, required this.stressKnown});

  static const empty = SyllabifiedWord(syllables: [], stressKnown: false);

  bool get isEmpty => syllables.isEmpty;

  /// Plain transliteration with no syllable breaks: `bərēšîṯ`.
  String get flat => syllables.map((s) => s.text).join();

  /// Syllable breaks only: `bə·rē·šîṯ`.
  String get segmented => syllables.map((s) => s.text).join('·');

  /// Syllable breaks with the tone marked: `bə·rē·ˈšîṯ`.
  String get marked {
    if (!stressKnown) return segmented;
    final buffer = StringBuffer();
    for (int i = 0; i < syllables.length; i++) {
      if (i > 0) buffer.write('·');
      if (syllables[i].stressed) buffer.write('ˈ');
      buffer.write(syllables[i].text);
    }
    return buffer.toString();
  }
}

// --- Character classes -------------------------------------------------

const int _dagesh = 0x05BC;
const int _shinDot = 0x05C1;
const int _sinDot = 0x05C2;
const int _shva = 0x05B0;
const int _rafe = 0x05BF;
const int _qamatsQatan = 0x05C7;

const int _he = 0x05D4;
const int _vav = 0x05D5;
const int _yod = 0x05D9;

/// Gutturals and resh, which never take dagesh forte.
const Set<int> _noDoubling = {0x05D0, 0x05D4, 0x05D7, 0x05E2, 0x05E8};

/// Base consonant transliterations. Spirantized forms are handled separately.
const Map<int, String> _consonants = {
  0x05D0: 'ʾ', // alef
  0x05D1: 'b', // bet
  0x05D2: 'g', // gimel
  0x05D3: 'd', // dalet
  0x05D4: 'h', // he
  0x05D5: 'w', // vav
  0x05D6: 'z', // zayin
  0x05D7: 'ḥ', // chet
  0x05D8: 'ṭ', // tet
  0x05D9: 'y', // yod
  0x05DA: 'k', // kaf sofit
  0x05DB: 'k', // kaf
  0x05DC: 'l', // lamed
  0x05DD: 'm', // mem sofit
  0x05DE: 'm', // mem
  0x05DF: 'n', // nun sofit
  0x05E0: 'n', // nun
  0x05E1: 's', // samekh
  0x05E2: 'ʿ', // ayin
  0x05E3: 'p', // pe sofit
  0x05E4: 'p', // pe
  0x05E5: 'ṣ', // tsade sofit
  0x05E6: 'ṣ', // tsade
  0x05E7: 'q', // qof
  0x05E8: 'r', // resh
  0x05E9: 'š', // shin (sin dot switches this to ś)
  0x05EA: 't', // tav
};

/// Spirantized (no-dagesh) forms of the bgdkpt letters.
const Map<int, String> _spirantized = {
  0x05D1: 'ḇ',
  0x05D2: 'ḡ',
  0x05D3: 'ḏ',
  0x05DB: 'ḵ',
  0x05DA: 'ḵ',
  0x05E4: 'p̄',
  0x05E3: 'p̄',
  0x05EA: 'ṯ',
};

/// Full vowels. Shva is excluded — it is decided contextually.
const Map<int, String> _vowels = {
  0x05B1: 'ĕ', // hataf segol
  0x05B2: 'ă', // hataf patach
  0x05B3: 'ŏ', // hataf qamats
  0x05B4: 'i', // hiriq
  0x05B5: 'ē', // tsere
  0x05B6: 'e', // segol
  0x05B7: 'a', // patach
  0x05B8: 'ā', // qamats
  0x05B9: 'ō', // holam
  0x05BA: 'ō', // holam haser
  0x05BB: 'u', // qubuts
  _qamatsQatan: 'o',
};

/// Vowels counted as long for the shva rule and for mater combinations.
const Set<int> _longVowels = {0x05B5, 0x05B8, 0x05B9, 0x05BA};

/// One consonant with everything pointed on it.
class _LetterUnit {
  final int consonant;
  final int index; // position in the source string
  int? vowel;
  bool hasDagesh = false;
  bool hasShva = false;
  bool hasRafe = false;
  bool hasShinDot = false;
  bool hasSinDot = false;
  bool accented = false;

  _LetterUnit(this.consonant, this.index);

  bool get isGuttural => _noDoubling.contains(consonant);
}

/// Splits [word] into letter units, attaching each diacritic to its consonant.
List<_LetterUnit> _parseUnits(String word, {int? stressIndex}) {
  final units = <_LetterUnit>[];
  for (int i = 0; i < word.length; i++) {
    final cp = word.codeUnitAt(i);

    if (isHebrewConsonant(cp)) {
      final unit = _LetterUnit(cp, i);
      if (stressIndex != null && i == stressIndex) unit.accented = true;
      units.add(unit);
      continue;
    }

    if (units.isEmpty) continue;
    final unit = units.last;

    if (cp == _dagesh) {
      unit.hasDagesh = true;
    } else if (cp == _shva) {
      unit.hasShva = true;
    } else if (cp == _rafe) {
      unit.hasRafe = true;
    } else if (cp == _shinDot) {
      unit.hasShinDot = true;
    } else if (cp == _sinDot) {
      unit.hasSinDot = true;
    } else if (_vowels.containsKey(cp)) {
      unit.vowel ??= cp;
    }
  }
  return units;
}

/// Decides whether the shva on [i] is vocal.
///
/// Follows the standard teaching rules: word-initial, under a doubled letter,
/// the second of two consecutive shvas, or after a long vowel.
bool _isVocalShva(
  List<_LetterUnit> units,
  int i,
  List<bool> forte,
  List<bool> absorbed,
) {
  if (i == 0) return true;
  if (forte[i]) return true;

  final previous = units[i - 1];

  // The previous letter was a vowel letter, so the syllable before this one
  // ended in a long vowel.
  if (absorbed[i - 1]) return true;

  if (previous.hasShva && previous.vowel == null) {
    // Two in a row: the first closes its syllable, the second opens one.
    return true;
  }
  if (previous.vowel != null && _longVowels.contains(previous.vowel)) {
    return true;
  }
  return false;
}

/// Marks which dagesh points are forte (doubling) rather than lene.
///
/// A dagesh is forte when the letter sits between vowels; at the start of a
/// word or after a closed syllable it is lene, which only spirantizes.
List<bool> _classifyDagesh(List<_LetterUnit> units) {
  final forte = List<bool>.filled(units.length, false);
  for (int i = 0; i < units.length; i++) {
    final unit = units[i];
    if (!unit.hasDagesh || i == 0) continue;
    if (unit.isGuttural) continue;

    final previous = units[i - 1];
    final previousIsOpen = previous.vowel != null;
    if (previousIsOpen) forte[i] = true;
  }
  return forte;
}

/// Transliterates one letter unit's consonant in its plosive (dagesh) form.
///
/// Spirantization is decided by [_buildSyllables], which can see the preceding
/// vowel; this only handles the sin/shin dot and doubling.
String _consonantText(_LetterUnit unit, bool isForte) {
  final base = unit.consonant == 0x05E9
      ? (unit.hasSinDot ? 'ś' : 'š')
      : (_consonants[unit.consonant] ?? '');
  return isForte ? '$base$base' : base;
}

/// True when [unit] carries no pointing of its own and so can serve as a
/// vowel letter.
bool _isBare(_LetterUnit unit) =>
    unit.vowel == null && !unit.hasShva && !unit.hasDagesh;

/// The result of resolving vowel letters across a word.
class _Nuclei {
  /// Vowel text of the syllable opened by each unit, or null where the unit
  /// opens no syllable (silent shva, bare closing consonant).
  final List<String?> nucleus;

  /// Units that write nothing of their own because they were absorbed into a
  /// neighbouring syllable as a vowel letter.
  final List<bool> absorbed;

  const _Nuclei(this.nucleus, this.absorbed);
}

/// Works out each syllable nucleus, folding matres lectionis into the vowel
/// they lengthen.
///
/// Handles both directions of the encoding: a vowel pointed on the consonant
/// with the letter following it (hiriq + yod → î), and a vowel pointed on the
/// vowel letter itself (vav + holam → ô, vav + dagesh → û).
_Nuclei _resolveNuclei(List<_LetterUnit> units, List<bool> forte) {
  final nucleus = List<String?>.filled(units.length, null);
  final absorbed = List<bool>.filled(units.length, false);

  for (int i = 0; i < units.length; i++) {
    if (absorbed[i]) continue;
    final unit = units[i];
    final next = i + 1 < units.length ? units[i + 1] : null;

    String? base;

    if (unit.vowel != null) {
      base = _vowels[unit.vowel] ?? '';

      // A following vowel letter lengthens this vowel.
      if (next != null && _isBare(next)) {
        if (next.consonant == _yod &&
            (unit.vowel == 0x05B4 ||
                unit.vowel == 0x05B5 ||
                unit.vowel == 0x05B6)) {
          base = unit.vowel == 0x05B4 ? 'î' : 'ê';
          absorbed[i + 1] = true;
        } else if (next.consonant == _vav &&
            (unit.vowel == 0x05B9 || unit.vowel == 0x05BA)) {
          base = 'ô';
          absorbed[i + 1] = true;
        } else if (next.consonant == _he && i + 1 == units.length - 1) {
          // Final he is a vowel letter, not a consonant.
          absorbed[i + 1] = true;
        }
      }
    } else if (unit.hasShva && _isVocalShva(units, i, forte, absorbed)) {
      base = 'ə';
    } else if (next != null && next.consonant == _vav && !next.hasShva) {
      // The vav itself carries the vowel: holam male or shuruq.
      if (next.vowel == 0x05B9 || next.vowel == 0x05BA) {
        base = 'ô';
        absorbed[i + 1] = true;
      } else if (next.hasDagesh && next.vowel == null) {
        base = 'û';
        absorbed[i + 1] = true;
      }
    }

    nucleus[i] = base;
  }

  return _Nuclei(nucleus, absorbed);
}

/// Builds the syllables of a parsed word.
List<Syllable> _buildSyllables(List<_LetterUnit> units) {
  if (units.isEmpty) return const [];

  final forte = _classifyDagesh(units);
  final resolved = _resolveNuclei(units, forte);
  final syllables = <Syllable>[];

  var currentText = StringBuffer();
  var currentStressed = false;
  var currentOpen = false; // whether the current syllable has a nucleus yet

  // Whether a vowel sound immediately precedes the letter being written, which
  // is what decides spirantization of the bgdkpt letters.
  var afterVowel = false;

  void flush() {
    if (currentText.isNotEmpty) {
      syllables.add(
        Syllable(text: currentText.toString(), stressed: currentStressed),
      );
    }
    currentText = StringBuffer();
    currentStressed = false;
    currentOpen = false;
  }

  for (int i = 0; i < units.length; i++) {
    final unit = units[i];

    // A vowel letter belongs to the syllable already being built; it writes
    // nothing of its own and leaves the preceding vowel sound in place.
    if (resolved.absorbed[i]) {
      if (unit.accented) currentStressed = true;
      continue;
    }

    final consonant =
        _spirantized.containsKey(unit.consonant) &&
            !unit.hasDagesh &&
            afterVowel
        ? _spirantized[unit.consonant]!
        : _consonantText(unit, false);

    final nucleus = resolved.nucleus[i];

    if (nucleus != null) {
      // A doubled letter is shared: its first half closes the syllable before
      // it, its second half opens this one (haš·šā·ma·yim).
      if (forte[i] && currentOpen) {
        currentText.write(consonant);
        flush();
      } else if (currentOpen) {
        flush();
      }

      // A new syllable starts here.
      currentText.write(consonant);
      if (unit.accented) currentStressed = true;
      currentText.write(nucleus);
      currentOpen = true;
      afterVowel = true;
    } else {
      // Silent shva or bare consonant: closes the syllable being built.
      currentText.write(consonant);
      if (unit.accented) currentStressed = true;
      if (currentOpen) flush();
      afterVowel = false;
    }
  }

  flush();
  return syllables;
}

/// Syllabifies and transliterates a pointed Hebrew [word], marking the tone
/// when the accentuation reveals it.
///
/// Pass [isVerseFinal] for the last word of a verse so that U+05BD is read as
/// silluq rather than meteg.
SyllabifiedWord syllabifyHebrew(String word, {bool isVerseFinal = false}) {
  if (word.isEmpty) return SyllabifiedWord.empty;

  final stressIndex = stressedConsonantIndex(word, isVerseFinal: isVerseFinal);
  final units = _parseUnits(word, stressIndex: stressIndex);
  if (units.isEmpty) return SyllabifiedWord.empty;

  final syllables = _buildSyllables(units);
  if (syllables.isEmpty) return SyllabifiedWord.empty;

  final stressKnown = stressIndex != null && syllables.any((s) => s.stressed);

  return SyllabifiedWord(syllables: syllables, stressKnown: stressKnown);
}
