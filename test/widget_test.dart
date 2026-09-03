import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/translation.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/features/home/home_screen.dart';
import 'package:original_bible/features/reading/syntax_tree_screen.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/main.dart';
import 'package:original_bible/providers/database_provider.dart';
import 'package:original_bible/shared/widgets/tappable_word.dart';

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

Widget _buildTestApp(Widget child, {MediaQueryData? mediaQueryData}) {
  Widget app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  if (mediaQueryData != null) {
    app = MediaQuery(data: mediaQueryData, child: app);
  }

  return ProviderScope(
    overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
    child: app,
  );
}

void main() {
  group('App Initialization', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
          child: const OriginalBibleApp(),
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Home Screen', () {
    testWidgets('Home screen displays main sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // Home deliberately carries no settings shortcut and no app title:
      // Settings is a destination in the navigation bar, and repeating it
      // here was pure furniture.
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('Respects text scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          mediaQueryData: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });

  group('Theme', () {
    testWidgets('App supports dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [bibleDaoProvider.overrideWithValue(_FakeBibleDao())],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });

  group('Syntax Tree', () {
    testWidgets('Syntax tree screen renders without layout exceptions', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final words = [
        Word(
          id: 1,
          verseId: 'GEN.1.1',
          position: 0,
          displayText: 'בְּרֵאשִׁית',
          lemma: 'רֵאשִׁית',
          strongs: 'H7225',
          morphCode: 'HNcfsa',
          language: 'heb',
        ),
        Word(
          id: 2,
          verseId: 'GEN.1.1',
          position: 1,
          displayText: 'בָּרָא',
          lemma: 'בָּרָא',
          strongs: 'H1254',
          morphCode: 'HVqp3ms',
          language: 'heb',
        ),
        Word(
          id: 3,
          verseId: 'GEN.1.1',
          position: 2,
          displayText: 'אֱלֹהִים',
          lemma: 'אֱלֹהִים',
          strongs: 'H430',
          morphCode: 'HNcmpa',
          language: 'heb',
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          SyntaxTreeScreen(words: words, isOT: true, verseReference: 'GEN.1.1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syntax Tree'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Word Widgets', () {
    testWidgets('TappableWord disposes cleanly', (WidgetTester tester) async {
      final word = Word(
        id: 42,
        verseId: 'GEN.1.1',
        position: 0,
        displayText: 'בָּרָא',
        lemma: 'בָּרָא',
        strongs: 'H1254',
        morphCode: 'HVqp3ms',
        language: 'heb',
      );

      await tester.pumpWidget(
        _buildTestApp(
          Scaffold(
            body: Center(
              child: TappableWord(word: word, isOT: true, fontSize: 24),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(_buildTestApp(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
