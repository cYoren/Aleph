// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:original_bible/data/database/daos/bible_dao.dart';
import 'package:original_bible/data/models/book.dart';
import 'package:original_bible/data/models/lexicon_entry.dart';
import 'package:original_bible/data/models/translation.dart';
import 'package:original_bible/data/models/verse.dart';
import 'package:original_bible/data/models/word.dart';
import 'package:original_bible/l10n/generated/app_localizations.dart';
import 'package:original_bible/providers/database_provider.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:original_bible/app/theme.dart';
import 'package:original_bible/features/onboarding/onboarding_screen.dart';

import 'package:original_bible/shared/widgets/tappable_word.dart';
import 'package:original_bible/shared/widgets/definition_sheet.dart';
import 'package:original_bible/features/explain/explain_provider.dart';

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
  Future<List<Verse>> search(
    String query, {
    required String translationId,
  }) async => [];

  @override
  Future<List<Word>> getWordsForVerse(String verseId) async => [
    Word.fromMap({
      "id": 1,
      "verse_id": 1,
      "position": 1,
      "word": "בְּ",
      "lemma": "בְּ",
      "morph": "R",
      "strongs": "H0871A",
      "language": "heb",
    }),
    Word.fromMap({
      "id": 2,
      "verse_id": 1,
      "position": 2,
      "word": "רֵאשִׁ֖ית",
      "lemma": "רֵאשִׁית",
      "morph": "Ncfsa",
      "strongs": "H7225",
      "language": "heb",
    }),
    Word.fromMap({
      "id": 3,
      "verse_id": 1,
      "position": 3,
      "word": "בָּרָ֣א",
      "lemma": "בָּרָא",
      "morph": "Vqp3ms",
      "strongs": "H1254",
      "language": "heb",
    }),
    Word.fromMap({
      "id": 4,
      "verse_id": 1,
      "position": 4,
      "word": "אֱלֹהִ֑ים",
      "lemma": "אֱלֹהִים",
      "morph": "Ncmpa",
      "strongs": "H0430",
      "language": "heb",
    }),
  ];

  @override
  Future<LexiconEntry?> getLexiconEntry(String key) async => LexiconEntry(
    strongsId: key,
    lemma: 'רֵאשִׁית',
    gloss: 'beginning',
    definition: 'The beginning.',
  );

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

Future<GoRouter> _start(
  WidgetTester tester, {
  bool ai = false,
  String locale = 'en',
  double scale = 1,
}) async {
  SharedPreferences.setMockInitialValues({'appLanguage': locale});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: '/reading',
        builder: (context, state) =>
            const Scaffold(body: Text('Reader destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bibleDaoProvider.overrideWithValue(_FakeBibleDao()),
        explainConfiguredProvider.overrideWithValue(ai),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(locale),
        theme: AppTheme.light(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('first action opens a real dictionary lookup before setup', (
    tester,
  ) async {
    await _start(tester);
    expect(find.byType(TappableWord), findsNWidgets(3));
    // Proclitic prefixes do not make an empty first dictionary experience.
    expect(
      tester
          .widgetList<TappableWord>(find.byType(TappableWord))
          .any((w) => w.word.strongs == 'H0871A'),
      isFalse,
    );
    await tester.tap(find.byType(TappableWord).first);
    await tester.pumpAndSettle();
    expect(find.byType(DefinitionSheet), findsOneWidget);
    expect(find.text('The beginning.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('two steps persist completion and enter the reader', (
    tester,
  ) async {
    await _start(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Which scriptures are you reading?'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Reader destination'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('hasCompletedOnboarding'),
      isTrue,
    );
  });
  testWidgets('skip enters the reader', (tester) async {
    await _start(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Reader destination'), findsOneWidget);
  });
  testWidgets('configured AI still presents its choice and privacy note', (
    tester,
  ) async {
    await _start(tester, ai: true);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      find.textContaining('This is the only part of the app'),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('German at double text size stays scrollable and completes', (
    tester,
  ) async {
    await _start(tester, locale: 'de', scale: 2);
    final context = tester.element(find.byType(OnboardingScreen));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.next));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(l10n.getStarted));
    await tester.pumpAndSettle();
    expect(find.text('Reader destination'), findsOneWidget);
  });
}
