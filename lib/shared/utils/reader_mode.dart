import '../../data/models/lexicon_entry.dart';
import '../../data/models/srs_progress.dart';
import '../../data/models/word.dart';

/// Reader's Bible mode: like a printed Reader's Greek NT / Hebrew OT, words
/// below this whole-Bible frequency get an inline gloss. Printed readers
/// typically gloss words occurring fewer than ~30 times.
const int kReaderModeFrequencyThreshold = 30;

/// Words the user already knows (SRS mastery at or above this) render plain
/// even when rare — reading itself becomes the review loop.
const double kReaderModeMasterySuppression = 0.6;

const int _maxGlossLength = 24;

/// Decides which words of a verse get an inline gloss in reader mode.
///
/// Returns word.id -> gloss text. A word is glossed when:
/// - it has a lexicon key and a gloss,
/// - its whole-Bible frequency is below [kReaderModeFrequencyThreshold]
///   (unknown frequency counts as rare), and
/// - the user has not yet mastered it in SRS.
Map<int, String> selectReaderGlosses({
  required List<Word> words,
  required Map<String, int> frequencies,
  required Map<String, SrsProgress> progress,
  required Map<String, LexiconEntry> lexicon,
}) {
  final result = <int, String>{};

  for (final word in words) {
    final key = word.lexiconLookupKey;
    if (key == null) continue;

    final frequency = frequencies[key];
    if (frequency != null && frequency >= kReaderModeFrequencyThreshold) {
      continue;
    }

    final mastery = progress[key]?.masteryScore ?? 0.0;
    if (mastery >= kReaderModeMasterySuppression) {
      continue;
    }

    final gloss = lexicon[key]?.gloss?.trim();
    if (gloss == null || gloss.isEmpty) continue;

    result[word.id] = gloss.length <= _maxGlossLength
        ? gloss
        : '${gloss.substring(0, _maxGlossLength - 1)}…';
  }

  return result;
}
