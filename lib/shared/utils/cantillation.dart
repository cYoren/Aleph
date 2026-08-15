/// Masoretic cantillation (te'amim) analysis.
///
/// Every OT verse in the bundled database carries the full accentuation of the
/// Leningrad Codex. Those marks encode two things a learner needs and that no
/// other layer of our data provides:
///
/// 1. **Stress.** Most accents are written on the stressed syllable, so the
///    text itself tells us where the tone falls — see [stressedConsonantIndex].
/// 2. **Phrase structure.** The disjunctive accents divide a verse into nested
///    sense units, strongest break first. Reading Hebrew in those units instead
///    of word by word is the step from decoding to actually reading — see
///    [senseUnits].
///
/// The hierarchy implemented here is the prose ("21 books") system. The three
/// poetic books (Psalms, Proverbs, Job) use a partly different set; accents
/// exclusive to it are marked [Taam.poetic] and given their nearest prose rank,
/// which is good enough for display but is not a full poetic analysis.
library;

/// Whether an accent separates its word from what follows, or binds it to it.
enum TaamType {
  /// Marks a break. Strength is given by [Taam.rank].
  disjunctive,

  /// Binds this word to the next.
  conjunctive,
}

/// Where a mark sits relative to the stressed syllable.
enum TaamPlacement {
  /// Written on the stressed syllable, so it reveals the stress.
  impositive,

  /// Always on the first letter of the word, whatever the stress.
  prepositive,

  /// Always on the last letter of the word, whatever the stress.
  postpositive,
}

/// One cantillation mark.
class Taam {
  /// The Unicode code unit of the mark itself (U+0591..U+05AF, or U+05BD for
  /// silluq).
  final int codeUnit;

  /// Traditional name, for tooltips and teaching copy.
  final String name;

  final TaamType type;

  /// Break strength for disjunctives: 1 is the strongest (verse-splitting),
  /// 4 the weakest. Always 0 for conjunctives.
  final int rank;

  final TaamPlacement placement;

  /// True for accents used only in Psalms, Proverbs, and Job.
  final bool poetic;

  const Taam({
    required this.codeUnit,
    required this.name,
    required this.type,
    required this.rank,
    required this.placement,
    this.poetic = false,
  });

  bool get isDisjunctive => type == TaamType.disjunctive;

  /// Whether this mark can be used to locate the stressed syllable.
  bool get marksStress => placement == TaamPlacement.impositive;
}

/// Meteg and silluq share a glyph (U+05BD). Which one it is depends on
/// position: silluq falls on the last accented word of a verse.
const int kMetegOrSilluq = 0x05BD;

/// Sof pasuq (׃) — the end-of-verse marker.
const int kSofPasuq = 0x05C3;

/// Paseq (׀) — a light separator bar, not itself an accent.
const int kPaseq = 0x05C0;

/// Maqaf (־) — joins words into one accentual unit.
const int kMaqaf = 0x05BE;

const Taam _silluq = Taam(
  codeUnit: kMetegOrSilluq,
  name: 'Silluq',
  type: TaamType.disjunctive,
  rank: 1,
  placement: TaamPlacement.impositive,
);

