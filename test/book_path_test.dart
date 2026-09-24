import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/srs_progress.dart';
import 'package:original_bible/features/paths/book_path.dart';

SrsProgress _p(String id, {int reps = 0, double mastery = 0}) => SrsProgress(
  strongsId: id,
  repetitions: reps,
  masteryScore: mastery,
  nextReviewAt: DateTime(2026),
  lastReviewedAt: DateTime(2026),
);

void main() {
  // A prefix of 40 tokens, then 100 vocabulary tokens: 40, 30, 20, 10.
  const counts = {'PFX': 40, 'A': 40, 'B': 30, 'C': 20, 'D': 10};
  const studyable = {'A', 'B', 'C', 'D'};

  test('a beginner starts at zero: grammar is not counted as reading', () {
    final s = computePathStats(
      counts: counts,
      studyable: studyable,
      progress: const {},
    );
    expect(s.knownCoverage, 0);
    // A(40) + B(30) = 70 < 80, + C(20) = 90: three words to the goal.
    expect(s.wordsToGoal, 3);
  });

  test('learning and known words move the numbers separately', () {
    final s = computePathStats(
      counts: counts,
      studyable: studyable,
      progress: {'A': _p('A', reps: 3, mastery: 0.7), 'B': _p('B', reps: 1)},
    );
    expect(s.knownCoverage, 0.4);
    expect(s.learningCoverage, 0.7);
    expect(s.wordsToGoal, 1);
  });

  test('an empty book is not divided by zero', () {
    final s = computePathStats(
      counts: const {},
      studyable: const {},
      progress: const {},
    );
    expect(s.knownCoverage, 0);
  });
}
