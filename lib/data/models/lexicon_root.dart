/// A Hebrew root (shoresh) behind a Strong's number.
///
/// Words built on one root share a TWOT number, so this is what makes a search
/// across binyanim and derived nouns possible: אָבַד, אִבּוּד and אֹבֵד are three
/// Strong's numbers and one root.
class LexiconRoot {
  final String strongsId;

  /// The root as BDB prints it, pointed ('בָּרַךְ').
  final String root;

  /// The root's own short meaning from BDB ('kneel'), empty when it has none.
  final String gloss;

  /// TWOT root number: every word on this root shares it.
  final String twot;

  const LexiconRoot({
    required this.strongsId,
    required this.root,
    required this.gloss,
    required this.twot,
  });

  factory LexiconRoot.fromMap(Map<String, dynamic> map) {
    return LexiconRoot(
      strongsId: map['strongs_id']?.toString() ?? '',
      root: map['root']?.toString() ?? '',
      gloss: map['root_gloss']?.toString() ?? '',
      twot: map['twot']?.toString() ?? '',
    );
  }
}

/// One word built on a root, with how often it occurs.
class RootMember {
  final String strongsId;
  final String lemma;
  final String gloss;
  final int count;

  const RootMember({
    required this.strongsId,
    required this.lemma,
    required this.gloss,
    required this.count,
  });

  factory RootMember.fromMap(Map<String, dynamic> map) {
    return RootMember(
      strongsId: map['strongs_id']?.toString() ?? '',
      lemma: map['lemma']?.toString() ?? '',
      gloss: map['gloss']?.toString() ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }
}