/// The te'amim proper, keyed by code unit.
///
/// Ranks follow the usual four-level grouping (emperors / kings / dukes /
/// counts) used in Yeivin and the standard grammars.
const Map<int, Taam> _accents = {
  // --- Rank 1: splits the whole verse ---
  0x0591: Taam(
    codeUnit: 0x0591,
    name: 'Etnachta',
    type: TaamType.disjunctive,
    rank: 1,
    placement: TaamPlacement.impositive,
  ),

  // --- Rank 2 ---
  0x0592: Taam(
    codeUnit: 0x0592,
    name: 'Segolta',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.postpositive,
  ),
  0x0593: Taam(
    codeUnit: 0x0593,
    name: 'Shalshelet',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.impositive,
  ),
  0x0594: Taam(
    codeUnit: 0x0594,
    name: 'Zaqef qatan',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.impositive,
  ),
  0x0595: Taam(
    codeUnit: 0x0595,
    name: 'Zaqef gadol',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.impositive,
  ),
  0x0596: Taam(
    codeUnit: 0x0596,
    name: 'Tipcha',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.impositive,
  ),

  // --- Rank 3 ---
  0x0597: Taam(
    codeUnit: 0x0597,
    name: 'Revia',
    type: TaamType.disjunctive,
    rank: 3,
    placement: TaamPlacement.impositive,
  ),
  0x0598: Taam(
    codeUnit: 0x0598,
    name: 'Zarqa',
    type: TaamType.disjunctive,
    rank: 3,
    placement: TaamPlacement.postpositive,
  ),
  0x0599: Taam(
    codeUnit: 0x0599,
    name: 'Pashta',
    type: TaamType.disjunctive,
    rank: 3,
    placement: TaamPlacement.postpositive,
  ),
  0x059A: Taam(
    codeUnit: 0x059A,
    name: 'Yetiv',
    type: TaamType.disjunctive,
    rank: 3,
    placement: TaamPlacement.prepositive,
  ),
  0x059B: Taam(
    codeUnit: 0x059B,
    name: 'Tevir',
    type: TaamType.disjunctive,
    rank: 3,
    placement: TaamPlacement.impositive,
  ),

  // --- Rank 4 ---
  0x059C: Taam(
    codeUnit: 0x059C,
    name: 'Geresh',
    type: TaamType.disjunctive,
    rank: 4,
    placement: TaamPlacement.impositive,
  ),
  0x059D: Taam(
    codeUnit: 0x059D,
    name: 'Geresh muqdam',
    type: TaamType.disjunctive,
    rank: 4,
    placement: TaamPlacement.impositive,
  ),
  0x059E: Taam(
    codeUnit: 0x059E,
    name: 'Gershayim',
    type: TaamType.disjunctive,
    rank: 4,
    placement: TaamPlacement.impositive,
  ),
  0x059F: Taam(
    codeUnit: 0x059F,
    name: 'Qarney para',
    type: TaamType.disjunctive,
    rank: 4,
    placement: TaamPlacement.impositive,
  ),
  0x05A0: Taam(
    codeUnit: 0x05A0,
    name: 'Telisha gedola',
    type: TaamType.disjunctive,
    rank: 4,
    placement: TaamPlacement.prepositive,
  ),
  0x05A1: Taam(
    codeUnit: 0x05A1,
    name: 'Pazer',
    type: TaamType.disjunctive,
    rank: 4,
    placement: TaamPlacement.impositive,
  ),

  // --- Conjunctives ---
  0x05A3: Taam(
    codeUnit: 0x05A3,
    name: 'Munach',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
  ),
  0x05A4: Taam(
    codeUnit: 0x05A4,
    name: 'Mahpakh',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
  ),
  0x05A5: Taam(
    codeUnit: 0x05A5,
    name: 'Merkha',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
  ),
  0x05A6: Taam(
    codeUnit: 0x05A6,
    name: 'Merkha kefula',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
  ),
  0x05A7: Taam(
    codeUnit: 0x05A7,
    name: 'Darga',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
  ),
  0x05A8: Taam(
    codeUnit: 0x05A8,
    name: 'Qadma',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
  ),
  0x05A9: Taam(
    codeUnit: 0x05A9,
    name: 'Telisha qetana',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.postpositive,
  ),

  // --- Poetic books (Psalms, Proverbs, Job) ---
  0x05A2: Taam(
    codeUnit: 0x05A2,
    name: 'Atnach hafukh',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
    poetic: true,
  ),
  0x05AA: Taam(
    codeUnit: 0x05AA,
    name: 'Yerach ben yomo',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
    poetic: true,
  ),
  0x05AB: Taam(
    codeUnit: 0x05AB,
    name: 'Ole',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.impositive,
    poetic: true,
  ),
  0x05AC: Taam(
    codeUnit: 0x05AC,
    name: 'Iluy',
    type: TaamType.conjunctive,
    rank: 0,
    placement: TaamPlacement.impositive,
    poetic: true,
  ),
  0x05AD: Taam(
    codeUnit: 0x05AD,
    name: 'Dehi',
    type: TaamType.disjunctive,
    rank: 2,
    placement: TaamPlacement.prepositive,
    poetic: true,
  ),
  0x05AE: Taam(
    codeUnit: 0x05AE,
    name: 'Zinor',
    type: TaamType.disjunctive,
    rank: 3,
    placement: TaamPlacement.postpositive,
    poetic: true,
  ),
};

/// U+05AF is a masoretic notation circle, not an accent.
const int _masoraCircle = 0x05AF;

/// True for the accent block, excluding the masora circle.
bool isTaamCodeUnit(int codeUnit) {
  return codeUnit >= 0x0591 && codeUnit <= 0x05AE;
}

/// Looks up a mark by code unit. Returns null for non-accents.
Taam? taamFor(int codeUnit) => _accents[codeUnit];

/// Every accent present in [word], in the order written.
///
/// [isVerseFinal] tells us to read U+05BD as silluq rather than meteg; silluq
/// only ever appears on the last accented word of a verse.
List<Taam> taamimIn(String word, {bool isVerseFinal = false}) {
  final result = <Taam>[];
  for (final codeUnit in word.codeUnits) {
    if (codeUnit == _masoraCircle) continue;
    final taam = _accents[codeUnit];
    if (taam != null) {
      result.add(taam);
      continue;
    }
    if (isVerseFinal && codeUnit == kMetegOrSilluq) {
      result.add(_silluq);
    }
  }
  return result;
}

