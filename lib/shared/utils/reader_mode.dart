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

/// Ceiling on the adaptive bar. Without it, one hard word reviewed early could
/// gloss half the verse; with it, reader mode stays a reader and not a crib.
const int kReaderModeMaxAdaptiveThreshold = 500;

/// The frequency bar this reader's glosses start at.
///
/// A fixed bar of 30 assumes every word above it is known, which is false for
/// everyone at first and true for nobody exactly. The reader tells us where
/// their own edge is: a word they have met in review but not mastered is a word
/// the frequency table got wrong about them. Gloss up to the most frequent of
/// those, so the help follows the reader instead of the average.
int adaptiveReaderThreshold({
  required Map<String, SrsProgress> progress,
  required Map<String, int> frequencies,
}) {
  var threshold = kReaderModeFrequencyThreshold;
  for (final entry in progress.entries) {
    final item = entry.value;
    if (item.masteryScore >= kReaderModeMasterySuppression) continue;
    final frequency = frequencies[entry.key];
    if (frequency == null) continue;
    // The gloss rule is "rarer than the bar", so the frontier word itself needs
    // the bar to sit one past its frequency.
    if (frequency + 1 > threshold) threshold = frequency + 1;
  }
  return threshold.clamp(
    kReaderModeFrequencyThreshold,
    kReaderModeMaxAdaptiveThreshold,
  );
}

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
  int threshold = kReaderModeFrequencyThreshold,
}) {
  final result = <int, String>{};

  for (final word in words) {
    final key = word.lexiconLookupKey;
    if (key == null) continue;

    final frequency = frequencies[key];
    if (frequency != null && frequency >= threshold) {
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
