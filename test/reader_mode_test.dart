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

    test('a word the reader is stuck on is glossed past the fixed bar', () {
      // 120 occurrences, so the printed-reader bar of 30 skips it — but this
      // reader has it in review and has not mastered it, which is the app's own
      // evidence that the bar is wrong for them.
      final words = [_word(1, strongs: 'H7777')];
      final frequencies = {'H7777': 120};
      final progress = {'H7777': _progress(0.2)};
      final lexicon = {'H7777': _entry('stuck word')};

      expect(
        selectReaderGlosses(
          words: words,
          frequencies: frequencies,
          progress: progress,
          lexicon: lexicon,
        ),
        isEmpty,
      );

      final threshold = adaptiveReaderThreshold(
        progress: progress,
        frequencies: frequencies,
      );
      expect(threshold, 121);
      expect(
        selectReaderGlosses(
          words: words,
          frequencies: frequencies,
          progress: progress,
          lexicon: lexicon,
          threshold: threshold,
        ),
        {1: 'stuck word'},
      );
    });
  });

  group('adaptiveReaderThreshold', () {
    test('starts at the printed-reader convention with nothing in review', () {
      expect(
        adaptiveReaderThreshold(progress: {}, frequencies: {}),
        kReaderModeFrequencyThreshold,
      );
    });

    test('rises to the most frequent word the reader has not mastered', () {
      final threshold = adaptiveReaderThreshold(
        progress: {
          'H1': _progress(0.1),
          'H2': _progress(0.3),
        },
        frequencies: {'H1': 400, 'H2': 90},
      );
      expect(threshold, 401);
    });

    test('words already mastered do not move the bar', () {
      final threshold = adaptiveReaderThreshold(
        progress: {'H1': _progress(kReaderModeMasterySuppression)},
        frequencies: {'H1': 900},
      );
      expect(threshold, kReaderModeFrequencyThreshold);
    });

    test('never falls below the base bar and never runs away', () {
      expect(
        adaptiveReaderThreshold(
          progress: {'H1': _progress(0.1)},
          frequencies: {'H1': 3},
        ),
        kReaderModeFrequencyThreshold,
      );
      expect(
        adaptiveReaderThreshold(
          progress: {'H1': _progress(0.1)},
          frequencies: {'H1': 40000},
        ),
        kReaderModeMaxAdaptiveThreshold,
      );
    });
  });
}
