/// Guards the numbered sense list the definition sheet renders.
///
/// The source dictionaries nest senses to arbitrary depth and sometimes leave a
/// parent with no text of its own (that is how BDB marks the binyanim). Getting
/// the layout wrong reads as a wall of indented fragments, so the two rules —
/// drop empty nodes, measure depth against surviving ancestors — are pinned
/// here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/lexicon_sense.dart';

LexiconSense _sense({
  required int level,
  String number = '',
  String heading = '',
  String summary = '',
  String strongsId = 'H1288',
}) {
  return LexiconSense(
    strongsId: strongsId,
    source: 'BDB',
    level: level,
    number: number,
    heading: heading,
    summary: summary,
  );
}

void main() {
  group('layoutSenses', () {
    test('keeps the dictionary numbering and its own ordering', () {
      final rows = layoutSenses([
        _sense(level: 0, number: '1', heading: 'father of individual'),
        _sense(level: 0, number: '2', heading: 'head of household'),
      ]);

      expect(rows.map((r) => r.marker), ['1', '2']);
      expect(rows.map((r) => r.heading), [
        'father of individual',
        'head of household',
      ]);
      expect(rows.every((r) => r.depth == 0), isTrue);
    });

    test('indents children under their parent', () {
      final rows = layoutSenses([
        _sense(level: 0, number: '1', heading: 'rulers, judges'),
        _sense(level: 1, number: 'a', heading: 'divine ones'),
        _sense(level: 1, number: 'b', heading: 'angels'),
      ]);

      expect(rows.map((r) => r.depth), [0, 1, 1]);
    });

    test('a parent with no text of its own does not leave a hole', () {
      // BDB marks a binyan as a bare <sense> holding only children.
      final rows = layoutSenses([
        _sense(level: 0, heading: 'Qal'),
        _sense(level: 1, number: '1', heading: 'kneel down'),
        _sense(level: 1, number: '2', heading: 'bless'),
      ]);

      expect(rows.map((r) => r.heading), ['Qal', 'kneel down', 'bless']);
      expect(rows.map((r) => r.depth), [0, 1, 1]);
    });

    test('fully empty nodes are dropped and their children move up', () {
      final rows = layoutSenses([
        _sense(level: 0),
        _sense(level: 1, heading: 'bless'),
      ]);

      expect(rows, hasLength(1));
      expect(rows.single.heading, 'bless');
      expect(rows.single.depth, 0);
    });

    test('depth is capped so deep entries stay readable on a phone', () {
      final rows = layoutSenses([
        _sense(level: 0, heading: 'a'),
        _sense(level: 1, heading: 'b'),
        _sense(level: 2, heading: 'c'),
        _sense(level: 3, heading: 'd'),
        _sense(level: 4, heading: 'e'),
      ]);

      expect(rows.map((r) => r.depth), [0, 1, 2, 2, 2]);
    });

    test('the marker falls back to a bullet when there is no number', () {
      final rows = layoutSenses([_sense(level: 0, heading: 'Qal')]);
      expect(rows.single.marker, '·');
    });

    test('an empty list stays empty', () {
      expect(layoutSenses(const []), isEmpty);
    });
  });

  group('LexiconSense.fromMap', () {
    test('tolerates missing columns', () {
      final sense = LexiconSense.fromMap({'strongs_id': 'G3056'});
      expect(sense.strongsId, 'G3056');
      expect(sense.level, 0);
      expect(sense.heading, '');
      expect(sense.hasHeading, isFalse);
    });
  });
}
