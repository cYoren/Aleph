import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/reading/reading_screen.dart';
import '../features/reading/book_picker_screen.dart';
import '../features/reading/syntax_tree_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/bookmarks/bookmarks_screen.dart';
import '../features/onboarding/language_selection_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/startup/startup_gate_screen.dart';
import '../features/export/export_composer_screen.dart';
import '../features/memorization/memorization_practice_screen.dart';
import '../features/memorization/memorization_screen.dart';
import '../features/vocabulary/vocabulary_screen.dart';
import '../features/word_study/word_study_screen.dart';
import '../data/models/memorization_passage.dart';
import '../shared/widgets/app_scaffold.dart';
import '../data/models/verse.dart';
import '../data/models/word.dart';
import '../l10n/generated/app_localizations.dart';

final router = GoRouter(
  initialLocation: '/startup',
  routes: [
    GoRoute(
      path: '/startup',
      builder: (context, state) => const StartupGateScreen(),
    ),
    // Onboarding routes (no scaffold)
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Main app routes (with scaffold)
    ShellRoute(
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/reading',
          builder: (context, state) => const ReadingScreen(),
        ),
        GoRoute(
          path: '/bookmarks',
          builder: (context, state) => const BookmarksScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    // Full-screen modal for book picker
    GoRoute(
      path: '/book-picker',
      builder: (context, state) => const BookPickerScreen(),
    ),
    // Full-screen modal for export
    GoRoute(
      path: '/export',
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final extra = state.extra;
        if (extra is! Map<String, dynamic>) {
          return _RouteDataErrorScreen(
            title: l10n.exportUnavailableTitle,
            message: l10n.missingExportRouteData,
          );
        }

        final verse = extra['verse'];
        final translationText = extra['translationText'];
        final reference = extra['reference'];
        final isOT = extra['isOT'];
        if (verse is! Verse ||
            translationText is! String ||
            reference is! String ||
            isOT is! bool) {
          return _RouteDataErrorScreen(
            title: l10n.exportUnavailableTitle,
            message: l10n.invalidExportRouteData,
          );
        }

        return ExportComposerScreen(
          verse: verse,
          translationText: translationText,
          reference: reference,
          isOT: isOT,
        );
      },
    ),
    // Full-screen modal for vocabulary decks + SRS review
    GoRoute(
      path: '/vocabulary',
      builder: (context, state) => const VocabularyScreen(),
    ),
    // Passage memorization list + practice
    GoRoute(
      path: '/memorization',
      builder: (context, state) => const MemorizationScreen(),
    ),
    GoRoute(
      path: '/memorization-practice',
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final extra = state.extra;
        if (extra is! MemorizationPassage) {
          return _RouteDataErrorScreen(
            title: l10n.memorizationTitle,
            message: l10n.missingMemorizationRouteData,
          );
        }
        return MemorizationPracticeScreen(passage: extra);
      },
    ),
    // Full-screen modal for word study (concordance)
    GoRoute(
      path: '/word-study',
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final extra = state.extra;
        if (extra is! Map<String, dynamic>) {
          return _RouteDataErrorScreen(
            title: l10n.wordStudyUnavailableTitle,
            message: l10n.missingWordStudyRouteData,
          );
        }

        final lexiconKey = extra['lexiconKey'];
        final displayWord = extra['displayWord'];
        final isHebrew = extra['isHebrew'];
        if (lexiconKey is! String ||
            displayWord is! String ||
            isHebrew is! bool) {
          return _RouteDataErrorScreen(
            title: l10n.wordStudyUnavailableTitle,
            message: l10n.missingWordStudyRouteData,
          );
        }

        return WordStudyScreen(
          lexiconKey: lexiconKey,
          displayWord: displayWord,
          isHebrew: isHebrew,
        );
      },
    ),
    // Full-screen modal for syntax tree
    GoRoute(
      path: '/syntax-tree',
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final extra = state.extra;
        if (extra is! Map<String, dynamic>) {
          return _RouteDataErrorScreen(
            title: l10n.syntaxTreeUnavailableTitle,
            message: l10n.missingSyntaxTreeRouteData,
          );
        }

        final words = extra['words'];
        final isOT = extra['isOT'];
        final verseReference = extra['verseReference'];
        if (words is! List<Word> ||
            isOT is! bool ||
            verseReference is! String) {
          return _RouteDataErrorScreen(
            title: l10n.syntaxTreeUnavailableTitle,
            message: l10n.invalidSyntaxTreeRouteData,
          );
        }

        return SyntaxTreeScreen(
          words: words,
          isOT: isOT,
          verseReference: verseReference,
        );
      },
    ),
  ],
);

class _RouteDataErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const _RouteDataErrorScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
