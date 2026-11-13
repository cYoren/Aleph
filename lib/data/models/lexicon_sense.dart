/// One numbered sense of a lexicon entry.
///
/// BDB and Abbott-Smith both organise an entry as a numbered hierarchy
/// ("1 a) ...", "I. 1. ..."). The `lexicon` table keeps only the flattened text
/// of the entry, which is why the definition sheet used to show a single
/// paragraph for a word with nine distinct meanings. These rows keep the
/// structure from the source dictionaries.
class LexiconSense {
  final String strongsId;

  /// Which lexicon this sense comes from: 'BDB' or 'Abbott-Smith'.
  final String source;

  /// Nesting depth in the source's own hierarchy, 0 = top level.
  final int level;

  /// The dictionary's own sense number, kept verbatim ('1', 'I.', '(a)').
  final String number;

  /// The sense's own gloss words, e.g. 'head of household'. May be empty when
  /// the dictionary only wrote prose for that node.
  final String heading;

  /// The sense's prose, with scripture references removed.
  final String summary;

  const LexiconSense({
    required this.strongsId,
    required this.source,
    required this.level,
    required this.number,
    required this.heading,
    required this.summary,
  });

  bool get hasHeading => heading.isNotEmpty;
  bool get hasSummary => summary.isNotEmpty;

  factory LexiconSense.fromMap(Map<String, dynamic> map) {
    return LexiconSense(
      strongsId: map['strongs_id']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      level: (map['level'] as num?)?.toInt() ?? 0,
      number: map['number']?.toString() ?? '',
      heading: map['heading']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
    );
  }
}

/// One rendered line of a sense list.
class SenseRow {
  final int depth;
  final String number;
  final String heading;
  final String summary;

  /// Marker shown before the heading: the dictionary's number, or a bullet for
  /// an unnumbered line such as a Hebrew stem (Qal, Niphal).
  String get marker => number.isNotEmpty ? number : '·';

  const SenseRow({
    required this.depth,
    required this.number,
    required this.heading,
    required this.summary,
  });
}

/// Turns raw rows into something renderable.
///
/// Two things the source data does not promise and the sheet needs:
/// - empty nodes (a `<sense>` that only holds children, which is how BDB marks
///   the binyanim) are dropped, and their children move up;
/// - depth is measured against the surviving ancestors rather than the raw
///   level, and capped, so a six-deep entry does not walk off the right edge of
///   a phone.
List<SenseRow> layoutSenses(List<LexiconSense> senses, {int maxDepth = 2}) {
  final rows = <SenseRow>[];
  // Raw levels of the rows currently open, nearest ancestor last.
  final openLevels = <int>[];

  for (final sense in senses) {
    if (!sense.hasHeading && !sense.hasSummary) continue;

    while (openLevels.isNotEmpty && openLevels.last >= sense.level) {
      openLevels.removeLast();
    }
    final depth = openLevels.length.clamp(0, maxDepth);
    openLevels.add(sense.level);

    rows.add(
      SenseRow(
        depth: depth,
        number: sense.number,
        heading: sense.heading,
        summary: sense.summary,
      ),
    );
  }

  return rows;
}
