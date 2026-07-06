import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/shared/utils/parsing_quiz.dart';

Word _word(int id, String morph) {
  return Word(
    id: id,
    verseId: 'GEN.1.$id',
    position: 1,
    displayText: 'w$id',
    lemma: 'l$id',
    morphCode: morph,
    language: 'grc',
  );
}

void main() {
  // Distinct Greek Robinson-style morph codes that decode differently.
  final pool = [
    _word(1, 'V-PAI-1S'),
    _word(2, 'V-AAI-3S'),
    _word(3, 'N-NSM'),
    _word(4, 'N-GSF'),
    _word(5, 'A-APN'),
    _word(6, 'V-PAI-1S'), // duplicate parsing of word 1
  ];

  group('buildParsingQuiz', () {
    test('builds questions with 4 unique options including the answer', () {
      final quiz = buildParsingQuiz(pool: pool, isHebrew: false, seed: 7);
      expect(quiz, isNotEmpty);
      for (final q in quiz) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options, contains(q.correctAnswer));
      }
    });

    test('duplicate parsings collapse into one question', () {
      final quiz = buildParsingQuiz(
        pool: pool,
        isHebrew: false,
        questionCount: 20,
        seed: 7,
      );
      final answers = quiz.map((q) => q.correctAnswer).toList();
      expect(answers.toSet().length, answers.length);
      expect(quiz.length, 5); // 6 words, 5 distinct parsings
    });

    test('same seed builds the same quiz', () {
      final a = buildParsingQuiz(pool: pool, isHebrew: false, seed: 3);
      final b = buildParsingQuiz(pool: pool, isHebrew: false, seed: 3);
      expect(
        a.map((q) => q.correctAnswer).toList(),
        b.map((q) => q.correctAnswer).toList(),
      );
      expect(
        a.map((q) => q.options.join('|')).toList(),
        b.map((q) => q.options.join('|')).toList(),
      );
    });

    test('too few distinct parsings yields no quiz', () {
      final tiny = [_word(1, 'V-PAI-1S'), _word(2, 'N-NSM')];
      expect(buildParsingQuiz(pool: tiny, isHebrew: false, seed: 1), isEmpty);
    });

    test('words without morph codes are ignored', () {
      final mixed = [
        ...pool,
        Word(
          id: 99,
          verseId: 'GEN.1.99',
          position: 1,
          displayText: 'bare',
          language: 'grc',
        ),
      ];
      final quiz = buildParsingQuiz(
        pool: mixed,
        isHebrew: false,
        questionCount: 20,
        seed: 7,
      );
      expect(quiz.length, 5);
    });
  });
}
