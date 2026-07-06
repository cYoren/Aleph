import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../shared/utils/parsing_quiz.dart';

/// Fresh random quiz per visit (autoDispose), keyed by language.
final parsingQuizProvider =
    FutureProvider.autoDispose.family<List<ParsingQuestion>, String>((
      ref,
      language,
    ) async {
      final dao = ref.watch(bibleDaoProvider);
      final pool = await dao.getRandomMorphWords(language: language);
      return buildParsingQuiz(
        pool: pool,
        isHebrew: language == 'heb',
        seed: Random().nextInt(1 << 30),
      );
    });

/// Morphology drill: identify the grammatical form of a random word.
class ParsingQuizScreen extends ConsumerStatefulWidget {
  final String language;

  const ParsingQuizScreen({super.key, required this.language});

  @override
  ConsumerState<ParsingQuizScreen> createState() => _ParsingQuizScreenState();
}

class _ParsingQuizScreenState extends ConsumerState<ParsingQuizScreen> {
  int _index = 0;
  int _score = 0;
  String? _selected;

  bool get _isHebrew => widget.language == 'heb';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final quizAsync = ref.watch(parsingQuizProvider(widget.language));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parsingQuizTitle)),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(child: Text(l10n.noUsageDataAvailable));
          }
          if (_index >= questions.length) {
            return _buildSummary(questions.length, l10n, colorScheme);
          }
          return _buildQuestion(questions[_index], questions.length, l10n,
              colorScheme);
        },
      ),
    );
  }

  Widget _buildQuestion(
    ParsingQuestion question,
    int total,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final answered = _selected != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_index + 1} / $total',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.whatFormIsThis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  question.word.displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _isHebrew ? 'EzraSIL' : 'Gentium',
                    fontSize: 42,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (question.word.lemma != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    question.word.lemma!,
                    style: TextStyle(
                      fontFamily: _isHebrew ? 'EzraSIL' : 'Gentium',
                      fontSize: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...question.options.map((option) {
            final isCorrect = option == question.correctAnswer;
            final isSelected = option == _selected;

            Color? background;
            Color? foreground;
            if (answered && isCorrect) {
              background = Colors.green.withValues(alpha: 0.15);
              foreground = Colors.green.shade800;
            } else if (answered && isSelected && !isCorrect) {
              background = colorScheme.errorContainer.withValues(alpha: 0.5);
              foreground = colorScheme.error;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: answered
                    ? null
                    : () {
                        setState(() {
                          _selected = option;
                          if (isCorrect) _score++;
                        });
                      },
                style: OutlinedButton.styleFrom(
                  backgroundColor: background,
                  disabledForegroundColor:
                      foreground ?? colorScheme.onSurfaceVariant,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(option, style: const TextStyle(fontSize: 14)),
              ),
            );
          }),
          const Spacer(),
          if (answered)
            FilledButton(
              onPressed: () {
                setState(() {
                  _index++;
                  _selected = null;
                });
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.nextQuestion),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    int total,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _score >= total * 0.7 ? Icons.emoji_events : Icons.school,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.quizScore(_score, total),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                setState(() {
                  _index = 0;
                  _score = 0;
                  _selected = null;
                });
                ref.invalidate(parsingQuizProvider(widget.language));
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.practiceAgain),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.doneButton),
            ),
          ],
        ),
      ),
    );
  }
}
