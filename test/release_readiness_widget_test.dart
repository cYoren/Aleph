import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/bookmark.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/translation.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/features/bookmarks/bookmarks_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/main.dart';
import 'package:original_bible/providers/bookmarks_provider.dart';
import 'package:original_bible/providers/books_provider.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:original_bible/shared/widgets/app_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBibleDao extends BibleDAO {
  @override
  Future<List<Book>> getBooks() async {
    return [
      Book(
        id: 1,
        abbreviation: 'GEN',
        name: 'Genesis',
        testament: 'OT',
        order: 1,
        chapterCount: 50,
      ),
      Book(
        id: 43,
        abbreviation: 'JHN',
        name: 'John',
        testament: 'NT',
        order: 43,
        chapterCount: 21,
      ),
    ];
  }

  @override
  Future<List<Verse>> getVersesForChapter(String bookId, int chapter) async {
    return [
      Verse(
        id: '$bookId.$chapter.1',
        bookId: bookId,
        chapter: chapter,
        verseNumber: 1,
        textContent: bookId == 'GEN'
            ? 'בְּרֵאשִׁית בָּרָא אֱלֹהִים'
            : 'Ἐν ἀρχῇ ἦν ὁ λόγος',
      ),
    ];
  }

  @override
  Future<Map<String, String>> getTranslationVersesForChapter(
    String bookId,
    int chapter,
    String translationId,
  ) async {
    return {'$bookId.$chapter.1': 'In the beginning'};
  }

  @override
  Future<SearchResults> search(
    String query, {
    required String translationId,
    int limit = 200,
  }) async => SearchResults.empty;

  @override
  Future<List<Word>> getWordsForVerse(String verseId) async => [];

  @override
  Future<LexiconEntry?> getLexiconEntry(String key) async => null;

  @override
  Future<List<Translation>> getTranslations() async {
    return [
      Translation(
        id: 'KJV',
        name: 'King James Version',
        language: 'en',
        abbreviation: 'KJV',
      ),
    ];
  }
}

Widget _buildLocalizedApp(
  Widget child, {
  String locale = 'en',
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Widget _buildLocalizedRouterApp({String locale = 'en'}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const AppScaffold(child: SizedBox.shrink()),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Release readiness widgets', () {
    testWidgets('bottom navigation uses localized home label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildLocalizedRouterApp(locale: 'pt'));
      await tester.pumpAndSettle();

      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Favoritos'), findsOneWidget);
    });

    testWidgets('removing a bookmark is immediate and offers undo', (
      WidgetTester tester,
    ) async {
      final bookmarks = [
        Bookmark(
          verseId: 'GEN.1.1',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      final books = [
        Book(
          id: 1,
          abbreviation: 'GEN',
          name: 'Genesis',
          testament: 'OT',
          order: 1,
          chapterCount: 50,
        ),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          const BookmarksScreen(),
          overrides: [
            bookmarksProvider.overrideWith((ref) async => bookmarks),
            booksProvider.overrideWith((ref) async => books),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('GEN.1.1')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Removing a bookmark is immediate and undoable, rather than a modal
      // confirmation. The card used to animate the swipe, snap back, and then
      // ask — visibly un-deleting itself before the question.
      expect(find.text('Bookmark removed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('bookmark time formatting is localized for Portuguese', (
      WidgetTester tester,
    ) async {
      final bookmarks = [
        Bookmark(
          verseId: 'GEN.1.1',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      final books = [
        Book(
          id: 1,
          abbreviation: 'GEN',
          name: 'Gênesis',
          testament: 'OT',
          order: 1,
          chapterCount: 50,
        ),
      ];

      await tester.pumpWidget(
        _buildLocalizedApp(
          const BookmarksScreen(),
          locale: 'pt',
          overrides: [
            bookmarksProvider.overrideWith((ref) async => bookmarks),
            booksProvider.overrideWith((ref) async => books),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BookmarksScreen));
      final l10n = AppLocalizations.of(context)!;
      final expected = _normalizeText(l10n.bookmarkTimeDaysAgo(2));
      final renderedTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .map(_normalizeText)
          .toList();

      expect(renderedTexts, contains(expected));
    });

    testWidgets('onboarding flow reaches home without exceptions', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'hasCompletedOnboarding': false,
        'translation': 'KJV',
        'appLanguage': 'en',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
          child: const OriginalBibleApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Language'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Home itself has no settings button; the bar underneath it does, and
      // its unselected icon is the outlined one.
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

String _normalizeText(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
