import '../../data/models/word.dart';
import 'morphology_decoder.dart';

/// One "what form is this?" question: a surface form with its decoded
/// morphology as the correct answer among shuffled distractors.
class ParsingQuestion {
  final Word word;
  final String correctAnswer;
  final List<String> options;

  const ParsingQuestion({
    required this.word,
    required this.correctAnswer,
    required this.options,
  });
}

int _nextInt(int state) => (state * 1664525 + 1013904223) & 0x7fffffff;

/// Builds a parsing quiz from a pool of morphology-tagged words.
///
/// Questions use distinct decoded parsings so distractors are guaranteed to
/// be wrong; the [seed] makes construction deterministic for tests.
///
/// Pass [labels] (an English-label-to-localized-label map, see
/// `MorphologyLabels.map`) to spell the answers and options out in the reader's
/// language. The English parse is still what decides which parsings are
/// *distinct*; the localized strings are only used for display, and options are
/// de-duplicated after localization so two labels that happen to translate the
/// same can never produce a duplicate button.
List<ParsingQuestion> buildParsingQuiz({
  required List<Word> pool,
  required bool isHebrew,
  int questionCount = 8,
  int optionCount = 4,
  int seed = 0,
  Map<String, String>? labels,
}) {
  String display(String english) {
    if (labels == null || labels.isEmpty) return english;
    return english.split(', ').map((part) => labels[part] ?? part).join(', ');
  }

  // Keep one word per distinct decoded parsing (compared in English).
  final byParsing = <String, Word>{};
  for (final word in pool) {
    final code = word.morphCode;
    if (code == null || code.isEmpty) continue;
    final decoded = MorphologyDecoder.decode(code, isHebrew: isHebrew).trim();
    if (decoded.isEmpty || decoded == code) continue;
    byParsing.putIfAbsent(decoded, () => word);
  }

  final parsings = byParsing.keys.toList();
  if (parsings.length < optionCount) return const [];

  var state = seed == 0 ? 1 : (seed & 0x7fffffff);

  // Seeded shuffle of the distinct parsings.
  for (var i = parsings.length - 1; i > 0; i--) {
    state = _nextInt(state);
    final j = state % (i + 1);
    final tmp = parsings[i];
    parsings[i] = parsings[j];
    parsings[j] = tmp;
  }

  final questions = <ParsingQuestion>[];
  for (final answer in parsings.take(questionCount)) {
    final answerText = display(answer);
    final distractors = <String>[];
    // Walk the shuffled list from a seeded offset for varied distractors.
    state = _nextInt(state);
    var idx = state % parsings.length;
    var guard = 0;
    while (distractors.length < optionCount - 1 && guard < parsings.length * 2) {
      guard++;
      final candidate = display(parsings[idx % parsings.length]);
      // Distinct from the answer and from the distractors *after* translation.
      if (candidate != answerText && !distractors.contains(candidate)) {
        distractors.add(candidate);
      }
      idx++;
    }
    if (distractors.length < optionCount - 1) continue;

    final options = [answerText, ...distractors];
    for (var i = options.length - 1; i > 0; i--) {
      state = _nextInt(state);
      final j = state % (i + 1);
      final tmp = options[i];
      options[i] = options[j];
      options[j] = tmp;
    }

    questions.add(
      ParsingQuestion(
        word: byParsing[answer]!,
        correctAnswer: answerText,
        options: options,
      ),
    );
  }
  return questions;
}
