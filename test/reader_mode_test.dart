import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/srs_progress.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/shared/utils/reader_mode.dart';

Word _word(int id, {String? strongs, String? lemma}) {
  return Word(
    id: id,
    verseId: 'GEN.1.1',
    position: id,
    displayText: 'w$id',
    strongs: strongs,
    lemma: lemma,
    language: 'heb',
  );
}

LexiconEntry _entry(String gloss) {
  return LexiconEntry.fromMap({'lemma': 'x', 'gloss': gloss});
}

SrsProgress _progress(double mastery) {
  final now = DateTime(2026, 7, 5);
  return SrsProgress(
    strongsId: 'H1',
    masteryScore: mastery,
    nextReviewAt: now,
    lastReviewedAt: now,
  );
}

void main() {
  group('selectReaderGlosses', () {
    test('rare word gets a gloss', () {
      final result = selectReaderGlosses(
        words: [_word(1, strongs: 'H1')],
        frequencies: {'H1': 5},
        progress: {},
        lexicon: {'H1': _entry('rare thing')},
      );
      expect(result, {1: 'rare thing'});
    });

    test('frequent word is not glossed', () {
      final result = selectReaderGlosses(
        words: [_word(1, strongs: 'H1')],
        frequencies: {'H1': kReaderModeFrequencyThreshold},
        progress: {},
        lexicon: {'H1': _entry('common thing')},
      );
      expect(result, isEmpty);
    });

    test('unknown frequency counts as rare', () {
      final result = selectReaderGlosses(
        words: [_word(1, strongs: 'H1')],
        frequencies: {},
        progress: {},
        lexicon: {'H1': _entry('mystery')},
      );
      expect(result, {1: 'mystery'});
    });

    test('mastered word is suppressed even when rare', () {
      final result = selectReaderGlosses(
        words: [_word(1, strongs: 'H1')],
        frequencies: {'H1': 3},
        progress: {'H1': _progress(kReaderModeMasterySuppression)},
        lexicon: {'H1': _entry('learned already')},
      );
      expect(result, isEmpty);
    });

    test('word below mastery cutoff still gets a gloss', () {
      final result = selectReaderGlosses(
        words: [_word(1, strongs: 'H1')],
        frequencies: {'H1': 3},
        progress: {'H1': _progress(0.2)},
        lexicon: {'H1': _entry('still learning')},
      );
      expect(result, {1: 'still learning'});
    });

    test('word without lexicon key or gloss is skipped', () {
      final result = selectReaderGlosses(
        words: [_word(1), _word(2, strongs: 'H2')],
        frequencies: {},
        progress: {},
        lexicon: {},
      );
      expect(result, isEmpty);
    });

    test('lemma fallback works when strongs is missing', () {
      final result = selectReaderGlosses(
        words: [_word(1, lemma: 'אור')],
        frequencies: {'אור': 4},
        progress: {},
        lexicon: {'אור': _entry('light')},
      );
      expect(result, {1: 'light'});
    });

    test('long glosses are truncated with an ellipsis', () {
      final longGloss = 'an extremely long interlinear gloss text';
      final result = selectReaderGlosses(
        words: [_word(1, strongs: 'H1')],
        frequencies: {'H1': 2},
        progress: {},
        lexicon: {'H1': _entry(longGloss)},
      );
      final gloss = result[1]!;
      expect(gloss.endsWith('…'), isTrue);
      expect(gloss.length, lessThan(longGloss.length));
    });
  });
}