/// The accent that governs [word] — the strongest disjunctive if any is
/// present, otherwise the first conjunctive.
///
/// Returns null for unaccented words (prefixes joined by maqaf, tokens split
/// morphologically by the source data, or unpointed text).
Taam? primaryTaam(String word, {bool isVerseFinal = false}) {
  final marks = taamimIn(word, isVerseFinal: isVerseFinal);
  if (marks.isEmpty) return null;

  Taam? strongestDisjunctive;
  for (final mark in marks) {
    if (!mark.isDisjunctive) continue;
    if (strongestDisjunctive == null || mark.rank < strongestDisjunctive.rank) {
      strongestDisjunctive = mark;
    }
  }
  return strongestDisjunctive ?? marks.first;
}

/// Index into [word] of the consonant carrying the stressed syllable.
///
/// Returns null when the stress cannot be read off the accentuation: an
/// unaccented word, or a prepositive/postpositive accent, which is written at
/// a fixed edge of the word and says nothing about where the tone falls.
int? stressedConsonantIndex(String word, {bool isVerseFinal = false}) {
  if (word.isEmpty) return null;

  for (int i = 0; i < word.length; i++) {
    final codeUnit = word.codeUnitAt(i);
    if (codeUnit == _masoraCircle) continue;

    final taam =
        _accents[codeUnit] ??
        (isVerseFinal && codeUnit == kMetegOrSilluq ? _silluq : null);
    if (taam == null || !taam.marksStress) continue;

    // The mark is written after the consonant it belongs to, with any vowel
    // points in between. Walk back to that consonant.
    for (int j = i - 1; j >= 0; j--) {
      if (isHebrewConsonant(word.codeUnitAt(j))) return j;
    }
    return null;
  }

  return null;
}

/// True for the Hebrew letters alef..tav (U+05D0..U+05EA), plus the final
/// forms, which fall inside that range.
bool isHebrewConsonant(int codeUnit) {
  return codeUnit >= 0x05D0 && codeUnit <= 0x05EA;
}

/// A run of words the Masoretes marked off as one unit of sense.
class SenseUnit {
  /// Indices into the original word list, in order.
  final List<int> wordIndices;

  /// The disjunctive that closed this unit, or null for the final run of a
  /// verse when the text carries no closing accent.
  final Taam? closingTaam;

  const SenseUnit({required this.wordIndices, required this.closingTaam});

  /// Break strength that ended this unit; 5 (weaker than any real accent) when
  /// the unit simply ran to the end of the verse.
  int get breakRank => closingTaam?.rank ?? 5;

  bool get isEmpty => wordIndices.isEmpty;
}

/// Divides a verse into sense units at every disjunctive of [upToRank] or
/// stronger.
///
/// [words] are the verse's tokens in reading order. Rank 1 alone gives the
/// single great division of the verse (at etnachta); rank 2 gives the clause
/// level, which is the most useful default for reading aloud; rank 4 gives
/// nearly every accentual phrase.
///
/// Tokens the source data split morphologically (a prefixed preposition, say)
/// carry no accent of their own and simply stay with the word they belong to.
List<SenseUnit> senseUnits(List<String> words, {int upToRank = 2}) {
  if (words.isEmpty) return const [];

  final units = <SenseUnit>[];
  var current = <int>[];

  for (int i = 0; i < words.length; i++) {
    current.add(i);

    final isLast = i == words.length - 1;
    final taam = primaryTaam(words[i], isVerseFinal: isLast);

    final closes = taam != null && taam.isDisjunctive && taam.rank <= upToRank;

    if (closes) {
      units.add(SenseUnit(wordIndices: current, closingTaam: taam));
      current = <int>[];
    }
  }

  if (current.isNotEmpty) {
    units.add(SenseUnit(wordIndices: current, closingTaam: null));
  }

  return units;
}

/// Strips cantillation from [text], leaving consonants and vowel points.
///
/// Meteg (U+05BD) is kept: it is pointing rather than accentuation, and
/// removing it changes how a word is read aloud.
String stripCantillation(String text) {
  if (text.isEmpty) return text;
  final buffer = StringBuffer();
  for (final codeUnit in text.codeUnits) {
    if (codeUnit >= 0x0591 && codeUnit <= _masoraCircle) continue;
    buffer.writeCharCode(codeUnit);
  }
  return buffer.toString();
}
