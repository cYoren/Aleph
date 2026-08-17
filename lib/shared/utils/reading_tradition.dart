/// Which scriptures the reader came here for, and how they are arranged.
///
/// The app ships one database — the Hebrew Bible and the Greek New Testament —
/// and that is not going to change. What changes is the framing. "Old
/// Testament" is a Christian name for someone else's scriptures, and a Jewish
/// reader opening a Hebrew-text app to find Genesis filed under *old* and
/// Malachi followed by Matthew is being told, quietly, that the app was not
/// built for them.
///
/// So the reader says once, during onboarding, which tradition they read in,
/// and the app arranges itself around that answer. Neither choice removes
/// anything: the Greek New Testament is still there for a Jewish reader who
/// wants it, and the Tanakh ordering is still available to a Christian who is
/// curious. Only the default arrangement and the names differ.
library;

enum ReadingTradition {
  /// Protestant canon and ordering: Old Testament, then New Testament.
  christian,

  /// Tanakh: Torah, Nevi'im, Ketuvim, in the traditional Jewish order.
  jewish;

  static ReadingTradition fromName(String? name) {
    return ReadingTradition.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ReadingTradition.christian,
    );
  }
}

/// The three divisions of the Tanakh.
enum TanakhSection { torah, neviim, ketuvim }

/// Books of the Tanakh in traditional Jewish order, by section.
///
/// This is not the Christian Old Testament reshuffled — it is a different
/// arrangement of the same books, and the differences carry meaning. Chronicles
/// closes the canon rather than sitting among the histories; Daniel is in the
/// Writings, not among the Prophets; Ruth, Lamentations and Esther belong to
/// the five Megillot read at festivals.
///
/// Books the Masoretic tradition counts as one (Samuel, Kings, Ezra–Nehemiah,
/// Chronicles, and the Twelve) are listed as the separate volumes the database
/// stores, in their traditional sequence.
const Map<TanakhSection, List<String>> kTanakhOrder = {
  TanakhSection.torah: ['GEN', 'EXO', 'LEV', 'NUM', 'DEU'],
  TanakhSection.neviim: [
    // Former Prophets
    'JOS', 'JDG', '1SA', '2SA', '1KI', '2KI',
    // Latter Prophets
    'ISA', 'JER', 'EZK',
    // The Twelve
    'HOS', 'JOL', 'AMO', 'OBA', 'JON', 'MIC',
    'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL',
  ],
  TanakhSection.ketuvim: [
    'PSA', 'PRO', 'JOB',
    // The five Megillot
    'SNG', 'RUT', 'LAM', 'ECC', 'EST',
    'DAN', 'EZR', 'NEH', '1CH', '2CH',
  ],
};

/// Position of each Tanakh book in the traditional order, for sorting.
final Map<String, int> kTanakhPositions = {
  for (final (index, abbreviation) in kTanakhOrder.values
      .expand((books) => books)
      .indexed)
    abbreviation: index,
};

/// Sorts [abbreviations] into the order this tradition reads them in.
///
/// Anything not in the Tanakh (the New Testament) keeps its existing relative
/// order and follows the Hebrew Bible, rather than being dropped: the text is
/// in the database either way, and hiding it would break search and
/// cross-references for no gain.
List<T> sortForTradition<T>(
  List<T> items,
  ReadingTradition tradition, {
  required String Function(T) abbreviationOf,
}) {
  if (tradition == ReadingTradition.christian) return items;

  final sorted = [...items];
  sorted.sort((a, b) {
    final positionA = kTanakhPositions[abbreviationOf(a)];
    final positionB = kTanakhPositions[abbreviationOf(b)];
    if (positionA == null && positionB == null) return 0;
    if (positionA == null) return 1;
    if (positionB == null) return -1;
    return positionA.compareTo(positionB);
  });
  return sorted;
}

/// Verses offered as the verse of the day, per tradition.
///
/// The Christian list draws on both testaments. The Jewish list stays in the
/// Tanakh and leans on the passages a Jewish reader would actually recognise —
/// the Shema, the priestly blessing, the opening of Bereshit — rather than
/// Hebrew Bible verses chosen for how often they are quoted in the New
/// Testament.
const List<String> kChristianDailyVerses = [
  'GEN.1.1', 'GEN.1.3', 'JHN.1.1', 'JHN.3.16', 'PSA.23.1',
  'PSA.119.105', 'PRO.3.5', 'ISA.40.31', 'JER.29.11', 'ROM.8.28',
  'PHP.4.13', 'HEB.11.1', 'MAT.5.14', 'MAT.6.33', 'ROM.12.2',
];

const List<String> kJewishDailyVerses = [
  'GEN.1.1', 'GEN.1.3', 'GEN.12.2', 'EXO.3.14', 'EXO.20.2',
  'LEV.19.18', 'NUM.6.24', 'DEU.6.4', 'DEU.30.19', 'JOS.1.9',
  '1SA.16.7', 'PSA.23.1', 'PSA.121.1', 'PSA.119.105', 'PRO.3.5',
  'ECC.3.1', 'ISA.40.31', 'JER.29.11', 'MIC.6.8', 'JOB.19.25',
];

List<String> dailyVersesFor(ReadingTradition tradition) =>
    tradition == ReadingTradition.jewish
        ? kJewishDailyVerses
        : kChristianDailyVerses;
